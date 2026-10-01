#!/usr/bin/env bun
import { execFileSync } from "node:child_process";
import { mkdir, mkdtemp, readdir, rename, rm } from "node:fs/promises";
import { basename, dirname, join, resolve } from "node:path";
import { isDeepStrictEqual, parseArgs } from "node:util";
import usercssMeta, { type Metadata } from "usercss-meta";

const excludedIds = ["gmail", "shinigami-eyes"];
const darkFlavors = ["frappe", "macchiato", "mocha"];
const headerPattern = /\/\*\s*==UserStyle==[\s\S]*?==\/UserStyle==\s*\*\//;
const settings = {
  settings: {
    updateInterval: 24,
    updateOnlyEnabled: true,
    patchCsp: true,
    "editor.linter": "",
  },
};

type Style = {
  enabled: true;
  name: string;
  description: string | undefined;
  author: string | undefined;
  url: string | undefined;
  updateUrl: string | undefined;
  usercssData: Metadata;
  sourceCode: string;
  originalDigest: string;
};

const { values, positionals } = parseArgs({
  args: Bun.argv.slice(2),
  allowPositionals: true,
  options: {
    include: { type: "string", multiple: true },
    help: { type: "boolean", short: "h" },
  },
});
if (values.help) {
  console.log(
    "Usage: catppuccin-userstyles [--include gmail,shinigami-eyes] <upstream checkout> <empty output directory>",
  );
  process.exit(0);
}
const [rootArg, outputArg] = positionals;
if (positionals.length !== 2 || !rootArg || !outputArg) {
  throw new Error(
    "Expected an upstream checkout and an empty output directory",
  );
}
const includedIds = new Set(
  values.include?.flatMap((value) => value.split(",").map((id) => id.trim())),
);
for (const id of includedIds) {
  if (!excludedIds.includes(id))
    throw new Error(`Unknown --include style: ${id}`);
}
const root = resolve(rootArg);
const output = resolve(outputArg);
const revision = execFileSync("git", ["-C", root, "rev-parse", "HEAD"], {
  encoding: "utf8",
}).trim();
const files = (
  await Array.fromAsync(
    new Bun.Glob("styles/*/catppuccin.user.less").scan({
      cwd: root,
      absolute: true,
      onlyFiles: true,
    }),
  )
).sort();
const excluded: string[] = [];
const styles: Style[] = [];
for (const file of files) {
  const id = basename(dirname(file));
  if (excludedIds.includes(id) && !includedIds.has(id)) {
    excluded.push(id);
    continue;
  }
  try {
    const sourceCode = (await Bun.file(file).text()).replace(/\r\n?/g, "\n");
    const { metadata } = usercssMeta.parse(sourceCode);
    if (metadata.preprocessor !== "less") {
      throw new Error(`Unsupported preprocessor: ${metadata.preprocessor}`);
    }
    styles.push({
      enabled: true,
      name: metadata.name,
      description: metadata.description,
      author: metadata.author,
      url: metadata.url,
      updateUrl: metadata.updateURL,
      usercssData: metadata,
      sourceCode,
      originalDigest: digest(sourceCode),
    });
  } catch (cause) {
    throw new Error(`Failed to read userstyle ${id}`, { cause });
  }
}
if (!styles.length) throw new Error(`No userstyles found under ${root}/styles`);

// Derive accents from every style so discovery does not depend on file order
const accents = [
  ...new Set(
    styles.flatMap((style) => {
      const variable = style.usercssData.vars?.accentColor;
      return variable ? selectOptions(style.usercssData, "accentColor") : [];
    }),
  ),
].sort();
if (!accents.length) throw new Error("No accentColor options found");
await mkdir(output, { recursive: true });
if ((await readdir(output)).length) {
  throw new Error(`Output directory must be empty: ${output}`);
}
const assets: { name: string; sha256: string }[] = [];
// Publish the complete directory only after every variant has been validated
const staging = await mkdtemp(join(dirname(output), ".catppuccin-build-"));
try {
  await writeImport("catppuccin-import.json", styles);
  for (const darkFlavor of darkFlavors) {
    for (const accentColor of accents) {
      const variants = styles.map((style) => {
        const variant = structuredClone(style);
        for (const [name, value] of Object.entries({
          lightFlavor: "latte",
          darkFlavor,
          accentColor,
        })) {
          const variable = variant.usercssData.vars?.[name];
          // Some styles have no light mode or accent selector
          if (!variable) continue;
          if (!selectOptions(variant.usercssData, name).includes(value)) {
            throw new Error(`Unknown ${name} value ${value} in ${style.name}`);
          }
          variable.default = value;
          variable.value = value;
        }
        if (!headerPattern.test(variant.sourceCode)) {
          throw new Error(`Missing UserStyle header in ${style.name}`);
        }
        // A replacement callback preserves literal $ sequences in metadata
        variant.sourceCode = variant.sourceCode.replace(headerPattern, () =>
          usercssMeta.stringify(variant.usercssData),
        );
        const parsed = usercssMeta.parse(variant.sourceCode).metadata;
        const expected = structuredClone(variant.usercssData);
        // Selected values live in the import metadata, outside the source header
        for (const variable of Object.values(expected.vars ?? {})) {
          variable.value = null;
        }
        if (!isDeepStrictEqual(parsed, expected)) {
          throw new Error(`Header metadata differs in ${style.name}`);
        }
        variant.originalDigest = digest(variant.sourceCode);
        return variant;
      });
      await writeImport(
        `catppuccin-latte-${darkFlavor}-${accentColor}-import.json`,
        variants,
      );
    }
  }
  await Bun.write(
    join(staging, "manifest.json"),
    `${JSON.stringify(
      {
        upstream: "https://github.com/catppuccin/userstyles",
        revision,
        styleCount: styles.length,
        excluded,
        lightFlavor: "latte",
        darkFlavors,
        accents,
        assets,
      },
      null,
      2,
    )}\n`,
  );
  await rename(staging, output);
} finally {
  await rm(staging, { recursive: true, force: true });
}
console.log(
  `Generated ${assets.length} Stylus imports with ${styles.length} styles from ${revision}`,
);
console.log(`Excluded: ${excluded.join(", ") || "none"}`);

function selectOptions(metadata: Metadata, name: string): string[] {
  const variable = metadata.vars?.[name];
  if (
    variable?.type !== "select" ||
    !Array.isArray(variable.options) ||
    !variable.options.length
  ) {
    throw new Error(`Invalid select variable ${name} in ${metadata.name}`);
  }
  return variable.options.map((option) => option.name);
}

function digest(source: string): string {
  // Stylus hashes UserCSS source with SHA-1 to detect upstream updates
  return new Bun.CryptoHasher("sha1").update(source).digest("hex");
}

async function writeImport(name: string, entries: Style[]): Promise<void> {
  const json = `${JSON.stringify([settings, ...entries], null, 2)}\n`;
  await Bun.write(join(staging, name), json);
  assets.push({
    name,
    sha256: new Bun.CryptoHasher("sha256").update(json).digest("hex"),
  });
}
