#!/bin/zsh
# Reads the flyer only; it writes generated files to flyers/exports/.

set -euo pipefail

flyer_dir="${0:A:h}"
runtime_node="/Users/hjamaan/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node"
runtime_modules="/Users/hjamaan/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules"
runtime_python="/Users/hjamaan/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3"
png="$flyer_dir/exports/images/assure-ai-2027-call-for-papers.png"
jpg="$flyer_dir/exports/images/assure-ai-2027-call-for-papers.jpg"
pdf="$flyer_dir/exports/pdf/assure-ai-2027-call-for-papers.pdf"

mkdir -p "${png:h}" "${pdf:h}"

NODE_PATH="$runtime_modules" "$runtime_node" -e '
const { chromium } = require("playwright");
(async () => {
  const browser = await chromium.launch({
    headless: true,
    executablePath: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  });
  // Use a desktop canvas so the poster retains its designed 680px width.
  const page = await browser.newPage({ viewport: { width: 1400, height: 1100 }, deviceScaleFactor: 2 });
  await page.goto(process.argv[1], { waitUntil: "networkidle" });
  await page.locator(".poster").screenshot({ path: process.argv[2] });
  await browser.close();
})().catch(error => { console.error(error); process.exit(1); });
' "file://$flyer_dir/index.html" "$png"

sips -s format jpeg "$png" --out "$jpg" >/dev/null
"$runtime_python" -c '
from PIL import Image
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader
import sys
source, output = sys.argv[1:]
image = Image.open(source)
width, height = image.size
page_width = 510
page_height = page_width * height / width
document = canvas.Canvas(output, pagesize=(page_width, page_height))
document.drawImage(ImageReader(image), 0, 0, width=page_width, height=page_height)
document.showPage()
document.save()
' "$png" "$pdf"

echo "Generated PNG, JPG, and PDF in flyers/exports."
