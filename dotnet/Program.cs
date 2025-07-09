using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Text;

namespace WurdumRustInterop;

// Struct to match Rust's DataWithCallback
[StructLayout(LayoutKind.Sequential)]
internal unsafe struct DataWithCallback
{
    public int* data;
    public int length;
    public delegate* unmanaged[Cdecl]<int, void> callback;
}

// Modern interop with LibraryImport (source generators)
internal static partial class RustInterop
{
    public const string LibraryName = "rustlib";

    // Simple functions using LibraryImport
    [LibraryImport(LibraryName)]
    public static partial int add_numbers(int a, int b);

    [LibraryImport(LibraryName)]
    public static partial ulong fibonacci(uint n);

    // String handling with UTF-8 marshalling
    [LibraryImport(LibraryName)]
    private static partial IntPtr process_string([MarshalAs(UnmanagedType.LPUTF8Str)] string input);

    [LibraryImport(LibraryName)]
    internal static partial void free_rust_string(IntPtr s);

    // Modern callback approach using function pointers
    [LibraryImport(LibraryName)]
    public static unsafe partial int process_data_with_callback(DataWithCallback dataStruct);

    [LibraryImport(LibraryName)]
    public static unsafe partial int sum_with_callback(DataWithCallback dataStruct);

    // Wrapper for safe string handling
    public static string ProcessString(string input)
    {
        var resultPtr = process_string(input);
        if (resultPtr == IntPtr.Zero) return string.Empty;

        try
        {
            unsafe
            {
                var resultUtf8Ptr = (byte*)resultPtr;
                var length = GetUtf8StringLength(resultUtf8Ptr);
                return Encoding.UTF8.GetString(resultUtf8Ptr, length);
            }
        }
        finally
        {
            free_rust_string(resultPtr);
        }

        static unsafe int GetUtf8StringLength(byte* ptr)
        {
            if (ptr == null) return 0;
            var length = 0;
            while (ptr[length] != 0) length++;
            return length;
        }
    }
}

public class Program
{
    static Program()
    {
        // Initialize native library loader
        NativeLibraryLoader.Initialize();
    }

    // Callback implementations with UnmanagedCallersOnly for better performance
    [UnmanagedCallersOnly(CallConvs = [typeof(CallConvCdecl)])]
    private static void ProcessCallbackNative(int value)
    {
        Console.WriteLine($"  → Rust processed value: {value}");
    }

    [UnmanagedCallersOnly(CallConvs = [typeof(CallConvCdecl)])]
    private static void SumCallbackNative(int value)
    {
        Console.WriteLine($"  → Running sum: {value}");
    }

    public static void Main(string[] args)
    {
        Console.WriteLine("=== Wurdum .NET-Rust Interop Demo (Modernized) ===\n");

        // Example 1: Call simple addition function
        int result = RustInterop.add_numbers(5, 7);
        Console.WriteLine($"5 + 7 = {result}");

        // Example 2: Process a string (now with automatic memory management)
        string processedStr = RustInterop.ProcessString("hello from modern dotnet");
        Console.WriteLine($"Processed string: {processedStr}");

        // Example 3: Calculate Fibonacci
        ulong fib = RustInterop.fibonacci(10);
        Console.WriteLine($"Fibonacci(10) = {fib}");

        Console.WriteLine("\n=== Modernized Callback Examples ===");

        // Example 4: Data processing with callback using Span and function pointers
        unsafe
        {
            Console.WriteLine("\nExample 4: Processing data with callback");
            Span<int> data = [1, 2, 3, 4, 5];
            Console.WriteLine($"Original data: [{string.Join(", ", data.ToArray())}]");
            Console.WriteLine("Rust will double each value and call back:");

            fixed (int* dataPtr = data)
            {
                var dataStruct = new DataWithCallback
                {
                    data = dataPtr,
                    length = data.Length,
                    callback = &ProcessCallbackNative
                };

                int processedCount = RustInterop.process_data_with_callback(dataStruct);
                Console.WriteLine($"Processed {processedCount} elements");
            }
        }

        // Example 5: Sum calculation with callback
        unsafe
        {
            Console.WriteLine("\nExample 5: Sum calculation with running totals callback");

            // Using array for larger data that might not fit on stack
            int[] data2 = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
            Console.WriteLine($"Data: [{string.Join(", ", data2)}]");
            Console.WriteLine("Rust will calculate running sums and call back:");

            // Using fixed statement for heap-allocated array
            fixed (int* dataPtr = data2)
            {
                var dataStruct = new DataWithCallback
                {
                    data = dataPtr,
                    length = data2.Length,
                    callback = &SumCallbackNative
                };

                int totalSum = RustInterop.sum_with_callback(dataStruct);
                Console.WriteLine($"Final sum: {totalSum}");
            }
        }

        // Example 6: Advanced - Using CollectionsMarshal for List<T>
        Console.WriteLine("\nExample 6: Using CollectionsMarshal with List<T>");
        unsafe
        {
            var list = new List<int> { 2, 4, 6, 8, 10 };
            var span = CollectionsMarshal.AsSpan(list);

            fixed (int* dataPtr = span)
            {
                var dataStruct = new DataWithCallback
                {
                    data = dataPtr,
                    length = span.Length,
                    callback = &SumCallbackNative
                };

                int sum = RustInterop.sum_with_callback(dataStruct);
                Console.WriteLine($"Sum of list: {sum}");
            }
        }
    }
}
