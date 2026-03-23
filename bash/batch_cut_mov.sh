#!/bin/zsh
set -euo pipefail

FFMPEG="/Users/terry/apps/ffmpeg/bin/ffmpeg"
FFPROBE="/Users/terry/apps/ffmpeg/bin/ffprobe"

BASE_DIR="/Users/terry/projects/python/video"
CUT_DIR="${BASE_DIR}/cut"
TRANSFERRED_DIR="${BASE_DIR}/transferred"

CUT_HEAD=3
CUT_TAIL=1

mkdir -p "$CUT_DIR"
mkdir -p "$TRANSFERRED_DIR"

if [[ ! -x "$FFMPEG" ]]; then
  echo "ffmpeg 不可执行: $FFMPEG"
  exit 1
fi

if [[ ! -x "$FFPROBE" ]]; then
  echo "ffprobe 不可执行: $FFPROBE"
  exit 1
fi

get_duration() {
  local input="$1"
  "$FFPROBE" -v error \
    -show_entries format=duration \
    -of default=nk=1:nw=1 \
    "$input"
}

convert_one() {
  local input="$1"
  local filename="${input:t}"
  local basename="${filename:r}"
  local output="${CUT_DIR}/${filename}"
  local moved_target="${TRANSFERRED_DIR}/${filename}"

  echo "开始处理: $filename"

  if [[ -f "$output" ]]; then
    echo "cut 中已存在文件，跳过裁剪: $output"
    if [[ ! -f "$moved_target" ]]; then
      mv "$input" "$moved_target"
      echo "原视频已移到: $moved_target"
    else
      echo "transferred 中已存在同名文件，原视频保留: $input"
    fi
    return 0
  fi

  local duration
  duration="$(get_duration "$input")"

  if [[ -z "$duration" ]]; then
    echo "无法读取视频时长，跳过: $filename"
    return 1
  fi

  local start_time="$CUT_HEAD"
  local keep_duration

  keep_duration=$(awk -v d="$duration" -v h="$CUT_HEAD" -v t="$CUT_TAIL" 'BEGIN { printf "%.3f", d - h - t }')

  if awk -v kd="$keep_duration" 'BEGIN { exit !(kd <= 0) }'; then
    echo "视频太短，无法裁掉前 ${CUT_HEAD} 秒和后 ${CUT_TAIL} 秒: $filename"
    return 1
  fi

  echo "原时长: ${duration} 秒"
  echo "裁剪后时长: ${keep_duration} 秒"

  "$FFMPEG" -y \
    -ss "$start_time" \
    -i "$input" \
    -t "$keep_duration" \
    -c:v libx264 \
    -preset medium \
    -crf 18 \
    -c:a aac \
    -movflags +faststart \
    "$output"

  if [[ -f "$output" ]]; then
    echo "裁剪成功: $output"

    if [[ ! -f "$moved_target" ]]; then
      mv "$input" "$moved_target"
      echo "原视频已移到: $moved_target"
    else
      echo "警告: transferred 中已存在同名文件，未移动原视频: $input"
    fi
  else
    echo "裁剪失败: $filename"
    return 1
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