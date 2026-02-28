#!/usr/bin/env bash
set -euo pipefail

# cssgram.sh - Apply CSSgram Instagram-style filters to images using ImageMagick 7
# Replicates CSS filter properties + blend-mode overlays as closely as possible.
#
# Usage:
#   ./cssgram.sh <filter> <input> [output]
#   ./cssgram.sh list
#
# If output is omitted, saves to <input_base>-<filter>.<ext>

FILTERS=(
  1977 aden brannan brooklyn clarendon earlybird gingham
  hudson inkwell kelvin lark lofi maven mayfair moon
  nashville perpetua reyes rise slumber stinson toaster
  valencia walden willow xpro2
)

usage() {
  cat <<EOF
Usage: $(basename "$0") <filter> <input> [output]
       $(basename "$0") list

Apply CSSgram Instagram-style filters to images using ImageMagick.

If output is omitted, saves to <input_base>-<filter>.<ext>

Run '$(basename "$0") list' to see all available filters.
EOF
}

list_filters() {
  echo "Available filters:"
  for f in "${FILTERS[@]}"; do
    echo "  $f"
  done
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

FILTER="$1"

if [[ "$FILTER" == "list" || "$FILTER" == "--list" || "$FILTER" == "-l" ]]; then
  list_filters
  exit 0
fi

if [[ "$FILTER" == "--help" || "$FILTER" == "-h" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

INPUT="$2"
if [[ ! -f "$INPUT" ]]; then
  echo "Error: Input file '$INPUT' not found" >&2
  exit 1
fi

# Determine output filename
if [[ $# -ge 3 ]]; then
  OUTPUT="$3"
else
  EXT="${INPUT##*.}"
  BASE="${INPUT%.*}"
  OUTPUT="${BASE}-${FILTER}.${EXT}"
fi

# Get image dimensions
DIMS=$(magick identify -format '%w %h' "$INPUT[0]")
W=${DIMS%% *}
H=${DIMS##* }

# ---- CSS-to-ImageMagick mapping notes ----
#
# brightness(x)  -> -modulate {x*100},100,100
# saturate(x)    -> -modulate 100,{x*100},100
# hue-rotate(d)  -> -modulate 100,100,{100 + d/1.8}
# contrast(c>=1) -> -level {50-50/c}%,{50+50/c}%
# contrast(c<1)  -> +level {(1-c)*50}%,{(1+c)*50}%
# sepia(x)       -> -color-matrix (blended sepia matrix)
# grayscale(x)   -> -color-matrix (blended grayscale matrix)
#
# Blend modes map directly: Screen, Multiply, Overlay, SoftLight,
# Lighten, Darken, ColorDodge, ColorBurn, Exclusion, Colorize
# ----

case "$FILTER" in

  # ._1977: contrast(1.1) brightness(1.1) saturate(1.3)
  # ::after rgba(243,106,188,.3) screen
  1977)
    magick "$INPUT" \
      -level 4.55%,95.45% \
      -modulate 110,130,100 \
      \( +clone -fill "rgb(243,106,188)" -colorize 100% \
         -alpha set -channel A -evaluate set 30% +channel \) \
      -compose Screen -composite \
      "$OUTPUT"
    ;;

  # .aden: hue-rotate(-20deg) contrast(.9) saturate(.85) brightness(1.2)
  # ::after linear-gradient(to right, rgba(66,10,14,.2), transparent) darken
  aden)
    magick "$INPUT" \
      -modulate 120,85,88.9 \
      +level 5%,95% \
      \( -size "${W}x${H}" gradient:"rgb(66,10,14)-none" -rotate -90 \
         -alpha set -channel A -evaluate set 20% +channel \) \
      -compose Darken -composite \
      "$OUTPUT"
    ;;

  # .brannan: sepia(.5) contrast(1.4)
  # ::after rgba(161,44,199,.31) lighten
  brannan)
    magick "$INPUT" \
      -color-matrix \
        '3: 0.6965 0.3845 0.0945  0.1745 0.843 0.084  0.136 0.267 0.5655' \
      -level 14.29%,85.71% \
      \( +clone -fill "rgb(161,44,199)" -colorize 100% \
         -alpha set -channel A -evaluate set 31% +channel \) \
      -compose Lighten -composite \
      "$OUTPUT"
    ;;

  # .brooklyn: contrast(.9) brightness(1.1)
  # ::after radial-gradient(circle, rgba(168,223,193,.4) 70%, #c4b7c8) overlay
  brooklyn)
    magick "$INPUT" \
      +level 5%,95% \
      -modulate 110,100,100 \
      \( -size "${W}x${H}" radial-gradient:"rgb(168,223,193)-rgb(196,183,200)" \
         -alpha set -channel A -evaluate set 60% +channel \) \
      -compose Overlay -composite \
      "$OUTPUT"
    ;;

  # .clarendon: contrast(1.2) saturate(1.35)
  # ::before rgba(127,187,227,.2) overlay
  clarendon)
    magick "$INPUT" \
      \( +clone -fill "rgb(127,187,227)" -colorize 100% \
         -alpha set -channel A -evaluate set 20% +channel \) \
      -compose Overlay -composite \
      -level 8.33%,91.67% \
      -modulate 100,135,100 \
      "$OUTPUT"
    ;;

  # .earlybird: contrast(.9) sepia(.2)
  # ::after radial-gradient(circle, #d0ba8e 20%, #360309 85%, #1d0210 100%) overlay
  earlybird)
    magick "$INPUT" \
      +level 5%,95% \
      -color-matrix \
        '3: 0.8786 0.1538 0.0378  0.0698 0.9372 0.0336  0.0544 0.1068 0.8262' \
      \( -size "${W}x${H}" radial-gradient:"rgb(208,186,142)-rgb(29,2,16)" \) \
      -compose Overlay -composite \
      "$OUTPUT"
    ;;

  # .gingham: brightness(1.05) hue-rotate(-10deg)
  # ::after linear-gradient(to right, rgba(66,10,14,.2), transparent) darken
  gingham)
    magick "$INPUT" \
      -modulate 105,100,94.4 \
      \( -size "${W}x${H}" gradient:"rgb(66,10,14)-none" -rotate -90 \
         -alpha set -channel A -evaluate set 20% +channel \) \
      -compose Darken -composite \
      "$OUTPUT"
    ;;

  # .hudson: brightness(1.2) contrast(.9) saturate(1.1)
  # ::after radial-gradient(circle, #a6b1ff 50%, #342134) multiply opacity(.5)
  hudson)
    magick "$INPUT" \
      -modulate 120,110,100 \
      +level 5%,95% \
      \( -size "${W}x${H}" radial-gradient:"rgb(166,177,255)-rgb(52,33,52)" \
         -alpha set -channel A -evaluate set 50% +channel \) \
      -compose Multiply -composite \
      "$OUTPUT"
    ;;

  # .inkwell: sepia(.3) contrast(1.1) brightness(1.1) grayscale(1)
  inkwell)
    magick "$INPUT" \
      -color-matrix \
        '3: 0.8179 0.2307 0.0567  0.1047 0.9058 0.0504  0.0816 0.1602 0.7393' \
      -level 4.55%,95.45% \
      -modulate 110,100,100 \
      -colorspace Gray -colorspace sRGB \
      "$OUTPUT"
    ;;

  # .kelvin: ::after #b77d21 overlay  ::before #382c34 color-dodge
  kelvin)
    magick "$INPUT" \
      \( +clone -fill "rgb(56,44,52)" -colorize 100% \) \
      -compose ColorDodge -composite \
      \( +clone -fill "rgb(183,125,33)" -colorize 100% \) \
      -compose Overlay -composite \
      "$OUTPUT"
    ;;

  # .lark: contrast(.9)
  # ::before #22253f color-dodge
  # ::after rgba(242,242,242,.8) darken
  lark)
    magick "$INPUT" \
      \( +clone -fill "rgb(34,37,63)" -colorize 100% \) \
      -compose ColorDodge -composite \
      +level 5%,95% \
      \( +clone -fill "rgb(242,242,242)" -colorize 100% \
         -alpha set -channel A -evaluate set 80% +channel \) \
      -compose Darken -composite \
      "$OUTPUT"
    ;;

  # .lofi: saturate(1.1) contrast(1.5)
  # ::after radial-gradient(circle, transparent 70%, #222 150%) multiply
  lofi)
    magick "$INPUT" \
      -modulate 100,110,100 \
      -level 16.67%,83.33% \
      \( -size "${W}x${H}" radial-gradient:"none-rgb(34,34,34)" \) \
      -compose Multiply -composite \
      "$OUTPUT"
    ;;

  # .maven: sepia(.25) brightness(.95) contrast(.95) saturate(1.5)
  # ::after rgba(3,230,26,.2) hue-rotate(-13deg) overlay
  maven)
    magick "$INPUT" \
      -color-matrix \
        '3: 0.8482 0.1923 0.0473  0.0873 0.9215 0.042  0.068 0.1335 0.7828' \
      -modulate 95,150,100 \
      +level 2.5%,97.5% \
      \( +clone -fill "rgb(3,230,26)" -colorize 100% \
         -alpha set -channel A -evaluate set 20% +channel \) \
      -compose Overlay -composite \
      "$OUTPUT"
    ;;

  # .mayfair: contrast(1.1) saturate(1.1)
  # ::after radial-gradient(circle at 40% 40%, rgba(255,255,255,.8),
  #         rgba(255,200,200,.6), #111 60%) overlay opacity(.4)
  mayfair)
    magick "$INPUT" \
      -level 4.55%,95.45% \
      -modulate 100,110,100 \
      \( -size "${W}x${H}" radial-gradient:"rgb(255,255,255)-rgb(17,17,17)" \
         -alpha set -channel A -evaluate set 40% +channel \) \
      -compose Overlay -composite \
      "$OUTPUT"
    ;;

  # .moon: grayscale(1) contrast(1.1) brightness(1.1)
  # ::before #a0a0a0 soft-light
  # ::after #383838 lighten
  moon)
    magick "$INPUT" \
      -colorspace Gray -colorspace sRGB \
      -level 4.55%,95.45% \
      -modulate 110,100,100 \
      \( +clone -fill "rgb(160,160,160)" -colorize 100% \) \
      -compose SoftLight -composite \
      \( +clone -fill "rgb(56,56,56)" -colorize 100% \) \
      -compose Lighten -composite \
      "$OUTPUT"
    ;;

  # .nashville: sepia(.2) contrast(1.2) brightness(1.05) saturate(1.2)
  # ::before rgba(247,176,153,.56) darken
  # ::after rgba(0,70,150,.4) lighten
  nashville)
    magick "$INPUT" \
      \( +clone -fill "rgb(247,176,153)" -colorize 100% \
         -alpha set -channel A -evaluate set 56% +channel \) \
      -compose Darken -composite \
      -color-matrix \
        '3: 0.8786 0.1538 0.0378  0.0698 0.9372 0.0336  0.0544 0.1068 0.8262' \
      -level 8.33%,91.67% \
      -modulate 105,120,100 \
      \( +clone -fill "rgb(0,70,150)" -colorize 100% \
         -alpha set -channel A -evaluate set 40% +channel \) \
      -compose Lighten -composite \
      "$OUTPUT"
    ;;

  # .perpetua: ::after linear-gradient(to bottom, #005b9a, #e6c13d) soft-light opacity(.5)
  perpetua)
    magick "$INPUT" \
      \( -size "${W}x${H}" gradient:"rgb(0,91,154)-rgb(230,193,61)" \
         -alpha set -channel A -evaluate set 50% +channel \) \
      -compose SoftLight -composite \
      "$OUTPUT"
    ;;

  # .reyes: sepia(.22) brightness(1.1) contrast(.85) saturate(.75)
  # ::after #efcdad soft-light opacity(.5)
  reyes)
    magick "$INPUT" \
      -color-matrix \
        '3: 0.8665 0.1692 0.0416  0.0768 0.9309 0.037  0.0598 0.1175 0.8088' \
      -modulate 110,75,100 \
      +level 7.5%,92.5% \
      \( +clone -fill "rgb(239,205,173)" -colorize 100% \
         -alpha set -channel A -evaluate set 50% +channel \) \
      -compose SoftLight -composite \
      "$OUTPUT"
    ;;

  # .rise: brightness(1.05) sepia(.2) contrast(.9) saturate(.9)
  # ::before radial-gradient(rgba(236,205,169,.15) 55%, rgba(50,30,7,.4)) multiply
  # ::after radial-gradient(rgba(232,197,152,.8), transparent 90%) overlay opacity(.6)
  rise)
    magick "$INPUT" \
      \( -size "${W}x${H}" radial-gradient:"rgb(236,205,169)-rgb(50,30,7)" \
         -alpha set -channel A -evaluate set 30% +channel \) \
      -compose Multiply -composite \
      -color-matrix \
        '3: 0.8786 0.1538 0.0378  0.0698 0.9372 0.0336  0.0544 0.1068 0.8262' \
      -modulate 105,90,100 \
      +level 5%,95% \
      \( -size "${W}x${H}" radial-gradient:"rgb(232,197,152)-none" \
         -alpha set -channel A -evaluate set 48% +channel \) \
      -compose Overlay -composite \
      "$OUTPUT"
    ;;

  # .slumber: saturate(.66) brightness(1.05)
  # ::before rgba(69,41,12,.4) lighten
  # ::after rgba(125,105,24,.5) soft-light
  slumber)
    magick "$INPUT" \
      \( +clone -fill "rgb(69,41,12)" -colorize 100% \
         -alpha set -channel A -evaluate set 40% +channel \) \
      -compose Lighten -composite \
      -modulate 105,66,100 \
      \( +clone -fill "rgb(125,105,24)" -colorize 100% \
         -alpha set -channel A -evaluate set 50% +channel \) \
      -compose SoftLight -composite \
      "$OUTPUT"
    ;;

  # .stinson: brightness(1.15) saturate(.85) contrast(.75)
  # ::before rgba(240,149,128,.3) soft-light
  stinson)
    magick "$INPUT" \
      \( +clone -fill "rgb(240,149,128)" -colorize 100% \
         -alpha set -channel A -evaluate set 30% +channel \) \
      -compose SoftLight -composite \
      -modulate 115,85,100 \
      +level 12.5%,87.5% \
      "$OUTPUT"
    ;;

  # .toaster: contrast(1.5) brightness(.9)
  # ::after radial-gradient(circle, #804e0f, #3b003b) screen
  toaster)
    magick "$INPUT" \
      -level 16.67%,83.33% \
      -modulate 90,100,100 \
      \( -size "${W}x${H}" radial-gradient:"rgb(128,78,15)-rgb(59,0,59)" \) \
      -compose Screen -composite \
      "$OUTPUT"
    ;;

  # .valencia: contrast(1.08) brightness(1.08) sepia(.08)
  # ::after #3a0339 exclusion opacity(.5)
  valencia)
    magick "$INPUT" \
      -level 3.7%,96.3% \
      -modulate 108,100,100 \
      -color-matrix \
        '3: 0.9514 0.0615 0.0151  0.0279 0.9749 0.0134  0.0218 0.0427 0.9305' \
      \( +clone -fill "rgb(58,3,57)" -colorize 100% \
         -alpha set -channel A -evaluate set 50% +channel \) \
      -compose Exclusion -composite \
      "$OUTPUT"
    ;;

  # .walden: brightness(1.1) hue-rotate(-10deg) sepia(.3) saturate(1.6)
  # ::after #04c screen opacity(.3)
  walden)
    magick "$INPUT" \
      -modulate 110,160,94.4 \
      -color-matrix \
        '3: 0.8179 0.2307 0.0567  0.1047 0.9058 0.0504  0.0816 0.1602 0.7393' \
      \( +clone -fill "rgb(0,68,204)" -colorize 100% \
         -alpha set -channel A -evaluate set 30% +channel \) \
      -compose Screen -composite \
      "$OUTPUT"
    ;;

  # .willow: grayscale(.5) contrast(.95) brightness(.9)
  # ::before radial-gradient(#d4a9af 55%, #000 150%) overlay
  # ::after #d8cdcb color
  willow)
    magick "$INPUT" \
      \( -size "${W}x${H}" radial-gradient:"rgb(212,169,175)-black" \) \
      -compose Overlay -composite \
      -color-matrix \
        '3: 0.6063 0.3576 0.0361  0.1063 0.8576 0.0361  0.1063 0.3576 0.5361' \
      +level 2.5%,97.5% \
      -modulate 90,100,100 \
      \( +clone -fill "rgb(216,205,203)" -colorize 100% \) \
      -compose Colorize -composite \
      "$OUTPUT"
    ;;

  # .xpro2: sepia(.3)
  # ::after radial-gradient(circle, #e6e7e0 40%, rgba(43,42,161,.6) 110%) color-burn
  xpro2)
    magick "$INPUT" \
      -color-matrix \
        '3: 0.8179 0.2307 0.0567  0.1047 0.9058 0.0504  0.0816 0.1602 0.7393' \
      \( -size "${W}x${H}" radial-gradient:"rgb(230,231,224)-rgb(43,42,161)" \
         -alpha set -channel A -evaluate set 80% +channel \) \
      -compose ColorBurn -composite \
      "$OUTPUT"
    ;;

  *)
    echo "Error: Unknown filter '$FILTER'" >&2
    echo "Run '$(basename "$0") list' to see available filters." >&2
    exit 1
    ;;
esac

echo "Saved: $OUTPUT"
