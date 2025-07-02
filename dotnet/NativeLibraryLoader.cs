using System;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;

namespace WurdumRustInterop
{
    public static class NativeLibraryLoader
    {
        static NativeLibraryLoader()
        {
            // Set up custom library resolution
            NativeLibrary.SetDllImportResolver(Assembly.GetExecutingAssembly(), DllImportResolver);
        }

        private static IntPtr DllImportResolver(string libraryName, Assembly assembly, DllImportSearchPath? searchPath)
        {
            if (libraryName != "rustlib")
                return IntPtr.Zero;

            string libraryPath = GetLibraryPath();

            if (!string.IsNullOrEmpty(libraryPath) && File.Exists(libraryPath))
            {
                return NativeLibrary.Load(libraryPath);
            }

            // Fallback to default resolution
            return IntPtr.Zero;
        }

        private static string GetLibraryPath()
        {
            string assemblyLocation = Assembly.GetExecutingAssembly().Location;
            string directory = Path.GetDirectoryName(assemblyLocation) ?? ".";

            string libraryName;
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
            {
                libraryName = "librustlib.so";
            }
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
            {
                libraryName = "librustlib.dylib";
            }
            else
            {
                throw new PlatformNotSupportedException("This platform is not supported");
            }

            // Try multiple locations
            string[] searchPaths = new[]
            {
                Path.Combine(directory, libraryName),
                Path.Combine(directory, "..", "dist", libraryName),
                Path.Combine(Environment.CurrentDirectory, libraryName),
                libraryName
            };

            foreach (var path in searchPaths)
            {
                if (File.Exists(path))
                {
                    Console.WriteLine($"Loading native library from: {Path.GetFullPath(path)}");
                    return path;
                }
            }

            throw new DllNotFoundException($"Could not find {libraryName} in any of the search paths");
        }

        public static void Initialize()
        {
            // Static constructor will run
        }
    }
}
