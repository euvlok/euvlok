export async function listWorkflowFiles(): Promise<string[]> {
  return Array.fromAsync(
    new Bun.Glob('.github/workflows/*.{yml,yaml}').scan({
      cwd: process.cwd(),
      followSymlinks: false,
      onlyFiles: true,
    }),
  ).then((files) => files.sort((a, b) => a.localeCompare(b)));
}

export async function hashWorkflowFiles(): Promise<string> {
  const files = await listWorkflowFiles();
  const hasher = new Bun.CryptoHasher('sha256');

  for (const file of files) {
    hasher.update(`${file}\0`);
    hasher.update(new Uint8Array(await Bun.file(file).arrayBuffer()));
    hasher.update('\0');
  }

  return hasher.digest('hex');
}
