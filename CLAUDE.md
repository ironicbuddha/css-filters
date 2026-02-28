# cssgram.sh — Instagram-style Image Filters via ImageMagick

## What It Is
A bash script that replicates CSSgram's Instagram-style CSS filters as real
image transformations using ImageMagick 7 (`magick` CLI). Each filter is a
faithful port of the CSS filter/blend-mode recipe from the CSSgram library.

## Usage
  ./cssgram.sh <filter> <input> [output]
  ./cssgram.sh list

If output is omitted, it auto-names the file as `<base>-<filter>.<ext>`.

## Available Filters (25)
1977, aden, brannan, brooklyn, clarendon, earlybird, gingham, hudson,
inkwell, kelvin, lark, lofi, maven, mayfair, moon, nashville, perpetua,
reyes, rise, slumber, stinson, toaster, valencia, walden, willow, xpro2

## How Filters Are Built
Each filter is a `case` branch that chains ImageMagick operations matching
the original CSS. A filter combines up to three layers:

1. **Base adjustments** — applied directly to the image:
   - `brightness(x)` → `-modulate {x*100},100,100`
   - `saturate(x)` → `-modulate 100,{x*100},100`
   - `hue-rotate(d)` → `-modulate 100,100,{100 + d/1.8}`
   - `contrast(c≥1)` → `-level {50-50/c}%,{50+50/c}%`
   - `contrast(c<1)` → `+level {(1-c)*50}%,{(1+c)*50}%`
   - `sepia(x)` → `-color-matrix` with a blended sepia matrix
   - `grayscale(x)` → `-color-matrix` or `-colorspace Gray`

2. **Overlay layers** (`::before` / `::after` in CSS) — composited on top:
   - Solid color fills: `+clone -fill "rgb(...)" -colorize 100%`
   - Gradients: `gradient:` or `radial-gradient:` sized to image dimensions
   - Opacity: `-alpha set -channel A -evaluate set N% +channel`

3. **Blend modes** — how overlays merge with the base:
   Screen, Multiply, Overlay, SoftLight, Lighten, Darken,
   ColorDodge, ColorBurn, Exclusion, Colorize

## Key Implementation Details
- Requires ImageMagick 7 (the `magick` command, not `convert`).
- Image dimensions are read with `magick identify` so gradient overlays
  match the input size.
- CSS `::before` overlays are composited first (before base adjustments);
  `::after` overlays are composited last. The ordering in each case branch
  mirrors the CSS stacking order.
- Sepia/grayscale use pre-computed 3×3 color matrices that blend between
  identity and the target matrix at the specified intensity.
- The script uses `set -euo pipefail` for strict error handling.

## Adding a New Filter
1. Find the CSS definition (filter properties + pseudo-element overlays).
2. Convert each CSS property using the mapping above.
3. Add a new `case` branch following the existing pattern:
   - Comment with the original CSS recipe.
   - Chain the ImageMagick operations in correct stacking order.
   - Add the filter name to the FILTERS array.
