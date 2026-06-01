use std::io::Write as _;

use dotfiles_common::process::{self, argv};

const PLAYERS: &[&str] = &["spotify", "rhythmbox", "Feishin"];
const NO_PLAYER_MESSAGE: &str = "No Player Found";

fn main() {
    if let Err(err) = run() {
        eprintln!("error: {err}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), Box<dyn std::error::Error>> {
    let output = process::capture_with_env(
        &argv(["playerctl", "-a", "metadata"]),
        std::iter::empty::<(String, String)>(),
    );
    let Ok(output) = output else {
        println!("{NO_PLAYER_MESSAGE}");
        return Ok(());
    };
    if !output.succeeded() {
        println!("{NO_PLAYER_MESSAGE}");
        return Ok(());
    }

    let metadata = String::from_utf8_lossy(&output.stdout);
    match render_track_text(&metadata) {
        Some(text) if !text.is_empty() => println!("{text}"),
        _ => println!("{NO_PLAYER_MESSAGE}"),
    }
    std::io::stdout().flush()?;
    Ok(())
}

fn render_track_text(metadata: &str) -> Option<String> {
    let mut artists = Vec::new();
    let mut titles = Vec::new();
    for line in metadata.lines().filter(|line| is_wanted_player(line)) {
        if let Some(value) = read_metadata(line, "xesam:artist") {
            artists.push(value);
        }
        if let Some(value) = read_metadata(line, "xesam:title") {
            titles.push(value);
        }
    }

    if artists.is_empty() && titles.is_empty() {
        return None;
    }

    let mut text = String::new();
    text.push_str(&artists.join("\n"));
    if !artists.is_empty() && !titles.is_empty() {
        text.push_str(" - ");
    }
    text.push_str(&titles.join("\n"));
    Some(collapse_spaces(&text))
}

fn is_wanted_player(line: &str) -> bool {
    PLAYERS.iter().any(|player| line.contains(player))
}

fn read_metadata(line: &str, key: &str) -> Option<String> {
    let index = line.find(key)?;
    Some(line[index + key.len()..].trim().to_owned())
}

fn collapse_spaces(text: &str) -> String {
    text.split_whitespace().collect::<Vec<_>>().join(" ")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn compacts_track_metadata() {
        let metadata = "spotify xesam:artist  Artist\nspotify xesam:title Song";
        assert_eq!(
            render_track_text(metadata).as_deref(),
            Some("Artist - Song")
        );
    }

    #[test]
    fn ignores_unwanted_players() {
        assert!(render_track_text("vlc xesam:title Movie").is_none());
    }
}
