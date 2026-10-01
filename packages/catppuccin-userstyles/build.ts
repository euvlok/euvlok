#!/usr/bin/env bun
import { execFileSync } from "node:child_process";
import { mkdir, mkdtemp, readdir, rename, rm } from "node:fs/promises";
import { basename, dirname, join, resolve } from "node:path";
import { isDeepStrictEqual, parseArgs } from "node:util";
import usercssMeta, { type Metadata, type Variable } from "usercss-meta";

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
const isExcluded = (file: string) => {
  const id = basename(dirname(file));
  return excludedIds.includes(id) && !includedIds.has(id);
};
const excluded = files
  .filter(isExcluded)
  .map((file) => basename(dirname(file)));
const styles = await Array.fromAsync(
  files.filter((file) => !isExcluded(file)),
  readStyle,
);
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
type Selections = Readonly<Record<string, string>>;
type ImportPlan = Readonly<{ name: string; selections?: Selections }>;
type Asset = Readonly<{ name: string; sha256: string }>;
const imports: readonly ImportPlan[] = [
  { name: "catppuccin-import.json" },
  ...darkFlavors.flatMap((darkFlavor) =>
    accents.map((accentColor) => ({
      name: `catppuccin-latte-${darkFlavor}-${accentColor}-import.json`,
      selections: { lightFlavor: "latte", darkFlavor, accentColor },
    })),
  ),
];
// Publish the complete directory only after every variant has been validated
const staging = await mkdtemp(join(dirname(output), ".catppuccin-build-"));
try {
  const assets = await Array.fromAsync(imports, ({ name, selections }) =>
    writeImport(
      staging,
      name,
      selections
        ? styles.map((style) => styleVariant(style, selections))
        : styles,
    ),
  );
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
  console.log(
    `Generated ${assets.length} Stylus imports with ${styles.length} styles from ${revision}`,
  );
  console.log(`Excluded: ${excluded.join(", ") || "none"}`);
} finally {
  await rm(staging, { recursive: true, force: true });
}

async function readStyle(file: string): Promise<Style> {
  const id = basename(dirname(file));
  try {
    const sourceCode = (await Bun.file(file).text()).replace(/\r\n?/g, "\n");
    const { metadata } = usercssMeta.parse(sourceCode);
    if (metadata.preprocessor !== "less") {
      throw new Error(`Unsupported preprocessor: ${metadata.preprocessor}`);
    }
    return {
      enabled: true,
      name: metadata.name,
      description: metadata.description,
      author: metadata.author,
      url: metadata.url,
      updateUrl: metadata.updateURL,
      usercssData: metadata,
      sourceCode,
      originalDigest: digest(sourceCode),
    };
  } catch (cause) {
    throw new Error(`Failed to read userstyle ${id}`, { cause });
  }
}

function styleVariant(style: Style, selections: Selections): Style {
  const metadata = structuredClone(style.usercssData);
  const usercssData = mapVariables(metadata, (variable, name) => {
    const value = selections[name];
    if (value === undefined) return variable;
    if (!selectOptions(metadata, name).includes(value)) {
      throw new Error(`Unknown ${name} value ${value} in ${style.name}`);
    }
    return { ...variable, default: value, value };
  });
  if (!headerPattern.test(style.sourceCode)) {
    throw new Error(`Missing UserStyle header in ${style.name}`);
  }
  // A replacement callback preserves literal $ sequences in metadata
  const sourceCode = style.sourceCode.replace(headerPattern, () =>
    usercssMeta.stringify(usercssData),
  );
  const parsed = usercssMeta.parse(sourceCode).metadata;
  // Selected values live in the import metadata, outside the source header
  const expected = mapVariables(usercssData, (variable) => ({
    ...variable,
    value: null,
  }));
  if (!isDeepStrictEqual(parsed, expected)) {
    throw new Error(`Header metadata differs in ${style.name}`);
  }
  return {
    ...style,
    usercssData,
    sourceCode,
    originalDigest: digest(sourceCode),
  };
}

function mapVariables(
  metadata: Metadata,
  transform: (variable: Variable, name: string) => Variable,
): Metadata {
  return metadata.vars
    ? {
        ...metadata,
        vars: Object.fromEntries(
          Object.entries(metadata.vars).map(([name, variable]) => [
            name,
            transform(variable, name),
          ]),
        ),
      }
    : metadata;
}

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

async function writeImport(
  directory: string,
  name: string,
  entries: readonly Style[],
): Promise<Asset> {
  const json = `${JSON.stringify([settings, ...entries], null, 2)}\n`;
  await Bun.write(join(directory, name), json);
  return {
    name,
    sha256: new Bun.CryptoHasher("sha256").update(json).digest("hex"),
  };
}
