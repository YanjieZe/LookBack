<p align="center"><img src="Assets/lookback-logo-v1.png" width="144" alt="回望 Logo"></p>
<h1 align="center">LookBack · 回望</h1>
<p align="center">转开头，屏幕模糊。看回来，继续专注。</p>
<p align="center"><a href="README.md">English</a> · macOS 14+ · Swift / AppKit · MIT</p>

回望通过 **AirPods 头部追踪**，在你转头离开屏幕时自动模糊桌面，回头后恢复清晰。它有独立窗口和 Dock 图标，不依赖菜单栏操作。

**不用摄像头，不用账号，不上传运动数据。** 判断的是头部朝向，不是眼球注视点。

## 功能

- 左右转头、抬头或低头触发模糊，覆盖连接的显示器。
- 一键校准，将当前朝向设为正对屏幕。
- 左右、上下阈值独立可调 **15–60°**，默认均为 **15°**，延迟可调 **0.2–2 秒**。
- 实时显示头部角度、运动权限、耳机连接状态和收到的帧数。
- 两秒模糊预览、暂停/恢复、暂停一分钟。
- 点击 **×** 隐藏窗口，后台继续检测；点击 Dock 图标重新打开；**⌘Q** 退出并解除模糊。
- 控制窗口保持清晰，模糊遮罩不拦截鼠标操作。

## 环境要求

- macOS 14 Sonoma 或更新版本。
- 支持头部追踪的 AirPods，例如 AirPods Pro、AirPods 3/4、AirPods Max。
- 耳机需要戴在耳朵里，并连接到**这台 Mac**。
- 允许回望访问「运动与健身」。
- 构建需要 Apple Command Line Tools 和支持 macOS 14 API 的 Swift 编译器，无需完整 Xcode 或第三方依赖。

## 构建与安装

首次安装编译工具：

```sh
xcode-select --install
```

克隆并构建：

```sh
git clone https://github.com/YanjieZe/LookBack.git
cd LookBack
./build.sh
open /Applications/LookBack.app
```

脚本直接安装或更新 **`/Applications/LookBack.app`**。更新前用 **⌘Q** 退出正在运行的应用。名称和安装位置固定，不会每次生成不同名称的应用；中间文件位于 `.build.noindex/`。

应用采用本地 ad-hoc 签名，尚未经过 Apple 公证。重新编译后系统可能再次询问运动权限。安装需要对 `/Applications` 有写入权限。

只编译检查、不影响已安装的应用：

```sh
./build.sh --check
./test.sh
```

## 开始使用

1. 佩戴 AirPods，将它连接到 Mac。
2. 点击「连接 AirPods」，允许「运动与健身」权限。
3. 等待帧数增加、角度开始变化。
4. 正对屏幕，点击「校准当前朝向」。
5. 转头离开，再回头观察效果。

任一方向超过自己的阈值（默认均为 **15°**） 并持续 **0.6 秒**后模糊；两个方向都回到各自阈值减 8°以内（默认 **7°以内**）持续 **0.25 秒**恢复。进入与退出阈值之间的差值用于避免反复闪烁。

换座位或重新连接后请再次校准。设置与校准当前只保留在本次运行中。应用获得焦点时，**Esc** 可暂停一分钟。暂停检测仍会接收运动数据，退出应用才会停止采集。

## 常见问题

| 问题 | 处理方式 |
| --- | --- |
| 已连接但一直收到 0 帧 | 音频连接不代表运动数据已经开始传输。将两只耳机放回盒中，合盖约 10 秒，再佩戴并连接到 Mac，然后点击重新连接。 |
| 校准按钮不可用 | 尚未收到新鲜的运动数据；校准需要最近一秒内有样本。 |
| 运动权限被拒绝 | 系统设置 → 隐私与安全 → 运动与健身，允许 LookBack，再重新连接或重启应用。 |
| 突然停止追踪 | 检查 AirPods 是否自动切换到 iPhone 或其他设备，将连接切回 Mac。 |
| 频繁误触发 | 调高角度或延迟，并正对屏幕重新校准。 |
| 只有压暗，没有模糊 | 当前 macOS 的非公开模糊接口可能不可用；应用会退化为压暗。 |
| 关闭后找不到窗口 | 点击 Dock 图标，或打开 `/Applications/LookBack.app`。× 只隐藏窗口。 |

运动数据中断约两秒后，应用会恢复清晰。重新连接后需要再次校准。

## 隐私与限制

- 使用 CoreMotion 读取耳机朝向，不申请摄像头、麦克风或录屏权限。
- 没有网络请求、分析统计或账号，不保存运动记录。帧数仅保留在内存中，连接事件会写入本机系统日志。
- 头部方向无法证明眼睛是否注视屏幕。此工具不能替代隐私屏幕或锁屏。
- 模糊沿用 HeadOrbit 的 **`CGSSetWindowBackgroundBlurRadius` 非公开 WindowServer 接口**。系统更新可能影响效果，不适合直接提交 Mac App Store。
- 耳机运动数据传输可能不稳定；多显示器、Spaces 与独占全屏组合仍需进一步验证。

## 开发与贡献

核心代码位于 `Sources/`：`main.swift` 提供窗口、控制、遮罩和生命周期，`HeadTracker.swift` 负责运动会话，`DwellTrigger.swift` 实现触发延迟和回正迟滞。`Tests/` 包含状态机测试，`Resources/` 保存应用图标。

已在 Apple Silicon 上验证编译、状态机测试，以及真实 AirPods 的运动数据、校准和转头效果。自动测试不覆盖蓝牙硬件或系统模糊渲染。

提交修改前运行 `./build.sh --check` 和 `./test.sh`。报告问题时请附上 macOS 版本、耳机型号、权限和连接状态、帧数变化及复现步骤，避免上传包含个人信息的完整日志。

## 致谢与许可

基于 [Cogria-AI / HeadOrbit](https://github.com/Cogria-AI/HeadOrbit) 的提交 `344eaf95db628e1947ae90894960d436af55f117`，复用或修改其运动追踪、姿态、音频检测、触发状态机和模糊接口代码。原 MIT 声明保留在 [HeadOrbit-LICENSE](HeadOrbit-LICENSE)。

回望增加独立 GUI、Dock 窗口行为、连接诊断与部分连接处理改进，以及应用视觉标识。Logo 由 AI 图像生成工具制作，[提示词与说明](Assets/logo-notes.md) 随源码提供。

项目以 [MIT License](LICENSE) 开源，欢迎提交 Issue 和 Pull Request。
