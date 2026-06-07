/// Escapes text for use inside a Nix double-quoted string.
#[must_use]
pub fn escape_string(value: &str) -> String {
    escape_string_inner(value, false)
}

/// Escapes text for contexts that also treat `$` as special.
#[must_use]
pub fn escape_string_and_dollar(value: &str) -> String {
    escape_string_inner(value, true)
}

/// Wraps text in a Nix double-quoted string literal.
#[must_use]
pub fn string_literal(value: &str) -> String {
    format!("\"{}\"", escape_string(value))
}

/// Wraps text in a Nix double-quoted string literal and escapes `$`.
#[must_use]
pub fn string_literal_escaping_dollar(value: &str) -> String {
    format!("\"{}\"", escape_string_and_dollar(value))
}

fn escape_string_inner(value: &str, escape_dollar: bool) -> String {
    let mut escaped = String::with_capacity(value.len());
    for ch in value.chars() {
        match ch {
            '\\' => escaped.push_str("\\\\"),
            '"' => escaped.push_str("\\\""),
            '$' if escape_dollar => escaped.push_str("\\$"),
            '\n' => escaped.push_str("\\n"),
            '\r' => escaped.push_str("\\r"),
            '\t' => escaped.push_str("\\t"),
            _ => escaped.push(ch),
        }
    }
    escaped
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn escapes_double_quoted_string_content() {
        assert_eq!(escape_string("a\\b\"c\n\r\t"), "a\\\\b\\\"c\\n\\r\\t");
    }

    #[test]
    fn dollar_escaping_is_opt_in() {
        assert_eq!(escape_string("$HOME"), "$HOME");
        assert_eq!(escape_string_and_dollar("$HOME"), "\\$HOME");
    }

    #[test]
    fn wraps_string_literals() {
        assert_eq!(string_literal("hello"), "\"hello\"");
        assert_eq!(string_literal_escaping_dollar("$HOME"), "\"\\$HOME\"");
    }
}
