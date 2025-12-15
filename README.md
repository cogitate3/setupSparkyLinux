# Setup Sparky Linux 7.5

[English](README.en.md) [使用说明](setup.md) [User Manual](setup.en.md)

一键安装脚本，用于设置和自定义 Sparky Linux 7.5（或其他基于 Debian Bookworm 的发行版）。

![安装菜单](https://raw.githubusercontent.com/alt369/picgo/main/202501161907286.png)

## 概述

本项目旨在通过自动化安装常用软件和配置，简化全新 Linux 安装的过程。脚本使用 Bash 编写，专为 Sparky Linux 定制，但也足够灵活，可用于其他基于 Debian Bookworm 的发行版，如 MX Linux 和 Linux Mint。

## 项目动机

我开发这个项目的主要目的是在解决个人需求（简化轻量级 Linux 系统的设置）的同时学习 Bash 语言。

为了充分利用我的旧电脑，我探索了轻量级、资源效率高的 Linux 桌面系统。通过 [DistroWatch.com](https://distrowatch.com/)，我测试了几乎所有排名前 20 的发行版，并发现了 Linux live 模式的强大功能。Live 模式对于初始系统测试非常有价值，我也注意到 Linux 桌面体验这些年来显著改善，现在已经能够媲美约 90%的 Windows 系统可用性。

### 探索历程

为了更方便地尝试不同的系统，我接触到了 [Ventoy](https://ventoy.net/)，这是一个改变游戏规则的工具。通过 Ventoy，我可以将数十个 Linux 发行版复制到单个 USB 驱动器上，随时按需启动任何系统。这种方法使我能够绕过典型 Windows 计算机的限制，访问文件并使用硬件，而无需更改硬盘。

后来，我想知道这种自由是否也可以扩展到 Windows。经过一些研究，我发现了 **Windows To Go**，它使我能够直接从高速 USB 驱动器安装和运行 Windows。这成为了我主要的 Windows 设置，并加深了我对便携式操作系统的热情。

### 脚本的灵感来源

在使用官方 Linux 发行版时，我希望有一种快速安装我喜欢的软件的方法。这激发了我学习 Bash 编程来创建一键安装脚本的兴趣。虽然多年来进展缓慢，但这个想法一直存在。

最近，在 **windsurf**、编程参考资料和各种 AI 助手的帮助下，我终于在一周的专注努力后完成了这个脚本的 0.3 版本。调试过程充满挑战——AI 工具有时会引入一些需要手动修正的细微问题。最终，我在最后的调试阶段禁用了 windsurf 的自动完成功能以确保准确性。

脚本包含大量注释，既帮助我学习，也作为其他探索 Bash 的人的参考资源。

## 功能特点

- 通过单个命令安装基本软件和依赖项
- 专为 Sparky Linux 设计，但可适用于其他基于 Debian Bookworm 的系统
- 包含详细注释，便于学习

## 架构升级与重构 (v0.x -> Modular)

最近我们对项目进行了核心架构的重构，将单体脚本拆分为独立的模块化系统。这一主要改动解决了以下关键问题：

1.  **解决了“牵一发而动全身”的维护难题**
    *   **模块化架构**：每个功能（如 `rime`, `micro`, `plank`）拆分为独立的 `.mod.sh` 文件。修改 Rime 输入法模块不再担心意外破坏其他功能。
    *   **标准化接口**：所有模块遵循统一的 `mod_check`, `mod_install`, `mod_uninstall` 接口，结构清晰，极易扩展。

2.  **解决了安装效率与依赖管理问题**
    *   **批量安装优化**：重构了底层的包管理函数，支持一次性批量安装所有依赖，显著减少了 `sudo` 调用次数，大幅提升安装速度。
    *   **精准依赖**：清晰罗列核心包、前端界面、插件和字体依赖，告别依赖混乱。

3.  **解决了“功能缺失”与配置问题**
    *   **全自动配置**：不仅安装软件，更自动处理环境变量（如解决 Fcitx5 在 GTK/Qt 程序中的兼容性）和配置文件。
    *   **智能检测**：引入 `im-config` 等工具自动设置默认应用，实现真正的“零干预”安装。

4.  **提升了脚本的健壮性（幂等性）**
    *   **智能状态检查**：`mod_check` 函数现在会同时检查软件安装状态和配置文件状态。如果已正确配置，脚本会自动跳过，避免重复操作覆盖用户个性化设置。

这次重构将项目从一个简单的安装脚本升级为**专业、可扩展的系统配置框架**。

## 系统要求

- 基于 Debian Bookworm 的 Linux 发行版（如 Sparky Linux、MX Linux 或 Linux Mint）
- Bash shell（大多数 Linux 发行版的默认 shell）

## 使用方法

1. 克隆此仓库：

   ```bash
   git clone https://github.com/cogitate3/setupSparkyLinux.git
   cd setupSparkyLinux
   ```

2. 运行安装脚本：

   ```bash
   ```bash
   sudo bash ./setup.sh
   ```
   ```

3. 按照屏幕上的说明完成安装。

## 未来计划

- 测试和优化脚本在其他基于 Debian 的发行版上的表现
- 继续提升 Bash 编程技能并改进脚本功能

## 贡献

欢迎贡献、反馈和建议！请随时提出问题或提交拉取请求。

## 许可证

本项目采用 GPL-3.0 许可证。详情请参见 LICENSE 文件。

## 致谢

**特别感谢 [Emer Chen](https://sourceforge.net/u/ldsemerchen/profile/)**，这位热心的兄弟向我介绍了 Sparky Linux，并耐心回答了我这个 Linux 新手的各种初学者问题。Emer Chen 定制的 [Live Debian System (Debian Respin)](https://sourceforge.net/projects/antix-mate-respin/) 极其用户友好，有着完善的本地化、美观的界面，并预装了许多实用的应用程序。

**衷心感谢这些令人惊叹的工具和平台**，它们让我们作为开发者和用户的生活变得更加轻松：

- **[devv.ai](https://devv.ai/)**：程序员的福音。只需输入错误信息，就能得到答案。简单方便！

- **[ChatGPT-Next-Web](https://github.com/ChatGPTNextWeb/ChatGPT-Next-Web)**：有了这个开源项目，你可以自行部署 OpenAI 的 API，灵活管理和使用 AI 服务。

- **[chatgpt.com](https://chatgpt.com/)**：无所不知的助手。几乎所有问题都能找到答案。

- **[Claude.ai](https://claude.ai/new)**：在编程方面非常专业，能提供可靠的解决方案。

- **Grok-beta**：有了这个工具，不用再担心处理糟糕的英语了。

这些工具和平台共同让技术挑战变得轻而易举，前所未有地提升了我们的效率。感谢它们的存在，让我们的工作和学习体验更加顺畅和高效！

## 下一步计划：

- [x] 一键安装和配置 zsh 及其插件和界面定制
- [x] 一键配置挂载 webdav 远程文件夹
- [x] 一键安装中文输入法
- [x] 添加 plank 的自启动配置
- [x] 添加 angrysearch 的自启动配置
- [x] 添加云存储 (Rclone)
- [x] 添加实用的桌面截图翻译软件 (Pot)
- 测试和优化脚本在 MX Linux 和 Linux Mint 发行版上的兼容性
- 筛选软件，优化菜单布置，使其更易于导航，
