Bagshui:LoadComponent(function()

-- Simplified Chinese for Bagshui (this project's translation; keys missing
-- here fall back to enUS). The "Game Stuff" names and the Name/Tooltip
-- identifiers must match the zhCN 1.12 client's own text, so only those
-- whose client wording is certain are translated; the rest stay English.

BsLocalization:AddLocale("zhCN", {

-- ### Game Stuff ###

-- Player classes.
["Druid"] = "德鲁伊",
["Hunter"] = "猎人",
["Mage"] = "法师",
["Paladin"] = "圣骑士",
["Priest"] = "牧师",
["Rogue"] = "盗贼",
["Shaman"] = "萨满祭司",
["Warlock"] = "术士",
["Warrior"] = "战士",

-- Item classes and subclasses.
["Devices"] = "装置",
["Explosives"] = "爆炸物",
["Junk"] = "垃圾",
["Key"] = "钥匙",
["Miscellaneous"] = "其它",
["Parts"] = "零件",
["Quest"] = "任务",
["Trade Goods"] = "商品",

-- Skill types.
["Class Skills"] = "职业技能",
["Professions"] = "专业技能",
["Secondary Skills"] = "辅助技能",
["Weapon Skills"] = "武器技能",
["Languages"] = "语言",

-- Skills.
["Axes"] = "斧",
["Dual Wield"] = "双武器",
["Fishing"] = "钓鱼",
["Maces"] = "锤",
["Swords"] = "剑",
["Plate Mail"] = "板甲",
["Shield"] = "盾牌",

-- Professions that have their own bag types.
["Enchanting"] = "附魔",
["Herbalism"] = "草药学",


-- ### General ###

["AbandonChanges"] = "放弃修改",
["About"] = "关于",
["Actions"] = "操作",
["Add"] = "添加",
["AddSlashRemove"] = "添加/移除",
["Aliases"] = "别名",
["AltClick"] = "Alt+点击",
["AltRightClick"] = "Alt+右键",
["Ascending"] = "升序",
["Available"] = "可用",
["Background"] = "背景",
["Bag"] = "背包",
["Border"] = "边框",
["Bottom"] = "底部",
["Cancel"] = "取消",
["Catalog"] = "物品总览",
["Categories"] = "分类",
["Category"] = "分类",
["CharacterData"] = "角色数据",
["CategorySlashItem"] = "分类/物品",
["ClassCategory"] = "职业分类",
["Clear"] = "清除",
["Click"] = "点击",
["Close"] = "关闭",
["Color"] = "颜色",
["Column"] = "列",
["Copy"] = "复制",
["Create"] = "创建",
["Creation"] = "创建",
["Custom"] = "自定义",
["Default"] = "默认",
["Delete"] = "删除",
["Deletion"] = "删除",
["Descending"] = "降序",
["Details"] = "详情",
["Dialog"] = "对话框",
["Disable"] = "禁用",
["Duplicate"] = "复制一份",
["Edit"] = "编辑",
["Editing"] = "编辑",
["EmptyBagSlot"] = "空背包栏",
["Export"] = "导出",
["Full"] = "完整",
["Group"] = "组",
["Help"] = "帮助",
["Hidden"] = "已隐藏",
["Hide"] = "隐藏",
["HoldAlt"] = "按住 Alt",
["HoldControlAlt"] = "按住 Ctrl+Alt",
["Horizontal"] = "水平",
["Ignore"] = "忽略",
["Import"] = "导入",
["ImportSlashExport"] = "导入/导出",
["Info"] = "信息",
["Information"] = "信息",
["Inventory"] = "物品栏",
["Item"] = "物品",
["ItemProperties"] = "物品属性",
["KeepEditing"] = "继续编辑",
["Label"] = "标签",
["Left"] = "左",
["Location"] = "位置",
["Lock"] = "锁定",
["LogWindow"] = "日志窗口",
["Manage"] = "管理",
["Menu"] = "菜单",
["MoreInformation"] = "更多信息",
["Move"] = "移动",
["MoveDown"] = "下移",
["MoveUp"] = "上移",
["Name"] = "名称",
["New"] = "新",
["No"] = "否",
["NotNow"] = "以后再说",
["NoItemsAvailable"] = "（没有可用物品）",
["NoneAssigned"] = "（未分配）",
["NoneParenthesis"] = "（无）",
["NoRuleFunction"] = "（没有规则函数）",
["NoValue"] = "（无值）",
["Open"] = "打开",
["PleaseWait"] = "请稍候……",
["Profile"] = "配置",
["Prefix_Add"] = "添加%s",
["Prefix_Bag"] = "背包 %s",
["Prefix_Class"] = "职业%s",
["Prefix_ClickFor"] = "点击查看%s",
["Prefix_Default"] = "默认%s",
["Prefix_Edit"] = "编辑%s",
["Prefix_Manage"] = "管理%s",
["Prefix_Move"] = "移动%s",
["Prefix_New"] = "新建%s",
["Prefix_OpenMenuFor"] = "打开%s的菜单",
["Prefix_Remove"] = "移除%s",
["Prefix_Search"] = "搜索%s",
["Prefix_Sort"] = "整理%s",
["Prefix_Target"] = "目标%s",
["Prefix_Toggle"] = "开关%s",
["Prefix_Unnamed"] = "（未命名的%s）",
["Profiles"] = "配置",
["Quality"] = "品质",
["ReleaseAlt"] = "松开 Alt",
["Reload"] = "重新载入",
["Remove"] = "移除",
["Rename"] = "重命名",
["Replace"] = "替换",
["Report"] = "报告",
["Right"] = "右",
["RightClick"] = "右键",
["Row"] = "行",
["Save"] = "保存",
["Search"] = "搜索",
["Settings"] = "设置",
["Share"] = "分享",
["Show"] = "显示",
["SortOrder"] = "排序方式",
["SortOrders"] = "排序方式",
["Sorting"] = "排序",
["Stack"] = "合并",
["Suffix_Default"] = "%s " .. LIGHTYELLOW_FONT_COLOR_CODE .. " [默认]" .. FONT_COLOR_CODE_CLOSE,
["Suffix_EmptySlot"] = "%s 空格",
["Suffix_Menu"] = "%s菜单",
["Suffix_ReadOnly"] = "%s " .. LIGHTYELLOW_FONT_COLOR_CODE .. "[只读]" .. FONT_COLOR_CODE_CLOSE,
["Suffix_Reversed"] = "%s [反向]",
["Suffix_Sets"] = "%d 套",
["Symbol_Brackets"] = "[%s]",
["Symbol_Colon"] = "%s：",
["Symbol_Ellipsis"] = "%s…",
["Templates"] = "模板",
["Text"] = "文字",
["Toggle"] = "开关",
["Top"] = "顶部",
["Total"] = "总计",
["Undo"] = "撤销",
["Unknown"] = "未知",
["Unlock"] = "解锁",
["Unnamed"] = "（未命名）",
["Unstack"] = "展开",
["Used"] = "已用",
["UseDefault"] = "使用默认",
["Validate"] = "校验",
["Vertical"] = "垂直",
["VersionNumber"] = "版本 %s",
["Yes"] = "是",

-- Inventory types.
["Bags"] = "背包",
["Bank"] = "银行",
["Equipped"] = "已装备",
["Keyring"] = "钥匙链",

-- Abbreviations for tooltip use.
["Abbrev_Bags"] = "背包",
["Abbrev_Bank"] = "银行",
["Abbrev_Keyring"] = "钥匙",
["Abbrev_Equipped"] = "装备",

-- Slash command help message.
["Slash_Help"] = "%s 命令：",
["Slash_Help_Postscript"] = "在命令后加 Help 可以查看子命令列表。",

-- Key bindings.
["Binding_Resort"] = "全部整理",
["Binding_Restack"] = "全部合并堆叠",

-- Item properties.
["ItemPropFriendly_activeQuest"] = "当前任务物品",
["ItemPropFriendly_baseName"] = "基础名称",
["ItemPropFriendly_bagNum"] = "背包编号",
["ItemPropFriendly_bagType"] = "背包类型",
["ItemPropFriendly_bindsOnEquip"] = "装备后绑定",
["ItemPropFriendly_charges"] = "充能次数",
["ItemPropFriendly_count"] = "数量",
["ItemPropFriendly_equipLocation"] = "装备位置",
["ItemPropFriendly_equipLocationLocalized"] = "装备位置（本地化）",
["ItemPropFriendly_emptySlot"] = "空格",
["ItemPropFriendly_id"] = "物品 ID",
["ItemPropFriendly_itemLink"] = "物品链接",
["ItemPropFriendly_itemString"] = "物品字符串",
["ItemPropFriendly_locked"] = "已锁定",
["ItemPropFriendly_maxStackCount"] = "最大堆叠数",
["ItemPropFriendly_minLevel"] = "最低等级",
["ItemPropFriendly_name"] = "!!Name!!",
["ItemPropFriendly_periodicTable"] = "PeriodicTable",
["ItemPropFriendly_quality"] = "!!Quality!!",
["ItemPropFriendly_qualityLocalized"] = "品质（本地化）",
["ItemPropFriendly_readable"] = "可阅读",
["ItemPropFriendly_slotNum"] = "格子编号",
["ItemPropFriendly_soulbound"] = "灵魂绑定",
["ItemPropFriendly_stacks"] = "可堆叠",
["ItemPropFriendly_subtype"] = "子类型",
["ItemPropFriendly_SuffixName"] = "后缀名称",
["ItemPropFriendly_tooltip"] = "鼠标提示",
["ItemPropFriendly_type"] = "类型",
["ItemPropFriendly_uncategorized"] = "未分类",


-- ### Inventory UI ###

["Inventory_NoData"] = "离线物品栏数据不可用。",

-- Toolbar.
["Toolbar_Menu_TooltipTitle"] = "菜单",
["Toolbar_ExitEditMode"] = "退出编辑模式",
["Toolbar_Catalog_TooltipTitle"] = "物品总览（全账号）",
["Toolbar_Catalog_TooltipText"] = "查看和搜索本账号所有角色的物品。",
["Toolbar_Character_TooltipTitle"] = "角色",
["Toolbar_Character_TooltipText"] = "查看你其他角色的%s。",
["Toolbar_Hide_TooltipTitle"] = "不显示隐藏的物品",
["Toolbar_Show_TooltipTitle"] = "显示隐藏的物品",
["Toolbar_Show_TooltipText"] = "开关隐藏物品的显示。",
["Toolbar_Search_TooltipTitle"] = "搜索",
["Toolbar_Search_TooltipText"] = "筛选你的%s里的物品。" .. BS_NEWLINE .. "搜索时按 Shift+回车 打开物品总览。",
["Toolbar_Resort_TooltipTitle"] = "整理",
["Toolbar_Resort_TooltipText"] = "重新排序并分类。",
["Toolbar_Restack_TooltipTitle"] = "合并堆叠",
["Toolbar_Restack_TooltipText"] = "把可堆叠的物品合并到一起。",
["Toolbar_HighlightChanges_TooltipTitle"] = "高亮变化",
["Toolbar_HighlightChanges_TooltipText"] = "开关最近变化物品的高亮。" .. BS_NEWLINE .. GRAY_FONT_COLOR_CODE .. "Alt+点击把所有物品标记为未变化。",
["Toolbar_UnHighlightChanges_TooltipTitle"] = "不高亮变化",

-- Action Tooltips.
["Tooltip_Inventory_ToggleBagSlotHighlightLockHint"] = "%s以%s格子高亮。",
["Tooltip_Inventory_ToggleEmptySlotStacking"] = "%s以%s空格。",
["Tooltip_Inventory_TradeShortcut"] = "%s与%s交易。",

-- Edit Mode.
["EditMode"] = "编辑模式",
["EditMode_CategoryInGroup"] = "在当前结构中分配给了组“%s”。",
["EditMode_CategoryNotInGroup"] = "在当前结构中没有分配给任何组。",
["EditMode_Prompt_NewGroupName"] = "新组的标签（可选，建议填写）：",
["EditMode_Prompt_RenameGroup"] = "%s 的新标签：",
["EditMode_Prompt_DeleteGroup"] = "删除选中的组？!!Warning_NoUndo!!",
["EditMode_Tooltip_SelectNew"] = "选择新的%s。",

-- Main Menu.
["Menu_Main_EditMode_TooltipText"] = "修改当前结构（调整组的排列、分配分类等）。",
["Menu_Main_Settings_TooltipText"] = "打开设置菜单。",
["Menu_Main_ManageCategories_TooltipText"] = "打开分类管理器。",
["Menu_Main_ManageProfiles_TooltipText"] = "打开配置管理器。",
["Menu_Main_ManageSortOrders_TooltipText"] = "打开排序方式管理器。",
["Menu_Main_Toggle_TooltipText"] = "开关%s窗口。",

-- Settings Menu.
["Menu_Settings"] = "%s设置",
["Menu_Settings_About"] = "关于 Bagshui",
["Menu_Settings_Accessibility"] = "辅助功能",
["Menu_Settings_Advanced"] = "高级",
["Menu_Settings_Anchoring"] = "锚点",
["Menu_Settings_Behaviors"] = "行为",
["Menu_Settings_Badges"] = "物品标记",
["Menu_Settings_ChangeTiming"] = "库存变化计时",
["Menu_Settings_Colors"] = "颜色",
["Menu_Settings_ColorHistory_TooltipTitle"] = "取色历史",
["Menu_Settings_Commands"] = "命令",
["Menu_Settings_DefaultProfiles"] = "默认配置",
["Menu_Settings_Defaults"] = "默认值",
["Menu_Settings_Etcetera"] = "其他",
["Menu_Settings_General"] = "常规",
["Menu_Settings_GroupDefaults"] = "组默认值",
["Menu_Settings_Groups"] = "组",
["Menu_Settings_Hooks_Suffix"] = "接管%s",
["Menu_Settings_Integration"] = "插件整合",
["Menu_Settings_Interface"] = "界面",
["Menu_Settings_ItemSlots"] = "物品格",
["Menu_Settings_More"] = "更多",
["Menu_Settings_More_TooltipTitle"] = "更多设置",
["Menu_Settings_Overrides"] = "覆盖",
["Menu_Settings_Open"] = "!!Open!!",
["Menu_Settings_Options"] = "选项",
["Menu_Settings_Profile"] = "配置",
["Menu_Settings_Size"] = "尺寸",
["Menu_Settings_Tinting"] = "物品着色",
["Menu_Settings_Toolbar"] = "工具栏",
["Menu_Settings_Tooltips"] = "鼠标提示",
["Menu_Settings_ToggleBagsWith"] = "跟随开关背包",
["Menu_Settings_StockBadgeColors"] = "库存颜色",
["Menu_Settings_View"] = "显示",
["Menu_Settings_Window"] = "窗口",

-- Category Menu.
["Menu_Category_Move_TooltipText"] = "拿起这个分类，把它移到另一个组。",
["Menu_Category_Edit_TooltipText"] = "在编辑器中打开这个分类。",
["Menu_Category_Remove_TooltipText"] = "把这个分类从当前组移除。!!Info_NoDelete!!",

-- Group Menu.
["Menu_Group_Rename_TooltipTitle"] = "重命名组",
["Menu_Group_Rename_TooltipText"] = "修改这个组的标签。",
["Menu_Group_Move_TooltipTitle"] = "移动组",
["Menu_Group_Move_TooltipText"] = "拿起这个组，把它移到新位置。",
["Menu_Group_Delete_TooltipTitle"] = "删除组",
["Menu_Group_Delete_TooltipText"] = "彻底删除这个组，并取消所有分类的分配。!!Warning_NoUndo!!",

["Menu_Group_Add_Category_TooltipText"] = "把一个已有分类分配给这个组。",
["Menu_Group_Configure_Category_TooltipText"] = "显示这个分类的右键菜单。",
["Menu_Group_New_Category_TooltipTitle"] = "新建分类",
["Menu_Group_New_Category_TooltipText"] = "新建一个分类并分配给这个组。",
["Menu_Group_Move_Category_TooltipText"] = "拿起这个组里的一个分类，把它移到另一个组。",
["Menu_Group_Remove_Category_TooltipText"] = "从这个组移除一个分类。!!Info_NoDelete!!",
["Menu_Group_Edit_Category_TooltipText"] = "编辑这个组里的一个分类。",
["Menu_Group_DefaultColor_TooltipTitle"] = "使用默认的组%s颜色",
["Menu_Group_DefaultColor_TooltipText"] = "使用设置中定义的组%s颜色。",
["Menu_Group_DefaultSortOrder_TooltipTitle"] = "使用默认排序方式",
["Menu_Group_DefaultSortOrder_TooltipText"] = "使用当前结构的默认排序方式：" .. BS_NEWLINE .. "%s",
["Menu_Group_HideGroup"] = "隐藏组",
["Menu_Group_HideGroup_TooltipText"] = "除非打开“显示隐藏的物品”，否则不显示这个组。",
["Menu_Group_HideStockBadge"] = "隐藏库存标记",
["Menu_Group_HideStockBadge_TooltipText"] = "这个组不显示库存变化标记（新增/增加/减少）。",
["Menu_Group_Settings_TooltipTitle"] = "组设置",
["Menu_Group_Settings_TooltipText"] = "管理这个组自己的选项，包括背景和边框颜色。",
["Menu_Group_Color_TooltipTitle"] = "组%s颜色",
["Menu_Group_Color_TooltipText"] = "设置这个组的%s。",
["Menu_Group_SortOrder_TooltipTitle"] = "组排序方式",
["Menu_Group_SortOrder_TooltipText"] = "修改这个组里物品的排序方式。",

-- Item Menu.
["Menu_Item_AssignToCategory"] = "直接分配",
["Menu_Item_AssignToCategory_TooltipTitle"] = "直接分配到分类",
["Menu_Item_AssignToCategory_TooltipText"] = "把这个物品的 ID 直接分配到一个或多个自定义分类（不使用规则函数）。",
["Menu_Item_Information_TooltipTitle"] = "物品信息",
["Menu_Item_Information_TooltipText"] = "查看这个物品的属性，并打开物品信息窗口。",
["Menu_Item_Information_Submenu_TooltipText"] = "点击打开物品信息窗口。",
["Menu_Item_Manage_TooltipTitle"] = "管理物品",
["Menu_Item_Manage_TooltipText"] = "Bagshui 的物品操作。",
["Menu_Item_MatchedCategories"] = "匹配的分类",
["Menu_Item_MatchedCategories_TooltipTitle"] = "匹配的分类",
["Menu_Item_MatchedCategories_TooltipText"] = "这个物品匹配到的所有分类，按顺序排列。",
["Menu_Item_MatchedCategory_TooltipText"] = "点击编辑。",
["Menu_Item_Move_TooltipText"] = "拿起这个物品，把它直接分配到新分类。",
["Menu_Item_RemoveFromEquippedGear"] = "移出已装备列表",
["Menu_Item_RemoveFromEquippedGear_TooltipText"] = "把这个物品从你装备过的物品列表中移除（Equipped() 规则将不再匹配它）。",
["Menu_Item_ResetStockState"] = "重置库存状态",
["Menu_Item_ResetStockState_TooltipText"] = "清除这个物品的新增/增加/减少状态。",

-- Item Stock State.
["StockState"] = "库存状态",
["StockLastChange"] = "上次变化",
["Stock_New"] = "!!New!!",
["Stock_Up"] = "增加",
["Stock_Down"] = "减少",
["Stock_"] = "无",

-- Item Information window title.
["BagshuiItemInformation"] = "Bagshui 物品信息",


-- ### Categories and Groups ###

-- Templates.
["Suffix_Items"] = "%s物品",
["Suffix_Potions"] = "%s药水",
["Suffix_Reagents"] = "%s材料",

-- Special categories.
["TurtleWoWGlyphs"] = "雕文（Turtle WoW）",
["SoulboundGear"] = "灵魂绑定装备",

-- Name identifiers: text in item names, as the zhCN client writes them.
["NameIdentifier_AntiVenom"] = [[抗毒药剂]],
["NameIdentifier_Bandage"] = [[绷带]],
["NameIdentifier_Elixir"] = [[药剂]],
["NameIdentifier_Firestone"] = [[火焰石]],
["NameIdentifier_FrostOil"] = [[冰霜之油]],
["NameIdentifier_HallowedWand"] = [[神圣魔杖]],
["NameIdentifier_Idol"] = [[神像]],
["NameIdentifier_ManaOil"] = [[法力之油]],
["NameIdentifier_Poison"] = [[毒药]],
["NameIdentifier_Potion"] = [[药水]],
["NameIdentifier_Scroll"] = [[卷轴]],
["NameIdentifier_ShadowOil"] = [[暗影之油]],
["NameIdentifier_SharpeningStone"] = [[磨刀石]],
["NameIdentifier_Soulstone"] = [[灵魂石]],
["NameIdentifier_Spellstone"] = [[法术石]],
["NameIdentifier_Weightstone"] = [[平衡石]],
["NameIdentifier_WizardOil"] = [[巫师之油]],

-- Tooltip identifiers. Numbers in zhCN tooltips may or may not have spaces
-- around them, so the potion patterns allow both.
["TooltipIdentifier_Buff_WellFed"] = [[进食充分]],
["TooltipIdentifier_Drink"] = [[饮用时必须保持坐姿]],
["TooltipIdentifier_Food"] = [[进食时必须保持坐姿]],
["TooltipIdentifier_Mount"] = [[召唤和解散一匹可骑乘的]],
["TooltipIdentifier_PotionHealth"] = [[/恢复%s*[%d.]+%s*到%s*[%d.]+%s*点生命值/]],
["TooltipIdentifier_PotionMana"] = [[/恢复%s*[%d.]+%s*到%s*[%d.]+%s*点法力值/]],
["TooltipIdentifier_QuestItem"] = [[任务物品]],
["TooltipParse_AlreadyKnown"] = _G.ITEM_SPELL_KNOWN,

-- Shared Category/Group Names.
["ActiveQuest"] = "当前任务",
["Bandages"] = "绷带",
["BindOnEquip"] = "装备后绑定",
["Books"] = "书籍",
["Buffs"] = "增益",
["Companions"] = "宠物",
["Consumables"] = "消耗品",
["Disguises"] = "伪装",
["Drink"] = "饮料",
["Elixirs"] = "药剂",
["Empty"] = "空",
["EmptySlots"] = "空格",
["Equipment"] = "装备",
["EquippedGear"] = "已装备的装备",
["FirstAid"] = "急救",
["Food"] = "食物",
["FoodBuffs"] = "食物增益",
["Gear"] = "装备",
["Glyphs"] = "雕文",
["Gray"] = "灰色",
["Health"] = "生命",
["Items"] = "物品",
["Juju"] = "魔精",
["Keys"] = "钥匙",
["Mana"] = "法力",
["Misc"] = "杂项",
["Mounts"] = "坐骑",
["MyGear"] = "我的装备",
["Other"] = "其他",
["Potions"] = "药水",
["PotionsSlashRunes"] = "药水/符文",
["ProfessionBags"] = "专业背包",
["ProfessionCrafts"] = "专业制品",
["ProfessionReagents"] = "专业材料",
["Reagents"] = "材料",
["Recipes"] = "配方",
["Runes"] = "符文",
["Scrolls"] = "卷轴",
["Teleports"] = "传送",
["Tools"] = "工具",
["TradeTools"] = "专业工具",
["Uncategorized"] = "未分类",
["WeaponBuffs"] = "武器增益",
["Weapons"] = "武器",

-- Category names that are different from group names.
["Category_ProfessionBags"] = "专业背包（已学）",
["Category_ProfessionBagsAll"] = "专业背包（全部）",
["Category_ProfessionCrafts"] = "专业制品（已学配方）",
["Category_ProfessionReagents"] = "专业材料（已学配方）",


-- ### Sort Orders ###

["SortOrder_Default_MinLevel"] = "标准，按最低等级",
["SortOrder_Default_MinLevelNameRev"] = "标准，按最低等级，物品名反向",
["SortOrder_Default_NameRev"] = "标准，物品名反向",
["SortOrder_Default"] = "标准",
["SortOrder_Manual"] = "手动（只按背包/格子编号）",


-- ### Profiles ###
["ManageProfile"] = "管理配置",
["Profile_Design"] = "外观",
["Profile_Structure"] = "结构",
["Profile_Abbrev_Design"] = "外观",
["Profile_Abbrev_Structure"] = "结构",

["Object_UsedInProfiles"] = "用于以下配置：",
["Object_UsedByCharacters"] = "以下角色在用：",
["Object_ProfileUses"] = "配置用量：",


-- ### Object List/Manager/Editor ###

["ObjectList_ActionNotAllowed"] = "%s操作不适用于%s。",
["ObjectList_ShowObjectUses"] = "显示%s的使用情况",
["ObjectList_ShowProfileUses"] = "显示配置的使用情况",
["ObjectList_ImportSuccessful"] = "已导入%s“%s”。",
["ObjectList_ImportReusingExisting"] = "跳过导入%s“%s”，因为它和“%s”完全相同。",

["ObjectManager_Column_Name"] = "!!Name!!",
["ObjectManager_Column_InUse"] = "使用中",
["ObjectManager_Column_Realm"] = "服务器",
["ObjectManager_Column_Sequence"] = "顺序",
["ObjectManager_Column_Source"] = "来源",
["ObjectManager_Column_LastInventoryUpdate"] = "物品更新时间",

["ObjectManager_DeletePrompt"] = "删除以下%s？%s%s!!Warning_NoUndo!!",
["ObjectManager_DeleteForPrompt"] = "删除%s：“%s”？%s!!Warning_NoUndo!!",

["ObjectEditor_UnsavedPrompt"] = "关闭前保存对%s“%s”的修改吗？",
["ObjectEditor_RequiredField"] = "%s为必填项",

["ItemList_NewPrompt"] = "要添加的物品标识：" .. BS_NEWLINE .. GRAY_FONT_COLOR_CODE .. "可以是物品 ID、物品链接/物品字符串或数据库网址。" .. BS_NEWLINE .. "多个之间用空格、制表符、逗号、分号或换行分隔。" .. FONT_COLOR_CODE_CLOSE,
["ItemList_CopyPrompt"] = "物品 ID：",


-- ### Managers and Windows ###

["CategoryManager"] = "Bagshui 分类管理器",
["CategoryEditor"] = "编辑分类",
["CategoryEditor_Field_name"] = "!!Name!!",
["CategoryEditor_Field_nameSort"] = "名称（排序用）",
["CategoryEditor_Field_nameSort_TooltipText"] = "排序时使用这个名称代替分类名，不影响显示的名称。",
["CategoryEditor_Field_sequence"] = "顺序",
["CategoryEditor_Field_sequence_TooltipText"] = "控制分类的判断顺序。" .. BS_NEWLINE .. "0 = 最先，100 = 最后",
["CategoryEditor_Field_class"] = "职业",
["CategoryEditor_Field_rule"] = "规则",
["CategoryEditor_Field_rule_TooltipText"] = "一个或多个 Bagshui 规则函数，可以用 and/or/not 组合，用括号分组。详见文档。",
["CategoryEditor_Field_list"] = "直接分配",
["CategoryEditor_Field_list_TooltipText"] = "直接分配到这个分类的物品列表（不使用规则函数）。",
["CategoryEditor_AddRuleFunction"] = "添加规则函数",
["CategoryEditor_RuleFunctionWiki"] = "规则帮助",
["CategoryEditor_RuleValidation_Validate"] = "校验规则",
["CategoryEditor_RuleValidation_Valid"] = "规则有效",
["CategoryEditor_RuleValidation_Invalid"] = "规则校验出错：",

["CharacterDataManager"] = "Bagshui 角色数据管理器",
["CharacterDataManager_DeleteInfo"] = "只删除物品数据，不会动配置。",

["SortOrderManager"] = "Bagshui 排序方式管理器",
["SortOrderEditor"] = "编辑排序方式",
["SortOrderEditor_Field_name"] = "!!Name!!",
["SortOrderEditor_Field_fields"] = "字段",
["SortOrderEditor_NormalWordOrder"] = "正常词序",
["SortOrderEditor_ReverseWordOrder"] = "反向词序",

["ProfileManager"] = "Bagshui 配置管理器",
["ProfileManager_ReplaceTooltipTitle"] = "替换%s",
["ProfileManager_ReplaceTooltipText"] = "把%s设置从配置“%s”复制到“%s”。",
["ProfileManager_ReplacePrompt"] = "替换%s设置：让配置“%s”改用“%s”的设置？!!Warning_NoUndo!!",

["ProfileEditor"] = "编辑配置",
["ProfileEditor_Field_name"] = "!!Name!!",
["ProfileEditor_FooterText"] = "配置通过设置菜单和编辑模式修改。",

["ShareManager"] = "Bagshui 导入/导出",
["ShareManager_ExportPrompt"] = "按 Ctrl+C 复制。",
["ShareManager_ExportEncodeCheckbox"] = "优化以便分享",
["ShareManager_ExportEncodeExplanation"] = "请分享优化（压缩/编码）后的版本，它在各种网络传输中都不会损坏。想看分享的内容，把未优化的版本复制到文本编辑器里。",
["ShareManager_ImportPrompt"] = "按 Ctrl+V 粘贴要导入的 Bagshui 数据。",

["CatalogManager"] = "Bagshui 物品总览",
["CatalogManager_SearchBoxPlaceholder"] = "搜索全账号物品",
["CatalogManager_KnownCharacters"] = "显示以下角色的物品：",

["GameReport"] = "Bagshui 游戏环境报告",
["GameReport_Instructions"] = "把下面的文字复制到错误报告的“环境”部分。",


-- ### Rule Function Templates ###

["RuleFunction_LuaStringPatternsSupported"] = BS_NEWLINE .. GRAY_FONT_COLOR_CODE .. '用“/斜杠包起来/”可以使用 Lua 字符串模式。' .. FONT_COLOR_CODE_CLOSE,
["RuleFunction_PT_CaseSensitiveParameters"] = BS_NEWLINE .. GRAY_FONT_COLOR_CODE .. "集合名区分大小写。" .. FONT_COLOR_CODE_CLOSE,

["RuleFunction_ActiveQuest_ExampleDescription1"] = "检查物品是否是当前角色任务日志里的任务目标。",

["RuleFunction_Bag_GenericDescription"] = "检查物品是否在指定编号的背包里",
["RuleFunction_Bag_ExampleDescription"] = "检查物品是否在指定编号的背包里（%d 号是第 %d 个容器，位于%s）",
["RuleFunction_Bag_ExampleDescriptionExtra1"] = "检查物品是否在任一指定编号的背包里。",

["RuleFunction_BagType_GenericDescription"] = "检查物品是否在指定类型的背包里。",
["RuleFunction_BagType_ExampleDescription"] = "检查物品是否在“%s”类型的背包里。",
["RuleFunction_BagType_ExampleDescriptionExtra1"] = "检查物品是否在当前角色某个专业的专用背包里" .. GRAY_FONT_COLOR_CODE .. BS_NEWLINE .. "ProfessionBag 是触发这个功能的关键字，不能加引号。" .. FONT_COLOR_CODE_CLOSE,
["RuleFunction_BagType_ExampleDescriptionExtra2"] = "检查物品是否在任何专业专用背包里。" .. GRAY_FONT_COLOR_CODE .. BS_NEWLINE .. "AllProfessionBags 是触发这个功能的关键字，不能加引号。" .. FONT_COLOR_CODE_CLOSE,
["RuleFunction_BagType_ExampleDescriptionExtra3"] = '检查物品是否在任一指定类型的背包里。',

["RuleFunction_BindsOnEquip_ExampleDescription1"] = "检查物品是否装备后绑定",

["RuleFunction_CharacterLevelRange_GenericDescription"] = "按当前角色的等级检查物品是否可用。",
["RuleFunction_CharacterLevelRange_ExampleDescription1"] = "检查物品是否正好在当前角色等级可用。",
["RuleFunction_CharacterLevelRange_ExampleDescription2"] = "检查物品是否在当前角色等级上下 <levelsBelowOrAbove> 级内可用。",
["RuleFunction_CharacterLevelRange_ExampleDescription3"] = "检查物品是否在当前角色等级低 <below> 级到高 <above> 级之间可用。",

["RuleFunction_Count_GenericDescription"] = "检查堆叠数量。",
["RuleFunction_Count_ExampleDescription1"] = "检查这一叠是否至少有 <number> 个。",
["RuleFunction_Count_ExampleDescription2"] = "检查这一叠是否有 <min> 到 <max> 个。",

["RuleFunction_EmptySlot_ExampleDescription1"] = "检查背包格子是否是空的。",

["RuleFunction_EquipLocation_GenericDescription"] = "检查物品能否装备在指定位置。",
["RuleFunction_EquipLocation_ExampleDescription"] = "检查物品能否装备在%s位置。",
["RuleFunction_EquipLocation_ExampleDescriptionExtra1"] = "检查物品能否装备在任一指定位置。",

["RuleFunction_Equipped_ExampleDescription1"] = "检查物品是否装备过（可以匹配没有灵魂绑定的装备）。" .. GRAY_FONT_COLOR_CODE .. BS_NEWLINE .. "也可以传入和 EquipLocation() 相同的参数，只匹配特定装备位置。" .. FONT_COLOR_CODE_CLOSE,

["RuleFunction_Id_GenericDescription"] = '检查物品 ID 是否完全一致。',
["RuleFunction_Id_ExampleDescription1"] = "检查物品 ID 是否完全一致。",
["RuleFunction_Id_ExampleDescriptionExtra1"] = "检查物品 ID 是否与任一参数一致。",

["RuleFunction_ItemString_GenericDescription"] = "检查物品字符串是否匹配（用来匹配特定的附魔或后缀 ID）。",
["RuleFunction_ItemString_ExampleDescription1"] = RED_FONT_COLOR_CODE .. "请改用 Id(itemId)。" .. FONT_COLOR_CODE_CLOSE .. BS_NEWLINE .. "检查物品字符串是否以“item:<itemId>:”开头",
["RuleFunction_ItemString_ExampleDescription2"] = RED_FONT_COLOR_CODE .. "请改用 Id(itemId)。" .. FONT_COLOR_CODE_CLOSE .. BS_NEWLINE .. "检查物品字符串是否以“item:<itemId>:”开头（item: 前缀可省略）。",
["RuleFunction_ItemString_ExampleDescription3"] = "检查物品字符串是否以“item:<itemId>:<enchantId>:”开头（item: 前缀可省略）。",
["RuleFunction_ItemString_ExampleDescription4"] = "检查物品字符串是否以“item:<itemId>:<enchantId>:<suffixId>:”开头（item: 前缀可省略）。",
["RuleFunction_ItemString_ExampleDescriptionExtra1"] = '检查物品字符串是否与任一参数匹配。',

["RuleFunction_Location_GenericDescription"] = "检查物品是否存放在特定位置（背包、银行等）",
["RuleFunction_Location_ExampleDescription"] = "检查物品是否在你的%s里",
["RuleFunction_Location_ExampleDescriptionExtra1"] = "检查物品是否存放在任一指定位置。",

["RuleFunction_MinLevel_GenericDescription"] = "按指定等级检查物品是否可用。",
["RuleFunction_MinLevel_ExampleDescription1"] = "检查物品是否在 <level> 级及以上可用。",
["RuleFunction_MinLevel_ExampleDescription2"] = "检查物品是否在 <min> 到 <max> 级可用。",

["RuleFunction_Name_GenericDescription"] = "检查物品名称是否包含指定文字。!!RuleFunction_LuaStringPatternsSupported!!",
["RuleFunction_Name_ExampleDescription1"] = "检查物品名称是否包含指定文字。!!RuleFunction_LuaStringPatternsSupported!!",
["RuleFunction_Name_ExampleDescriptionExtra1"] = "检查物品名称是否包含任一指定文字。!!RuleFunction_LuaStringPatternsSupported!!",

["RuleFunction_NameExact_GenericDescription"] = "检查物品名称是否与指定文字完全一致。",
["RuleFunction_NameExact_ExampleDescription1"] = "检查物品名称是否与指定文字完全一致。",
["RuleFunction_NameExact_ExampleDescriptionExtra1"] = "检查物品名称是否与任一指定文字完全一致。",

["RuleFunction_Outfit_GenericDescription"] = "检查物品是否属于某套 Outfitter 或 ItemRack 套装。",
["RuleFunction_Outfit_ExampleDescription1"] = "检查物品是否属于任何 Outfitter 或 ItemRack 套装。",
["RuleFunction_Outfit_ExampleDescription2"] = "检查物品是否属于指定的 Outfitter 或 ItemRack 套装。",
["RuleFunction_Outfit_ExampleDescriptionExtra1"] = "检查物品是否属于任一指定的 Outfitter 或 ItemRack 套装。",

["RuleFunction_PeriodicTable_GenericDescription"] = "检查物品是否属于某个 PeriodicTable 集合。!!RuleFunction_PT_CaseSensitiveParameters!!",
["RuleFunction_PeriodicTable_ExampleDescription"] = "检查物品是否属于 PeriodicTable 集合“%s”。!!RuleFunction_PT_CaseSensitiveParameters!!",
["RuleFunction_PeriodicTable_ExampleDescriptionExtra1"] = "检查物品是否属于任一指定的 PeriodicTable 集合。!!RuleFunction_PT_CaseSensitiveParameters!!",

["RuleFunction_ProfessionCraft_GenericDescription"] = "检查物品是否由当前角色的专业制作（只算已学配方）。",
["RuleFunction_ProfessionCraft_ExampleDescription1"] = "检查物品是否由当前角色的任一专业制作（只算已学配方）。",
["RuleFunction_ProfessionCraft_ExampleDescription2"] = "检查物品是否由当前角色的指定专业制作（只算已学配方）。",
["RuleFunction_ProfessionCraft_ExampleDescriptionExtra1"] = "检查物品是否由当前角色的任一指定专业制作（只算已学配方）。",

["RuleFunction_ProfessionReagent_GenericDescription"] = "检查物品是否是当前角色专业制作的材料（只算已学配方）。",
["RuleFunction_ProfessionReagent_ExampleDescription1"] = "检查物品是否是当前角色任一专业制作的材料（只算已学配方）。",
["RuleFunction_ProfessionReagent_ExampleDescription2"] = "检查物品是否是当前角色指定专业制作的材料（只算已学配方）。",
["RuleFunction_ProfessionReagent_ExampleDescriptionExtra1"] = "检查物品是否是当前角色任一指定专业制作的材料（只算已学配方）。",

["RuleFunction_Quality_GenericDescription"] = "检查物品是否是指定品质。",
["RuleFunction_Quality_ExampleDescription"] = "检查物品是否是%s品质。",
["RuleFunction_Quality_ExampleDescriptionExtra1"] = "检查物品是否是任一指定品质。",

["RuleFunction_RequiresClass_GenericDescription"] = "检查物品能否被指定职业使用。",
["RuleFunction_RequiresClass_ExampleDescription"] = "检查物品能否被%s使用。",
["RuleFunction_RequiresClass_ExampleDescriptionExtra1"] = "检查物品能否被任一指定职业使用。",

["RuleFunction_Soulbound_ExampleDescription1"] = "检查物品是否已灵魂绑定。",

["RuleFunction_Stacks_ExampleDescription1"] = "检查物品能否堆叠。",

["RuleFunction_Subtype_GenericDescription"] = "检查物品是否是指定子类型",
["RuleFunction_Subtype_ExampleDescription"] = "检查物品的子类型是否是“%s”。",
["RuleFunction_Subtype_ExampleDescriptionExtra1"] = "检查物品是否是任一指定子类型。",

["RuleFunction_Tooltip_GenericDescription"] = "检查鼠标提示是否包含指定文字。!!RuleFunction_LuaStringPatternsSupported!!",
["RuleFunction_Tooltip_ExampleDescription1"] = "检查物品鼠标提示是否包含指定文字。!!RuleFunction_LuaStringPatternsSupported!!",
["RuleFunction_Tooltip_ExampleDescriptionExtra1"] = "检查鼠标提示是否包含任一指定文字。!!RuleFunction_LuaStringPatternsSupported!!",

["RuleFunction_Type_GenericDescription"] = "检查物品是否是指定类型。",
["RuleFunction_Type_ExampleDescription"] = "检查物品的类型是否是“%s”。",
["RuleFunction_Type_ExampleDescriptionExtra1"] = "检查物品是否是任一指定类型。",

["RuleFunction_Usable_ExampleDescription1"] = "按等级、技能和专业检查当前角色能否使用这个物品。",

["RuleFunction_Wishlist_ExampleDescription1"] = "检查物品是否在 AtlasLoot 愿望单上。",


-- ### Tips/Help ###
["BagshuiTooltipIntro"] = "显示 Bagshui 信息提示",


-- ### Errors/Warnings ###

["Error"] = "错误",
["Error_AddonDependency"] = "%s 没有安装或没有启用。",
["Error_CategoryEvaluation"] = "%s：%s",
["Error_DuplicateName"] = "已经有一个%s叫 %s。",
["Error_GroupNotFound"] = "找不到组 ID %s。",
["Error_HearthstoneNotFound"] = "找不到炉石。",
["Error_ImportInvalidFormat"] = "导入失败：数据格式不对。",
["Error_ImportVersionTooNew"] = "导入失败：请升级到最新版的 Bagshui。",
["Error_ItemCategoryUnknown"] = "!未知！（不应该出现这种情况）。",
["Error_RestackFailed"] = "合并堆叠失败：%s",
["Error_SaveFailed"] = "%s 保存失败：%s",
["Error_Suffix_Retrying"] = "%s；正在重试…",

["Info_NoDelete"] = BS_NEWLINE .. GRAY_FONT_COLOR_CODE .. "不会删除这个分类。" .. FONT_COLOR_CODE_CLOSE,

["Warning_NoUndo"] = BS_NEWLINE .. RED_FONT_COLOR_CODE .. "此操作无法撤销！" .. FONT_COLOR_CODE_CLOSE,
["Warning_RuleFunctionOverwrite"] = "覆盖已有的规则环境函数 %s()",
["Warning_BuiltinRuleFunctionCollision"] = "第三方规则函数/别名 %s() 没有载入，因为它和 Bagshui 内置规则函数重名",

["Compat_ReloadUIPrompt"] = "需要重新载入界面。",
["Compat_pfUIBags"] = "强烈建议禁用 pfUI 的背包模块，以免出现多个银行窗口。",
["Compat_pfUIBagsInfo"] = "如果改主意了，可以在 pfUI 设置 > 组件 > 模块里管理 pfUI 背包模块。",
["Compat_tDFAllInOneBags"] = "如果想用 Bagshui 作为默认背包，建议禁用 tDF 的整合背包模块。",
["Compat_tDFAllInOneBagsInfo"] = "如果改主意了，可以在 tDF 选项里管理整合背包模块。",

["Error_RuleFunctionInvalid"] = '«%s» 不是有效的规则函数——如果想作为参数，请加引号，例如 Function("parameter")',
["Error_RuleVariablePropertyInvalid"] = "«%s» 不是有效的%s属性",
["Error_RuleExecution"] = "规则函数 %s 出错：%s",
["Error_RuleNoArguments"] = "至少需要一个参数，但一个也没有提供",
["Error_RuleNilArgument"] = "参数 %s 无效：不允许为 nil",
["Error_RuleInvalidArgument"] = "参数 %s 无效：«%s» 是%s，应为%s",
["Error_RuleInvalidArgumentType"] = "%s 不是有效的参数类型；允许的参数类型：%s",
["Error_RuleTooManyArguments"] = "规则函数最多 50 个参数。要用更多参数，用 or 再调用一次 %s，例如：or %s(param1, param2, etc)",

["Error_Rule_ItemLevelStat"] = "经典版魔兽世界没有物品等级，所以不能用 ItemLevelStat()。",
["Error_Rule_ItemStat"] = "暂不支持 ItemStat() 和 ItemStatActive()，可以改用 Tooltip() 检查属性。",

-- ### Logging ###

["LogWindowTitle"] = "Bagshui 日志",
["ClearLog"] = "清空日志",
["Log_Info"] = "信息",
["Log_Warn"] = "警告",
["Log_Error"] = "错误",

["SettingReset_LogStart"] = "%s 已重置",
["SettingReset_InvalidValue"] = "值无效",
["SettingReset_Outdated"] = "已过时",


-- ### Help/Misc ###

["BagshuiDataReset"] = "因版本变化，配置已重置（原版本：%s / 新版本：%s）。",
["HowToUrl"] = "游戏里不能直接打开网址，请复制这个网址（Ctrl+C）到浏览器里打开。",


-- ### Settings: Tooltips, Scopes, Special ###

["Setting_HookBagTooltipTitle"] = "接管%s",
["Setting_HookBagTooltipText"] = "接管“开关%s”的按键绑定。",
["SettingScope_Account"] = "对本账号所有角色生效。",
["SettingScope_Character"] = "对这个角色的所有物品窗口生效。",
["Setting_DisabledBy_HideGroupLabels"] = "× 已禁用，因为当前结构开启了“隐藏组标签”。",
["Setting_EnabledBy_ColorblindMode"] = "√ 已启用，因为开启了色盲模式。",
["Setting_Profile_SetAllHint"] = "Shift+点击可用于所有配置类型。",
["Setting_Reset_TooltipText"] = "恢复默认：Ctrl+Alt+Shift+点击。",
["Setting_Profile_Use"] = "设为当前的%s%s配置。",


-- ### Settings ###

["aboutBagshui_TooltipTitle"] = "关于 Bagshui",

["colorblindMode"] = "色盲模式",
["colorblindMode_TooltipText"] = "无论外观设置如何，始终显示物品品质和不可用标记。",

["createNewProfileDesign"] = "复制",
["createNewProfileDesign_TooltipTitle"] = "复制外观配置",
["createNewProfileDesign_TooltipText"] = "复制新角色使用的默认配置。",

["createNewProfileStructure"] = "复制",
["createNewProfileStructure_TooltipTitle"] = "复制结构配置",
["createNewProfileStructure_TooltipText"] = "复制新角色使用的默认配置。",

["defaultSortOrder"] = "排序方式",
["defaultSortOrder_TooltipTitle"] = "默认排序方式",
["defaultSortOrder_TooltipText"] = "没有单独设置排序方式的组如何排序。",

["defaultProfileDesign"] = "外观",
["defaultProfileDesign_TooltipTitle"] = "默认外观配置",
["defaultProfileDesign_TooltipText"] = "新角色使用的配置。",

["defaultProfileStructure"] = "结构",
["defaultProfileStructure_TooltipTitle"] = "默认结构配置",
["defaultProfileStructure_TooltipText"] = "新角色使用的配置。",

["windowDoubleClickActions"] = "双击开关",
["windowDoubleClickActions_TooltipText"] = "双击物品窗口的空白处显示/隐藏所有工具栏。" .. BS_NEWLINE .. "Alt+双击锁定/解锁位置。",

["globalInfoTooltips"] = "物品信息",
["globalInfoTooltips_TooltipTitle"] = "接管所有物品提示",
["globalInfoTooltips_TooltipText"] = "在任何地方（角色窗口、聊天链接等）按住 Alt 都显示 Bagshui 信息提示。",

["groupBackgroundDefault"] = "背景",
["groupBackgroundDefault_TooltipTitle"] = "默认组背景色",
["groupBackgroundDefault_TooltipText"] = "组没有单独设置颜色时使用的背景色。",

["groupBorderDefault"] = "边框",
["groupBorderDefault_TooltipTitle"] = "默认组边框色",
["groupBorderDefault_TooltipText"] = "组没有单独设置颜色时使用的边框色。",

["groupLabelDefault"] = "标签",
["groupLabelDefault_TooltipTitle"] = "默认组标签颜色",
["groupLabelDefault_TooltipText"] = "组没有单独设置颜色时使用的标签颜色。",

["groupMargin"] = "间距",
["groupMargin_TooltipTitle"] = "组间距",
["groupMargin_TooltipText"] = "组与组之间的距离。",

["groupPadding"] = "内边距",
["groupPadding_TooltipTitle"] = "组内边距",
["groupPadding_TooltipText"] = "组边框和里面物品之间的距离。",

["groupUseSkinColors"] = "使用%s颜色",
["groupUseSkinColors_TooltipTitle"] = "组使用%s颜色",
["groupUseSkinColors_TooltipText"] = "使用%s的颜色，而不是 Bagshui 的设置。",

["hideGroupLabelsOverride"] = "隐藏组标签",
["hideGroupLabelsOverride_TooltipText"] = "即使外观设置开启了组标签，也不显示。",

["itemMargin"] = "间距",
["itemMargin_TooltipTitle"] = "物品间距",
["itemMargin_TooltipText"] = "物品之间的距离。",

["itemActiveQuestBadges"] = "当前任务",
["itemActiveQuestBadges_TooltipTitle"] = "当前任务物品标记",
["itemActiveQuestBadges_TooltipText"] = "物品是当前任务的目标时，在顶部显示一个问号。",

["itemQualityBadges"] = "!!Quality!!",
["itemQualityBadges_TooltipTitle"] = "物品品质标记",
["itemQualityBadges_TooltipText"] = "在左下角显示物品品质图标。",

["itemUsableBadges"] = "不可用",
["itemUsableBadges_TooltipTitle"] = "物品不可用标记",
["itemUsableBadges_TooltipText"] = "在左上角为不可用/已学会的物品显示图标。",

["itemUsableColors"] = "不可用",
["itemUsableColors_TooltipTitle"] = "物品不可用着色",
["itemUsableColors_TooltipText"] = "给不可用/已学会的物品加上红色/绿色。",

["itemSize"] = "大小",
["itemSize_TooltipTitle"] = "物品大小",
["itemSize_TooltipText"] = "物品图标的宽和高。",

["itemStockBadges"] = "库存",
["itemStockBadges_TooltipTitle"] = "物品库存标记",
["itemStockBadges_TooltipText"] = "标出新物品和数量增减。",

["itemStockChangeExpiration"] = "有效期",
["itemStockChangeExpiration_TooltipTitle"] = "库存变化标记有效期",
["itemStockChangeExpiration_TooltipText"] = "超过这个时间后，物品不再算作有变化（新增/增加/减少）。",

["itemStockBadgeFadeDuration"] = "淡出",
["itemStockBadgeFadeDuration_TooltipTitle"] = "库存标记淡出时长",
["itemStockBadgeFadeDuration_TooltipText"] = "库存变化标记（新增/增加/减少）在有效期结束前这么长时间开始淡出。",

["profileDesign"] = "配置",
["profileDesign_TooltipTitle"] = "外观配置",
["profileDesign_TooltipText"] = "外观（物品栏看起来怎样）使用的配置。",

["profileStructure"] = "配置",
["profileStructure_TooltipTitle"] = "结构配置",
["profileStructure_TooltipText"] = "结构（物品栏怎样组织）使用的配置。",

["replaceBank"] = "替换银行",
["replaceBank_TooltipText"] = "用 Bagshui 银行代替暴雪银行。",

["resetStockState"] = "标记为无变化",
["resetStockState_TooltipText"] = "把这个物品栏里所有物品都设为不再是新增、增加或减少。",

["showBagBar"] = "背包栏",
["showBagBar_TooltipText"] = "在左下角显示背包栏。",

["showFooter"] = "底部工具栏",
["showFooter_TooltipTitle"] = "底部工具栏",
["showFooter_TooltipText"] = "显示底部工具栏。" .. BS_NEWLINE .. LIGHTYELLOW_FONT_COLOR_CODE .. "隐藏后，物品下方的所有内容都会消失，包括背包栏和金钱显示。" .. FONT_COLOR_CODE_CLOSE,

["showGroupLabels"] = "标签",
["showGroupLabels_TooltipTitle"] = "组标签",
["showGroupLabels_TooltipText"] = "在组的上方显示标签。",

["showHeader"] = "顶部工具栏",
["showHeader_TooltipTitle"] = "顶部工具栏",
["showHeader_TooltipText"] = "显示顶部工具栏。" .. BS_NEWLINE .. LIGHTYELLOW_FONT_COLOR_CODE .. "隐藏后，物品上方的所有内容都会消失，包括关闭按钮，只能用按键绑定、动作条按钮或宏来关闭。" .. FONT_COLOR_CODE_CLOSE,

["showHearthstone"] = "炉石按钮",
["showHearthstone_TooltipText"] = "显示炉石按钮。" .. BS_NEWLINE .. LIGHTYELLOW_FONT_COLOR_CODE .. "只对背包生效。" .. FONT_COLOR_CODE_CLOSE,

["showLogWindow_TooltipText"] = "打开 Bagshui 日志窗口。",

["showMoney"] = "金钱",
["showMoney_TooltipText"] = "在右下角显示金钱。",

["stackEmptySlots"] = "合并空格",
["stackEmptySlots_TooltipTitle"] = "合并空格",
["stackEmptySlots_TooltipText"] = "把空格合并成一叠，点击可以展开（专业背包的空格单独合并）。",

["toolbarButtonColor"] = "图标",
["toolbarButtonColor_TooltipTitle"] = "工具栏图标颜色",
["toolbarButtonColor_TooltipText"] = "这个物品栏工具栏图标的颜色。",

["toggleBagsWithAuctionHouse"] = "拍卖行",
["toggleBagsWithAuctionHouse_TooltipTitle"] = "跟随拍卖行开关背包",
["toggleBagsWithAuctionHouse_TooltipText"] = "打开和离开拍卖行时自动开关背包。",

["toggleBagsWithBankFrame"] = "银行",
["toggleBagsWithBankFrame_TooltipTitle"] = "跟随银行开关背包",
["toggleBagsWithBankFrame_TooltipText"] = "打开和离开银行时自动开关背包。",

["toggleBagsWithMailFrame"] = "邮箱",
["toggleBagsWithMailFrame_TooltipTitle"] = "跟随邮箱开关背包",
["toggleBagsWithMailFrame_TooltipText"] = "使用邮箱时自动开关背包。",

["toggleBagsWithTradeFrame"] = "交易",
["toggleBagsWithTradeFrame_TooltipTitle"] = "跟随交易开关背包",
["toggleBagsWithTradeFrame_TooltipText"] = "和其他玩家交易时自动开关背包。",

["windowAnchorXPoint"] = "水平",
["windowAnchorXPoint_TooltipTitle"] = "水平锚点",
["windowAnchorXPoint_TooltipText"] = "窗口从屏幕的这一边开始水平扩展。",

["windowAnchorYPoint"] = "垂直",
["windowAnchorYPoint_TooltipTitle"] = "垂直锚点",
["windowAnchorYPoint_TooltipText"] = "窗口从屏幕的这一边开始垂直扩展。",

["windowBackground"] = "背景",
["windowBackground_TooltipTitle"] = "窗口背景色",
["windowBackground_TooltipText"] = "这个物品窗口的背景颜色。",

["windowBorder"] = "边框",
["windowBorder_TooltipTitle"] = "窗口边框色",
["windowBorder_TooltipText"] = "这个物品窗口的边框颜色。",

["windowLocked"] = "锁定位置",
["windowLocked_TooltipText"] = "不允许移动这个窗口。",

["windowMaxColumns"] = "最大列数",
["windowMaxColumns_TooltipText"] = "窗口宽度上限，按每行物品数计算。",

["windowScale"] = "缩放",
["windowScale_TooltipTitle"] = "窗口缩放",
["windowScale_TooltipText"] = "整个窗口的相对大小。",

["windowUseSkinColors"] = "使用%s颜色",
["windowUseSkinColors_TooltipTitle"] = "窗口使用%s颜色",
["windowUseSkinColors_TooltipText"] = "使用%s的颜色，而不是 Bagshui 的设置。",

})

end)
