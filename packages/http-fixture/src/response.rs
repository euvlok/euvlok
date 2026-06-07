use std::collections::BTreeMap;
use std::io::Cursor;

use serde_json::Value;
use tiny_http::{Header, Response, StatusCode};

use crate::error::{Error, Result};

pub(crate) type FixtureHttpResponse = Response<Cursor<Vec<u8>>>;

#[derive(Debug)]
pub(crate) struct FixtureResponse {
    pub(crate) status: StatusCode,
    pub(crate) content_type: Option<String>,
    pub(crate) headers: BTreeMap<String, String>,
    pub(crate) body: Body,
}

#[derive(Debug)]
pub(crate) enum Body {
    Text(String),
    Html(String),
    Json(Value),
    Empty,
}

impl FixtureResponse {
    pub(crate) fn to_response(&self) -> Result<FixtureHttpResponse> {
        let (body, inferred_content_type) = match &self.body {
            Body::Text(body) => (body.as_bytes().to_vec(), Some("text/plain; charset=utf-8")),
            Body::Html(body) => (body.as_bytes().to_vec(), Some("text/html; charset=utf-8")),
            Body::Json(body) => (serde_json::to_vec(body)?, Some("application/json")),
            Body::Empty => (Vec::new(), None),
        };
        let mut response = Response::from_data(body).with_status_code(self.status);
        if let Some(content_type) = self.content_type.as_deref().or(inferred_content_type) {
            response = response.with_header(make_header("Content-Type", content_type)?);
        }
        for (name, value) in &self.headers {
            response = response.with_header(make_header(name, value)?);
        }
        Ok(response)
    }
}

pub(crate) fn make_header(name: &str, value: &str) -> Result<Header> {
    Header::from_bytes(name, value).map_err(|_| Error::Header {
        name: name.to_owned(),
    })
}

pub(crate) fn not_found_response() -> Result<FixtureHttpResponse> {
    let body = serde_json::json!({ "error": "not_found" });
    Ok(Response::from_data(serde_json::to_vec(&body)?)
        .with_status_code(StatusCode(404))
        .with_header(make_header("Content-Type", "application/json")?))
}

pub(crate) fn internal_error_response() -> FixtureHttpResponse {
    let response =
        Response::from_string(r#"{"error":"internal_error"}"#).with_status_code(StatusCode(500));
    match make_header("Content-Type", "application/json") {
        Ok(header) => response.with_header(header),
        Err(_) => response,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;
    use std::io::Read;

    #[test]
    fn builds_json_html_headers_and_not_found_responses()
    -> std::result::Result<(), Box<dyn std::error::Error>> {
        let mut headers = BTreeMap::new();
        headers.insert("X-Fixture".into(), "yes".into());
        let response = FixtureResponse {
            status: StatusCode(202),
            content_type: None,
            headers,
            body: Body::Json(json!({ "ok": true })),
        }
        .to_response()?;

        assert_eq!(response.status_code(), StatusCode(202));
        assert_header(&response, "Content-Type", "application/json");
        assert_header(&response, "X-Fixture", "yes");
        assert_eq!(body_text(response)?, r#"{"ok":true}"#);

        let response = FixtureResponse {
            status: StatusCode(200),
            content_type: None,
            headers: BTreeMap::new(),
            body: Body::Html("<h1>ok</h1>".into()),
        }
        .to_response()?;
        assert_header(&response, "Content-Type", "text/html; charset=utf-8");

        let response = not_found_response()?;
        assert_eq!(response.status_code(), StatusCode(404));
        assert_eq!(body_text(response)?, r#"{"error":"not_found"}"#);
        Ok(())
    }

    fn assert_header(response: &FixtureHttpResponse, name: &str, value: &str) {
        assert!(response.headers().iter().any(|header| {
            header.field.to_string().eq_ignore_ascii_case(name) && header.value.as_str() == value
        }));
    }

    fn body_text(response: FixtureHttpResponse) -> std::io::Result<String> {
        let mut reader = response.into_reader();
        let mut body = String::new();
        reader.read_to_string(&mut body)?;
        Ok(body)
    }
}
