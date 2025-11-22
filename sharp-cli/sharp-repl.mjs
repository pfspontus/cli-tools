#!/usr/bin/env node
import repl from "node:repl";
import sharp from "sharp";
import { recolorGradient } from "./recolor-gradient.mjs";

console.log("Sharp REPL");
console.log("Context:");
console.log('  - sharp            (sharp image library)');
console.log('  - load(path)       -> sharp(input)');
console.log('  - save(image, out) -> writes to disk');
console.log('  - recolorGradient(input, output, options)');
console.log("");
console.log('Tips: use top-level await, e.g.');
console.log('  const img = load("in.png")');
console.log('  await img.resize(200).toFile("out.png")');
console.log("");
console.log('Type help() for a quick reference.');
console.log("");

const r = repl.start({
  prompt: "sharp> ",
  useGlobal: true,
});

r.context.sharp = sharp;
r.context.load = input => sharp(input);
r.context.save = async (image, output) => {
  await image.toFile(output);
  return output;
};
r.context.recolorGradient = recolorGradient;

function help() {
  console.log("Sharp REPL helpers:");
  console.log('  sharp            - the sharp module');
  console.log('  load(path)       - create a sharp instance from file');
  console.log('  save(img, path)  - write a sharp pipeline to file');
  console.log('  recolorGradient(input, output, { color, opacity, flip, flop })');
  console.log("");
  console.log("Examples:");
  console.log('  const img = load("in.png")');
  console.log('  const meta = await img.metadata()');
  console.log('  await img.resize(200).toFile("out.png")');
  console.log("");
  console.log('  await recolorGradient(');
  console.log('    "mask.png",');
  console.log('    "mask-red.png",');
  console.log('    { color: "#ff0000", opacity: 0.8, flip: true },');
  console.log("  );");
}

r.context.help = help;

