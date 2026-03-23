#!/bin/zsh
set -euo pipefail

FFMPEG="/Users/terry/apps/ffmpeg/bin/ffmpeg"
FFPROBE="/Users/terry/apps/ffmpeg/bin/ffprobe"

BASE_DIR="/Users/terry/projects/python/video"
GIF_DIR="${BASE_DIR}/gif"
TRANSFERRED_DIR="${BASE_DIR}/transferred"

TARGET_BYTES=$((95 * 1024 * 1024 / 10))   # 9.5 MiB
START_WIDTH=640
MIN_WIDTH=320
START_FPS=12
MIN_FPS=4

mkdir -p "$GIF_DIR"
mkdir -p "$TRANSFERRED_DIR"

if [[ ! -x "$FFMPEG" ]]; then
  echo "ffmpeg 不可执行: $FFMPEG"
  exit 1
fi

if [[ ! -x "$FFPROBE" ]]; then
  echo "ffprobe 不可执行: $FFPROBE"
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

make_gif() {
  local in_file="$1"
  local out_file="$2"
  local width="$3"
  local fps="$4"
  local palette="$TMP_DIR/palette.png"

  "$FFMPEG" -y -i "$in_file" \
    -vf "fps=${fps},scale=${width}:-1:flags=lanczos,palettegen=stats_mode=diff" \
    "$palette" >/dev/null 2>&1

  "$FFMPEG" -y -i "$in_file" -i "$palette" \
    -lavfi "fps=${fps},scale=${width}:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=sierra2_4a" \
    "$out_file" >/dev/null 2>&1
}

convert_one() {
  local input="$1"
  local filename="${input:t}"
  local basename="${filename:r}"
  local output="${GIF_DIR}/${basename}.gif"
  local moved_target="${TRANSFERRED_DIR}/${filename}"

  echo "开始处理: $filename"

  if [[ -f "$output" ]]; then
    echo "已存在 GIF，跳过转换: $output"
    if [[ ! -f "$moved_target" ]]; then
      mv "$input" "$moved_target"
      echo "原视频已移到: $moved_target"
    else
      echo "transferred 中已存在同名文件，原视频保留: $input"
    fi
    return 0
  fi

  local duration
  duration="$("$FFPROBE" -v error -show_entries format=duration -of default=nk=1:nw=1 "$input" | awk '{printf "%.0f", $1}')"

  if [[ -z "${duration}" || "${duration}" -le 0 ]]; then
    echo "无法读取视频时长，跳过: $filename"
    return 1
  fi

  local fps="$START_FPS"
  local width="$START_WIDTH"

  if [[ "$duration" -ge 30 ]]; then
    fps=8
  fi

  if [[ "$duration" -ge 60 ]]; then
    fps=6
  fi

  local success=0
  local best_file=""
  local cur_fps=""
  local candidate=""
  local size=""
  local size_mb=""

  while [[ "$width" -ge "$MIN_WIDTH" ]]; do
    cur_fps="$fps"

    while [[ "$cur_fps" -ge "$MIN_FPS" ]]; do
      candidate="$TMP_DIR/${basename}_${width}_${cur_fps}.gif"
      rm -f "$candidate"

      echo "尝试参数: width=${width}, fps=${cur_fps}"
      make_gif "$input" "$candidate" "$width" "$cur_fps"

      size=$(stat -f%z "$candidate")
      size_mb=$(awk "BEGIN {printf \"%.2f\", $size/1024/1024}")
      echo "生成大小: ${size_mb} MB"

      best_file="$candidate"

      if [[ "$size" -le "$TARGET_BYTES" ]]; then
        cp "$candidate" "$output"
        echo "GIF 转换成功: $output"

        if [[ ! -f "$moved_target" ]]; then
          mv "$input" "$moved_target"
          echo "原视频已移到: $moved_target"
        else
          echo "警告: transferred 中已存在同名文件，未移动原视频: $input"
        fi

        success=1
        break 2
      fi

      cur_fps=$((cur_fps - 2))
    done

    width=$((width - 80))
  done

  if [[ "$success" -eq 0 ]]; then
    if [[ -n "$best_file" && -f "$best_file" ]]; then
      cp "$best_file" "$output"
      local final_size
      local final_size_mb
      final_size=$(stat -f%z "$output")
      final_size_mb=$(awk "BEGIN {printf \"%.2f\", $final_size/1024/1024}")
      echo "已尽量压缩，但可能仍超过公众号限制: $output (${final_size_mb} MB)"
    else
      echo "转换失败: $filename"
      return 1
    fi
  fi

  return 0
}

found_any=0

while IFS= read -r -d '' mov_file; do
  found_any=1
  convert_one "$mov_file" || true
  echo "----------------------------------------"
done < <(
  find "$BASE_DIR" -maxdepth 1 -type f \( -iname "*.mov" -o -iname "*.MOV" \) -print0
)

if [[ "$found_any" -eq 0 ]]; then
  echo "没有找到需要处理的 mov 文件。"
else
  echo "全部处理完成。"
fi