/**
 * List GitHub Actions workflow YAML files in the current repository.
 */
export async function listWorkflowFiles(): Promise<string[]> {
  return Array.fromAsync(
    new Bun.Glob('.github/workflows/*.{yml,yaml}').scan({
      cwd: process.cwd(),
      followSymlinks: false,
      onlyFiles: true,
    }),
  ).then((files) => files.sort((a, b) => a.localeCompare(b)));
}

/**
 * Hash workflow file names and contents into a stable repository fingerprint.
 */
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
