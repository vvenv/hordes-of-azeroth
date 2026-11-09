# macOS Support Plan

Fork: `vvenv/hordes-of-azeroth` (from `jonhaldors/hordes-of-azeroth`)  
Client fork: `vvenv/hordes-of-azeroth-client`  
Server fork: `vvenv/hordes-of-azeroth-server`  
Host: Apple Silicon (arm64), macOS 26.x  

## Local paths

| Role | Path |
| --- | --- |
| Repo | `/Users/liwenfu/vvenv/hordes-of-azeroth` |
| WoW tooling / launcher tree | `/Users/liwenfu/vvenv/wow` |
| Game + server data | `/Users/liwenfu/vvenv/wow-data` |
| enUS 1.12.1 client | `/Users/liwenfu/vvenv/wow-data/client` → `vmangos-deploy/storage/mangosd/client-data` |
| zhCN 1.12.1 client | `/Users/liwenfu/vvenv/wow-data/client-zhCN` |

HoA upstream asks for enUS build 5875. Spike uses the enUS tree via symlink into the repo; `WOW_DATA` points at its `Data` folder.

## Goal

Ship a playable **macOS arm64 beta** with the same Install → Play loop as Linux:

- `HoALauncher-macos.tar.gz`
- `manifest-macos.json`
- packages: launcher, client, server, extractors + shared addon/glue/db/navmesh

Non-goals for v1: notarization, Intel Mac, Wine, gameplay changes.

## Why this shape

Linux already added a parallel OS path:

- `tools/build-linux.ps1` + `tools/linux/build.sh`
- `config/release.json` `os: linux` packages
- `manifest-linux.json`
- launcher `Platform` currently treats non-Windows as Linux

macOS is the same pattern with a third OS state (Mach-O, Metal/wgpu, `open`, portable MariaDB).

## Phases

### Phase 0 — Spike (gate)

Manual build on this Mac, no launcher:

1. Client: `cargo build --profile ship -p hoa --no-default-features` with `WOW_DATA`
2. Server: CMake build of `mangosd` / `realmd` + Extractors on Darwin
3. MariaDB: pick a portable macOS arm64 layout under `server/mariadb`
4. Run DB → realmd → mangosd → client into one session

Hard stops: wgpu/Metal crash, MoveMapGenerator broken, process/window startup assumptions, unsigned binary UX only if it blocks install.

### Phase 1 — Launcher tri-state

Change `tools/launcher` so non-Windows is not assumed Linux:

- `Platform.cs`: `IsMac`, manifest name, `open`, Mach-O exec bit
- `osx-arm64` publish
- `GameClient.cs`: no `MainWindowHandle` wait; Metal backend env if needed
- `LocalServer.cs` / folder helpers: Darwin binary and dylib paths
- Loc + README beta copy

### Phase 2 — Build + release

- `tools/macos/build.sh` (server + client, `@loader_path` / `install_name_tool`)
- `config/release.json` MariaDB + packages for `os: macos`
- CI on `macos-14` (or local pack script) → release assets
- `manifest-macos.json` + launcher tarball

### Phase 3 — Playtest

Fresh install, navmesh download/fallback build, solo run, coop host/join, controller, sleep/wake, update/backup, Gatekeeper notes (`xattr` quarantine).

### Phase 4 — Docs

README Mac badge + install, FAQ, `BUILDING.md` Darwin notes, Discord / issue pointer.

## Working order (this fork)

1. Symlink WoW client data into the repo / set `WOW_DATA`
2. Point submodules at `vvenv/*` forks when pushing submodule changes
3. Land Phase 0 evidence in this doc’s “Spike log”
4. Implement Phase 1/2 against the Linux templates

## Spike log

- 2026-11-09: Forked `vvenv/hordes-of-azeroth`, `-client`, `-server`.
- Linked repo `Data` / `WoW.exe` → `../wow-data/client`.
- enUS `Data` is missing `base.MPQ` (zhCN tree has it). Track as data risk if client boot fails.
- Official MariaDB 11.4.13 archive has **no macOS bintar** (only linux + winx64). Packaging via `tools/macos/pack-mariadb.sh` from Homebrew (`mariadb` 13.0.2 bottle eventually installed).
- Launcher `osx-arm64` publish OK (`release/build/macos/launcher/HoALauncher`).
- Submodules checked out; client `cargo build --profile ship -p hoa` in progress.
- Server CMake configures on Darwin with Homebrew MariaDB + OpenSSL.
- Fix required: `BonkIntegrity.cpp` used Linux `<link.h>` / `dl_iterate_phdr` — gated to `__linux__`; macOS FindCodeRanges is a no-op for now.
- `FindMySQL.cmake` gained Homebrew `mariadb` / `mariadb-connector-c` paths.
- Server **builds and runs** on Darwin: `realmd` :3724 and `mangosd` :8085 came up against imported `packages-v0.6.4` SQL + reused extracted maps from `wow-data`.
- MariaDB: live Homebrew prefix works; first `pack-mariadb.sh` rsync tree got `mariadbd` SIGKILL on bootstrap — switched packer to `ditto` of the Cellar.
- `mangosd` exits if stdin hits EOF (no TTY). `tools/macos/start-server.sh` keeps a FIFO open.
- Account `PLAYER` / `player` (GM 6) inserted with SRP6 verifier matching launcher `CoopAccounts`.
- Client `ship` binary built (124MB arm64). Launches on Metal, loads GlueXML / world catalogs without `base.MPQ`.
- Auth smoke: mangosd `account create PLAYER player` works; client authenticates and reaches realm list (`1 realm published`). Earlier hand-rolled SRP insert was wrong.
- Auth + realm select OK with `WOW_REALM="Hordes of Azeroth"`; char select shows 0 heroes.
- Ship profile builds `--no-default-features` so `WOW_RIG` is absent; need a `cargo build --release -p hoa` (default `dev` features) to auto-create a body for enter-world smoke.
- Glue stubs: write `BonkAccount.lua` / `BonkStats.lua` locally (gitignored). zhCN + enUS `FRIZQT__.TTF` → missing CJK glyphs; smoke with `HOA_LANGUAGE=enUS`.
- `tools/macos/smoke-client.sh` wraps the unattended env.
- **Enter-world smoke OK** (2026-11-09): release+dev client + `.probe-identity` + stock glue (BonkGlue temporarily stripped) + `WOW_RIG="human warrior 1"` → created `Humwarsmoke`, `net: in world as Humwarsmoke`, preflight on **GM Island**.
- BonkGlue blocks stock `WOW_RIG` create/select presses; use `HOA_STOCK_GLUE=1` for first create, then restore Bonk for HoA hero UI.
- Ship (`--no-default-features`) still the player binary; release+dev is the probe/smoke binary.
- **BonkGlue enter-world OK** (2026-11-09): full GlueXML toc + `WOW_CHAR=Humwarsmoke` → `net: in world as Humwarsmoke` through Bonk hero UI. Unattended smokes need `BENILLA_HOME=<repo>/benilla-config` (now default in `smoke-client.sh`) so `Interface\AddOns\HordesOfAzeroth\Textures\*` resolve; without it glue pad textures warn and stay green.
- Launcher Phase 1 code already tri-state (`Platform.IsMac`, Metal `WGPU_BACKEND`, Mach-O exec bit, `manifest-macos.json`).
- **Install layout stage OK** (2026-11-09): `tools/macos/pack-launcher.py` → `HoALauncher-macos.tar.gz` (~42 MB); `tools/macos/stage-dev-install.sh` lays launcher + ship client + server + MariaDB + Glue/AddOns into `release/build/macos/dev-install` (Data/WoW.exe symlinked from wow-data). Staged ship client + `WOW_CHAR=Humwarsmoke` entered world against the live local realm.
- Remaining for shippable beta: `manifest-macos.json` via `tools/release.ps1` (needs `pwsh`), Gatekeeper/`xattr` notes, and a full launcher GUI Install→Play on a clean folder.
