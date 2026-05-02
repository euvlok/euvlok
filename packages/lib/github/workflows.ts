import { relative } from 'node:path';
import { create as createGlob } from '@actions/glob';

export async function listWorkflowFiles(): Promise<string[]> {
  const globber = await createGlob('.github/workflows/*.yml\n.github/workflows/*.yaml', {
    followSymbolicLinks: false,
  });
  const files = await globber.glob();
  return files.map((file) => relative(process.cwd(), file)).sort((a, b) => a.localeCompare(b));
}
