# TFM Compatibility Reference

This is the complete Target Framework Moniker (TFM) compatibility chain as defined in `dotnet/private/common.bzl`. The chain determines which TFMs can be used as dependencies for a given target TFM.

## Compatibility Rules

- A target can depend on libraries targeting the same TFM or any compatible (older) TFM
- Compatibility is transitive: if A is compatible with B, and B is compatible with C, then A is compatible with C
- The TFM transition selects the **highest compatible** framework version

## .NET Standard

```
netstandard
└── netstandard1.0
    └── netstandard1.1
        └── netstandard1.2
            └── netstandard1.3
                └── netstandard1.4
                    └── netstandard1.5
                        └── netstandard1.6
                            └── netstandard2.0
                                └── netstandard2.1
```

**Key insight**: `netstandard2.0` is the universal compatibility target. Libraries targeting `netstandard2.0` can be consumed by:
- All .NET Core 2.0+ / .NET 5.0+ targets
- All .NET Framework 4.6.1+ targets

This is why source generators MUST target `netstandard2.0`.

## .NET Framework (Legacy)

```
net11
└── net20
    └── net30
        └── net35
            └── net40
                └── net403
                    └── net45 ←── netstandard1.1
                        └── net451 ←── netstandard1.2
                            └── net452
                                └── net46 ←── netstandard1.3
                                    └── net461 ←── netstandard2.0
                                        └── net462
                                            └── net47
                                                └── net471
                                                    └── net472
                                                        └── net48
                                                            └── net481
```

## .NET Core / .NET 5+

```
netcoreapp1.0 ←── netstandard1.6
└── netcoreapp1.1
    └── netcoreapp2.0 ←── netstandard2.0
        └── netcoreapp2.1
            └── netcoreapp2.2
                └── netcoreapp3.0 ←── netstandard2.1
                    └── netcoreapp3.1
                        └── net5.0
                            └── net6.0
                                └── net7.0
                                    └── net8.0
                                        └── net9.0
                                            └── net10.0
```

## Default TFM

The default TFM is `net10.0` (set in `common.bzl` as `DEFAULT_TFM`).

## TFM → SDK Version Mapping

| TFM | SDK Version | Notes |
|-----|-------------|-------|
| net10.0 | 10.0.100 | Latest, default |
| net9.0 | 9.0.100 | |
| net8.0 | 8.0.100 | LTS |
| net7.0 | 7.0.100 | End of life |
| net6.0 | 6.0.100 | End of life |
| net5.0 | 5.0.100 | End of life |
| netcoreapp3.1 | 3.1.100 | End of life |

Higher SDK versions can target lower TFMs (e.g., SDK 10.0 can build `net8.0` projects).

## Cross-Family Compatibility

The `←──` arrows in the diagrams above show where framework families connect:

- **net45** can consume **netstandard1.1** libraries
- **net461** can consume **netstandard2.0** libraries
- **netcoreapp2.0** can consume **netstandard2.0** libraries
- **netcoreapp3.0** can consume **netstandard2.1** libraries

## Multi-Targeting

When a project targets multiple TFMs (e.g., `["net8.0", "net6.0", "netstandard2.0"]`), the TFM transition selects the highest compatible version for each consumer:

- A `net8.0` consumer gets the `net8.0` build
- A `net6.0` consumer gets the `net6.0` build
- A `netstandard2.0` consumer gets the `netstandard2.0` build
- A `net7.0` consumer gets the `net6.0` build (highest compatible)

## Framework Preprocessor Symbols

Each TFM automatically defines preprocessor symbols:

| TFM | Symbols Defined |
|-----|----------------|
| net8.0 | `NET8_0`, `NET8_0_OR_GREATER`, `NET7_0_OR_GREATER`, ..., `NET5_0_OR_GREATER`, `NET` |
| netstandard2.0 | `NETSTANDARD2_0`, `NETSTANDARD2_0_OR_GREATER`, ..., `NETSTANDARD` |
| net481 | `NET481`, `NET481_OR_GREATER`, ..., `NETFRAMEWORK` |

These are added automatically by rules_dotnet — do NOT add them to `defines`.
