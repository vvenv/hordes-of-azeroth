# Azeroth（经典单机版）

一个在自己电脑上跑的魔兽世界 1.12.1 经典版：做任务、升级、探索，五人副本里自动有机器人队友补满队伍。

- **原版内容**：服务端是原版 [vmangos](https://github.com/vmangos/core)，世界数据、任务、刷怪都是 1.12 原样。
- **机器人组队**：进入五人副本 3 秒后，队伍自动补满 5 人。缺坦克就补坦克，缺治疗就补治疗，其余补不同职业的输出。bot 和你同级、装备匹配等级，掷骰全部放弃。活着离开副本时 bot 自动解散。
- **中文**：用简体中文 1.12 客户端的数据，界面、任务、NPC、物品都是中文。
- **单人化**：没有聊天频道，聊天框只当消息记录用（系统、拾取、经验、任务和 NPC 说话）。
- **插件**：pfUI、pfQuest、Atlas 三件套、Bagshui 等一套 1.12 插件，已经按单人旅行做任务配好，不弹首次设置向导。另有 GMBox 2.0（副本与机器人面板、传送、物品、GM 工具），界面和 pfUI 风格一致。
- **经验 2 倍**，掉落和金钱保持 1 倍。在 `config/mangosd.overrides.conf` 里可以改。

目前只支持 **Apple Silicon 的 Mac**，从源码构建。

> 这个仓库 fork 自 [Hordes of Azeroth](https://github.com/jonhaldors/hordes-of-azeroth)（幸存者玩法）。`classic` 分支去掉了幸存者（Bonk）和放置抽卡（Squad）玩法，改回经典模式；原来的玩法保留在 `main` 和 `squad` 分支。

---

## 需要准备

| 东西 | 说明 |
|---|---|
| Mac | Apple Silicon（M 系列芯片）。目前在 macOS 26 上测试过 |
| 开发工具 | Xcode 命令行工具：`xcode-select --install` |
| Homebrew 包 | `brew install cmake mariadb openssl@3 pkg-config` |
| Rust | 用 [rustup](https://rustup.rs) 安装 |
| 1.12.1 客户端 | build 5875 的 `Data` 文件夹。推荐简体中文版（zhCN），英文版（enUS）也可以 |
| 服务端地图数据 | vmangos 提取工具从 1.12 客户端提取的 `maps`、`vmaps`、`mmaps` 和 `5875/dbc` |
| 插件（可选） | 第三方 1.12 插件所在的文件夹 |

默认这些游戏数据都放在仓库**旁边**的 `../wow-data` 里：

```
../wow-data/
├── client-zhCN/Data/        中文客户端的 MPQ（CLIENT_LOCALE=enUS 时用 client/Data）
├── vmangos-deploy/storage/mangosd/extracted-data/
│   ├── maps/  vmaps/  mmaps/  5875/
└── addons/                  第三方插件（pfUI、pfQuest、Atlas……）
```

放在别处的话，运行安装脚本时用环境变量指过去：`WOW_DATA_ROOT`（整个文件夹）、`CLIENT_LOCALE`（`zhCN` 或 `enUS`）、`HOA_EXTRACTED`（提取好的地图数据）、`ADDONS_SRC`（插件文件夹）。

还没有提取好的地图数据的话，用 vmangos 自带的提取工具从 1.12 客户端生成：构建时加 `-DBUILD_EXTRACTORS=1`，用法见 [vmangos](https://github.com/vmangos/core) 的文档。

---

## 第一次安装

```sh
git clone --recurse-submodules -b classic git@github.com:vvenv/hordes-of-azeroth.git
cd hordes-of-azeroth

tools/macos/build-classic.sh                         # 编译服务端和客户端（第一次要编译一阵子）
tools/macos/setup-classic.sh                         # 数据库、配置、客户端数据、插件
tools/macos/play.sh --server-only                    # 先把服务器开起来
tools/macos/create-account.sh 账号 密码 gm           # 建账号；gm 表示给 GM 权限
tools/macos/play.sh                                  # 进游戏
```

各步骤做了什么：

1. **`build-classic.sh`**：编译服务端（`mangosd`、`realmd`），装到 `release/build/macos/server-classic`；再编译客户端，生成 `release/build/macos/client-target/release/HordesOfAzeroth`。也可以只编一边：`build-classic.sh server` 或 `build-classic.sh client`。
2. **`setup-classic.sh`**：重复运行是安全的，已有的东西不会动。它会：
   - 把服务端程序和地图数据链接进 `server/run`、`server/data`；
   - 初始化并启动 MariaDB（数据在 `server/mariadb-data`）；
   - 第一次运行时，下载 vmangos 官方世界数据库快照（约 30 MB），建四个库：`classic_world`、`classic_characters`、`classic_realmd`、`classic_logs`；以后再运行只补新的数据库迁移；
   - 生成服务端配置，把 `Data/` 链接到客户端的 MPQ；
   - 设置客户端（服务器名 Azeroth，不限插件脚本内存），安装插件。

   加 `--reset-db` 会清空重建这四个库，**角色也会被清掉**。
3. **`create-account.sh`**：需要服务器在运行。加 `gm` 的账号才能用 GMBox 的传送、物品和工具按钮；机器人组队不需要 GM。

## 日常使用

| 做什么 | 命令 |
|---|---|
| 开始玩 | `tools/macos/play.sh`（服务器没开会先开） |
| 只开服务器 | `tools/macos/play.sh --server-only` |
| 关服务器 | `tools/macos/stop-server.sh`（加 `--all` 连 MariaDB 一起关） |
| 拉代码后重新编译 | `tools/macos/build-classic.sh`，再 `tools/macos/setup-classic.sh`（补数据库迁移） |
| 改了服务端设置 | 改 `config/mangosd.overrides.conf`，然后运行 `tools/macos/apply-config.sh`，重启服务器 |
| 更新插件 | `tools/macos/install-addons.sh`，然后**完全重启**客户端（`/reload` 不会加载新插件） |

关掉客户端后服务器会继续运行。服务器的输出在 `server/logs/mangosd.out`。

---

## 游戏里

### 机器人队友

- 进五人副本 3 秒后自动补满队伍。登录时就在副本里也算进入。
- 活着离开副本，副本里补的 bot 会解散；死了跑尸的路上不会解散。
- 团队副本不会自动补。在野外想带 bot 做精英任务，用「补满队伍」或 `.bots fill`。

**GMBox 的「副本」页**：输入 `/gd`，或者右键小地图上的 GMBox 按钮打开。

- **我的职责**：自动、坦克、治疗、输出四选一，bot 会补齐你之外的职责。选“自动”时，按职业、天赋和是否带盾来判断。
- **进副本自动补机器人**开关，**补满队伍**，**解散机器人**。
- **副本列表**：按推荐等级排序，颜色和任务日志一样。点一下直接传送进副本，这个功能需要 GM 账号。
- **指挥**：到我身边、集火目标、停手、坦克拉怪（输出 bot 等 10 秒再动手）、原地待命、继续。

不用插件也可以直接输命令：

| 命令 | 作用 |
|---|---|
| `.bots` | 查看自己的职责和自动补位设置 |
| `.bots role tank\|healer\|dps\|auto` | 设定自己的职责 |
| `.bots auto on\|off` | 进副本是否自动补 bot |
| `.bots fill` / `.bots dismiss` | 立刻补满 / 解散 bot |
| `.partybot cometome` | 所有 bot 到你身边 |
| `.partybot attackstart` / `attackstop` | 集火你的目标 / 停手 |
| `.partybot pull` | 坦克 bot 去拉你选中的怪 |
| `.partybot pause` / `unpause` | 原地待命 / 继续（选中某个 bot 时只对它生效） |

### 单人设置（Solo 插件）

`Interface/AddOns/!Solo` 每次登录都会对每个角色生效：

- **聊天**：不显示说话、喊话、表情、密语、队伍、公会和频道消息，只保留系统、拾取、金钱、经验、声望、技能、任务和 NPC 说话。服务器也拒绝加入任何频道（`Channel.Disable = 1`）。
- **pfUI**：跳过首次设置向导，新角色用 Modern 布局。另外：
  - 世界地图显示未探索区域；小地图放大，常显区域名和坐标；任务日志显示等级；
  - 底部信息栏不显示公会和好友，改为经验、耐久、背包空格；
  - 升级和拿到史诗装备时自动截图，自动卖灰色物品；
  - 关掉团队框体、更新检查、密语转发、社交增强、复制聊天和 pfUI 自带背包（背包用 Bagshui）。
- **pfQuest**：新角色跳过欢迎向导，世界地图显示刷怪点和任务图标，小地图显示刷怪点，打开导航箭头。

想改某一项，就改 `Solo.lua` 里对应的表，再运行 `tools/macos/install-addons.sh`。

### GMBox 的其他页

- **传送**：服务器上的 997 个传送点，中文、英文、拼音都能搜。也可以用 `/gt 地名`。
- **物品**：按名字或 id 搜物品放进背包，可以勾选“我能用”。也可以用 `/gi 名字 数量`。
- **工具**：GM 模式、无敌、飞行、复活、修理、学技能、加速、加钱加等级，以及任意命令输入框。

---

## 目录

| 位置 | 内容 |
|---|---|
| `server/core` | 服务端（子模块，`classic` 分支）：原版 vmangos 加上 macOS 修复和副本机器人 `src/game/PlayerBots/DungeonBotMgr.*` |
| `client` | 客户端（子模块）：[benilla](https://github.com/samwhosung/benilla)，用 Rust 从零写的 1.12 客户端 |
| `Interface/AddOns/GMBox` | GMBox 插件 |
| `Interface/AddOns/!Solo` | 单人设置插件（名字以 `!` 开头，保证比其他插件先加载） |
| `config/` | 服务端配置改动（`*.overrides.conf`）和 MariaDB 配置 |
| `tools/macos/` | 构建、安装、启动脚本 |
| `benilla-config/` | 客户端设置、插件（`AddOns/`）和插件存档（`saved/`），不进 git |
| `Data/` | 指向客户端 MPQ 的链接，不进 git |
| `server/run`、`server/data`、`server/logs` | 服务端运行目录、地图数据、日志，不进 git |

服务端完全是 vmangos 原版加我们自己的少量提交，跟进上游很直接：

```sh
cd server/core
git fetch upstream            # upstream = https://github.com/vmangos/core.git
git merge upstream/development
cd ../.. && tools/macos/build-classic.sh server && tools/macos/setup-classic.sh
```

新增数据库迁移文件（`server/core/sql/migrations`）之后要重新编译服务端，因为 `mangosd` 会把迁移列表编进程序。数据库缺迁移时它会拒绝启动。

---

## 常见问题

**客户端进游戏后十几秒自己退出了。**
插件超过了 1.12 默认的 48 MB 脚本内存上限。`setup-classic.sh` 会在 `benilla-config/config.toml` 里设置 `scriptMemory = "0"`（不限），重新运行一遍即可。

**服务器重启后，原来在副本里下线的角色出现在副本门口外面。**
这是原版机制：重启后副本实例没了，角色会被放到门口。走进传送门就会照常补 bot。

**GM 命令没反应，提示“您无法使用此命令”。**
GM 权限读的是 `classic_realmd.account_access` 表，不是 `account.gmlevel`。用 `tools/macos/create-account.sh 账号 密码 gm` 建账号，或者在服务器控制台执行 `account set gmlevel 账号 6`。

**bot 太弱或者太强。**
副本难度还没调，这是下一步要做的。

---

## 关于

非官方的爱好者项目，与 Blizzard Entertainment 无关。仓库和构建产物里不含任何游戏本身的文件：模型、贴图、声音、地图和游戏数据都来自你自己的 1.12.1 客户端。

World of Warcraft 和 Blizzard Entertainment 是 Blizzard Entertainment, Inc. 的商标或注册商标。

本仓库代码使用 [GNU General Public License v3.0](LICENSE)。客户端基于 [benilla](https://github.com/samwhosung/benilla)（MIT 或 Apache-2.0）。服务端基于 [VMaNGOS](https://github.com/vmangos/core)（GPL-2.0）。第三方插件各有各的许可，由安装脚本从你自己的插件文件夹复制，不随仓库分发。其他依赖见 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)。

`BUILDING.md` 和 `CHANGELOG.md` 记录的是原来的幸存者玩法（Windows 启动器版），不适用于 `classic` 分支。
