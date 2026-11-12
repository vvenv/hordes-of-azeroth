# GM Box — 给本地 VMaNGOS realm 用的 GM 面板

装在 1.12.1 客户端里（`client/Interface/AddOns/GMBox`）。所有按钮做的事都一样：
把一条 `.` 开头的 GM 命令通过聊天发给服务端。需要 GM 账号（本 realm 的 `admin`
是 gmlevel 6），没权限的话服务端只会拒绝，不会有别的后果。

## 打开

| 操作 | 说明 |
|---|---|
| `/gm` | 开关面板 |
| `/gt <关键词>` | 传送：只有一个匹配就直接过去，多个就打开列表 |
| `/gi <关键词或 id> [数量]` | 加物品：同上，唯一匹配直接进包 |
| `/gm help` | 帮助 |

也可以在「按键设置 → GM Box」里绑一个快捷键。

## 三个页签

**Teleport** — 服务端 `game_tele` 表里的 997 个地点，输入片段即可搜索
（`iron` → Ironforge，`gurub` → ZulGurub，短别名如 `brd`、`av`、`aq40` 也在里面）。

- 左键 = `.tele <地名>`
- Shift+左键 = `.go xyz`（按坐标硬跳，`.tele` 名字有歧义时用它）
- 右键 = 收藏（打星，搜索框为空时排在最前）
- 底部：`go xyz` 手输坐标、`Recall`（回到上次传送前的位置）、`Where`（`.gps`）

**Items** — 服务端 `item_template` 里的 17707 件物品，按名字或 id 搜。
名字按品质染色，右侧是 id，鼠标悬停出物品提示。

- 左键 = `.additem <id> <数量>`，数量取底部输入框（1/5/20/100 有快捷按钮）
- Shift+左键 = 只加 1 个
- 右键 = 收藏

**Tools** — 常用开关，一行一组：GM 模式与隐身、god/fly/waterwalk、全飞行点、
全地图、复活、脱卡、修装、满技能、学光本职法术与天赋、移速 1/2/4/7 倍、加钱加等级、
以及对玩家的 `.goname`（去他那）/ `.namego`（把他叫来）/ `.pinfo`。
最下面有一个「Any command」输入框，任何没做成按钮的命令都能直接敲（前面的点可省）。

搜索框为空时，列表显示的是收藏 + 最近用过的，收藏和最近记录存在
`WTF/Account/ADMIN/SavedVariables/GMBox.lua`。

## 中英文

插件在载入时看 `GetLocale()`：中文客户端（zhCN）下界面标签、地图名、提示和聊天回显
都是中文，物品列表显示中文名（数据库 `locales_item.name_loc4`，覆盖 89%，没有中文名的
回落到英文）。**搜索中英文都认**——`/gi 亚麻布` 和 `/gi linen cloth` 都能命中 2589。

传送点名字保持英文原样（`Ironforge`、`brd`、`aq40`），因为那是 `.tele` 命令的键，必须
逐字传给服务端；地图那一列是中文。

英文客户端下一切照旧，不受影响。

## 数据是烤进插件里的

`Data_Tele.lua` 和 `Data_Items.lua` 是从世界数据库直接导出的，搜索完全在本地完成，
不跟服务端交互，所以打字即出结果。数据库变了（比如 `.tele add` 加了新传送点、
改了物品表）就重新生成：

```sh
~/vvenv/wow/bin/gmbox-gen-data.sh
```

脚本会读 `config/mangosd.conf` 里的 `WowPatch`，和服务端一样按「不超过该补丁的最新
一版」取物品（`item_template` 每件物品每个补丁各存一行，不去重会出现同名重复项）。

## 注意

- 新加的插件要**完全重启客户端**才会被识别，`/console reloadui` 不行。
- 死亡状态下客户端可能不让发 `SAY`，那时按钮会没反应——先复活或用 `.revive`
  之外的途径。
- 命令走的是聊天通道，但服务端 `HandleMessagechatOpcode` 会把 `.` 开头的行交给命令
  解析器，不会广播出去；命令不存在时只回一句 "There is no such command"。
- `.cheat fly` / `.cheat god` 这类开关是否可用取决于核心编译选项，不支持时同样只会
  收到 "There is no such command"，无副作用。
