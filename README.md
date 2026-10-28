# ArtCraft 简体中文补丁

这是一个不改动原安装文件的中文界面补丁，适用于 Windows 版
ArtCraft 0.41.0。

## 对方需要什么

- Windows 10 或 Windows 11
- 已安装官方 ArtCraft 0.41.0
- 不需要另外安装 Node.exe，补丁带有便携运行时,完整版懒人包（内含 node.exe）在右侧 Releases 下载

## 使用方法

1. 把压缩包完整解压到一个可写目录，例如桌面或文档目录。
2. 完全退出 ArtCraft，包括托盘图标。
3. 双击 `Launch ArtCraft Chinese.vbs`。
4. 第一次启动如果找不到 ArtCraft，会弹出文件选择框。选择已安装的
   `artcraft.exe`，之后会记住该位置。
5. 如需桌面图标，双击 `Create Desktop Shortcut.vbs`。

每次启动会从官方安装目录复制 `artcraft.exe` 到补丁的 `bin` 目录，
只在这份副本中开启本机调试端口，然后把中文翻译层注入界面。原版程序、
账号、作品、提示词和下载文件都不会被修改或迁移。

## 注意

- 只应在可信渠道接收补丁。补丁会生成未签名的程序副本，Windows
  SmartScreen 或杀毒软件可能弹出提示。
- ArtCraft 升级后，如果提示“启动参数不兼容”，说明当前补丁不支持
  新版本，需要等待补丁更新。
- 中文翻译在本机完成，不会把提示词或界面内容发送到额外服务器。
- Node.js 便携运行时的许可证见 `NODE-LICENSE.txt`。
- 补丁脚本采用 MIT 许可证，见 `PATCH-LICENSE.txt`。

## 翻译范围

已覆盖首页、左侧导航、登录/注册、图像/视频/音频/3D、背景替换、
灵感板、视频抽帧、常用生成参数、菜单和提示信息。

ArtCraft 品牌名、模型名、你输入的提示词、项目名、文件名和模型生成
内容会保持原样。
## 汉化前后对比
<img width="1262" height="661" alt="image" src="https://github.com/user-attachments/assets/aafdd49c-0363-4ff7-8583-e7f03b8b9ab3" />
<img width="1255" height="670" alt="image" src="https://github.com/user-attachments/assets/69c71ede-2638-4d3f-9795-5c0e4e98c0f3" />
<img width="1255" height="671" alt="image" src="https://github.com/user-attachments/assets/38537855-780c-4a96-a332-5e6761b23d83" />

<img width="1263" height="669" alt="image" src="https://github.com/user-attachments/assets/75a1e6d8-cd72-4998-abee-aed2e3a47b6a" />
<img width="1255" height="671" alt="image" src="https://github.com/user-attachments/assets/e439cad1-5cfb-4b52-8122-780068b92ee8" />
<img width="512" height="394" alt="image" src="https://github.com/user-attachments/assets/9963511b-03d1-4281-9122-c6ee9e13c9cf" />



