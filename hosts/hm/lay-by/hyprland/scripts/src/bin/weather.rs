use std::io::Write as _;

use dotfiles_common::http::Client;
use serde::Deserialize;

const API: &str = "https://api.openweathermap.org/data/2.5";
const KEY: &str = "a78c793d7f2431574ca9c5f56e74fc9b";
const CITY: &str = "4701458";
const UNITS: &str = "imperial";
const SYMBOL: &str = "°";

#[derive(Debug, Deserialize)]
struct WeatherResponse {
    weather: Vec<Weather>,
    main: Main,
}

#[derive(Debug, Deserialize)]
struct Weather {
    description: String,
    icon: String,
}

#[derive(Debug, Deserialize)]
struct Main {
    temp: f64,
}

fn main() {
    if let Err(err) = run() {
        eprintln!("error: {err}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), Box<dyn std::error::Error>> {
    let Some(text) = fetch_weather()? else {
        return Ok(());
    };
    println!("{text}");
    std::io::stdout().flush()?;
    Ok(())
}

fn fetch_weather() -> Result<Option<String>, Box<dyn std::error::Error>> {
    let client = Client::new("lay-by-waybar-weather")?;
    let response = client.get_text_response(&weather_url())?;
    if !response.status.is_success() {
        return Ok(None);
    }
    let weather = serde_json::from_str::<WeatherResponse>(&response.body)?;
    Ok(render_weather(&weather))
}

fn weather_url() -> String {
    format!(
        "{API}/weather?appid={KEY}&{}&units={UNITS}",
        city_param(CITY)
    )
}

fn city_param(city: &str) -> String {
    if city.parse::<u64>().is_ok() {
        format!("id={city}")
    } else {
        format!("q={city}")
    }
}

fn render_weather(response: &WeatherResponse) -> Option<String> {
    let current = response.weather.first()?;
    Some(format!(
        "{} {}, {}{SYMBOL}",
        icon_for(&current.icon),
        current.description,
        response.main.temp as i64,
    ))
}

fn icon_for(code: &str) -> &'static str {
    match code {
        "01d" | "01n" => "\u{e30d} ",
        "02d" | "02n" => "\u{e302} ",
        value if value.starts_with("03") => "\u{e33d} ",
        value if value.starts_with("04") => "\u{e312} ",
        "09d" | "09n" => "\u{e314} ",
        "10d" => "\u{e304} ",
        "10n" => "\u{e324} ",
        "11d" | "11n" => "\u{e315} ",
        "13d" | "13n" => "\u{e36f} ",
        "50d" | "50n" => "\u{e35d} ",
        _ => "\u{f00d}\t",
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn formats_weather() {
        let response = WeatherResponse {
            weather: vec![Weather {
                description: "clear sky".to_owned(),
                icon: "01d".to_owned(),
            }],
            main: Main { temp: 72.9 },
        };
        assert_eq!(
            render_weather(&response).as_deref(),
            Some("\u{e30d}  clear sky, 72°")
        );
    }

    #[test]
    fn selects_city_parameter() {
        assert_eq!(city_param("4701458"), "id=4701458");
        assert_eq!(city_param("Sofia"), "q=Sofia");
    }
}
