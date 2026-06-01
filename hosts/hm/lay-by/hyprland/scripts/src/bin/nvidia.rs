use std::io::Write as _;

use dotfiles_common::process::{self, argv};

const HOT_THRESHOLD_CELSIUS: i64 = 76;
const HOT_COLOR: &str = "#FE3120";

fn main() {
    if let Err(err) = run() {
        eprintln!("error: {err}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), Box<dyn std::error::Error>> {
    let Some((utilization, temperature)) = read_gpu_status()? else {
        return Ok(());
    };
    println!("{}", format_gpu_status(&utilization, temperature));
    std::io::stdout().flush()?;
    Ok(())
}

fn read_gpu_status() -> Result<Option<(String, i64)>, Box<dyn std::error::Error>> {
    let Some(temperature) = query_metric("--query-gpu=temperature.gpu")? else {
        return Ok(None);
    };
    let Some(utilization) = query_metric("--query-gpu=utilization.gpu")? else {
        return Ok(None);
    };
    let temperature = temperature.trim().parse::<i64>()?;
    Ok(Some((utilization.trim().to_owned(), temperature)))
}

fn query_metric(metric: &str) -> Result<Option<String>, Box<dyn std::error::Error>> {
    let output = process::capture_with_env(
        &argv(["nvidia-smi", metric, "--format=csv,noheader,nounits"]),
        std::iter::empty::<(String, String)>(),
    );
    let Ok(output) = output else {
        return Ok(None);
    };
    if !output.succeeded() {
        return Ok(None);
    }
    Ok(Some(String::from_utf8(output.stdout)?))
}

fn format_gpu_status(utilization: &str, temperature: i64) -> String {
    if temperature > HOT_THRESHOLD_CELSIUS {
        format!("{utilization} %{{F{HOT_COLOR}}}{temperature}°C")
    } else {
        format!("{utilization}% {temperature}°C")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn formats_hot_temperatures() {
        assert_eq!(format_gpu_status("42", 76), "42% 76°C");
        assert_eq!(format_gpu_status("88", 77), "88 %{F#FE3120}77°C");
    }
}
