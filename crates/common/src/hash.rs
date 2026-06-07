use base64::Engine as _;
use sha2::{Digest as _, Sha256};

/// Formats bytes as a Nix-compatible sha256 SRI hash.
#[must_use]
pub fn sha256_sri(bytes: impl AsRef<[u8]>) -> String {
    sri_from_sha256_digest(&Sha256::digest(bytes))
}

/// Formats an existing sha256 digest as a Nix-compatible SRI hash.
#[must_use]
pub fn sri_from_sha256_digest(digest: &[u8]) -> String {
    format!(
        "sha256-{}",
        base64::engine::general_purpose::STANDARD.encode(digest)
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn formats_sha256_sri_hashes() {
        assert_eq!(
            sha256_sri(b"hello world"),
            "sha256-uU0nuZNNPgilLlLX2n2r+sSE7+N6U4DukIj3rOLvzek="
        );
    }
}
