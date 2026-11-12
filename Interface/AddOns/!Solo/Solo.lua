--[[--------------------------------------------------------------------------
Solo -- single-player defaults for this realm (WoW 1.12.1, Lua 5.0).

The realm is one player and their bots, so:

  * chat is a message log: system, loot, experience, quests and what NPCs
    say stay; say, yell, whispers, party/guild talk and channels go. (The
    server refuses every channel join anyway: Channel.Disable.)
  * pfUI and pfQuest skip their first-run wizards and start from settings
    made for travelling and questing alone (the "travel preset" of the old
    local realm), on every character, every login.

The folder starts with "!" so it loads before every other addon: its
ADDON_LOADED handler then runs before pfUI's and pfQuest's own, at the moment
their per-character saved variables are loaded but not read yet.
----------------------------------------------------------------------------]]

-- ---------------------------------------------------------------- helpers --

local function Copy(t)
  if type(t) ~= "table" then return t end
  local out = {}
  for k, v in pairs(t) do out[k] = Copy(v) end
  return out
end

-- path = { "a", "b", "c" } sets t.a.b.c = value, creating tables on the way.
local function Set(t, path, value)
  local node = t
  for i = 1, table.getn(path) - 1 do
    local key = path[i]
    if type(node[key]) ~= "table" then node[key] = {} end
    node = node[key]
  end
  node[path[table.getn(path)]] = value
end

local function IsEmpty(t)
  return type(t) ~= "table" or next(t) == nil
end

-- -------------------------------------------------------------------- pfUI --

-- Set on every login, over whatever the character had.
local PFUI = {
  -- World map: show zones not visited yet and the exploration points.
  { { "appearance", "worldmap", "mapreveal" }, "1" },
  { { "appearance", "worldmap", "mapexploration" }, "1" },
  -- Minimap: bigger, with the zone name and coordinates always on.
  { { "appearance", "minimap", "size" }, "170" },
  { { "appearance", "minimap", "zonetext" }, "on" },
  { { "appearance", "minimap", "coordstext" }, "on" },
  { { "appearance", "border", "shadow" }, "1" },
  -- Quest levels in the quest log.
  { { "questlog", "showQuestLevels" }, "1" },
  -- Info panels: no guild or friends to count.
  { { "panel", "left", "left" }, "exp" },
  { { "panel", "left", "right" }, "bagspace" },
  -- One chat window (the message log); the right one stays off.
  { { "chat", "right", "enable" }, "0" },
  -- A travel journal: pfUI takes a screenshot on level up and on epic loot,
  -- without the interface and with the zone and time written on it.
  { { "screenshot", "levelup" }, "1" },
  { { "screenshot", "loot" }, "4" },
  { { "screenshot", "caption" }, "1" },
  { { "screenshot", "hideui" }, "1" },
  -- Grey items sell themselves at a vendor.
  { { "global", "autosell" }, "1" },
  -- Modules with nothing to do alone, or that only serve other players.
  { { "disabled", "raid" }, "1" },                -- a five-player party at most
  { { "disabled", "targettargettarget" }, "1" },
  { { "disabled", "updatenotify" }, "1" },        -- asks other players' clients
  { { "disabled", "whisperproxy" }, "1" },        -- forwards whispers
  { { "disabled", "socialmod" }, "1" },           -- friends and guild list tweaks
  { { "disabled", "chatcopy" }, "1" },            -- copy chat lines
  -- Bagshui is the bag addon; pfUI's own bags would open a second bank
  -- window (Bagshui asks for this on every login otherwise).
  { { "disabled", "bags" }, "1" },
}

-- The steps of pfUI's first-run wizard. Its profile step would copy the
-- Modern profile, which is what a new character gets here; the chat steps
-- would set up channels this realm does not have.
local PFUI_WIZARD = { "init", "profile", "cvars", "chat_right", "chat_position", "chat_channels", "finalize" }

local function PreparePfUI()
  if type(pfUI_config) ~= "table" then pfUI_config = {} end
  if type(pfUI_init) ~= "table" then pfUI_init = {} end

  if IsEmpty(pfUI_config) and pfUI_profiles and pfUI_profiles["Modern"] then
    pfUI_config = Copy(pfUI_profiles["Modern"])
  end
  for i = 1, table.getn(PFUI_WIZARD) do
    pfUI_init[PFUI_WIZARD[i]] = true
  end
  for i = 1, table.getn(PFUI) do
    Set(pfUI_config, PFUI[i][1], PFUI[i][2])
  end
end

-- ----------------------------------------------------------------- pfQuest --

-- Only for a character that has not been through pfQuest's welcome screen:
-- its "combined" mode (spawn points and icons on the world map, spawn points
-- on the minimap) with the arrow on. pfQuest fills in the rest itself.
local function PreparePfQuest()
  if type(pfQuest_config) ~= "table" then pfQuest_config = {} end
  if pfQuest_config["welcome"] == "1" then return end
  pfQuest_config["showspawn"] = "1"
  pfQuest_config["showspawnmini"] = "1"
  pfQuest_config["showcluster"] = "1"
  pfQuest_config["showclustermini"] = "0"
  pfQuest_config["arrow"] = "1"
  pfQuest_config["welcome"] = "1"
end

-- -------------------------------------------------------------------- chat --

-- Message groups the chat windows stop showing: other people talking.
-- What stays: system and error messages, loot, money, experience,
-- reputation, skills, quest and NPC speech, combat log.
local CHATTER = {
  "SAY", "YELL", "EMOTE", "WHISPER", "PARTY", "RAID", "RAID_LEADER", "RAID_WARNING",
  "GUILD", "OFFICER", "AFK", "DND", "IGNORED", "CHANNEL",
}

local function QuietChat()
  for i = 1, NUM_CHAT_WINDOWS or 7 do
    local frame = getglobal("ChatFrame" .. i)
    if frame then
      for k = 1, table.getn(CHATTER) do
        ChatFrame_RemoveMessageGroup(frame, CHATTER[k])
      end
    end
  end
end

-- ------------------------------------------------------------------ events --

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" then
    if arg1 == "pfUI" then
      PreparePfUI()
    elseif arg1 == "pfQuest" then
      PreparePfQuest()
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    QuietChat()
  end
end)
