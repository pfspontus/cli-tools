import sharp from "sharp";
import { fileURLToPath } from "node:url";
import path from "node:path";

function hexToRgba(hex) {
  let h = hex.replace(/^#/, "").trim();
  if (h.length === 3) h = h.split("").map(c => c + c).join("");
  if (h.length === 6) h = h + "ff";
  return {
    r: parseInt(h.slice(0, 2), 16),
    g: parseInt(h.slice(2, 4), 16),
    b: parseInt(h.slice(4, 6), 16),
    a: parseInt(h.slice(6, 8), 16),
  };
}

function printUsageAndExit(message) {
  if (message) {
    console.error(message);
  }
  console.error(
    "Usage: node recolor-gradient.mjs input.png output.png [--color #hex] [--opacity 0-1] [--flip] [--flop]",
  );
  process.exit(1);
}

export async function recolorGradient(
  input,
  output,
  {
    color = null,
    opacity = null,
    flip = false,
    flop = false,
  } = {},
) {
  const img = sharp(input).ensureAlpha();
  const { data, info } = await img.raw().toBuffer({ resolveWithObject: true });

  const target = color ? hexToRgba(color) : null;

  for (let i = 0; i < data.length; i += 4) {
    const r = data[i];
    const g = data[i + 1];
    const b = data[i + 2];

    // Bevara gradienten baserat på ljushet:
    if (target) {
      const lum = (r + g + b) / 3;
      const factor = lum / 255;

      data[i] = Math.round(target.r * factor);
      data[i + 1] = Math.round(target.g * factor);
      data[i + 2] = Math.round(target.b * factor);
    }

    // Opacity-reglering:
    if (opacity !== null) {
      data[i + 3] = Math.round(data[i + 3] * opacity);
    }
  }

  let pipeline = await sharp(data, {
    raw: { width: info.width, height: info.height, channels: 4 },
  });

  if (flip) pipeline = pipeline.flip();
  if (flop) pipeline = pipeline.flop();

  await pipeline.png().toFile(output);

  return output;
}

async function main() {
  const args = process.argv.slice(2);

  if (args.length < 2) {
    printUsageAndExit("Missing input/output arguments.");
  }

  const input = args[0];
  const output = args[1];

  let color = null;
  let opacity = null;
  let flip = false;
  let flop = false;

  for (let i = 2; i < args.length; i++) {
    const arg = args[i];

    if (arg === "--color") {
      if (i + 1 >= args.length || args[i + 1].startsWith("--")) {
        printUsageAndExit("Missing value for --color.");
      }
      color = args[i + 1];
      i++;
    } else if (arg === "--opacity") {
      if (i + 1 >= args.length || args[i + 1].startsWith("--")) {
        printUsageAndExit("Missing value for --opacity.");
      }
      opacity = parseFloat(args[i + 1]);
      if (Number.isNaN(opacity)) {
        printUsageAndExit(
          "Invalid value for --opacity. Expected a number between 0 and 1.",
        );
      }
      i++;
    } else if (arg === "--flip") {
      flip = true;
    } else if (arg === "--flop") {
      flop = true;
    }
  }

  await recolorGradient(input, output, { color, opacity, flip, flop });
  console.log(`Done: ${output}`);
}

const isDirectRun =
  process.argv[1] &&
  fileURLToPath(import.meta.url) === path.resolve(process.argv[1]);

if (isDirectRun) {
  main().catch(err => {
    console.error(err);
    process.exit(1);
  });
}
