--[[--------------------------------------------------------------------------
GMBox -- a small GM console for WoW 1.12.1 / Lua 5.0, aimed at VMaNGOS.

What it does: search the server's 997 teleport points and its 20034 items by
name, and fire the matching GM command with one click. The two databases are
baked into Data_Tele.lua / Data_Items.lua (dumped straight from the world DB),
so searching needs no server round trip and works while you are loading.

How the commands get to the server: every button ends up in SendChatMessage()
with a leading dot. VMaNGOS's WorldSession::HandleMessagechatOpcode hands any
dot-prefixed chat line to the command parser and never broadcasts it -- an
unknown command answers "There is no such command" rather than leaking into
/say. Nothing here needs a protected/secure context; it is all plain chat.

Requires a GM account (this realm: gmlevel 6). Without it the server simply
refuses each command.
----------------------------------------------------------------------------]]

local VERSION = "1.1.1"

-- The realm's world DB carries Simplified Chinese for ~89% of items, so on a
-- zhCN client the addon searches and shows Chinese names and labels. The 1.12
-- Chinese client reads UTF-8 (verified against pfQuest's own zhCN data), which
-- is what Data_Items.lua is written in.
local ZH = (GetLocale and GetLocale() == "zhCN") and true or false
local function L(en, zh) if ZH and zh then return zh end return en end

local ROWS      = 16     -- visible result rows
local ROW_H     = 15
local MAX_HITS  = 400    -- cap on search results, keeps sorting cheap
local MAX_RECENT = 12

-- Data_Tele.lua (loaded before this file) ships two index-aligned tables next
-- to GMBox_Tele: GMBox_TeleZH (Chinese area names, "" where none was found)
-- and GMBox_TelePY ("abbr pinyin" per entry). Searching any of the three is
-- why a zhCN client can hit the tele list by hanzi or pinyin.
local TELE_ALTS = { GMBox_TeleZH or {}, GMBox_TelePY or {} }

local COL = "|cff44ddff"                    -- addon colour, used in chat output
local QCOLOR = {                            -- item quality -> rgb
  [0] = { 0.62, 0.62, 0.62 }, [1] = { 1.00, 1.00, 1.00 },
  [2] = { 0.12, 1.00, 0.00 }, [3] = { 0.00, 0.44, 0.87 },
  [4] = { 0.64, 0.21, 0.93 }, [5] = { 1.00, 0.50, 0.00 },
  [6] = { 0.90, 0.80, 0.50 }, [7] = { 0.90, 0.80, 0.50 },
}

-- Map.dbc names for the ids that actually occur in game_tele.
local MAPNAME = {
  [0] = "Eastern Kingdoms", [1] = "Kalimdor", [13] = "Test", [30] = "Alterac Valley",
  [33] = "Shadowfang Keep", [34] = "Stockade", [36] = "Deadmines", [37] = "Azshara Crater",
  [43] = "Wailing Caverns", [47] = "Razorfen Kraul", [48] = "Blackfathom Deeps",
  [70] = "Uldaman", [90] = "Gnomeregan", [109] = "Sunken Temple", [129] = "Razorfen Downs",
  [189] = "Scarlet Monastery", [229] = "Blackrock Spire", [230] = "Blackrock Depths",
  [249] = "Onyxia's Lair", [289] = "Scholomance", [309] = "Zul'Gurub", [329] = "Stratholme",
  [349] = "Maraudon", [369] = "Deeprun Tram", [389] = "Ragefire Chasm", [409] = "Molten Core",
  [429] = "Dire Maul", [449] = "Alliance PvP", [451] = "GM Island", [469] = "Blackwing Lair",
  [489] = "Warsong Gulch", [509] = "Ruins of Ahn'Qiraj", [529] = "Arathi Basin",
  [531] = "Temple of Ahn'Qiraj", [533] = "Naxxramas",
}

local MAPNAME_ZH = {
  [0] = "东部王国", [1] = "卡利姆多", [13] = "测试", [30] = "奥特兰克山谷",
  [33] = "影牙城堡", [34] = "监狱", [36] = "死亡矿井", [37] = "艾萨拉火山口",
  [43] = "哀嚎洞穴", [47] = "剃刀沼泽", [48] = "黑暗深渊", [70] = "奥达曼",
  [90] = "诺莫瑞根", [109] = "沉没的神庙", [129] = "剃刀高地", [189] = "血色修道院",
  [229] = "黑石塔", [230] = "黑石深渊", [249] = "奥妮克希亚的巢穴", [289] = "通灵学院",
  [309] = "祖尔格拉布", [329] = "斯坦索姆", [349] = "玛拉顿", [369] = "地下铁",
  [389] = "怒焰裂谷", [409] = "熔火之心", [429] = "厄运之槌", [449] = "联盟 PvP",
  [451] = "GM 岛", [469] = "黑翼之巢", [489] = "战歌峡谷", [509] = "安其拉废墟",
  [529] = "阿拉希盆地", [531] = "安其拉神庙", [533] = "纳克萨玛斯",
}

local function MapLabel(id)
  if ZH then return MAPNAME_ZH[id] or MAPNAME[id] or ("map " .. id) end
  return MAPNAME[id] or ("map " .. id)
end

local function msg(s) DEFAULT_CHAT_FRAME:AddMessage(COL .. "GMBox|r: " .. s) end

-- ---------------------------------------------------------------- sending --

local function Cmd(s)
  if not s or s == "" then return end
  if string.sub(s, 1, 1) ~= "." then s = "." .. s end
  if string.len(s) > 250 then s = string.sub(s, 1, 250) end
  SendChatMessage(s, "SAY")
  return s
end

-- ------------------------------------------------------------- saved vars --

GMBoxDB = nil
local db

local function InitDB()
  if type(GMBoxDB) ~= "table" then GMBoxDB = {} end
  db = GMBoxDB
  if type(db.favTele)    ~= "table"  then db.favTele = {} end
  if type(db.favItem)    ~= "table"  then db.favItem = {} end
  if type(db.recentTele) ~= "table"  then db.recentTele = {} end
  if type(db.recentItem) ~= "table"  then db.recentItem = {} end
  if type(db.count)      ~= "number" then db.count = 1 end
  if type(db.tab)        ~= "number" then db.tab = 1 end
end

local function ListFind(t, v)
  for i = 1, table.getn(t) do if t[i] == v then return i end end
  return nil
end

local function Remember(t, v)
  local i = ListFind(t, v)
  if i then table.remove(t, i) end
  table.insert(t, 1, v)
  while table.getn(t) > MAX_RECENT do table.remove(t) end
end

local function ToggleFav(t, v)
  local i = ListFind(t, v)
  if i then table.remove(t, i) return false end
  table.insert(t, v)
  return true
end

-- ------------------------------------------------------------- search ------
-- Lowercase copies are built once, on first use: 20k string.lower() calls are
-- cheap enough as a one-off but not per keystroke.

local teleLower, teleByName
local itemLower, itemById, itemZH

local function BuildTele()
  if teleLower then return end
  teleLower, teleByName = {}, {}
  for i = 1, table.getn(GMBox_Tele) do
    local nm = GMBox_Tele[i][1]
    teleLower[i] = string.lower(nm)
    teleByName[string.lower(nm)] = i
  end
end

-- zhCN clients see and search the Chinese name when there is one; the English
-- game_tele name stays available (shown in the tooltip, always accepted by
-- /gt, and it is what gets sent to the server).
local function TeleDisplay(i)
  if ZH then
    local zh = GMBox_TeleZH and GMBox_TeleZH[i] or ""
    if zh and zh ~= "" then return zh end
  end
  return GMBox_Tele[i][1]
end

local function BuildItems()
  if itemLower then return end
  itemLower, itemById = {}, {}
  itemZH = GMBox_ItemNameZH and { GMBox_ItemNameZH } or nil   -- alternate names for Search()
  local names = GMBox_ItemName
  for i = 1, table.getn(names) do
    itemLower[i] = string.lower(names[i])
    itemById[GMBox_ItemID[i]] = i
  end
end

local function ItemQuality(i)
  return tonumber(string.sub(GMBox_ItemQuality, i, i)) or 1
end

-- Rank: earlier match wins, then shorter name -- so "iron" finds "Ironforge"
-- before "Fields of Iron", and "Ironforge" before "IronforgeBank".
local sortKey = {}
local function ByRank(a, b) return sortKey[a] < sortKey[b] end

-- `alts` is an optional list of alternate-name tables per index (Chinese name,
-- pinyin), so one pass matches either language. UTF-8 substring search is
-- plain byte search here, which is safe: a multi-byte sequence can never match
-- inside another one.
local function Search(lowered, alts, q, limit)
  local res = {}
  local n = table.getn(lowered)
  local hits = 0
  for i = 1, n do
    local at = string.find(lowered[i], q, 1, true)
    if not at and alts then
      for k = 1, table.getn(alts) do
        local a = alts[k][i]
        if a and a ~= "" then
          at = string.find(a, q, 1, true)
          if at then break end
        end
      end
    end
    if at then
      hits = hits + 1
      res[hits] = i
      sortKey[i] = (at - 1) * 1000 + string.len(lowered[i])
      if hits >= limit then break end
    end
  end
  table.sort(res, ByRank)
  return res
end

-- ------------------------------------------------------------- the frame ---

local rows = {}
local ui = {}
local view = { mode = "tele", results = {}, offset = 0, fav = false }

local function Backdrop(f)
  f:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })
end

local btnSeq = 0
local function Button(parent, w, h, text, point, rel, relPoint, x, y)
  btnSeq = btnSeq + 1
  local b = CreateFrame("Button", "GMBoxButton" .. btnSeq, parent, "UIPanelButtonTemplate")
  b:SetWidth(w) b:SetHeight(h) b:SetText(text)
  b:SetPoint(point, rel, relPoint, x, y)
  return b
end

local function Label(parent, text, font, point, rel, relPoint, x, y)
  local fs = parent:CreateFontString(nil, "ARTWORK", font or "GameFontNormalSmall")
  fs:SetText(text)
  fs:SetPoint(point, rel, relPoint, x, y)
  return fs
end

local Refresh, SetTab, RunSearch

-- current entry under a row, as a small record the click handlers understand
local function RowData(i)
  local idx = view.results[view.offset + i]
  if not idx then return nil end
  if view.mode == "tele" then
    local e = GMBox_Tele[idx]
    return { kind = "tele", name = e[1], show = TeleDisplay(idx),
             map = e[2], x = e[3], y = e[4], z = e[5] }
  else
    local en = GMBox_ItemName[idx]
    local cn = GMBox_ItemNameZH and GMBox_ItemNameZH[idx] or ""
    if cn == "" then cn = nil end
    return { kind = "item", id = GMBox_ItemID[idx], en = en, zh = cn,
             name = (ZH and cn) or en, q = ItemQuality(idx) }
  end
end

local function DoTele(d, useXYZ)
  if useXYZ then
    Cmd(".go xyz " .. d.x .. " " .. d.y .. " " .. d.z .. " " .. d.map)
  else
    Cmd(".tele " .. d.name)
  end
  Remember(db.recentTele, d.name)
  msg("-> " .. (d.show or d.name) .. " (" .. MapLabel(d.map) .. ")")
  Refresh()
end

local function DoItem(d, count)
  count = count or db.count or 1
  Cmd(".additem " .. d.id .. " " .. count)
  Remember(db.recentItem, d.id)
  msg("+" .. count .. " x " .. d.name .. " (" .. d.id .. ")")
  Refresh()
end

local function RowClick()
  local d = RowData(this.index)
  if not d then return end
  if arg1 == "RightButton" then
    local list = (d.kind == "tele") and db.favTele or db.favItem
    local key  = (d.kind == "tele") and d.name or d.id
    if ToggleFav(list, key) then msg(L("favourite added: ", "已收藏: ") .. d.name)
    else msg(L("favourite removed: ", "已取消收藏: ") .. d.name) end
    Refresh()
    return
  end
  if d.kind == "tele" then DoTele(d, IsShiftKeyDown())
  else DoItem(d, IsShiftKeyDown() and 1 or nil) end
end

local function RowEnter()
  local d = RowData(this.index)
  if not d then return end
  GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
  if d.kind == "item" then
    GameTooltip:SetHyperlink("item:" .. d.id .. ":0:0:0")
    GameTooltip:AddLine(" ")
    local other = ZH and d.en or d.zh
    if other then GameTooltip:AddLine(other, 0.8, 0.8, 0.8) end
    GameTooltip:AddLine("id " .. d.id, 0.6, 0.6, 0.6)
    GameTooltip:AddLine(L("Left click: add   Shift+click: add 1",
                          "左键放入背包   Shift+左键只放 1 个"), 0.4, 0.8, 1)
  else
    GameTooltip:AddLine(d.show or d.name)
    if ZH and d.show ~= d.name then
      GameTooltip:AddLine(d.name, 0.8, 0.8, 0.8)   -- the .tele name the server wants
    end
    GameTooltip:AddLine(MapLabel(d.map) ..
      "  " .. d.x .. " " .. d.y .. " " .. d.z, 0.8, 0.8, 0.8)
    GameTooltip:AddLine(L("Left click: .tele   Shift+click: .go xyz",
                          "左键 .tele 传送   Shift+左键按坐标 .go xyz"), 0.4, 0.8, 1)
  end
  GameTooltip:AddLine(L("Right click: toggle favourite", "右键收藏/取消收藏"), 0.4, 0.8, 1)
  GameTooltip:Show()
end

local function RowLeave() GameTooltip:Hide() end

-- ------------------------------------------------------------------ build --

local f = CreateFrame("Frame", "GMBoxFrame", UIParent)
f:SetWidth(566) f:SetHeight(410)
f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
Backdrop(f)
f:SetMovable(true) f:EnableMouse(true) f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", function() this:StartMoving() end)
f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
if f.SetClampedToScreen then f:SetClampedToScreen(true) end
f:Hide()
tinsert(UISpecialFrames, "GMBoxFrame")   -- Escape closes it

Label(f, L("GM Box ", "GM 工具箱 ") .. VERSION, "GameFontNormal", "TOP", f, "TOP", 0, -14)

local close = CreateFrame("Button", "GMBoxClose", f, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)

ui.tabs = {}
local TABS = { L("Teleport", "传送"), L("Items", "物品"), L("Tools", "工具") }
for i = 1, 3 do
  local b = Button(f, 96, 22, TABS[i], "TOPLEFT", f, "TOPLEFT", 16 + (i - 1) * 100, -34)
  b.index = i
  b:SetScript("OnClick", function() SetTab(this.index) end)
  ui.tabs[i] = b
end

-- search + result list (shared by the Teleport and Items tabs)
local panel = CreateFrame("Frame", nil, f)
panel:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -62)
panel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 16)
panel:EnableMouse(true)
panel:EnableMouseWheel(true)
panel:SetScript("OnMouseWheel", function()
  local step = (arg1 > 0) and -3 or 3
  view.offset = view.offset + step
  Refresh()
end)

ui.search = CreateFrame("EditBox", "GMBoxSearch", panel, "InputBoxTemplate")
ui.search:SetWidth(360) ui.search:SetHeight(20)
ui.search:SetPoint("TOPLEFT", panel, "TOPLEFT", 46, 0)
ui.search:SetAutoFocus(false)
ui.search:SetScript("OnTextChanged", function() RunSearch() end)
ui.search:SetScript("OnEscapePressed", function() this:ClearFocus() end)
ui.search:SetScript("OnEnterPressed", function()
  local d = RowData(1)
  if d then
    if d.kind == "tele" then DoTele(d) else DoItem(d) end
  end
end)
Label(panel, L("Find:", "搜索:"), "GameFontNormalSmall", "RIGHT", ui.search, "LEFT", -8, 0)

ui.clear = Button(panel, 52, 20, L("Clear", "清空"), "LEFT", ui.search, "RIGHT", 8, 0)
ui.clear:SetScript("OnClick", function()
  ui.search:SetText("")
  ui.search:ClearFocus()
end)

ui.favOnly = CreateFrame("CheckButton", "GMBoxFavCheck", panel, "UICheckButtonTemplate")
ui.favOnly:SetWidth(20) ui.favOnly:SetHeight(20)
ui.favOnly:SetPoint("LEFT", ui.clear, "RIGHT", 6, 0)
ui.favOnly:SetScript("OnClick", function() view.fav = this:GetChecked() and true or false RunSearch() end)
Label(panel, L("fav", "收藏"), "GameFontNormalSmall", "LEFT", ui.favOnly, "RIGHT", 0, 0)

for i = 1, ROWS do
  local b = CreateFrame("Button", "GMBoxRow" .. i, panel)
  b:SetWidth(524) b:SetHeight(ROW_H)
  if i == 1 then b:SetPoint("TOPLEFT", panel, "TOPLEFT", 2, -26)
  else b:SetPoint("TOPLEFT", rows[i - 1], "BOTTOMLEFT", 0, -1) end
  b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b.index = i
  b:SetScript("OnClick", RowClick)
  b:SetScript("OnEnter", RowEnter)
  b:SetScript("OnLeave", RowLeave)
  b.text = b:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  b.text:SetPoint("LEFT", b, "LEFT", 4, 0)
  b.text:SetJustifyH("LEFT")
  b.text:SetWidth(400)
  b.info = b:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  b.info:SetPoint("RIGHT", b, "RIGHT", -4, 0)
  b.info:SetJustifyH("RIGHT")
  rows[i] = b
end

ui.status = Label(panel, "", "GameFontDisableSmall", "BOTTOMLEFT", panel, "BOTTOMLEFT", 4, 30)

-- footer: item count on the Items tab, coordinate jump on the Teleport tab
ui.countLabel = Label(panel, L("Count:", "数量:"), "GameFontNormalSmall", "BOTTOMLEFT", panel, "BOTTOMLEFT", 4, 6)
ui.count = CreateFrame("EditBox", "GMBoxCount", panel, "InputBoxTemplate")
ui.count:SetWidth(50) ui.count:SetHeight(20)
ui.count:SetPoint("LEFT", ui.countLabel, "RIGHT", 10, 0)
ui.count:SetAutoFocus(false)
ui.count:SetNumeric(true)
ui.count:SetScript("OnTextChanged", function()
  local v = tonumber(this:GetText())
  if v and v > 0 then db.count = v end
end)
ui.count:SetScript("OnEscapePressed", function() this:ClearFocus() end)
ui.count:SetScript("OnEnterPressed", function() this:ClearFocus() end)

ui.quick = {}
local QUICKN = { 1, 5, 20, 100 }
for i = 1, 4 do
  local b = Button(panel, 34, 20, tostring(QUICKN[i]), "LEFT",
                   (i == 1) and ui.count or ui.quick[i - 1], "RIGHT", 4, 0)
  b.n = QUICKN[i]
  b:SetScript("OnClick", function()
    db.count = this.n
    ui.count:SetText(this.n)
  end)
  ui.quick[i] = b
end

ui.gox = CreateFrame("EditBox", "GMBoxGoXYZ", panel, "InputBoxTemplate")
ui.gox:SetWidth(190) ui.gox:SetHeight(20)
ui.gox:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 60, 6)
ui.gox:SetAutoFocus(false)
ui.gox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
ui.gox:SetScript("OnEnterPressed", function()
  local t = this:GetText()
  if t and t ~= "" then Cmd(".go xyz " .. t) msg(".go xyz " .. t) end
  this:ClearFocus()
end)
ui.goxLabel = Label(panel, L("go xyz:", "坐标:"), "GameFontNormalSmall", "RIGHT", ui.gox, "LEFT", -8, 0)
ui.recall = Button(panel, 70, 20, L("Recall", "回上个点"), "LEFT", ui.gox, "RIGHT", 8, 0)
ui.recall:SetScript("OnClick", function()
  Cmd(".recall")
  msg(L("recall (back to the spot before your last teleport)", "回到上次传送前的位置"))
end)
ui.gps = Button(panel, 60, 20, L("Where", "我在哪"), "LEFT", ui.recall, "RIGHT", 4, 0)
ui.gps:SetScript("OnClick", function() Cmd(".gps") end)

-- ------------------------------------------------------------- tools tab ---

local tools = CreateFrame("Frame", nil, f)
tools:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -62)
tools:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 16)
tools:Hide()

-- Each entry is { label, command, chinese label }. "%s" is replaced by the
-- player-name box below the grid.
local TOOLROWS = {
  { L("GM mode", "GM 模式"), {
    { "GM on", ".gm on", "开 GM" }, { "GM off", ".gm off", "关 GM" },
    { "Invis on", ".gm visible off", "隐身" }, { "Invis off", ".gm visible on", "现身" },
  } },
  { L("Cheats", "作弊"), {
    { "God on", ".cheat god on", "无敌开" }, { "God off", ".cheat god off", "无敌关" },
    { "Fly on", ".cheat fly on", "飞行开" }, { "Fly off", ".cheat fly off", "飞行关" },
  } },
  { L("More cheats", "更多"), {
    { "Waterwalk", ".cheat waterwalk on", "水上行走" },
    { "No waterwalk", ".cheat waterwalk off", "取消水行" },
    { "All taxis", ".taxicheat on", "全飞行点" },
    { "Explore map", ".explorecheat on", "全地图" },
  } },
  { L("Self", "自身"), {
    { "Revive", ".revive", "复活" }, { "Unstuck", ".unstuck", "脱卡" },
    { "Repair", ".repairitems", "修理" }, { "Max skills", ".maxskill", "满技能" },
  } },
  { L("Learn", "学习"), {
    { "My spells", ".learn all_myspells", "本职法术" },
    { "My talents", ".learn all_mytalents", "本职天赋" },
    { "Recipes", ".learn all_recipes", "配方" },
    { "Languages", ".learn all_lang", "语言" },
  } },
  { L("Speed", "移速"), {
    { "1x", ".modify speed 1" }, { "2x", ".modify speed 2" },
    { "4x", ".modify speed 4" }, { "7x", ".modify speed 7" },
  } },
  { L("Money / level", "金钱 / 等级"), {
    { "+10g", ".modify money 100000" }, { "+100g", ".modify money 1000000" },
    { "+1 level", ".levelup 1", "+1 级" }, { "+5 levels", ".levelup 5", "+5 级" },
  } },
  { L("Player", "玩家"), {
    { "Go to", ".goname %s", "去他那" }, { "Summon", ".namego %s", "召来" },
    { "Kill target", ".die", "杀死目标" }, { "Player info", ".pinfo %s", "玩家信息" },
  } },
}

local toolY = -4
for r = 1, table.getn(TOOLROWS) do
  local sect = TOOLROWS[r]
  Label(tools, sect[1], "GameFontNormalSmall", "TOPLEFT", tools, "TOPLEFT", 2, toolY)
  local defs = sect[2]
  for c = 1, table.getn(defs) do
    local b = Button(tools, 104, 20, L(defs[c][1], defs[c][3]), "TOPLEFT", tools, "TOPLEFT",
                     96 + (c - 1) * 108, toolY + 3)
    b.cmd = defs[c][2]
    b:SetScript("OnClick", function()
      local cmd = this.cmd
      if string.find(cmd, "%%s") then
        local who = GMBoxName:GetText()
        if not who or who == "" then
          if UnitExists("target") and UnitIsPlayer("target") then who = UnitName("target") end
        end
        if not who or who == "" then msg(L("type a player name in the box first", "先在下面的框里填玩家名")) return end
        cmd = string.gsub(cmd, "%%s", who)
      end
      msg(Cmd(cmd))
    end)
  end
  toolY = toolY - 32
end

local nameBox = CreateFrame("EditBox", "GMBoxName", tools, "InputBoxTemplate")
nameBox:SetWidth(150) nameBox:SetHeight(20)
nameBox:SetPoint("TOPLEFT", tools, "TOPLEFT", 96, toolY - 4)
nameBox:SetAutoFocus(false)
nameBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
nameBox:SetScript("OnEnterPressed", function() this:ClearFocus() end)
Label(tools, L("Player name", "玩家名"), "GameFontNormalSmall", "RIGHT", nameBox, "LEFT", -8, 0)
local grabTarget = Button(tools, 80, 20, L("Use target", "取当前目标"), "LEFT", nameBox, "RIGHT", 8, 0)
grabTarget:SetScript("OnClick", function()
  if UnitExists("target") then nameBox:SetText(UnitName("target"))
  else msg(L("no target", "没有目标")) end
end)

toolY = toolY - 34
local rawBox = CreateFrame("EditBox", "GMBoxRaw", tools, "InputBoxTemplate")
rawBox:SetWidth(360) rawBox:SetHeight(20)
rawBox:SetPoint("TOPLEFT", tools, "TOPLEFT", 96, toolY)
rawBox:SetAutoFocus(false)
rawBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
rawBox:SetScript("OnEnterPressed", function()
  local t = this:GetText()
  if t and t ~= "" then msg(Cmd(t)) this:SetText("") end
end)
Label(tools, L("Any command", "任意命令"), "GameFontNormalSmall", "RIGHT", rawBox, "LEFT", -8, 0)
Label(tools, L("(leading dot optional, Enter sends)", "(开头的点可省，回车发送)"), "GameFontDisableSmall",
      "TOPLEFT", rawBox, "BOTTOMLEFT", 0, -2)

-- ------------------------------------------------------------ list logic ---

local function BaseList()
  -- With an empty search box, show favourites first, then recent picks.
  local res, seen = {}, {}
  local function add(idx)
    if idx and not seen[idx] then seen[idx] = true table.insert(res, idx) end
  end
  if view.mode == "tele" then
    BuildTele()
    for i = 1, table.getn(db.favTele) do add(teleByName[string.lower(db.favTele[i])]) end
    if not view.fav then
      for i = 1, table.getn(db.recentTele) do add(teleByName[string.lower(db.recentTele[i])]) end
    end
  else
    if table.getn(db.favItem) == 0 and table.getn(db.recentItem) == 0 then return res end
    BuildItems()   -- 17k lowercase copies, so only pay for it when there is something to show
    for i = 1, table.getn(db.favItem) do add(itemById[db.favItem[i]]) end
    if not view.fav then
      for i = 1, table.getn(db.recentItem) do add(itemById[db.recentItem[i]]) end
    end
  end
  return res
end

local function IsFav(d)
  if d.kind == "tele" then return ListFind(db.favTele, d.name) ~= nil end
  return ListFind(db.favItem, d.id) ~= nil
end

function Refresh()
  local n = table.getn(view.results)
  local maxOff = n - ROWS
  if maxOff < 0 then maxOff = 0 end
  if view.offset > maxOff then view.offset = maxOff end
  if view.offset < 0 then view.offset = 0 end

  for i = 1, ROWS do
    local b, d = rows[i], RowData(i)
    if d then
      local star = IsFav(d) and "|cffffd100*|r " or ""
      if d.kind == "tele" then
        b.text:SetText(star .. (d.show or d.name))
        b.text:SetTextColor(1, 1, 1)
        b.info:SetText(MapLabel(d.map))
      else
        local c = QCOLOR[d.q] or QCOLOR[1]
        b.text:SetText(star .. d.name)
        b.text:SetTextColor(c[1], c[2], c[3])
        b.info:SetText(d.id)
      end
      b:Show()
    else
      b:Hide()
    end
  end

  local shown = n - view.offset
  if shown > ROWS then shown = ROWS end
  if n == 0 then
    if view.mode == "tele" then
      ui.status:SetText(L("no match -- type part of a place name, e.g. iron, orgri, gurub",
                          "没有匹配 -- 输入地名片段，如 iron、orgri、gurub"))
    else
      ui.status:SetText(L("no match -- type part of an item name, or an item id",
                          "没有匹配 -- 输入物品名（中英文都行）或物品 id"))
    end
  else
    ui.status:SetText(n .. L(" match(es), showing ", " 个匹配，显示第 ") .. (view.offset + 1) .. "-" ..
      (view.offset + shown) .. L("   (mouse wheel scrolls)", " 个   (滚轮翻页)"))
  end
end

function RunSearch()
  local q = string.lower(ui.search:GetText() or "")
  view.offset = 0
  if q == "" then
    view.results = BaseList()
    Refresh()
    return
  end
  if view.mode == "tele" then
    BuildTele()
    view.results = Search(teleLower, TELE_ALTS, q, MAX_HITS)
  else
    BuildItems()
    local id = tonumber(q)
    if id and itemById[id] then
      view.results = { itemById[id] }
    else
      view.results = Search(itemLower, itemZH, q, MAX_HITS)
    end
  end
  if view.fav then
    local keep = {}
    for i = 1, table.getn(view.results) do
      local idx = view.results[i]
      local isFav
      if view.mode == "tele" then isFav = ListFind(db.favTele, GMBox_Tele[idx][1])
      else isFav = ListFind(db.favItem, GMBox_ItemID[idx]) end
      if isFav then table.insert(keep, idx) end
    end
    view.results = keep
  end
  Refresh()
end

function SetTab(i)
  db.tab = i
  for t = 1, 3 do
    if t == i then ui.tabs[t]:Disable() else ui.tabs[t]:Enable() end
  end
  if i == 3 then
    panel:Hide()
    tools:Show()
    return
  end
  tools:Hide()
  panel:Show()
  view.mode = (i == 1) and "tele" or "item"
  local item = (i == 2)
  if item then
    ui.countLabel:Show() ui.count:Show()
    for k = 1, 4 do ui.quick[k]:Show() end
    ui.gox:Hide() ui.goxLabel:Hide() ui.recall:Hide() ui.gps:Hide()
    ui.count:SetText(db.count)
  else
    ui.countLabel:Hide() ui.count:Hide()
    for k = 1, 4 do ui.quick[k]:Hide() end
    ui.gox:Show() ui.goxLabel:Show() ui.recall:Show() ui.gps:Show()
  end
  RunSearch()
end

local function Toggle(tab, query)
  if tab then db.tab = tab end
  if not f:IsVisible() then f:Show() elseif not query and not tab then f:Hide() return end
  SetTab(db.tab)
  if query then
    ui.search:SetText(query)
    ui.search:SetFocus()
  end
  RunSearch()
end

-- --------------------------------------------------------------- bindings --

BINDING_HEADER_GMBOX = "GM Box"
BINDING_NAME_GMBOX_TOGGLE = "Toggle GM Box"
function GMBox_Toggle() Toggle() end

-- ----------------------------------------------------------------- slash ---

local function Help()
  if ZH then
    msg("命令:")
    msg("  /gm            开关窗口")
    msg("  /gt <文字>     传送: 唯一匹配直接过去，多个就开列表")
    msg("  /gi <文字|id> [数量]   物品: 同上，唯一匹配直接进包（中英文名都能搜）")
    msg("列表里: 左键执行，右键收藏，")
    msg("对地点 shift+左键 = 用 .go xyz 而不是 .tele")
  else
    msg("commands:")
    msg("  /gm            open or close the window")
    msg("  /gt <text>     teleport: one match goes instantly, otherwise the list opens")
    msg("  /gi <text|id> [count]   item: same idea, adds it straight to your bags")
    msg("in the list: left click = do it, right click = favourite,")
    msg("shift+click on a place = .go xyz instead of .tele")
  end
end

SLASH_GMBOX1 = "/gm"
SLASH_GMBOX2 = "/gmbox"
SlashCmdList["GMBOX"] = function(a)
  a = a or ""
  if a == "help" or a == "?" then Help() return end
  if a ~= "" then Toggle(nil, a) else Toggle() end
end

SLASH_GMBOXTELE1 = "/gt"
SlashCmdList["GMBOXTELE"] = function(a)
  a = string.gsub(a or "", "^%s+", "")
  if a == "" then Toggle(1) return end
  BuildTele()
  local q = string.lower(a)
  if teleByName[q] then
    local i = teleByName[q]
    DoTele({ kind = "tele", name = GMBox_Tele[i][1], map = GMBox_Tele[i][2],
             x = GMBox_Tele[i][3], y = GMBox_Tele[i][4], z = GMBox_Tele[i][5] })
    return
  end
  local res = Search(teleLower, TELE_ALTS, q, MAX_HITS)
  if table.getn(res) == 1 then
    local i = res[1]
    DoTele({ kind = "tele", name = GMBox_Tele[i][1], show = TeleDisplay(i), map = GMBox_Tele[i][2],
             x = GMBox_Tele[i][3], y = GMBox_Tele[i][4], z = GMBox_Tele[i][5] })
    return
  end
  if table.getn(res) == 0 then msg(L("no place matches '", "没有地点匹配 '") .. a .. "'") return end
  Toggle(1, a)
end

SLASH_GMBOXITEM1 = "/gi"
SlashCmdList["GMBOXITEM"] = function(a)
  a = string.gsub(a or "", "^%s+", "")
  if a == "" then Toggle(2) return end
  BuildItems()
  -- trailing number is a count, unless the whole argument is a number (= item id)
  local count, name = nil, a
  if not tonumber(a) then
    local at, _, digits = string.find(a, "%s+(%d+)$")
    if at then
      count = tonumber(digits)
      name = string.sub(a, 1, at - 1)
    end
  end
  local id = tonumber(name)
  if id then
    local i = itemById[id]
    if not i then msg(L("no item with id ", "没有这个 id 的物品: ") .. id) return end
    DoItem({ kind = "item", id = GMBox_ItemID[i], name = GMBox_ItemName[i] }, count)
    return
  end
  local res = Search(itemLower, itemZH, string.lower(name), MAX_HITS)
  if table.getn(res) == 0 then msg(L("no item matches '", "没有物品匹配 '") .. name .. "'") return end
  local top = res[1]
  local exact = string.lower(GMBox_ItemName[top]) == string.lower(name)
             or (GMBox_ItemNameZH and GMBox_ItemNameZH[top] == name)
  if table.getn(res) == 1 or exact then
    local i = res[1]
    DoItem({ kind = "item", id = GMBox_ItemID[i], name = GMBox_ItemName[i] }, count)
    return
  end
  if count then db.count = count end
  Toggle(2, name)
end

-- ----------------------------------------------------------------- events --

local ev = CreateFrame("Frame")
ev:RegisterEvent("VARIABLES_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
  if event == "VARIABLES_LOADED" then
    InitDB()
    ui.count:SetText(db.count)
    SetTab(db.tab)
    f:Hide()
  elseif event == "PLAYER_LOGIN" then
    if ZH then
      msg("就绪 -- " .. table.getn(GMBox_Tele) .. " 个地点，" ..
          table.getn(GMBox_ItemID) .. " 件物品。/gm 打开，/gm help 看用法。")
    else
      msg("ready -- " .. table.getn(GMBox_Tele) .. " places, " ..
          table.getn(GMBox_ItemID) .. " items. /gm to open, /gm help for the rest.")
    end
  end
end)

InitDB()   -- so the UI is usable even before VARIABLES_LOADED fires
