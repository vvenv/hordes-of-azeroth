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

local VERSION = "2.0.0"

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
  if type(db.mmAngle)    ~= "number" then db.mmAngle = 200 end
  if db.version == nil then
    -- 1.x had three tabs, Tools third; Tools is fourth since Dungeons came in.
    if db.tab == 3 then db.tab = 4 end
    db.version = 2
  end
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

-- The packed per-item columns (see Data_Items.lua): one char = 0..92, two
-- chars = 0..8648, from an alphabet of ASCII 32..126 without " and \.
local function Dec1(str, i)
  local b = string.byte(str, i)
  if not b then return 0 end
  if b > 92 then b = b - 1 end
  if b > 34 then b = b - 1 end
  return b - 32
end
local function Dec2(str, i) return Dec1(str, 2 * i - 1) * 93 + Dec1(str, 2 * i) end
local function HasBit(mask, bit) return math.mod(math.floor(mask / bit), 2) == 1 end

local CLASS_ID = { WARRIOR = 1, PALADIN = 2, HUNTER = 3, ROGUE = 4, PRIEST = 5,
                   SHAMAN = 7, MAGE = 8, WARLOCK = 9, DRUID = 11 }
local RACE_ID = { Human = 1, Orc = 2, Dwarf = 3, NightElf = 4, Scourge = 5,
                  Tauren = 6, Gnome = 7, Troll = 8 }
local ARMOR_RANK = { a = 1, b = 2, c = 3, d = 4 }   -- cloth, leather, mail, plate

-- "Can my character use this": class and race masks, required level, the
-- heaviest armour the class wears at this level, and shields.
local me = {}
local function RefreshMe()
  local _, cls = UnitClass("player")
  local _, race = UnitRace("player")
  me.level = UnitLevel("player") or 1
  me.classBit = math.pow(2, (CLASS_ID[cls or ""] or 1) - 1)
  me.raceBit = math.pow(2, (RACE_ID[race or ""] or 1) - 1)
  local heavy = me.level >= 40
  if cls == "WARRIOR" or cls == "PALADIN" then me.armor = heavy and 4 or 3
  elseif cls == "HUNTER" or cls == "SHAMAN" then me.armor = heavy and 3 or 2
  elseif cls == "ROGUE" or cls == "DRUID" then me.armor = 2
  else me.armor = 1 end
  me.shield = (cls == "WARRIOR" or cls == "PALADIN" or cls == "SHAMAN")
end

local function ItemUsable(i)
  if not GMBox_ItemReqLvl then return true end
  if Dec1(GMBox_ItemReqLvl, i) > me.level then return false end
  if not HasBit(Dec2(GMBox_ItemClass, i), me.classBit) then return false end
  if not HasBit(Dec2(GMBox_ItemRace, i), me.raceBit) then return false end
  local kind = string.sub(GMBox_ItemKind, i, i)
  if kind == "s" then return me.shield end
  local rank = ARMOR_RANK[kind]
  if rank and rank > me.armor then return false end
  return true
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
f:SetWidth(600) f:SetHeight(440)
f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
Backdrop(f)
f:SetMovable(true) f:EnableMouse(true) f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", function() this:StartMoving() end)
f:SetScript("OnDragStop", function()
  this:StopMovingOrSizing()
  local point, _, relPoint, x, y = this:GetPoint()
  db.point = { point, relPoint, x, y }
end)
if f.SetClampedToScreen then f:SetClampedToScreen(true) end
f:Hide()
tinsert(UISpecialFrames, "GMBoxFrame")   -- Escape closes it

Label(f, L("GM Box ", "GM 工具箱 ") .. VERSION, "GameFontNormal", "TOP", f, "TOP", 0, -14)

local close = CreateFrame("Button", "GMBoxClose", f, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)

ui.tabs = {}
local TABS = { L("Teleport", "传送"), L("Items", "物品"), L("Dungeons", "副本"), L("Tools", "工具") }
local NTABS = 4
for i = 1, NTABS do
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

ui.usable = CreateFrame("CheckButton", "GMBoxUsableCheck", panel, "UICheckButtonTemplate")
ui.usable:SetWidth(20) ui.usable:SetHeight(20)
ui.usable:SetPoint("LEFT", ui.favOnly, "RIGHT", 34, 0)
ui.usable:SetScript("OnClick", function() db.usable = this:GetChecked() and true or false RunSearch() end)
ui.usableLabel = Label(panel, L("usable", "我能用"), "GameFontNormalSmall", "LEFT", ui.usable, "RIGHT", 0, 0)

for i = 1, ROWS do
  local b = CreateFrame("Button", "GMBoxRow" .. i, panel)
  b:SetWidth(558) b:SetHeight(ROW_H)
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
  b.text:SetWidth(440)
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

-- ---------------------------------------------------------- dungeons tab ---
-- Five-player dungeons with the spot just inside their entrance (the
-- areatrigger_teleport targets), so one click lands the party inside. The
-- server fills the party with bots three seconds after a player enters a
-- five-player dungeon (DungeonBotMgr), and `.bots` sets the player's role.

local DUNGEONS = {
  -- { english, chinese, min, max, map, x, y, z, o, note }
  { "Ragefire Chasm",             "怒焰裂谷",           13, 18, 389,     0.8,    -8.2,  -15.5, 4.71 },
  { "Wailing Caverns",            "哀嚎洞穴",           17, 24,  43,  -158.4,   131.6,  -74.3, 5.85 },
  { "The Deadmines",              "死亡矿井",           17, 26,  36,   -14.6,  -385.5,   62.5, 1.57 },
  { "Shadowfang Keep",            "影牙城堡",           22, 30,  33,  -228.2,  2111.4,   76.9, 1.22 },
  { "Blackfathom Deeps",          "黑暗深渊",           24, 32,  48,  -150.2,   106.6,  -39.8, 4.45 },
  { "The Stockade",               "暴风城监狱",         24, 32,  34,    49.0,     0.5,  -16.4, 6.28 },
  { "Scarlet Monastery: Graveyard", "血色修道院：墓地",   26, 36, 189,  1687.3,  1050.1,   18.7, 1.57 },
  { "Gnomeregan",                 "诺莫瑞根",           29, 38,  90,  -329.1,    -3.2, -152.9, 2.97 },
  { "Razorfen Kraul",             "剃刀沼泽",           29, 38,  47,  1942.3,  1544.2,   83.3, 1.31 },
  { "Scarlet Monastery: Library", "血色修道院：图书馆", 29, 39, 189,   253.7,  -206.6,   18.7, 4.71 },
  { "Scarlet Monastery: Armory",  "血色修道院：军械库", 32, 42, 189,  1608.1,  -318.9,   18.7, 4.71 },
  { "Scarlet Monastery: Cathedral", "血色修道院：大教堂", 35, 45, 189,   853.2,  1319.2,   18.7, 1.57 },
  { "Razorfen Downs",             "剃刀高地",           37, 46, 129,  2593.7,  1111.2,   51.0, 4.71 },
  { "Uldaman",                    "奥达曼",             41, 51,  70,  -228.9,    46.1,  -46.0, 1.57 },
  { "Zul'Farrak",                 "祖尔法拉克",         42, 54, 209,  1212.7,   842.0,    8.9, 6.28 },
  { "Maraudon: Orange",           "玛拉顿：橙色入口",   46, 55, 349,  1016.8,  -458.5,  -43.5, 6.28 },
  { "Maraudon: Purple",           "玛拉顿：紫色入口",   46, 55, 349,   755.1,  -617.7,  -32.9, 1.57 },
  { "Sunken Temple",              "沉没的神庙",         50, 60, 109,  -315.9,   100.2, -131.8, 3.14 },
  { "Blackrock Depths",           "黑石深渊",           52, 60, 230,   456.9,    34.1,  -68.1, 4.71 },
  { "Lower Blackrock Spire",      "黑石塔下层",         55, 60, 229,    78.4,  -226.8,   49.8, 4.71 },
  { "Dire Maul: East",            "厄运之槌：东",       55, 60, 429,  -203.2,  -323.0,   -2.7, 4.71 },
  { "Dire Maul: West",            "厄运之槌：西",       57, 60, 429,   -65.7,   159.6,   -3.5, 2.36 },
  { "Dire Maul: North",           "厄运之槌：北",       57, 60, 429,   254.9,   -19.5,   -2.6, 5.50 },
  { "Scholomance",                "通灵学院",           58, 60, 289,   190.8,   126.3,  137.2, 6.28 },
  { "Stratholme: Main Gate",      "斯坦索姆：正门",     58, 60, 329,  3392.9, -3395.0,  143.1, 1.57 },
  { "Stratholme: Service Gate",   "斯坦索姆：后门",     58, 60, 329,  3590.9, -3643.2,  138.5, 5.50 },
}

-- What the server last said about this character's bots (`.bots status`).
local bots = { role = "auto", playing = nil, auto = true, known = false }

local ROLES = {
  { key = "auto",   en = "Auto",   zh = "自动" },
  { key = "tank",   en = "Tank",   zh = "坦克" },
  { key = "healer", en = "Healer", zh = "治疗" },
  { key = "dps",    en = "DPS",    zh = "输出" },
}
local ROLE_ZH = { tank = "坦克", healer = "治疗", ["melee dps"] = "近战输出",
                  ["ranged dps"] = "远程输出", auto = "自动" }

local function RoleText(r)
  if not r then return "?" end
  if ZH then return ROLE_ZH[r] or r end
  return r
end

-- Quest-log colours by how the dungeon's range sits against my level.
local function DungeonColor(d)
  local lvl = UnitLevel("player") or 1
  if lvl < d[3] - 2 then return 1, 0.1, 0.1 end        -- red: too low
  if lvl < d[3] then return 1, 0.5, 0.25 end           -- orange: a stretch
  if lvl <= d[4] - 3 then return 1, 0.82, 0 end        -- yellow: right
  if lvl <= d[4] + 2 then return 0.25, 0.75, 0.25 end  -- green: easy
  return 0.5, 0.5, 0.5                                 -- grey: trivial
end

local dung = CreateFrame("Frame", nil, f)
dung:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -62)
dung:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 16)
dung:Hide()

local dui = { roleButtons = {}, rows = {}, offset = 0 }
local DROWS = 13

Label(dung, L("I play", "我的职责"), "GameFontNormalSmall", "TOPLEFT", dung, "TOPLEFT", 2, -6)
for i = 1, table.getn(ROLES) do
  local r = ROLES[i]
  local b = Button(dung, 62, 20, L(r.en, r.zh), "TOPLEFT", dung, "TOPLEFT", 70 + (i - 1) * 66, -2)
  b.role = r.key
  b:SetScript("OnClick", function() Cmd(".bots role " .. this.role) end)
  b:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOM")
    if this.role == "auto" then
      GameTooltip:AddLine(L("Guess from class, talents and shield", "按职业、天赋和是否带盾自动判断"))
    else
      GameTooltip:AddLine(L("Bots fill the other roles around you", "机器人会补齐你之外的职责"))
    end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  dui.roleButtons[i] = b
end

dui.auto = CreateFrame("CheckButton", "GMBoxBotsAuto", dung, "UICheckButtonTemplate")
dui.auto:SetWidth(22) dui.auto:SetHeight(22)
dui.auto:SetPoint("TOPLEFT", dung, "TOPLEFT", 340, -1)
dui.auto:SetScript("OnClick", function()
  Cmd(".bots auto " .. (this:GetChecked() and "on" or "off"))
end)
Label(dung, L("Bots join in dungeons", "进副本自动补机器人"), "GameFontNormalSmall", "LEFT", dui.auto, "RIGHT", 0, 0)

dui.status = Label(dung, "", "GameFontHighlightSmall", "TOPLEFT", dung, "TOPLEFT", 2, -32)
dui.fill = Button(dung, 96, 20, L("Fill party", "补满队伍"), "TOPRIGHT", dung, "TOPRIGHT", -104, -28)
dui.fill:SetScript("OnClick", function() Cmd(".bots fill") end)
dui.dismiss = Button(dung, 96, 20, L("Dismiss bots", "解散机器人"), "TOPRIGHT", dung, "TOPRIGHT", -2, -28)
dui.dismiss:SetScript("OnClick", function() Cmd(".bots dismiss") end)

Label(dung, L("Dungeon (click to go inside)", "副本（点击直接传送进去）"), "GameFontNormalSmall",
      "TOPLEFT", dung, "TOPLEFT", 2, -58)
Label(dung, L("Level", "等级"), "GameFontNormalSmall", "TOPRIGHT", dung, "TOPRIGHT", -8, -58)

local function DungeonRefresh()
  local n = table.getn(DUNGEONS)
  if dui.offset > n - DROWS then dui.offset = n - DROWS end
  if dui.offset < 0 then dui.offset = 0 end
  for i = 1, DROWS do
    local b, d = dui.rows[i], DUNGEONS[dui.offset + i]
    if d then
      b.d = d
      b.text:SetText(ZH and d[2] or d[1])
      b.text:SetTextColor(DungeonColor(d))
      b.info:SetText(d[3] .. "-" .. d[4])
      b:Show()
    else
      b:Hide()
    end
  end
  for i = 1, table.getn(ROLES) do
    if ROLES[i].key == bots.role then dui.roleButtons[i]:Disable() else dui.roleButtons[i]:Enable() end
  end
  dui.auto:SetChecked(bots.auto and 1 or nil)
  if bots.known then
    local guessed = (bots.role == "auto") and L(" (guessed)", "（自动判断）") or ""
    dui.status:SetText(L("You play ", "你是") .. RoleText(bots.playing) .. guessed ..
      L(". Bots take the other roles.", "，机器人会补齐其余职责。"))
  else
    dui.status:SetText(L("Asking the server...", "正在向服务器查询..."))
  end
end

local function DungeonGo(d)
  -- The spot just inside the entrance; the server adds the bots there.
  Cmd(string.format(".go xyzo %.1f %.1f %.1f %.2f %d", d[6], d[7], d[8], d[9], d[5]))
  msg("-> " .. (ZH and d[2] or d[1]))
end

for i = 1, DROWS do
  local b = CreateFrame("Button", "GMBoxDungeonRow" .. i, dung)
  b:SetWidth(558) b:SetHeight(ROW_H)
  if i == 1 then b:SetPoint("TOPLEFT", dung, "TOPLEFT", 2, -74)
  else b:SetPoint("TOPLEFT", dui.rows[i - 1], "BOTTOMLEFT", 0, -1) end
  b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  b.text = b:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  b.text:SetPoint("LEFT", b, "LEFT", 4, 0)
  b.text:SetJustifyH("LEFT")
  b.text:SetWidth(440)
  b.info = b:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  b.info:SetPoint("RIGHT", b, "RIGHT", -4, 0)
  b.info:SetJustifyH("RIGHT")
  b:SetScript("OnClick", function() if this.d then DungeonGo(this.d) end end)
  b:SetScript("OnEnter", function()
    local d = this.d
    if not d then return end
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:AddLine(ZH and d[2] or d[1])
    if ZH then GameTooltip:AddLine(d[1], 0.8, 0.8, 0.8) end
    GameTooltip:AddLine(L("Recommended level ", "推荐等级 ") .. d[3] .. "-" .. d[4], 0.8, 0.8, 0.8)
    GameTooltip:AddLine(L("Click: teleport inside. Bots join three seconds later.",
                          "点击传送进副本，3 秒后机器人自动入队。"), 0.4, 0.8, 1)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  dui.rows[i] = b
end

dung:EnableMouseWheel(true)
dung:SetScript("OnMouseWheel", function()
  dui.offset = dui.offset + ((arg1 > 0) and -3 or 3)
  DungeonRefresh()
end)

-- Orders for the bots in the party (vmangos .partybot commands).
local BOTCMDS = {
  { L("Come to me", "到我身边"), ".partybot cometome",
    L("Every bot runs to you", "所有机器人跑到你身边") },
  { L("Attack target", "集火目标"), ".partybot attackstart",
    L("Every bot attacks your target", "所有机器人攻击你的目标") },
  { L("Stop", "停手"), ".partybot attackstop",
    L("Every bot stops attacking", "所有机器人停止攻击") },
  { L("Tank pulls", "坦克拉怪"), ".partybot pull",
    L("The tank bot pulls your target; damage bots wait 10 s", "坦克机器人去拉你的目标，输出机器人等 10 秒再动手") },
  { L("Hold", "原地待命"), ".partybot pause",
    L("Bots stop and wait (target one bot to hold only it)", "机器人原地待命（选中某个机器人则只对它）") },
  { L("Resume", "继续"), ".partybot unpause",
    L("Bots act again", "机器人恢复行动") },
}
Label(dung, L("Orders", "指挥"), "GameFontNormalSmall", "BOTTOMLEFT", dung, "BOTTOMLEFT", 2, 10)
for i = 1, table.getn(BOTCMDS) do
  local c = BOTCMDS[i]
  local b = Button(dung, 80, 20, c[1], "BOTTOMLEFT", dung, "BOTTOMLEFT", 44 + (i - 1) * 84, 4)
  b.cmd, b.tip = c[2], c[3]
  b:SetScript("OnClick", function() Cmd(this.cmd) end)
  b:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_TOP")
    GameTooltip:AddLine(this.tip)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- `.bots` answers with a machine line first: "[bots] role=tank playing=tank auto=1".
-- It feeds the panel and never reaches the chat window.
local function ParseBotsLine(text)
  local _, _, role, playing, auto = string.find(text, "^%[bots%] role=(.-) playing=(.-) auto=(%d)")
  if not role then return false end
  if role == "melee dps" or role == "ranged dps" then role = "dps" end
  bots.role, bots.playing, bots.auto, bots.known = role, playing, auto == "1", true
  if dung:IsVisible() then DungeonRefresh() end
  return true
end

local origChatEvent = ChatFrame_OnEvent
function ChatFrame_OnEvent(event)
  if event == "CHAT_MSG_SYSTEM" and arg1 and string.find(arg1, "^%[bots%]") then return end
  return origChatEvent(event)
end

-- ------------------------------------------------------- minimap button ---

local mm = CreateFrame("Button", "GMBoxMinimapButton", Minimap)
mm:SetWidth(31) mm:SetHeight(31)
mm:SetFrameStrata("MEDIUM")
mm:SetFrameLevel(8)
mm:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
mm:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mm:RegisterForDrag("LeftButton")
local mmIcon = mm:CreateTexture(nil, "BACKGROUND")
mmIcon:SetTexture("Interface\\Icons\\Ability_Warrior_BattleShout")
mmIcon:SetWidth(20) mmIcon:SetHeight(20)
mmIcon:SetPoint("TOPLEFT", mm, "TOPLEFT", 7, -5)
local mmBorder = mm:CreateTexture(nil, "OVERLAY")
mmBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
mmBorder:SetWidth(53) mmBorder:SetHeight(53)
mmBorder:SetPoint("TOPLEFT", mm, "TOPLEFT", 0, 0)

local function PlaceMinimapButton()
  local a = math.rad(db and db.mmAngle or 200)
  mm:ClearAllPoints()
  mm:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(a), 80 * math.sin(a))
end

mm:SetScript("OnDragStart", function()
  this:SetScript("OnUpdate", function()
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    db.mmAngle = math.deg(math.atan2(py / scale - my, px / scale - mx))
    PlaceMinimapButton()
  end)
end)
mm:SetScript("OnDragStop", function() this:SetScript("OnUpdate", nil) end)
mm:SetScript("OnEnter", function()
  GameTooltip:SetOwner(this, "ANCHOR_LEFT")
  GameTooltip:AddLine("GM Box")
  GameTooltip:AddLine(L("Left click: open or close", "左键：打开/关闭"), 0.8, 0.8, 0.8)
  GameTooltip:AddLine(L("Right click: dungeons and bots", "右键：副本与机器人"), 0.8, 0.8, 0.8)
  GameTooltip:AddLine(L("Drag: move around the minimap", "拖动：沿小地图移动"), 0.8, 0.8, 0.8)
  GameTooltip:Show()
end)
mm:SetScript("OnLeave", function() GameTooltip:Hide() end)

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
      view.results = Search(itemLower, itemZH, q, db.usable and 20000 or MAX_HITS)
    end
  end
  if view.mode == "item" and db.usable then
    RefreshMe()
    local keep = {}
    for i = 1, table.getn(view.results) do
      local idx = view.results[i]
      if ItemUsable(idx) then
        table.insert(keep, idx)
        if table.getn(keep) >= MAX_HITS then break end
      end
    end
    view.results = keep
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
  if i < 1 or i > NTABS then i = 1 end
  db.tab = i
  for t = 1, NTABS do
    if t == i then ui.tabs[t]:Disable() else ui.tabs[t]:Enable() end
  end
  panel:Hide() tools:Hide() dung:Hide()
  if i == 4 then
    tools:Show()
    return
  end
  if i == 3 then
    dung:Show()
    DungeonRefresh()
    Cmd(".bots status quiet")
    return
  end
  panel:Show()
  view.mode = (i == 1) and "tele" or "item"
  local item = (i == 2)
  if item then
    ui.countLabel:Show() ui.count:Show()
    ui.usable:Show() ui.usableLabel:Show()
    ui.usable:SetChecked(db.usable and 1 or nil)
    for k = 1, 4 do ui.quick[k]:Show() end
    ui.gox:Hide() ui.goxLabel:Hide() ui.recall:Hide() ui.gps:Hide()
    ui.count:SetText(db.count)
  else
    ui.countLabel:Hide() ui.count:Hide()
    ui.usable:Hide() ui.usableLabel:Hide()
    for k = 1, 4 do ui.quick[k]:Hide() end
    ui.gox:Show() ui.goxLabel:Show() ui.recall:Show() ui.gps:Show()
  end
  RunSearch()
end

local function Toggle(tab, query)
  if tab then db.tab = tab end
  if not f:IsVisible() then f:Show() elseif not query and not tab then f:Hide() return end
  SetTab(db.tab)
  if db.tab > 2 then return end
  if query then
    ui.search:SetText(query)
    ui.search:SetFocus()
  end
  RunSearch()
end

-- --------------------------------------------------------------- bindings --

mm:SetScript("OnClick", function()
  if arg1 == "RightButton" then
    if f:IsVisible() and db.tab == 3 then f:Hide() else Toggle(3) end
  else
    Toggle()
  end
end)

BINDING_HEADER_GMBOX = "GM Box"
BINDING_NAME_GMBOX_TOGGLE = "Toggle GM Box"
function GMBox_Toggle() Toggle() end

-- ----------------------------------------------------------------- slash ---

local function Help()
  if ZH then
    msg("命令:")
    msg("  /gm            开关窗口（小地图上也有按钮）")
    msg("  /gd            副本与机器人队友")
    msg("  /gt <文字>     传送: 唯一匹配直接过去，多个就开列表")
    msg("  /gi <文字|id> [数量]   物品: 同上，唯一匹配直接进包（中英文名都能搜）")
    msg("列表里: 左键执行，右键收藏，")
    msg("对地点 shift+左键 = 用 .go xyz 而不是 .tele")
  else
    msg("commands:")
    msg("  /gm            open or close the window (or the minimap button)")
    msg("  /gd            dungeons and bot party members")
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
  if a == "dungeon" or a == "dungeons" or a == "bots" or a == "fb" then Toggle(3) return end
  if a ~= "" then Toggle(nil, a) else Toggle() end
end

SLASH_GMBOXDUNGEON1 = "/gd"
SlashCmdList["GMBOXDUNGEON"] = function() Toggle(3) end

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
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("CHAT_MSG_SYSTEM")
ev:SetScript("OnEvent", function()
  if event == "VARIABLES_LOADED" then
    InitDB()
    ui.count:SetText(db.count)
    if db.point then
      f:ClearAllPoints()
      f:SetPoint(db.point[1], UIParent, db.point[2], db.point[3], db.point[4])
    end
    PlaceMinimapButton()
    f:Hide()
  elseif event == "CHAT_MSG_SYSTEM" then
    ParseBotsLine(arg1 or "")
  elseif event == "PLAYER_ENTERING_WORLD" then
    if not bots.known then Cmd(".bots status quiet") end
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
