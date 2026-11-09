using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Formats.Tar;

namespace HordesOfAzeroth.Launcher
{
    static class Platform
    {
        const UnixFileMode Executable = UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute
            | UnixFileMode.GroupRead | UnixFileMode.GroupExecute | UnixFileMode.OtherRead | UnixFileMode.OtherExecute;
        static readonly byte[] ElfMagic = { 0x7F, (byte)'E', (byte)'L', (byte)'F' };
        static readonly byte[] MachOBe = { 0xFE, 0xED, 0xFA, 0xCE };
        static readonly byte[] MachOLe = { 0xCE, 0xFA, 0xED, 0xFE };
        static readonly byte[] MachO64Be = { 0xFE, 0xED, 0xFA, 0xCF };
        static readonly byte[] MachO64Le = { 0xCF, 0xFA, 0xED, 0xFE };
        static readonly byte[] MachOFat = { 0xCA, 0xFE, 0xBA, 0xBE };
        static readonly byte[] MachOFat64 = { 0xCA, 0xFE, 0xBA, 0xBF };

        public static bool IsWindows => OperatingSystem.IsWindows();
        public static bool IsMac => OperatingSystem.IsMacOS();
        public static bool IsLinux => OperatingSystem.IsLinux();

        public static bool HasTray => IsWindows;

        public static string ManifestName => IsWindows ? "manifest.json" : IsMac ? "manifest-macos.json" : "manifest-linux.json";

        public static string SystemName => IsWindows ? "Windows" : IsMac ? "macOS" : "Linux";

        public static string PackageOs => IsWindows ? "windows" : IsMac ? "macos" : "linux";

        public static string Exe(string name) => IsWindows ? name + ".exe" : name;

        public static void OpenFolder(string path) => Open(path);

        public static void OpenUrl(string url) => Open(url);

        public static void ShowFile(string file)
        {
            if (IsMac)
            {
                TryStart(new ProcessStartInfo("open") { ArgumentList = { "-R", file }, UseShellExecute = false });
                return;
            }
            if (!IsWindows)
            {
                Open(Path.GetDirectoryName(file));
                return;
            }
            if (!TryStart(new ProcessStartInfo("explorer.exe", "/select,\"" + file + "\"") { UseShellExecute = true }))
                Open(Path.GetDirectoryName(file));
        }

        static void Open(string target)
        {
            if (IsMac)
            {
                TryStart(new ProcessStartInfo("open") { ArgumentList = { target }, UseShellExecute = false });
                return;
            }
            if (!IsWindows)
            {
                TryStart(new ProcessStartInfo("xdg-open") { ArgumentList = { target }, UseShellExecute = false });
                return;
            }
            if (!TryStart(new ProcessStartInfo(target) { UseShellExecute = true }))
                TryStart(new ProcessStartInfo("explorer.exe") { ArgumentList = { target }, UseShellExecute = false });
        }

        static bool TryStart(ProcessStartInfo info)
        {
            try
            {
                Process.Start(info)?.Dispose();
                return true;
            }
            catch (Exception error) when (error is System.ComponentModel.Win32Exception || error is InvalidOperationException || error is PlatformNotSupportedException || error is IOException)
            {
                Console.Error.WriteLine($"Couldn't open {info.FileName} {info.Arguments}: {error.Message}");
                return false;
            }
        }

        public static void MarkExecutableIfProgram(string file)
        {
            if (IsWindows)
                return;
            if (!(IsElf(file) || IsMachO(file)))
                return;
            SetUnixExecutable(file);
        }

        [System.Runtime.Versioning.UnsupportedOSPlatform("windows")]
        static void SetUnixExecutable(string file) => File.SetUnixFileMode(file, Executable);

        static bool IsElf(string file) => StartsWithMagic(file, ElfMagic);

        static bool IsMachO(string file) =>
            StartsWithMagic(file, MachOLe) || StartsWithMagic(file, MachOBe)
            || StartsWithMagic(file, MachO64Le) || StartsWithMagic(file, MachO64Be)
            || StartsWithMagic(file, MachOFat) || StartsWithMagic(file, MachOFat64);

        static bool StartsWithMagic(string file, byte[] magic)
        {
            byte[] head = new byte[magic.Length];
            using (FileStream stream = File.OpenRead(file))
                if (stream.Read(head, 0, head.Length) < head.Length)
                    return false;
            for (int i = 0; i < magic.Length; i++)
                if (head[i] != magic[i])
                    return false;
            return true;
        }

        public static bool IsTarball(string file) => file.EndsWith(".tar.gz", StringComparison.OrdinalIgnoreCase) || file.EndsWith(".tgz", StringComparison.OrdinalIgnoreCase);

        public static void ExtractTarball(string tarball, string targetDir, bool stripTopFolder)
        {
            string root = Path.GetFullPath(targetDir).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            using (FileStream file = File.OpenRead(tarball))
            using (GZipStream gzip = new GZipStream(file, CompressionMode.Decompress))
            using (TarReader reader = new TarReader(gzip))
            {
                TarEntry entry;
                while ((entry = reader.GetNextEntry()) != null)
                {
                    string relative = entry.Name.TrimStart('.', '/');
                    if (stripTopFolder)
                    {
                        int slash = relative.IndexOf('/');
                        if (slash < 0)
                            continue;
                        relative = relative.Substring(slash + 1);
                    }
                    if (relative.Length == 0)
                        continue;
                    string target = Path.GetFullPath(Path.Combine(root, relative));
                    if (!target.StartsWith(root, StringComparison.Ordinal))
                        throw new InvalidDataException(Loc.T("{0} contains a path outside the game folder.", Path.GetFileName(tarball)));
                    switch (entry.EntryType)
                    {
                        case TarEntryType.Directory:
                            Directory.CreateDirectory(target);
                            break;
                        case TarEntryType.SymbolicLink:
                            Directory.CreateDirectory(Path.GetDirectoryName(target));
                            if (File.Exists(target) || Directory.Exists(target))
                                File.Delete(target);
                            File.CreateSymbolicLink(target, entry.LinkName);
                            break;
                        case TarEntryType.RegularFile:
                        case TarEntryType.V7RegularFile:
                            Directory.CreateDirectory(Path.GetDirectoryName(target));
                            entry.ExtractToFile(target, true);
                            break;
                    }
                }
            }
        }
    }
}
