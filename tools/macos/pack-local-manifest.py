#!/usr/bin/env python3
"""Build macOS package zips + manifest-macos.json for HoALauncher --source.

Packs whatever local binaries/SQL we have, reuses cached shared zips from
release/cache/packages-v0.6.4 when present, and writes file: URLs that the
launcher resolves via --source <assets-dir>.
"""
from __future__ import annotations

import hashlib
import json
import os
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "release" / "build" / "macos" / "assets"
CACHE = ROOT / "release" / "cache" / "packages-v0.6.4"
# GameVersion.Parse accepts only 2–3 numeric parts (e.g. 0.6.5).
TAG = "v0.6.5"
VERSION = "0.6.5"
# Filename-only: HoALauncher --source copies these from the assets dir by basename.
BASE_URL = "https://local.invalid/hoa-macos"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def content_hash(files: list[tuple[str, str]]) -> str:
    # path:sha256 lines, sorted by path — matches release.ps1
    body = "\n".join(f"{path}:{digest}" for path, digest in sorted(files))
    return hashlib.sha256(body.encode()).hexdigest()


def add_tree(files: list[tuple[Path, str]], src_root: Path, prefix: str) -> None:
    for path in sorted(src_root.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(src_root).as_posix()
        files.append((path, f"{prefix}/{rel}" if prefix else rel))


def write_zip(name: str, entries: list[tuple[Path, str]]) -> dict:
    OUT.mkdir(parents=True, exist_ok=True)
    zip_path = OUT / f"{name}.zip"
    if zip_path.exists():
        zip_path.unlink()
    listed: list[dict] = []
    hashed: list[tuple[str, str]] = []
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for source, target in sorted(entries, key=lambda e: e[1]):
            if not source.is_file():
                raise FileNotFoundError(source)
            digest = sha256_file(source)
            info = zipfile.ZipInfo(target)
            info.date_time = (2000, 1, 1, 0, 0, 0)
            info.compress_type = zipfile.ZIP_DEFLATED
            # preserve exec bit for Mach-O / scripts
            mode = source.stat().st_mode & 0o777
            if mode & 0o111:
                info.external_attr = (0o100755 << 16)
            else:
                info.external_attr = (0o100644 << 16)
            with source.open("rb") as src, zf.open(info, "w") as dst:
                while True:
                    chunk = src.read(1024 * 1024)
                    if not chunk:
                        break
                    dst.write(chunk)
            listed.append({"path": target, "size": source.stat().st_size, "sha256": digest})
            hashed.append((target, digest))
    entry = {
        "name": name.split("-macos")[0] if name.endswith("-macos") else name,
        "release": TAG,
        "url": f"{BASE_URL}/{zip_path.name}",
        "size": zip_path.stat().st_size,
        "sha256": sha256_file(zip_path),
        "contentHash": content_hash(hashed),
        "files": listed,
    }
    print(f"{zip_path.name}: {len(listed)} files, {zip_path.stat().st_size / 1e6:.1f} MB")
    return entry


def reuse_zip(name: str, zip_path: Path) -> dict:
    """Reuse a prebuilt shared zip; still list member digests for Installer integrity."""
    OUT.mkdir(parents=True, exist_ok=True)
    dest = OUT / zip_path.name
    if dest.resolve() != zip_path.resolve():
        dest.write_bytes(zip_path.read_bytes())
    listed: list[dict] = []
    hashed: list[tuple[str, str]] = []
    with zipfile.ZipFile(dest) as zf:
        for info in sorted(zf.infolist(), key=lambda i: i.filename):
            if info.is_dir():
                continue
            data = zf.read(info.filename)
            digest = hashlib.sha256(data).hexdigest()
            listed.append({"path": info.filename, "size": len(data), "sha256": digest})
            hashed.append((info.filename, digest))
    entry = {
        "name": name,
        "release": TAG,
        "url": f"{BASE_URL}/{dest.name}",
        "size": dest.stat().st_size,
        "sha256": sha256_file(dest),
        "contentHash": content_hash(hashed),
        "files": listed,
    }
    print(f"reuse {dest.name}: {len(listed)} files, {dest.stat().st_size / 1e6:.1f} MB")
    return entry


def nav_groups() -> list[dict]:
    """Nav groups without downloads, like release.ps1 when no prebuilt mmaps
    exist: the launcher builds them locally with MoveMapGenerator.
    Set HOA_NO_NAV=1 to skip the "Monster paths" step entirely."""
    if os.environ.get("HOA_NO_NAV") == "1":
        return []
    groups = json.loads((ROOT / "config" / "navtiles.json").read_text())["groups"]
    return [{"name": g["name"], "maps": g["maps"]} for g in groups]


def main() -> None:
    # VERSION marker used by config package
    version_file = ROOT / "release" / "build" / "VERSION"
    version_file.parent.mkdir(parents=True, exist_ok=True)
    version_file.write_text(VERSION + "\n")

    packages: list[dict] = []

    # shared: addon + glue from working tree
    addon_files: list[tuple[Path, str]] = []
    add_tree(addon_files, ROOT / "Interface" / "AddOns" / "HordesOfAzeroth", "Interface/AddOns/HordesOfAzeroth")
    packages.append(write_zip("addon", addon_files))

    glue_files: list[tuple[Path, str]] = []
    add_tree(glue_files, ROOT / "Interface" / "GlueXML", "Interface/GlueXML")
    packages.append(write_zip("glue", glue_files))

    # macos binaries
    packages.append(
        write_zip(
            "launcher-macos",
            [(ROOT / "release/build/macos/launcher/HoALauncher", "HoALauncher")],
        )
    )
    client_entries = [
        (ROOT / "release/build/macos/client/HordesOfAzeroth", "HordesOfAzeroth.arm64"),
        (ROOT / "release/build/client/CLIENT-LICENSES.md", "CLIENT-LICENSES.md"),
        (ROOT / "THIRD-PARTY-NOTICES.md", "THIRD-PARTY-NOTICES.md"),
    ]
    packages.append(write_zip("client-macos", client_entries))

    server_dir = ROOT / "release/build/macos/server"
    server_entries = [
        (server_dir / "bin/mangosd", "server/run/mangosd"),
        (server_dir / "bin/realmd", "server/run/realmd"),
        (server_dir / "bin/libmariadb.dylib", "server/run/libmariadb.dylib"),
        (server_dir / "etc/mangosd.conf.dist", "server/run/mangosd.conf.dist"),
        (server_dir / "etc/realmd.conf.dist", "server/run/realmd.conf.dist"),
    ]
    packages.append(write_zip("server-macos", server_entries))

    ext = server_dir / "bin/Extractors"
    extractors: list[tuple[Path, str]] = []
    for name in (
        "MapExtractor",
        "VMapExtractor",
        "VMapAssembler",
        "MoveMapGenerator",
        "config.json",
        "offmesh.txt",
    ):
        extractors.append((ext / name, f"server/run/Extractors/{name}"))
    packages.append(write_zip("extractors-macos", extractors))

    # config package
    config_entries: list[tuple[Path, str]] = []
    for conf in sorted((ROOT / "config").glob("*.conf")):
        config_entries.append((conf, f"config/{conf.name}"))
    for name in ("mariadb.ini", "create-databases.sql", "navtiles.json"):
        config_entries.append((ROOT / "config" / name, f"config/{name}"))
    config_entries.append((version_file, "VERSION"))
    packages.append(write_zip("config", config_entries))

    # shared SQL packages from cache when available
    for name in ("base-db", "migrations", "world-db"):
        cached = CACHE / f"{name}.zip"
        if not cached.is_file():
            raise SystemExit(f"missing {cached}; run tools/macos/smoke-setup.sh first")
        packages.append(reuse_zip(name, cached))

    # MariaDB third-party
    maria = ROOT / "release/build/macos/mariadb.tar.gz"
    # Installer treats .tar.gz via Platform.IsTarball — keep filename in URL
    maria_dest = OUT / maria.name
    if maria_dest.resolve() != maria.resolve():
        maria_dest.write_bytes(maria.read_bytes())
    third_party = [
        {
            "name": "MariaDB",
            "url": f"{BASE_URL}/{maria_dest.name}",
            "size": maria_dest.stat().st_size,
            "sha256": sha256_file(maria_dest),
            "install": {"unzipTo": "server/mariadb", "stripTopFolder": True},
        }
    ]
    print(f"third-party {maria_dest.name}: {maria_dest.stat().st_size / 1e6:.1f} MB")

    # also ship launcher tarball beside the manifest for distribution smoke
    launcher_tgz = ROOT / "release/build/macos/HoALauncher-macos.tar.gz"
    if launcher_tgz.is_file():
        dest = OUT / launcher_tgz.name
        if dest.resolve() != launcher_tgz.resolve():
            dest.write_bytes(launcher_tgz.read_bytes())

    manifest = {
        "product": "Hordes of Azeroth",
        "version": VERSION,
        "tag": TAG,
        "published": True,
        "minLauncherVersion": "0.1.0",
        "realmName": "Hordes of Azeroth",
        "clientDlls": [],
        "releaseNotes": [
            {
                "version": VERSION,
                "notes": "- Local macOS arm64 packaging smoke (file: assets).",
            }
        ],
        "navTiles": nav_groups(),
        "thirdParty": third_party,
        "packages": packages,
    }
    manifest_path = OUT / "manifest-macos.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"wrote {manifest_path}")
    print(f"run:  {OUT.parent / 'dev-install'}/HoALauncher --source {OUT}")


if __name__ == "__main__":
    main()
