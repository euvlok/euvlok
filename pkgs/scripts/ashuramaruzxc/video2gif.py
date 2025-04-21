import argparse
import os
import subprocess
from glob import glob


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Script that re encodes videos to gifs"
    )
    parser.add_argument("path", type=str)
    args = parser.parse_args()

    types = ["mp4", "MP4", "mov", "MOV", "webm", "WEBM", "mkv", "MKV"]
    palette = "/tmp/palette.png"
    filters = "fps=24"

    try:
        subprocess.check_call(
            ["ffmpeg", "-help"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
    except subprocess.CalledProcessError:
        print("Нема в тебе ffmpeg'а лох")
        return None

    for file_type in types:
        files = glob(f"{args.path}/**/*.{file_type}", recursive=True)
        not_gifs = [file for file in files if os.path.isfile(file)]
        for file_input in not_gifs:
            dst = os.path.splitext(file_input)[0] + ".gif"
            print(f"Encoding {file_input} to {dst}")
            subprocess.call(
                [
                    "ffmpeg",
                    "-v",
                    "warning",
                    "-i",
                    file_input,
                    "-vf",
                    f"{filters},palettegen",
                    "-y",
                    palette,
                ]
            )
            subprocess.call(
                [
                    "ffmpeg",
                    "-v",
                    "warning",
                    "-i",
                    file_input,
                    "-i",
                    palette,
                    "-lavfi",
                    f"{filters} [x]; [x][1:v] paletteuse",
                    "-y",
                    dst,
                ]
            )
            os.remove(file_input)


if __name__ == "__main__":
    main()
