/* Minimal native library for P/Invoke — exercises spec-native-interop #349. */

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default")))
#endif

EXPORT int native_add(int a, int b) {
    return a + b;
}
