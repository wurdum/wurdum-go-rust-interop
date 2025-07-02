using System;
using System.Runtime.InteropServices;
using System.Text;

namespace WurdumRustInterop
{
    class Program
    {
        static Program()
        {
            // Initialize native library loader
            NativeLibraryLoader.Initialize();
        }
        // Platform-specific library loading
        private const string LibraryName = "rustlib";

        // Simple functions
        [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
        private static extern int add_numbers(int a, int b);

        [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
        private static extern IntPtr process_string(IntPtr input);

        [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
        private static extern void free_rust_string(IntPtr s);

        [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
        private static extern ulong fibonacci(uint n);

        // Callback delegate types
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate void CallbackDelegate(int value);

        // Struct for data with callback
        [StructLayout(LayoutKind.Sequential)]
        private struct DataWithCallback
        {
            public IntPtr data;
            public int length;
            public IntPtr callback; // Function pointer
        }

        // Functions that use callbacks
        [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
        private static extern int process_data_with_callback(DataWithCallback dataStruct);

        [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
        private static extern int sum_with_callback(DataWithCallback dataStruct);

        // Callback implementations
        private static void ProcessCallback(int value)
        {
            Console.WriteLine($"  → Rust processed value: {value}");
        }

        private static void SumCallback(int value)
        {
            Console.WriteLine($"  → Running sum: {value}");
        }

        static void Main(string[] args)
        {
            Console.WriteLine("=== Wurdum .NET-Rust Interop Demo ===");

            // Example 1: Call simple addition function
            int result = add_numbers(5, 7);
            Console.WriteLine($"5 + 7 = {result}");

            // Example 2: Process a string
            IntPtr inputPtr = Marshal.StringToHGlobalAnsi("hello from dotnet");
            try
            {
                IntPtr processedPtr = process_string(inputPtr);
                string processedStr = Marshal.PtrToStringAnsi(processedPtr);
                Console.WriteLine($"Processed string: {processedStr}");
                free_rust_string(processedPtr);
            }
            finally
            {
                Marshal.FreeHGlobal(inputPtr);
            }

            // Example 3: Calculate Fibonacci
            ulong fib = fibonacci(10);
            Console.WriteLine($"Fibonacci(10) = {fib}");

            Console.WriteLine("\n=== NEW: Callback Examples ===");

            // Example 4: Data processing with callback
            Console.WriteLine("\nExample 4: Processing data with callback");
            int[] data = { 1, 2, 3, 4, 5 };
            Console.WriteLine($"Original data: [{string.Join(", ", data)}]");
            Console.WriteLine("Rust will double each value and call back:");

            // Pin the array and delegate
            GCHandle dataHandle = GCHandle.Alloc(data, GCHandleType.Pinned);
            CallbackDelegate processDelegate = ProcessCallback;
            GCHandle processDelegateHandle = GCHandle.Alloc(processDelegate);

            try
            {
                DataWithCallback dataStruct = new DataWithCallback
                {
                    data = dataHandle.AddrOfPinnedObject(),
                    length = data.Length,
                    callback = Marshal.GetFunctionPointerForDelegate(processDelegate)
                };

                int processedCount = process_data_with_callback(dataStruct);
                Console.WriteLine($"Processed {processedCount} elements");
            }
            finally
            {
                dataHandle.Free();
                processDelegateHandle.Free();
            }

            // Example 5: Sum calculation with callback
            Console.WriteLine("\nExample 5: Sum calculation with running totals callback");
            int[] data2 = { 10, 20, 30, 40 };
            Console.WriteLine($"Data: [{string.Join(", ", data2)}]");
            Console.WriteLine("Rust will calculate running sums and call back:");

            GCHandle data2Handle = GCHandle.Alloc(data2, GCHandleType.Pinned);
            CallbackDelegate sumDelegate = SumCallback;
            GCHandle sumDelegateHandle = GCHandle.Alloc(sumDelegate);

            try
            {
                DataWithCallback dataStruct2 = new DataWithCallback
                {
                    data = data2Handle.AddrOfPinnedObject(),
                    length = data2.Length,
                    callback = Marshal.GetFunctionPointerForDelegate(sumDelegate)
                };

                int totalSum = sum_with_callback(dataStruct2);
                Console.WriteLine($"Final sum: {totalSum}");
            }
            finally
            {
                data2Handle.Free();
                sumDelegateHandle.Free();
            }
        }
    }
}
