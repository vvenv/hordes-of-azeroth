-- GMBox faction database -- generated from Faction.dbc (54 reputations).
-- Do not edit by hand; regenerate with bin/gmbox-gen-faction.py.
-- Entry layout: { id, name, zhName, pinyin, group }. The id is what
-- '.modify rep <id> <value>' expects; only factions with a
-- reputationListID are here, because the rest refuse the command.
-- group: 1 Alliance capitals, 2 Horde capitals, 3 neutral hubs,
--        4 grindable, 5 battlegrounds, 6 hidden / internal.

GMBox_Faction = {}

local t, n = GMBox_Faction, 0
local function A(a) for i = 1, table.getn(a) do n = n + 1; t[n] = a[i] end end

A({{69,"Darnassus","达纳苏斯","dnss danasusi",1},{54,"Gnomeregan Exiles","诺莫瑞根流亡者","nmrglwz nuomoruigenliuwangzhe",1},{47,"Ironforge","铁炉堡","tlb tielubao",1},{72,"Stormwind","暴风城","bfc baofengcheng",1},{530,"Darkspear Trolls","暗矛巨魔","amjm anmaojumo",2},{76,"Orgrimmar","奥格瑞玛","agrm aogeruima",2},{81,"Thunder Bluff","雷霆崖","lty leitingya",2},{68,"Undercity","幽暗城","yac youancheng",2}})
A({{21,"Booty Bay","藏宝海湾","cbhw cangbaohaiwan",3},{577,"Everlook","永望镇","ywz yongwangzhen",3},{369,"Gadgetzan","加基森","jjs jiajisen",3},{470,"Ratchet","棘齿城","jcc jichicheng",3},{169,"Steamwheedle Cartel","热砂港","rsg reshagang",3},{529,"Argent Dawn","银色黎明","yslm yinseliming",4},{87,"Bloodsail Buccaneers","血帆海盗","xfhd xuefanhaidao",4},{910,"Brood of Nozdormu","诺兹多姆的子嗣","nzdmdzs nuoziduomudezisi",4}})
A({{574,"Caer Darrow","凯尔达隆","kedl kaierdalong",4},{609,"Cenarion Circle","塞纳里奥议会","snlayh sainaliaoyihui",4},{909,"Darkmoon Faire","暗月马戏团","aymxt anyuemaxituan",4},{92,"Gelkis Clan Centaur","吉尔吉斯半人马","jejsbrm jierjisibanrenma",4},{749,"Hydraxian Waterlords","海达希亚水元素","hdxysys haidaxiyashuiyuansu",4},{93,"Magram Clan Centaur","玛格拉姆半人马","mglmbrm magelamubanrenma",4},{789,"Moro'gai","莫洛加","mlj moluojia",4},{630,"Ravasaur Trainers","暴掠龙训练师","bllxls baolvelongxunlianshi",4}})
A({{349,"Ravenholdt","拉文霍德","lwhd lawenhuode",4},{629,"Shatterspear Trolls","断矛巨魔","dmjm duanmaojumo",4},{809,"Shen'dralar","辛德拉","xdl xindela",4},{70,"Syndicate","辛迪加","xdj xindijia",4},{59,"Thorium Brotherhood","瑟银兄弟会","syxdh seyinxiongdihui",4},{576,"Timbermaw Hold","木喉要塞","mhys muhouyaosai",4},{471,"Wildhammer Clan","蛮锤部族","mcbz manchuibuzu",4},{589,"Wintersaber Trainers","冬刃豹训练师","drbxls dongrenbaoxunlianshi",4}})
A({{270,"Zandalar Tribe","赞达拉部族","zdlbz zandalabuzu",4},{891,"Alliance Forces","联盟部队","lmbd lianmengbudui",5},{709,"Battleground Neutral","","",5},{729,"Frostwolf Clan","霜狼氏族","slsz shuanglangshizu",5},{892,"Horde Forces","部落军队","bljd buluojundui",5},{890,"Silverwing Sentinels","银翼要塞","yyys yinyiyaosai",5},{730,"Stormpike Guard","雷矛卫队","lmwd leimaoweidui",5},{510,"The Defilers","污染者","wrz wuranzhe",5}})
A({{509,"The League of Arathor","阿拉索联军","alslj alasuolianjun",5},{889,"Warsong Outriders","战歌氏族","zgsz zhangeshizu",5},{469,"Alliance","联盟","lm lianmeng",6},{46,"Blacksmithing - Armorsmithing","","",6},{570,"Blacksmithing - Axesmithing","","",6},{569,"Blacksmithing - Hammersmithing","","",6},{571,"Blacksmithing - Swordsmithing","","",6},{289,"Blacksmithing - Weaponsmithing","","",6}})
A({{551,"Engineering - Gnome","","",6},{550,"Engineering - Goblin","","",6},{67,"Horde","部落","bl buluo",6},{86,"Leatherworking - Dragonscale","","",6},{83,"Leatherworking - Elemental","","",6},{549,"Leatherworking - Tribal","","",6}})
