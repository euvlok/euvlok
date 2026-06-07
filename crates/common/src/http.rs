use std::path::Path;

use fs_err as fs;
pub use reqwest::StatusCode;
use reqwest::blocking::{Client as ReqwestClient, ClientBuilder, Response};
use reqwest::header::{HeaderMap, LOCATION};
use reqwest::redirect::Policy;
use serde::Serialize;
use serde::de::DeserializeOwned;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum HttpError {
    #[error(transparent)]
    Request(#[from] reqwest::Error),
    #[error(transparent)]
    Io(#[from] std::io::Error),
}

pub struct Client {
    inner: ReqwestClient,
}

pub struct TextResponse {
    pub status: StatusCode,
    pub body: String,
}

impl Client {
    /// Creates an HTTP client with the supplied user agent.
    ///
    /// # Errors
    ///
    /// Returns an error if the underlying client cannot be built.
    pub fn new(user_agent: impl Into<String>) -> Result<Self, HttpError> {
        Ok(Self {
            inner: client_builder(user_agent.into()).build()?,
        })
    }

    /// Creates an HTTP client that does not follow redirects automatically.
    ///
    /// # Errors
    ///
    /// Returns an error if the underlying client cannot be built.
    pub fn new_without_redirects(user_agent: impl Into<String>) -> Result<Self, HttpError> {
        Ok(Self {
            inner: client_builder(user_agent.into())
                .redirect(Policy::none())
                .build()?,
        })
    }

    fn get(&self, url: &str) -> Result<Response, HttpError> {
        Ok(self.inner.get(url).send()?.error_for_status()?)
    }

    fn text_response(
        &self,
        request: reqwest::blocking::RequestBuilder,
    ) -> Result<TextResponse, HttpError> {
        let response = request.send()?;
        let status = response.status();
        let body = response.text()?;
        Ok(TextResponse { status, body })
    }

    /// Downloads `url` with bearer authentication and returns status plus body text.
    ///
    /// Unlike [`Self::text`], non-successful HTTP status codes are preserved in
    /// the returned response so API callers can include the response body in
    /// their own domain-specific errors.
    ///
    /// # Errors
    ///
    /// Returns an error if the request or response body read fails.
    pub fn get_bearer_text(&self, url: &str, token: &str) -> Result<TextResponse, HttpError> {
        self.text_response(self.inner.get(url).bearer_auth(token))
    }

    /// Issues a GET request and returns status plus response body text without
    /// converting non-success status codes into errors.
    ///
    /// # Errors
    ///
    /// Returns an error if the request or response body read fails.
    pub fn get_text_response(&self, url: &str) -> Result<TextResponse, HttpError> {
        self.text_response(self.inner.get(url))
    }

    /// Returns the redirect target for a request when the response includes one.
    ///
    /// # Errors
    ///
    /// Returns an error if the request fails or the Location header is not valid UTF-8.
    pub fn redirect_location(&self, url: &str) -> Result<Option<String>, HttpError> {
        let response = self.inner.get(url).send()?;
        if !response.status().is_redirection() {
            return Ok(None);
        }
        header_location(response.headers()).map_err(HttpError::Io)
    }

    /// Posts a JSON body with bearer authentication and returns status plus body text.
    ///
    /// # Errors
    ///
    /// Returns an error if the request, serialization, or response body read fails.
    pub fn post_json_bearer_text<T: Serialize + ?Sized>(
        &self,
        url: &str,
        token: &str,
        body: &T,
    ) -> Result<TextResponse, HttpError> {
        self.text_response(self.inner.post(url).bearer_auth(token).json(body))
    }

    /// Opens a response body reader for `url`.
    ///
    /// # Errors
    ///
    /// Returns an error if the request fails or the response status is unsuccessful.
    pub fn reader(&self, url: &str) -> Result<impl std::io::Read + use<>, HttpError> {
        self.get(url)
    }

    /// Downloads `url` as bytes.
    ///
    /// # Errors
    ///
    /// Returns an error if the request or response body read fails.
    pub fn bytes(&self, url: &str) -> Result<Vec<u8>, HttpError> {
        Ok(self.get(url)?.bytes()?.to_vec())
    }

    /// Downloads `url` as text.
    ///
    /// # Errors
    ///
    /// Returns an error if the request or response body read fails.
    pub fn text(&self, url: &str) -> Result<String, HttpError> {
        Ok(self.get(url)?.text()?)
    }

    /// Downloads and deserializes JSON from `url`.
    ///
    /// # Errors
    ///
    /// Returns an error if the request, body read, or JSON decoding fails.
    pub fn json<T: DeserializeOwned>(&self, url: &str) -> Result<T, HttpError> {
        Ok(self.get(url)?.json()?)
    }

    /// Downloads `url` to `path`.
    ///
    /// # Errors
    ///
    /// Returns an error if the request, directory creation, file creation, or copy fails.
    pub fn download_file(&self, url: &str, path: impl AsRef<Path>) -> Result<(), HttpError> {
        let path = path.as_ref();
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)?;
        }
        let mut response = self.get(url)?;
        let mut file = fs::File::create(path)?;
        response.copy_to(&mut file)?;
        Ok(())
    }
}

fn client_builder(user_agent: String) -> ClientBuilder {
    ReqwestClient::builder().user_agent(user_agent).http1_only()
}

fn header_location(headers: &HeaderMap) -> std::io::Result<Option<String>> {
    headers
        .get(LOCATION)
        .map(|value| {
            value
                .to_str()
                .map(ToOwned::to_owned)
                .map_err(std::io::Error::other)
        })
        .transpose()
}

#[cfg(test)]
mod tests {
    use std::io::{Read, Write};
    use std::net::TcpListener;

    use super::*;

    #[test]
    fn download_file_creates_parent_and_writes_body() {
        let listener = TcpListener::bind("127.0.0.1:0").expect("bind test server");
        let addr = listener.local_addr().expect("server address");
        let server = std::thread::spawn(move || {
            let (mut stream, _) = listener.accept().expect("accept request");
            let mut request = [0; 1024];
            let bytes_read = stream.read(&mut request).expect("read request");
            assert_ne!(bytes_read, 0);
            stream
                .write_all(b"HTTP/1.1 200 OK\r\nContent-Length: 11\r\n\r\nhello world")
                .expect("write response");
        });
        let temp = tempfile::tempdir().expect("tempdir");
        let path = temp.path().join("nested").join("download.txt");
        let client = Client::new("dotfiles-common-test").expect("client");

        client
            .download_file(&format!("http://{addr}/payload"), &path)
            .expect("download file");

        server.join().expect("server thread");
        assert_eq!(
            fs::read_to_string(path).expect("read download"),
            "hello world"
        );
    }
}
