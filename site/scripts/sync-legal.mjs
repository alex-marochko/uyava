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
  'legal/terms.md': 'terms.md',
  'legal/privacy.md': 'privacy.md',
  'legal/refunds.md': 'refunds.md',
  'legal/licenses.md': 'licenses.md',
};

if (!fs.existsSync(archivePath)) {
  console.error(`Missing legal archive at ${archivePath}`);
  process.exit(1);
}

fs.mkdirSync(outDir, { recursive: true });

const zip = new AdmZip(archivePath);
const entries = new Map(zip.getEntries().map((entry) => [entry.entryName, entry]));

let missing = false;
for (const [entryName, outName] of Object.entries(targets)) {
  const entry = entries.get(entryName);
  if (!entry) {
    console.error(`Missing ${entryName} inside legal_3.zip`);
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
