#!/bin/bash
set -euo pipefail

# Simple video -> GIF helper
# Usage: to-gif.sh [-w width] [-f fps] <input-video>
# Produces a GIF next to the input file with same basename.

usage() {
  cat <<EOF
Usage: $(basename "$0") [options] <input-video-file>

Options:
  -w, --width <pixels>   Output GIF width (default: 320)
  -f, --fps <num>        Frames per second (default: 10)
  -h, --help             Show this help and exit

Example:
  $(basename "$0") -w 480 -f 12 clip.mov
EOF
}

# Defaults
FPS=10
WIDTH=320

# Parse flags
if [[ $# -eq 0 ]]; then
  usage >&2
  exit 1
fi

input_file=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -w|--width)
      [[ $# -ge 2 ]] || { echo "Error: --width requires a value" >&2; exit 1; }
      WIDTH="$2"; shift 2;;
    -f|--fps)
      [[ $# -ge 2 ]] || { echo "Error: --fps requires a value" >&2; exit 1; }
      FPS="$2"; shift 2;;
    -h|--help)
      usage; exit 0;;
    --)
      shift; break;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1;;
    *)
      input_file="$1"; shift; break;;
  esac
done

# If input file not yet set, take first remaining positional
if [[ -z "$input_file" && $# -gt 0 ]]; then
  input_file="$1"; shift
fi

if [[ -z "$input_file" ]]; then
  echo "Error: input video file is required" >&2
  usage >&2
  exit 1
fi

# Validate numeric inputs
if ! [[ "$WIDTH" =~ ^[0-9]+$ ]]; then
  echo "Error: width must be an integer" >&2
  exit 1
fi
if ! [[ "$FPS" =~ ^[0-9]+$ ]]; then
  echo "Error: fps must be an integer" >&2
  exit 1
fi

if [[ ! -f "$input_file" ]]; then
  echo "Error: input file '$input_file' not found" >&2
  exit 1
fi

# Derive paths
output_dir="$(cd "$(dirname "$input_file")" && pwd)"
base_name="$(basename "$input_file")"
base_noext="${base_name%.*}"
palette_file="$output_dir/${base_noext}_palette.png"
gif_file="$output_dir/${base_noext}.gif"

echo "Converting '$input_file' -> '$gif_file'"
echo "Settings: width=$WIDTH fps=$FPS"

echo "Step 1/2: Generating palette ..."
if ! ffmpeg -hide_banner -loglevel error -i "$input_file" -vf "fps=$FPS,scale=$WIDTH:-1:flags=lanczos,palettegen" "$palette_file"; then
  echo "Palette generation failed. Re-running with full ffmpeg output for diagnostics..." >&2
  ffmpeg -i "$input_file" -vf "fps=$FPS,scale=$WIDTH:-1:flags=lanczos,palettegen" "$palette_file"
fi

echo "Step 2/2: Creating GIF ..."
if ! ffmpeg -hide_banner -loglevel error -i "$input_file" -i "$palette_file" -filter_complex "fps=$FPS,scale=$WIDTH:-1:flags=lanczos[x];[x][1:v]paletteuse" "$gif_file"; then
  echo "GIF creation failed. Re-running with full ffmpeg output for diagnostics..." >&2
  ffmpeg -i "$input_file" -i "$palette_file" -filter_complex "fps=$FPS,scale=$WIDTH:-1:flags=lanczos[x];[x][1:v]paletteuse" "$gif_file"
fi

echo "Cleaning up temporary palette file..."
rm -f "$palette_file" || true

echo "Done. GIF saved to: $gif_file"
