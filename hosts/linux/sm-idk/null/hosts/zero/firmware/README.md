This directory intentionally does not contain firmware blobs.

The `zero` host reads Apple Silicon peripheral firmware from `/boot/asahi` or
`/mnt/boot/asahi` when those paths exist. These files are extracted from macOS by
the Asahi installer and are non-redistributable, so they should not live in Git.
