--[[--------------------------------------------------------------------------
Chinese for benilla's own windows on a zhCN client: the options window
(BenillaOptionsFrame), its key bindings page and the ESC menu. benilla writes
their labels in English (the rows' tooltips already come from the client's
own OPTION_TOOLTIP_* strings, which are Chinese). This file swaps the label
texts through a table, so benilla itself stays untouched:

  * every FontString under the options window, when it opens and every
    0.2 s while it is open (rows, headers, buttons, the binding prompts);
  * dropdown entries as UIDropDownMenu_AddButton adds them;
  * the long tooltips benilla writes itself (BENILLA_TOOLTIP_* globals);
  * the ESC menu's buttons.

Row search keeps working in both languages: a translated row's search tag
gets the Chinese label appended.
----------------------------------------------------------------------------]]

if GetLocale() ~= "zhCN" then return end

local ZH = {
  -- window, tabs, buttons
  ["Options"] = "选项",
  ["Options Menu"] = "选项菜单",
  ["Game"] = "游戏",
  ["AddOns"] = "插件",
  ["Defaults"] = "恢复默认",
  ["Search"] = "搜索",
  ["Search Results"] = "搜索结果",
  ["No results found."] = "没有找到结果。",
  ["Close"] = "关闭",
  ["Apply"] = "应用",
  ["Support"] = "帮助",
  ["Edit Mode"] = "编辑模式",

  -- categories
  ["Controls"] = "控制",
  ["Interface"] = "界面",
  ["Action Bars"] = "动作条",
  ["Combat"] = "战斗",
  ["Social"] = "社交",
  ["Chat"] = "聊天",
  ["Keybindings"] = "按键设置",
  ["System"] = "系统",
  ["Graphics"] = "图形",
  ["Audio"] = "声音",
  ["Gameplay"] = "游戏性",
  ["Nameplates"] = "姓名板",

  -- controls
  ["Block Trades"] = "阻止交易",
  ["Auto Self Cast"] = "自动自我施法",
  ["Auto Loot"] = "自动拾取",
  ["Invert Mouse"] = "反转鼠标",
  ["Mouse Sensitivity"] = "鼠标灵敏度",
  ["Mouse Look Speed"] = "鼠标视角速度",
  ["Click-to-Move"] = "点击移动",
  ["Camera Following Style"] = "镜头跟随方式",
  ["Smart"] = "智能",
  ["Always"] = "总是",
  ["Never"] = "从不",
  ["Smart Pivot"] = "智能旋转",
  ["Follow Terrain"] = "跟随地形",
  ["Head Bob"] = "镜头晃动",
  ["Water Collision"] = "水面碰撞",
  ["Max Camera Distance"] = "最大镜头距离",
  ["Auto-Follow Speed"] = "自动跟随速度",
  ["Sticky Targeting"] = "目标锁定",
  ["Attack on assist"] = "协助时攻击",

  -- interface
  ["Status Bar Text"] = "状态条文字",
  ["Show Target of Target"] = "显示目标的目标",
  ["Raid"] = "团队",
  ["Party"] = "队伍",
  ["Solo"] = "单人",
  ["Party or Raid"] = "队伍或团队",
  ["Show When"] = "显示时机",
  ["Show Combo Points"] = "显示连击点",
  ["Buff Durations"] = "增益持续时间",
  ["Show Auras"] = "显示光环",
  ["Show Helm"] = "显示头盔",
  ["Show Cloak"] = "显示披风",
  ["Show Tutorials"] = "显示教程",
  ["Show Loading Screen Tips"] = "显示载入画面提示",
  ["Enhanced Tooltips"] = "增强鼠标提示",
  ["Show Detailed Tooltips"] = "显示详细鼠标提示",
  ["Detailed Loot Information"] = "详细拾取信息",
  ["Instant Quest Text"] = "立即显示任务文字",
  ["Automatic Quest Tracking"] = "自动追踪任务",
  ["Player Names"] = "玩家姓名",
  ["Player Guild Names"] = "玩家公会名称",
  ["Player Titles"] = "玩家头衔",
  ["NPC Names"] = "NPC 姓名",
  ["Show Own Name"] = "显示自己的姓名",
  ["Show Friendly Healer Names"] = "显示友方治疗者姓名",
  ["Friendly Name Plates"] = "友方姓名板",
  ["Enemy Name Plates"] = "敌方姓名板",
  ["UI Scale"] = "界面缩放",

  -- action bars
  ["Lock ActionBars"] = "锁定动作条",
  ["Always Show ActionBars"] = "总是显示动作条",
  ["Show Bottom Left ActionBar"] = "显示左下方动作条",
  ["Show Bottom Right ActionBar"] = "显示右下方动作条",
  ["Show Right ActionBar"] = "显示右侧动作条",
  ["Show Right ActionBar 2"] = "显示右侧动作条 2",

  -- combat
  ["Enable Floating Combat Text"] = "开启浮动战斗信息",
  ["Combat Text Float Mode"] = "战斗信息浮动方式",
  ["Scroll Up"] = "向上滚动",
  ["Scroll Down"] = "向下滚动",
  ["Arc"] = "弧形",
  ["Show Target Damage"] = "显示对目标的伤害",
  ["Pet Damage"] = "宠物伤害",
  ["Periodic Damage"] = "周期性伤害",
  ["Show Damage Reduction"] = "显示伤害减免",
  ["Show Dodge/Parries/Misses"] = "显示躲闪/招架/未命中",
  ["Show Energy Gains"] = "显示能量获得",
  ["Show Fading Auras"] = "显示消失的光环",
  ["Show Combat State"] = "显示战斗状态",
  ["Show Low Mana and Health"] = "显示低法力和低生命",
  ["Show Reactive Spells and Abilities"] = "显示触发的法术和技能",
  ["Show Honor Gained"] = "显示获得的荣誉",
  ["Show Reputation"] = "显示声望变化",

  -- social / chat
  ["Profanity Filter"] = "语言过滤",
  ["Disable Spam Filter"] = "关闭垃圾信息过滤",
  ["Guild Member Alert"] = "公会成员提示",
  ["Show Chat Bubbles"] = "显示聊天泡泡",
  ["Show Party Chat Bubbles"] = "显示队伍聊天泡泡",
  ["Remove Chat Hover Delay"] = "取消聊天悬停延迟",
  ["Auto Clear AFK"] = "自动取消暂离",

  -- key bindings
  ["Character Specific Key Bindings"] = "角色专用按键设置",
  ["Unbind Key"] = "解除绑定",
  ["Are you sure you want to reset all keybindings to their defaults?"] = "确定要把所有按键设置恢复为默认吗？",
  ["Not Bound"] = "未绑定",
  ["Key Bound Successfully"] = "按键绑定成功",
  ["Can't bind mousewheel to actions with up and down states"] = "不能把鼠标滚轮绑定到有按下/松开状态的动作上",

  -- graphics
  ["Display Mode"] = "显示模式",
  ["Resolution"] = "分辨率",
  ["Automatic"] = "自动",
  ["Windowed"] = "窗口",
  ["Windowed (Fullscreen)"] = "窗口（全屏）",
  ["Render Scale"] = "渲染缩放",
  ["Vertical Sync"] = "垂直同步",
  ["Brightness"] = "亮度",
  ["Terrain Distance"] = "地形距离",
  ["Environment Detail"] = "环境细节",
  ["Weather Intensity"] = "天气强度",
  ["Low"] = "低",
  ["Medium"] = "中",
  ["High"] = "高",
  ["Minimal"] = "最低",
  ["Full"] = "完全",

  -- audio
  ["Enable All Sound"] = "开启所有声音",
  ["Enable Music"] = "开启音乐",
  ["Enable Ambience"] = "开启环境音效",
  ["Enable Error Speech"] = "开启错误语音",
  ["Enable Sound in Background"] = "后台时播放声音",
  ["Master Volume"] = "主音量",
  ["Sound Volume"] = "音效音量",
  ["Music Volume"] = "音乐音量",
  ["Ambience Volume"] = "环境音量",
}

-- Texts with a variable part.
local PATTERNS = {
  { "^Press Key to Bind to Command %-> (.+)$", "请按下要绑定到“%s”的按键" },
}

-- The tooltips benilla writes itself (rows look them up by global name when
-- hovered, so replacing the globals is enough).
BENILLA_TOOLTIP_RENDER_SCALE =
  "以窗口分辨率的一定比例绘制 3D 世界，也可以高于窗口分辨率。界面不受这个设置影响。\n\n"
  .. "低于 100% 会牺牲清晰度换取帧数；高于 100% 是超采样，边缘更平滑但更耗帧数。点击“应用”后生效。"
BENILLA_TOOLTIP_BACKGROUND_SOUND =
  "切换到其他窗口时，游戏声音继续播放。\n\n"
  .. "关闭后，切走时游戏静音，切回来时恢复。静音期间声音仍在后台进行，较长的声音可能在你回来前已经播完。"
BENILLA_TOOLTIP_DISPLAY_MODE =
  "“窗口（全屏）”用无边框窗口铺满屏幕；“窗口”是普通窗口。\n\n"
  .. "没有独占全屏模式。魔兽世界本身在 8.0.1 去掉了它，现在的怀旧服也只提供这两种。"
BENILLA_TOOLTIP_RESOLUTION =
  "“自动”以屏幕自己的分辨率铺满屏幕。\n\n"
  .. "选择一个尺寸，就会以这个大小的窗口运行游戏。在 Steam Deck 等掌机上，窗口会被拉伸铺满屏幕。"
  .. "想保持全屏、只让 3D 世界用更低或更高的分辨率绘制，请用“渲染缩放”。"
BENILLA_TOOLTIP_BRIGHTNESS =
  "调亮或调暗整个画面，主要用于夜晚、洞穴和室内。\n\n"
  .. "这和 1.12 通过显示器伽马曲线做的校正相同，那种方式只在独占全屏下有效。"
  .. "benilla 改为对最终画面做校正，所以两种显示模式下都有效。"

local function Translate(text)
  if not text or text == "" then return nil end
  local zh = ZH[text]
  if zh then return zh end
  for i = 1, table.getn(PATTERNS) do
    local _, _, cap = string.find(text, PATTERNS[i][1])
    if cap then return string.format(PATTERNS[i][2], cap) end
  end
  return nil
end

local function TranslateRegions(frame)
  local regions = { frame:GetRegions() }
  for i = 1, table.getn(regions) do
    local r = regions[i]
    if r and r.GetObjectType and r:GetObjectType() == "FontString" then
      local zh = Translate(r:GetText())
      if zh then r:SetText(zh) end
    end
  end
end

-- Walks a frame tree once: font strings, button texts, and the rows' search
-- tags (English and Chinese, so either finds the row).
local function Walk(frame)
  if not frame then return end
  TranslateRegions(frame)
  if frame.searchTag and frame.GetName and frame:GetName() then
    local label = getglobal(frame:GetName() .. "Label")
    local text = label and label:GetText()
    if text and not string.find(frame.searchTag, text, 1, true) then
      frame.searchTag = frame.searchTag .. " " .. text
    end
  end
  local children = { frame:GetChildren() }
  for i = 1, table.getn(children) do
    Walk(children[i])
  end
end

-- Dropdown entries, as they are added.
local origAddButton = UIDropDownMenu_AddButton
function UIDropDownMenu_AddButton(info, level)
  if info and info.text then
    local zh = Translate(info.text)
    if zh then info.text = zh end
  end
  return origAddButton(info, level)
end

local watcher = CreateFrame("Frame")
local elapsed = 0
watcher:SetScript("OnUpdate", function()
  elapsed = elapsed + arg1
  if elapsed < 0.2 then return end
  elapsed = 0
  if BenillaOptionsFrame and BenillaOptionsFrame:IsVisible() then
    Walk(BenillaOptionsFrame)
  end
  if GameMenuFrame and GameMenuFrame:IsVisible() then
    Walk(GameMenuFrame)
  end
end)

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
  if BenillaOptionsFrame then Walk(BenillaOptionsFrame) end
  if GameMenuFrame then Walk(GameMenuFrame) end
end)
