# Third-party notices

This project is licensed under the GNU General Public License v3.0 (see `LICENSE`). It builds on or downloads the following projects, each under its own licence.

It is not affiliated with or endorsed by Blizzard Entertainment and contains no Blizzard files: the game client is a build of benilla, which reads the player's own World of Warcraft 1.12.1 data.

| Project | Used for | Licence | Source |
| --- | --- | --- | --- |
| benilla | The game client (submodule `client`, built as `benilla`) | MIT OR Apache-2.0 | https://github.com/samwhosung/benilla |
| Rust crates in the client | Bevy, wgpu, mlua's Lua and the other libraries benilla builds on | Each crate's own licence (MIT, Apache-2.0, MPL-2.0, zlib, BSD and similar) | https://crates.io |
| VMaNGOS | The game server (submodule `server/core`) | GPL-2.0 | https://github.com/vmangos/core |
| VMaNGOS world database | Downloaded by `tools/macos/setup-classic.sh` from the db_latest release | GPL-2.0 | https://github.com/vmangos/core/releases |
| MariaDB Server | The local database (Homebrew) | GPL-2.0 | https://mariadb.org |
| Hordes of Azeroth | The project this one is forked from | GPL-3.0 | https://github.com/jonhaldors/hordes-of-azeroth |

The third-party 1.12 addons (pfUI, pfQuest, Atlas, AtlasLoot, AtlasQuest, Bagshui, ShaguKill, ShaguNotify, SuperMacro, CleverMacro) are not part of this repository: `tools/macos/install-addons.sh` copies them from the player's own addon folder, and each keeps its own licence.

## benilla

benilla is dual-licensed under the MIT licence and the Apache License 2.0; the full Apache text is `LICENSE-APACHE` in the client source.

```
MIT License

Copyright (c) 2026 Sam

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
