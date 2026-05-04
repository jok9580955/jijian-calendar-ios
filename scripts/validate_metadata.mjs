import fs from "node:fs";
import path from "node:path";

const locales = [
  "ar-SA", "ca", "zh-Hans", "zh-Hant", "hr", "cs", "da", "nl-NL", "en-AU",
  "en-CA", "en-GB", "en-US", "fi", "fr-CA", "fr-FR", "de-DE", "el", "he",
  "hi", "hu", "id", "it", "ja", "ko", "ms", "no", "pl", "pt-BR", "pt-PT",
  "ro", "ru", "sk", "es-MX", "es-ES", "sv", "th", "tr", "uk", "vi"
];
const required = ["name.txt", "subtitle.txt", "keywords.txt", "description.txt", "release_notes.txt"];
const root = path.join(process.cwd(), "fastlane", "metadata");
const missing = [];
const invalid = [];

for (const locale of locales) {
  for (const file of required) {
    const target = path.join(root, locale, file);
    if (!fs.existsSync(target) || fs.readFileSync(target, "utf8").trim().length === 0) {
      missing.push(path.join("fastlane", "metadata", locale, file));
    }
  }
  const namePath = path.join(root, locale, "name.txt");
  if (fs.existsSync(namePath)) {
    const appName = fs.readFileSync(namePath, "utf8").trim();
    if ([...appName].length > 30) {
      invalid.push(`${locale}/name.txt exceeds 30 characters: ${appName}`);
    }
  }
  const subtitlePath = path.join(root, locale, "subtitle.txt");
  if (fs.existsSync(subtitlePath)) {
    const subtitle = fs.readFileSync(subtitlePath, "utf8").trim();
    if ([...subtitle].length > 30) {
      invalid.push(`${locale}/subtitle.txt exceeds 30 characters: ${subtitle}`);
    }
  }
  const keywordsPath = path.join(root, locale, "keywords.txt");
  if (fs.existsSync(keywordsPath)) {
    const keywords = fs.readFileSync(keywordsPath, "utf8").trim();
    if ([...keywords].length > 100) {
      invalid.push(`${locale}/keywords.txt exceeds 100 characters: ${keywords}`);
    }
  }
  const promotionalTextPath = path.join(root, locale, "promotional_text.txt");
  if (fs.existsSync(promotionalTextPath)) {
    const promotionalText = fs.readFileSync(promotionalTextPath, "utf8").trim();
    if ([...promotionalText].length > 170) {
      invalid.push(`${locale}/promotional_text.txt exceeds 170 characters: ${promotionalText}`);
    }
  }
}

if (missing.length > 0) {
  console.error(`Missing metadata files:\n${missing.join("\n")}`);
  process.exit(1);
}

if (invalid.length > 0) {
  console.error(`Invalid metadata:\n${invalid.join("\n")}`);
  process.exit(1);
}

console.log(`Metadata OK for ${locales.length} locales.`);
