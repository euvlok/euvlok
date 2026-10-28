# Run with:
# nix shell --impure --file ./eval.nix --command eval-performance INSTALLABLE [OUTPUT_DIRECTORY]
# Uses the caller's nix so benchmarks measure the installed evaluator
# EVAL_RUNS=5 EVAL_WARMUPS=1 EVAL_PROFILE=1 control sampling and profiling
# --runs, --warmups, and --profile override those environment defaults
# Writes per-run outputs, timings, stats, metrics, and summary.json
# Profiling writes folded stacks, plus an SVG when flamegraph.pl is on PATH
{
  pkgs ? import <nixpkgs> { },
}:
let
  python = pkgs.python315;
in
pkgs.writers.makePythonWriter python python.pkgs pkgs.buildPackages.python315.pkgs
  "/bin/eval-performance"
  {
    libraries = [ python.pkgs.click ];
  }
  ''
    import json
    import os
    import platform
    import shutil
    import subprocess
    import tempfile
    from pathlib import Path
    from statistics import fmean

    import click


    PLATFORM = platform.system()
    METRICS = (
        "wallSeconds", "cpuSeconds", "maxRssBytes", "evaluatorBytes",
        "gcBytes", "values", "functionCalls", "primopCalls", "thunks", "lookups",
    )


    def write_json(path, value):
        path.write_text(json.dumps(value, indent=2) + "\n")


    def execute(command, output, **env):
        with output.open("wb") as stream:
            subprocess.run(command, check=True, stdout=stream,
                           env=os.environ | env)


    def run_eval(evaluate, output_dir, series, run):
        prefix = output_dir / series / str(run)
        stats_path = prefix.with_suffix(".stats.json")
        timing_path = prefix.with_suffix(".time.txt")
        click.echo(f"{series} {run}: {evaluate}", err=True)
        if PLATFORM == "Darwin":
            timed = ["/usr/bin/time", "-lp", "-o", timing_path]
        else:
            timed = [
                "${pkgs.time}/bin/time",
                "-f", "real %e\nuser %U\nsys %S\nmax_rss_kib %M",
                "-o", timing_path,
            ]
        execute(timed + evaluate, prefix.with_suffix(".out"),
                NIX_SHOW_STATS="1", NIX_SHOW_STATS_PATH=str(stats_path))
        rows = [
            line.split(maxsplit=1)
            for line in timing_path.read_text().splitlines() if line.strip()
        ]
        timing = dict(rows)
        memory = {label: int(value) for value, label in rows if value.isdecimal()}
        stats = json.loads(stats_path.read_text())
        metrics = {
            "platform": PLATFORM,
            "run": run,
            "wallSeconds": float(timing["real"]),
            "cpuSeconds": stats["cpuTime"],
            "maxRssBytes": (
                memory["maximum resident set size"] if PLATFORM == "Darwin"
                else int(timing["max_rss_kib"]) * 1024
            ),
            "peakFootprintBytes": memory.get("peak memory footprint"),
            "evaluatorBytes": sum(
                stats[key]["bytes"] for key in ("envs", "list", "sets", "values")
            ),
            "gcBytes": stats["gc"]["totalBytes"],
            "values": stats["values"]["number"],
            "functionCalls": stats["nrFunctionCalls"],
            "primopCalls": stats["nrPrimOpCalls"],
            "thunks": stats["nrThunks"],
            "lookups": stats["nrLookups"],
        }
        write_json(prefix.with_suffix(".metrics.json"), metrics)
        return metrics


    @click.command()
    @click.argument("installable")
    @click.argument("output_dir", required=False, type=click.Path(path_type=Path))
    @click.option("--runs", envvar="EVAL_RUNS", default=5, type=click.IntRange(1))
    @click.option("--warmups", envvar="EVAL_WARMUPS", default=1,
                  type=click.IntRange(0))
    @click.option("--profile", envvar="EVAL_PROFILE", default="1",
                  type=click.Choice(["0", "1"]))
    def main(installable, output_dir, runs, warmups, profile):
        if PLATFORM not in ("Darwin", "Linux"):
            raise click.UsageError(f"unsupported platform: {PLATFORM}")
        output_dir = output_dir or (
            Path(tempfile.gettempdir()) / f"euvlok-eval-{os.getpid()}"
        )
        output_dir.mkdir(parents=True)
        for series in ("runs", "warmups"):
            (output_dir / series).mkdir()
        evaluate = ["nix", "eval", "--no-eval-cache", "--raw", installable]
        for run in range(1, warmups + 1):
            run_eval(evaluate, output_dir, "warmups", run)
        measurements = [
            run_eval(evaluate, output_dir, "runs", run)
            for run in range(1, runs + 1)
        ]
        summary = {
            "installable": installable, "platform": PLATFORM,
            "warmups": warmups, "runs": runs, "metrics": {},
        }
        for name in METRICS:
            values = [measurement[name] for measurement in measurements]
            summary["metrics"][name] = {
                "mean": fmean(values), "min": min(values), "max": max(values),
            }
        write_json(output_dir / "summary.json", summary)
        if profile == "1":
            execute(evaluate + [
                "--eval-profiler", "flamegraph",
                "--eval-profile-file", output_dir / "profile.folded",
            ], output_dir / "profile.out")
            if flamegraph := shutil.which("flamegraph.pl"):
                execute([
                    flamegraph, "--title", f"Nix evaluation: {installable}",
                    output_dir / "profile.folded",
                ], output_dir / "profile.svg")
        click.echo(f"results: {output_dir}", err=True)
        click.echo(json.dumps(summary, indent=2))


    if __name__ == "__main__":
        try:
            main()
        except subprocess.CalledProcessError as error:
            raise SystemExit(max(1, error.returncode))
        except OSError as error:
            click.echo(str(error), err=True)
            raise SystemExit(2)
  ''
