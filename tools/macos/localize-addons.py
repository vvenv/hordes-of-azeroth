#!/usr/bin/env python3
"""Simplified Chinese for the third-party addons, applied to the installed copies.

  tools/macos/localize-addons.py <AddOns folder>

install-addons.sh runs this after copying the addons, so a reinstall keeps
it. Every step is idempotent and prints what it changed. The addons' own
folder (../wow-data/addons) is never touched.

  Bagshui      no zhCN at all: adds Locale/zhCN.lua (tools/macos/addons-zhCN).
  SuperMacro   ruRU and English only: appends a zhCN block to localization.lua.
  ShaguKill    the "kills to next level" line.
  ShaguNotify  the popup titles it writes itself.
  CleverMacro  its load message.
  AtlasLoot    two bugs of its zhCN files: a `true` value in locale.cn.lua,
               which AceLocale allows only in the base locale, and TBC loot
               table titles in loottables.cn.lua for tables this 1.12 build
               lacks; either one stops the file on a Chinese client.
"""
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OVERLAY = os.path.join(HERE, "addons-zhCN")
MARK = "-- zhCN (tools/macos/localize-addons.py)"


def read(path):
    with open(path, encoding="utf-8-sig", errors="surrogateescape") as f:
        return f.read()


def write(path, text, bom=False):
    with open(path, "w", encoding="utf-8", errors="surrogateescape") as f:
        f.write(("﻿" if bom else "") + text)


def had_bom(path):
    with open(path, "rb") as f:
        return f.read(3) == b"\xef\xbb\xbf"


def replace_all(path, pairs, what):
    """Replace each (old, new) once; skip pairs already applied."""
    if not os.path.isfile(path):
        return
    text = read(path)
    new = text
    for old, rep in pairs:
        if old in new:
            new = new.replace(old, rep)
    if new != text:
        write(path, new, had_bom(path))
        print("localized " + what)


def bagshui(addons):
    locale = os.path.join(addons, "Bagshui", "Locale")
    if not os.path.isdir(locale):
        return
    shutil.copyfile(os.path.join(OVERLAY, "Bagshui", "Locale", "zhCN.lua"), os.path.join(locale, "zhCN.lua"))
    xml = os.path.join(locale, "Locales.xml")
    text = read(xml)
    if "zhCN.lua" not in text:
        text = text.replace('<Include file="enUS.lua" />', '<Include file="enUS.lua" />\n\t<Include file="zhCN.lua" />')
        write(xml, text)
    print("localized Bagshui")


SUPERMACRO_ZH = '''
''' + MARK + '''
if GetLocale() == "zhCN" then
	SUPERMACROFRAME_EXTEND_CHAR_LIMIT = "已用 %d/"..EXTEND_MAX_LETTERS.." 个字符";
	SUPERMACROFRAME_SUPER_CHAR_LIMIT = "已用 %d/"..SUPER_MAX_LETTERS.." 个字符";
	REGULAR = "普通";
	SUPER = "超级";
	SAVE_MACRO = "保存宏";
	ENTER_EXTEND_LABEL = "输入扩展 Lua 代码：";
	SAVE_EXTEND = "保存扩展";
	DELETE_EXTEND = "删除扩展";
	SAVE_SUPERMACRO = "保存超级宏";
	NEW_SUPERMACRO = "新建超级宏";
	DELETE_SUPERMACRO = "删除超级宏";
	SUPERMACRO_TITLE = "超级宏";
	SUPERMACRO_BUTTON = "宏\\n命\\n令";
	SUPERMACRO_OPTIONS = "超级宏选项";
	SUPERMACRO_NEW_ACCOUNT = "新建账号宏";
	SUPERMACRO_NEW_CHARACTER = "新建角色宏";
	SUPERMACRO_OPTIONS_TITLE = "超级宏选项";
	SUPERMACRO_MINIMAP = "打开超级宏窗口";

	SM_HIDE_ACTION = "隐藏动作条上的宏名";
	SM_MACRO_TIP_1 = "显示法术或物品的提示";
	SM_MACRO_TIP_2 = "显示宏代码的提示";
	SM_PRINT_COLOR = "SM_print() 和 /print 的输出颜色";
	SM_PRINT_COLOR_EXAMPLE_TEXT = "例如：现在看得见我吗？";
	SM_MINIMAP = "显示小地图按钮";
	SM_REPLACE_ICON = "自动替换动作图标";
	SM_CHECK_COOLDOWN = "自动检查动作冷却";
	SM_SHOW_MENU = "显示菜单按钮";
	SM_WORDWRAP = "长句自动换行";
	SM_MONO_FONT = "代码框使用等宽字体";
	SM_WINDOW_HEIGHT = "主窗口高度"
	SM_WINDOW_WIDTH = "主窗口宽度"
	SM_EDITBOX_FONT_SIZE = "代码框字号"

	SUPERMACRO_HELP_LINE1 = "只输入 /supermacro 显示帮助"
	SUPERMACRO_HELP_LINE2 = "/macro <宏名> 按名字运行一个宏"
	SUPERMACRO_HELP_LINE3 = "/supermacro hideaction 1 或 0：隐藏或显示动作按钮上的宏名"
	SUPERMACRO_HELP_LINE4 = "/supermacro printcolor <红> <绿> <蓝>，各为 0 到 1：修改 /print 的颜色"
	SUPERMACRO_HELP_LINE5 = "/supermacro macrotip 0-3，默认 1"
	SUPERMACRO_HELP_LINE6 = "0 普通，1 显示法术，2 显示宏代码，3 显示法术和/或代码"
end
'''


def supermacro(addons):
    path = os.path.join(addons, "SuperMacro", "localization.lua")
    if not os.path.isfile(path):
        return
    text = read(path)
    if MARK in text:
        return
    write(path, text.rstrip("\n") + "\n" + SUPERMACRO_ZH, had_bom(path))
    print("localized SuperMacro")


ZH = 'GetLocale() == "zhCN"'


def shagu(addons):
    replace_all(os.path.join(addons, "ShaguKill", "ShaguKill.lua"), [
        ('UIErrorsFrame:AddMessage("next level: |cffffffaa~" .. ShaguKill.RemainingKills .. "|r kills.")',
         'UIErrorsFrame:AddMessage((' + ZH + ') and ("距离升级：约 |cffffffaa" .. ShaguKill.RemainingKills .. "|r 只怪") or ("next level: |cffffffaa~" .. ShaguKill.RemainingKills .. "|r kills."))'),
        ('UIErrorsFrame:AddMessage("pet: |cffffffaa~" .. ShaguKill.petRemainingKills .. "|r kills.")',
         'UIErrorsFrame:AddMessage((' + ZH + ') and ("宠物升级：约 |cffffffaa" .. ShaguKill.petRemainingKills .. "|r 只怪") or ("pet: |cffffffaa~" .. ShaguKill.petRemainingKills .. "|r kills."))'),
    ], "ShaguKill")
    trig = os.path.join(addons, "ShaguNotify", "trigger")
    replace_all(os.path.join(trig, "combat_survive.lua"), [
        ('libnotify:ShowPopup("I will survive!"', 'libnotify:ShowPopup((' + ZH + ') and "死里逃生！" or "I will survive!"'),
    ], "ShaguNotify (survive)")
    replace_all(os.path.join(trig, "levelup.lua"), [
        ('libnotify:ShowPopup("Level: " .. arg1', 'libnotify:ShowPopup(((' + ZH + ') and "等级：" or "Level: ") .. arg1'),
    ], "ShaguNotify (level up)")
    replace_all(os.path.join(trig, "exploration.lua"), [
        ('nil, "Discovered")', 'nil, (' + ZH + ') and "发现新区域" or "Discovered")'),
    ], "ShaguNotify (exploration)")
    replace_all(os.path.join(addons, "CleverMacro", "CleverMacro.lua"), [
        ('DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCCCCleverMacro |r" .. VERSION .. "|cFF00CCCC loaded|r")',
         'DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCCCCleverMacro |r" .. VERSION .. ((' + ZH + ') and "|cFF00CCCC 已载入|r" or "|cFF00CCCC loaded|r"))'),
    ], "CleverMacro")


def atlasloot(addons):
    replace_all(os.path.join(addons, "AtlasLoot", "Locale", "locale.cn.lua"), [
        ('["Left-click to open AtlasLoot.\\nMiddle-click for AtlasLoot options.\\nRight-click and drag to move this button."] = true,',
         '["Left-click to open AtlasLoot.\\nMiddle-click for AtlasLoot options.\\nRight-click and drag to move this button."] = "左键打开 AtlasLoot。\\n中键打开 AtlasLoot 设置。\\n右键拖动可移动此按钮。",'),
    ], "AtlasLoot strings")
    path = os.path.join(addons, "AtlasLoot", "TableRegister", "loottables.cn.lua")
    if os.path.isfile(path):
        text = read(path)
        pat = re.compile(r'^(\s*)AtlasLoot_TableNames\["([^"]+)"\]\[1\] = *(".*?");?\s*$', re.M)
        new = pat.sub(r'\1if AtlasLoot_TableNames["\2"] then AtlasLoot_TableNames["\2"][1] = \3 end', text)
        if new != text:
            write(path, new, had_bom(path))
            print("localized AtlasLoot loot table titles")


def main():
    if len(sys.argv) != 2 or not os.path.isdir(sys.argv[1]):
        print(__doc__)
        return 2
    addons = sys.argv[1]
    bagshui(addons)
    supermacro(addons)
    shagu(addons)
    atlasloot(addons)
    return 0


if __name__ == "__main__":
    sys.exit(main())
