import argparse
import filecmp
import shutil
from pathlib import Path

import msgpack


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("destination", type=Path)
    parser.add_argument("libraries", nargs="+")
    args = parser.parse_args()
    args.destination.mkdir(parents=True, exist_ok=True)
    mapping_name = "TensileLiteLibrary_lazy_Mapping.dat"
    combined_mapping = {}
    # CMake rebuilds these shared outputs for all requested architectures
    shared_outputs = {"hipblasltExtOpLibrary.dat", "hipblasltTransform.hsaco"}

    for library in args.libraries:
        architecture, source_name = library.split("=", 1)
        source = Path(source_name)
        masters = (
            source / f"TensileLibrary_lazy_{architecture}.dat",
            source / f"TensileLibrary_{architecture}.dat",
        )
        if not any(master.is_file() for master in masters):
            raise ValueError(f"Missing master library for {architecture}")

        with (source / mapping_name).open("rb") as handle:
            mapping = msgpack.unpack(handle, strict_map_key=False)
        overlapping = combined_mapping.keys() & mapping.keys()
        if overlapping:
            raise ValueError(f"Overlapping solution indices for {architecture}")
        combined_mapping.update(mapping)

        for file in sorted(source.iterdir()):
            if file.name in shared_outputs or file.name in (
                mapping_name,
                ".tensile-solution-index",
            ):
                continue
            if not file.is_file():
                raise ValueError(f"Unexpected library entry: {file}")
            destination = args.destination / file.name
            if destination.exists():
                if not filecmp.cmp(file, destination, shallow=False):
                    raise ValueError(f"Conflicting library file: {file.name}")
            else:
                shutil.copy2(file, destination)
        print(f"Merged device library for {architecture}", flush=True)

    with (args.destination / mapping_name).open("wb") as handle:
        msgpack.pack(dict(sorted(combined_mapping.items())), handle)


if __name__ == "__main__":
    main()
