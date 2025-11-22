#!/usr/bin/env node
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
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

const defaultCompleter = r.completer;

r.completer = (line, callback) => {
  const stringContext = getIncompleteStringContext(line);
  if (!stringContext) {
    return runDefaultCompleter(defaultCompleter, r, line, callback);
  }

  let matches;
  try {
    matches = completeFilePath(stringContext.partial);
  } catch (error) {
    return runDefaultCompleter(defaultCompleter, r, line, callback);
  }

  if (matches.length === 0) {
    return runDefaultCompleter(defaultCompleter, r, line, callback);
  }

  if (typeof callback === "function") {
    return callback(null, [matches, stringContext.partial]);
  }

  return [matches, stringContext.partial];
};

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

function runDefaultCompleter(defaultCompleterFn, replServer, line, callback) {
  if (typeof defaultCompleterFn !== "function") {
    if (typeof callback === "function") {
      callback(null, [[], line]);
      return;
    }

    return [[], line];
  }

  if (defaultCompleterFn.length < 2) {
    const result = defaultCompleterFn.call(replServer, line);
    if (typeof callback === "function") {
      callback(null, result);
      return;
    }
    return result;
  }

  return defaultCompleterFn.call(replServer, line, callback);
}

function getIncompleteStringContext(line) {
  let currentQuote = null;
  let startIndex = -1;

  for (let i = 0; i < line.length; i += 1) {
    const char = line[i];
    if (!isQuote(char) || isEscaped(line, i)) {
      continue;
    }

    if (currentQuote === char) {
      currentQuote = null;
      startIndex = -1;
    } else if (currentQuote === null) {
      currentQuote = char;
      startIndex = i;
    }
  }

  if (!currentQuote || startIndex < 0) {
    return null;
  }

  return { partial: line.slice(startIndex + 1) };
}

function isQuote(char) {
  return char === '"' || char === "'" || char === "`";
}

function isEscaped(str, index) {
  let backslashCount = 0;
  for (let i = index - 1; i >= 0 && str[i] === "\\"; i -= 1) {
    backslashCount += 1;
  }
  return backslashCount % 2 === 1;
}

function completeFilePath(partialPath) {
  const { dirPrefix, rest, separator } = splitPartialPath(partialPath);
  const searchDir = resolveSearchDirectory(dirPrefix);

  let entries;
  try {
    entries = fs.readdirSync(searchDir, { withFileTypes: true });
  } catch {
    return [];
  }

  const preferredSeparator = separator ?? (path.sep === "\\" ? "\\" : "/");

  return entries
    .filter(entry => entry.name.startsWith(rest))
    .sort((a, b) => a.name.localeCompare(b.name))
    .map(entry => {
      const suffix = entry.isDirectory() ? preferredSeparator : "";
      return `${dirPrefix}${entry.name}${suffix}`;
    });
}

function splitPartialPath(partialPath) {
  const lastSlash = Math.max(partialPath.lastIndexOf("/"), partialPath.lastIndexOf("\\"));
  if (lastSlash === -1) {
    return { dirPrefix: "", rest: partialPath, separator: null };
  }

  return {
    dirPrefix: partialPath.slice(0, lastSlash + 1),
    rest: partialPath.slice(lastSlash + 1),
    separator: partialPath[lastSlash],
  };
}

function resolveSearchDirectory(prefix) {
  if (!prefix) {
    return process.cwd();
  }

  const trimmedPrefix =
    prefix.endsWith("/") || prefix.endsWith("\\") ? prefix.slice(0, -1) : prefix;
  const expandedPrefix = expandHomeDirectory(trimmedPrefix || ".");

  if (path.isAbsolute(expandedPrefix)) {
    return expandedPrefix;
  }

  return path.resolve(process.cwd(), expandedPrefix);
}

function expandHomeDirectory(p) {
  if (p === "~") {
    return os.homedir();
  }

  if (p.startsWith("~/") || p.startsWith("~\\")) {
    return path.join(os.homedir(), p.slice(2));
  }

  return p;
}
