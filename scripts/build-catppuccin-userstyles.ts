// Generates Stylus import variants from the base import.json built by
// catppuccin/userstyles' `deno task ci:stylus-import`.
// Produces one file per (lightFlavor × darkFlavor × accent) combination.

const BASE_FILE = "/tmp/userstyles/dist/import.json";
const OUTPUT_DIR = "/tmp/userstyles-output";

Deno.mkdirSync(OUTPUT_DIR, { recursive: true });

const baseData = JSON.parse(await Deno.readTextFile(BASE_FILE));

// Copy the unmodified base as-is
await Deno.writeTextFile(
  `${OUTPUT_DIR}/catppuccin-import.json`,
  JSON.stringify(baseData, null, 2),
);
console.log(`Base: ${baseData.length - 1} styles`);

// Derive accent list from the first style's metadata (all styles share the same options)
const firstStyle = baseData.find((s: Record<string, unknown>) => s.usercssData);
const accentOptions = firstStyle.usercssData.vars.accentColor.options as {
  name: string;
  label: string;
}[];
const accents = accentOptions.map((o) => o.name);

const darkFlavors = ["frappe", "macchiato", "mocha"];

function setSelectDefault(
  sourceCode: string,
  varName: string,
  label: string,
  target: string,
): string {
  const re = new RegExp(`@var select ${varName} "${label}" \\[([^\\]]+)\\]`);
  return sourceCode.replace(re, (full, opts) => {
    const updated = opts.replace(/\*/g, "").replace(
      new RegExp(`(${target}:[^"]*)`),
      `$1*`,
    );
    return `@var select ${varName} "${label}" [${updated}]`;
  });
}

for (const dark of darkFlavors) {
  for (const accent of accents) {
    const variant = structuredClone(baseData);

    for (let i = 1; i < variant.length; i++) {
      const s = variant[i];
      const vars = s.usercssData?.vars;
      if (vars?.lightFlavor) {
        vars.lightFlavor.default = "latte";
        vars.lightFlavor.value = "latte";
      }
      if (vars?.darkFlavor) {
        vars.darkFlavor.default = dark;
        vars.darkFlavor.value = dark;
      }
      if (vars?.accentColor) {
        vars.accentColor.default = accent;
        vars.accentColor.value = accent;
      }
      if (s.sourceCode) {
        let src = s.sourceCode;
        src = setSelectDefault(src, "lightFlavor", "Light Flavor", "latte");
        src = setSelectDefault(src, "darkFlavor", "Dark Flavor", dark);
        src = setSelectDefault(src, "accentColor", "Accent", accent);
        s.sourceCode = src;
      }
    }

    const name = `catppuccin-latte-${dark}-${accent}-import.json`;
    await Deno.writeTextFile(`${OUTPUT_DIR}/${name}`, JSON.stringify(variant, null, 2));
    console.log(name);
  }
}

console.log(`\nTotal variants: ${darkFlavors.length * accents.length}`);
