#!/usr/bin/env python3
"""Pack HoALauncher into HoALauncher-macos.tar.gz (same shape as tools/linux/pack-launcher.py)."""
import sys
import tarfile

source, target = sys.argv[1], sys.argv[2]
launcher_name = "HoALauncher"

with tarfile.open(target, "w:gz", format=tarfile.PAX_FORMAT) as archive:
    info = archive.gettarinfo(source, arcname=launcher_name)
    info.mode = 0o755
    info.uid = info.gid = 0
    info.uname = info.gname = ""
    info.mtime = 946684800
    with open(source, "rb") as data:
        archive.addfile(info, data)
