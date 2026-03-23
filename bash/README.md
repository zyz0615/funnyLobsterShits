# MOV Batch Tools for Social Media

两个用于批量处理 `.mov` 视频的小脚本：

- `batch_cut_mov.sh`：批量裁掉视频开头 3 秒、结尾 1 秒
- `batch_mov_to_gif.sh`：批量把 `.mov` 转成 `.gif`，并尽量压缩到适合公众号使用的大小

它们主要适合这样的工作流：

1. 把 `.mov` 视频放进指定目录
2. 批量裁剪，去掉开头和结尾多余部分
3. 或者直接批量转成 GIF
4. 已处理完成的原视频自动移动到 `transferred/`，避免重复处理

---

## Scripts

### `batch_cut_mov.sh`

这个脚本会扫描指定目录下的所有 `.mov` / `.MOV` 文件，并执行以下操作：

- 跳过前 **3 秒**
- 去掉结尾 **1 秒**
- 输出裁剪后的视频到 `cut/`
- 如果输出成功，把原始视频移动到 `transferred/`

如果视频太短，无法同时去掉前 3 秒和后 1 秒，会直接跳过。

---

### `batch_mov_to_gif.sh`

这个脚本会扫描指定目录下的所有 `.mov` / `.MOV` 文件，并执行以下操作：

- 批量生成 GIF 到 `gif/`
- 自动尝试不同参数组合压缩 GIF
- 优先从较高质量开始：
  - 初始宽度：`640`
  - 最低宽度：`320`
  - 初始帧率：`12`
  - 最低帧率：`4`
- 如果视频较长，会自动降低初始 FPS
- 尽量把 GIF 控制在约 **9.5 MiB** 左右
- 如果成功生成 GIF，则把原始视频移动到 `transferred/`

如果怎么压都压不进目标大小，脚本会保留“当前最优结果”，并提示它可能仍然超过公众号限制。

---

## Requirements

### 1. macOS + zsh

两个脚本都是基于 `zsh` 编写的：

```zsh
#!/bin/zsh
```

默认面向 macOS 环境。

### 2. FFmpeg and FFprobe

脚本依赖：

- `ffmpeg`
- `ffprobe`

当前脚本中使用的是固定路径：

```zsh
FFMPEG="/Users/terry/apps/ffmpeg/bin/ffmpeg"
FFPROBE="/Users/terry/apps/ffmpeg/bin/ffprobe"
```

如果你的安装路径不同，需要手动修改成自己的路径。

可以先用下面命令查看：

```bash
which ffmpeg
which ffprobe
```

例如 Homebrew 常见路径可能是：

```zsh
FFMPEG="/opt/homebrew/bin/ffmpeg"
FFPROBE="/opt/homebrew/bin/ffprobe"
```

### 3. Working Directory

当前脚本默认工作目录是：

```zsh
BASE_DIR="/Users/terry/projects/python/video"
```

也就是说：

- 待处理视频放在：`/Users/terry/projects/python/video`
- 裁剪结果输出到：`/Users/terry/projects/python/video/cut`
- GIF 输出到：`/Users/terry/projects/python/video/gif`
- 已处理原视频移动到：`/Users/terry/projects/python/video/transferred`

如果你想换成自己的目录，请修改脚本中的 `BASE_DIR`。

---

## Directory Structure

运行后目录大概会是这样：

```text
video/
├── a.mov
├── b.mov
├── c.MOV
├── cut/
│   ├── a.mov
│   └── b.mov
├── gif/
│   ├── a.gif
│   └── b.gif
└── transferred/
    ├── a.mov
    └── b.mov
```

说明：

- 原始 `.mov` 文件放在 `BASE_DIR` 根目录
- 裁剪视频输出到 `cut/`
- GIF 输出到 `gif/`
- 成功处理后的原视频会被移动到 `transferred/`

---

## Usage

### 1. Grant Execute Permission

第一次使用前，先给脚本执行权限：

```bash
chmod +x batch_cut_mov.sh
chmod +x batch_mov_to_gif.sh
```

---

### 2. Batch Cut MOV Files

把待处理的 `.mov` 文件放到 `BASE_DIR` 目录后，运行：

```bash
./batch_cut_mov.sh
```

它会自动：

- 扫描当前目录下所有 `.mov` / `.MOV`
- 裁掉前 3 秒和后 1 秒
- 输出到 `cut/`
- 原文件移动到 `transferred/`

---

### 3. Batch Convert MOV to GIF

同样，把 `.mov` 文件放到 `BASE_DIR` 后，运行：

```bash
./batch_mov_to_gif.sh
```

它会自动：

- 扫描 `.mov` / `.MOV`
- 生成 GIF 到 `gif/`
- 尝试压缩到适合公众号使用的大小
- 原文件移动到 `transferred/`

---

## How It Works

### Existing Output Files

两个脚本都做了防重复处理：

- 如果 `cut/` 里已经有同名输出视频，裁剪脚本会跳过
- 如果 `gif/` 里已经有同名 GIF，转 GIF 脚本会跳过

---

### Existing Files in `transferred/`

脚本不会强行覆盖。

如果 `transferred/` 中已经有同名文件，会给出提示，并保留当前原视频不动。

---

### Videos That Are Too Short

在裁剪脚本中，如果视频长度不足以同时去掉前 3 秒和后 1 秒，会直接跳过。

---

### GIF Too Large

GIF 脚本会自动逐步降低：

- 分辨率
- 帧率

如果还是压不进目标大小，它会保留当前最优版本，并提示该 GIF 可能仍然超过公众号限制。

---

## macOS Security Warnings

在 macOS 上第一次运行脚本时，常见问题通常有以下几种。

### 1. `zsh: permission denied`

原因通常是脚本还没有执行权限。

解决方法：

```bash
chmod +x batch_cut_mov.sh
chmod +x batch_mov_to_gif.sh
```

---

### 2. `Operation not permitted`

可能原因：

- 脚本访问了“桌面 / 文稿 / 下载”等受保护目录
- 终端没有被授予访问权限

解决方法：

打开：

**System Settings → Privacy & Security**

检查以下位置：

- **Files and Folders**
- **Full Disk Access**

把你使用的终端程序加入允许列表，例如：

- Terminal
- iTerm2
- Warp

修改后，建议重新打开终端再运行。

---

### 3. “Apple cannot check it for malicious software”
### 4. “Developer cannot be verified”

这是 macOS Gatekeeper 的正常保护机制。

如果你确认脚本来源可信，可以这样处理：

#### 方法 A：右键打开

1. 在 Finder 中找到脚本
2. 按住 `Control` 点击文件
3. 选择 **Open**
4. 在弹窗里再次点击 **Open**

#### 方法 B：在系统设置里允许

1. 打开 **System Settings**
2. 进入 **Privacy & Security**
3. 在底部找到被阻止的项目
4. 点击 **Open Anyway**
5. 输入密码确认

> 只建议在确认脚本来源可信的情况下这样做。

---

### 5. `ffmpeg 不可执行` 或 `ffprobe 不可执行`

这通常表示：

- 路径写错了
- 文件不存在
- 没有执行权限

先检查：

```bash
which ffmpeg
which ffprobe
```

然后把脚本顶部的路径改成你机器上的实际路径。

---

## Recommended Workflow

推荐按下面的顺序使用：

### Step 1. Cut videos

```bash
./batch_cut_mov.sh
```

### Step 2. Convert to GIF if needed

```bash
./batch_mov_to_gif.sh
```

如果你希望优先处理裁剪后的结果，也可以把 GIF 脚本中的 `BASE_DIR` 改到 `cut/` 对应目录。

---

## Configurable Parameters

### In `batch_cut_mov.sh`

```zsh
CUT_HEAD=3
CUT_TAIL=1
```

- `CUT_HEAD`：开头裁掉多少秒
- `CUT_TAIL`：结尾裁掉多少秒

---

### In `batch_mov_to_gif.sh`

```zsh
TARGET_BYTES=$((95 * 1024 * 1024 / 10))
START_WIDTH=640
MIN_WIDTH=320
START_FPS=12
MIN_FPS=4
```

- `TARGET_BYTES`：目标 GIF 大小
- `START_WIDTH`：起始宽度
- `MIN_WIDTH`：最小宽度
- `START_FPS`：起始帧率
- `MIN_FPS`：最小帧率

---

## Known Limitations

1. 当前脚本只扫描 `BASE_DIR` 根目录，不会递归处理子目录
2. 路径是写死的，需要手动改成自己的环境
3. 裁剪脚本会重新编码输出，不是无损秒切
4. GIF 压缩是启发式尝试，不保证一定压到平台限制以下
5. 当前主要面向 `.mov` 文件，其他格式没有直接支持

---

## License

For personal use / internal workflow.
