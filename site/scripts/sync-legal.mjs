import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import AdmZip from 'adm-zip';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const siteRoot = path.resolve(__dirname, '..');
const archivePath = path.resolve(siteRoot, '..', 'legal_3.zip');
const outDir = path.join(siteRoot, 'src', 'content', 'legal');

const targets = {
  terms: 'terms.md',
  privacy: 'privacy.md',
  refunds: 'refunds.md',
  licenses: 'licenses.md',
};

if (!fs.existsSync(archivePath)) {
  console.error(`Missing legal archive at ${archivePath}`);
  process.exit(1);
}

fs.mkdirSync(outDir, { recursive: true });

const zip = new AdmZip(archivePath);
const entries = zip.getEntries();

const findEntry = (filename) => {
  const matches = entries.filter((entry) => {
    if (entry.entryName.includes('__MACOSX')) {
      return false;
    }
    return entry.entryName.endsWith(`/${filename}`) || entry.entryName === filename;
  });

  return matches[0];
};

let missing = false;
for (const [key, outName] of Object.entries(targets)) {
  const entry = findEntry(outName);
  if (!entry) {
    console.error(`Missing ${outName} inside legal_3.zip`);
    missing = true;
    continue;
  }

  const outputPath = path.join(outDir, outName);
  const data = entry.getData();
  fs.writeFileSync(outputPath, data);
}

if (missing) {
  process.exit(1);
}

console.log('Legal documents synced.');
