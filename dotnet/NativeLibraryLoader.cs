using System.Diagnostics.CodeAnalysis;
using System.Reflection;
using System.Runtime.InteropServices;

namespace WurdumRustInterop;

/// <summary>
/// Handles platform-specific loading of the native Rust library with modern .NET features.
/// </summary>
public static class NativeLibraryLoader
{
    private static readonly Lock Lock = new();
    private static bool _initialized;

    static NativeLibraryLoader()
    {
        // Set up custom library resolution
        NativeLibrary.SetDllImportResolver(
            Assembly.GetExecutingAssembly(),
            DllImportResolver);
    }

    private static IntPtr DllImportResolver(
        string libraryName,
        Assembly assembly,
        DllImportSearchPath? searchPath)
    {
        string libraryFile = GetPlatformLibraryName();
        if (!string.Equals(libraryName, libraryFile, StringComparison.Ordinal))
            return IntPtr.Zero;

        if (TryGetLibraryPath(out string? libraryPath))
        {
            try
            {
                IntPtr handle = NativeLibrary.Load(libraryPath);
                Console.WriteLine($"✓ Loaded native library from: {Path.GetFullPath(libraryPath)}");
                return handle;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"✗ Failed to load library from {libraryPath}: {ex.Message}");
            }
        }

        // Fallback to default resolution
        return IntPtr.Zero;
    }

    private static bool TryGetLibraryPath([NotNullWhen(true)] out string? libraryPath)
    {
        libraryPath = null;

        string platformLibraryName = GetPlatformLibraryName();
        string[] searchPaths = GetSearchPaths(platformLibraryName);

        foreach (var path in searchPaths)
        {
            if (File.Exists(path))
            {
                Console.WriteLine($"Found {platformLibraryName} at: {Path.GetFullPath(path)}");
                libraryPath = path;
                return true;
            }
        }

        // Log searched paths for debugging
        Console.WriteLine($"Could not find {platformLibraryName} in any of these locations:");
        foreach (var path in searchPaths)
        {
            Console.WriteLine($"  - {Path.GetFullPath(path)}");
        }

        return false;
    }

    private static string GetPlatformLibraryName()
    {
        if (OperatingSystem.IsWindows())
            return "rustlib.dll";

        if (OperatingSystem.IsLinux())
            return "librustlib.so";

        if (OperatingSystem.IsMacOS())
            return "librustlib.dylib";

        throw new PlatformNotSupportedException($"Platform {RuntimeInformation.OSDescription} is not supported");
    }

    private static string[] GetSearchPaths(string libraryName)
    {
        string assemblyLocation = Assembly.GetExecutingAssembly().Location;
        string directory = !string.IsNullOrEmpty(assemblyLocation)
            ? Path.GetDirectoryName(assemblyLocation)!
            : Environment.CurrentDirectory;

        // Support for different runtime contexts (self-contained, framework-dependent, etc.)
        var searchPaths = new List<string>();

        // Assembly directory
        searchPaths.Add(Path.Combine(directory, libraryName));

        // Current working directory (important when running from dist/)
        searchPaths.Add(Path.Combine(".", libraryName));
        searchPaths.Add(libraryName);

        // Development paths
        searchPaths.Add(Path.Combine(directory, "..", "dist", libraryName));
        searchPaths.Add(Path.Combine(directory, "..", "..", "dist", libraryName));

        // Runtime directory
        if (!string.IsNullOrEmpty(AppContext.BaseDirectory))
        {
            searchPaths.Add(Path.Combine(AppContext.BaseDirectory, libraryName));
            searchPaths.Add(Path.Combine(AppContext.BaseDirectory, "native", libraryName));
        }

        // Current directory (important when running from dist/)
        searchPaths.Add(Path.Combine(Environment.CurrentDirectory, libraryName));
        searchPaths.Add(Path.Combine(Environment.CurrentDirectory, "dist", libraryName));

        // Same directory as the executable
        string? processPath = Environment.ProcessPath;
        if (!string.IsNullOrEmpty(processPath))
        {
            string? processDir = Path.GetDirectoryName(processPath);
            if (!string.IsNullOrEmpty(processDir))
            {
                searchPaths.Add(Path.Combine(processDir, libraryName));
            }
        }

        // System paths (last resort)
        searchPaths.Add(libraryName);

        // Platform-specific paths
        if (OperatingSystem.IsLinux())
        {
            searchPaths.Add("/usr/local/lib/" + libraryName);
            searchPaths.Add("/usr/lib/" + libraryName);
        }
        else if (OperatingSystem.IsMacOS())
        {
            searchPaths.Add("/usr/local/lib/" + libraryName);
            searchPaths.Add("/opt/homebrew/lib/" + libraryName); // Apple Silicon
        }

        return searchPaths.ToArray();
    }

    /// <summary>
    /// Ensures the native library loader is initialized.
    /// This method is thread-safe and idempotent.
    /// </summary>
    public static void Initialize()
    {
        if (_initialized)
            return;

        lock (Lock)
        {
            if (_initialized)
                return;

            // Static constructor will run and set up the resolver
            _initialized = true;

            // Optionally pre-load the library to fail fast
            string libraryFile = GetPlatformLibraryName();
            if (!TryGetLibraryPath(out string? libraryPath) || !NativeLibrary.TryLoad(libraryPath, out _))
            {
                // Try to provide more helpful error message
                string currentDir = Environment.CurrentDirectory;
                string? execDir = Path.GetDirectoryName(Environment.ProcessPath);

                throw new DllNotFoundException(
                    $"Failed to load {libraryFile}. " +
                    $"Ensure the {libraryFile} file is in the correct location.\n" +
                    $"Current directory: {currentDir}\n" +
                    $"Executable directory: {execDir ?? "unknown"}\n" +
                    $"Try placing {libraryFile} in the same directory as the executable.");
            }
        }
    }
}
