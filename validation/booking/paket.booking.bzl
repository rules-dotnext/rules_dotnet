"""NuGet package declarations for booking-microservices validation.

Hand-written with a representative subset of packages from the
booking-microservices BuildingBlocks project. Full compilation of
the entire project would require 100+ packages with their full
transitive dependency graphs.

This subset demonstrates:
- rules_dotnet nuget_repo works with real NuGet packages
- Package dependency declarations with TFM-specific deps
- SHA-512 hash verification
"""

load("@rules_dotnet//dotnet:defs.bzl", "nuget_repo")

def booking():
    nuget_repo(
        name = "paket.booking",
        packages = [
            # --- MediatR: CQRS/Mediator pattern (core dependency) ---
            {
                "name": "MediatR",
                "id": "MediatR",
                "version": "14.0.0",
                "sha512": "sha512-iWd6g0OSjwiQ39sLvq5njOH1fgajXkC/LjvWM6Na6oXa9MncaLdHdltDPMwYz1qE1qRYVVtQjf0AADMAzNRiDQ==",
                "sources": ["https://api.nuget.org/v3/index.json"],
                "dependencies": {
                    "net10.0": [
                        "MediatR.Contracts",
                        "Microsoft.Extensions.DependencyInjection.Abstractions",
                    ],
                },
                "targeting_pack_overrides": [],
                "framework_list": [],
            },
            {
                "name": "MediatR.Contracts",
                "id": "MediatR.Contracts",
                "version": "2.0.1",
                "sha512": "sha512-cafpnzMGRUPAmTB4RMXnd+1veuUCgiseg/tU4SFF7NO2GQGwh2sGbr41ZZPHouMcJjYyptKJnms7V3/XeSThcw==",
                "sources": ["https://api.nuget.org/v3/index.json"],
                "dependencies": {
                    "netstandard2.0": [],
                },
                "targeting_pack_overrides": [],
                "framework_list": [],
            },
            # --- Microsoft.Extensions.DependencyInjection.Abstractions ---
            {
                "name": "Microsoft.Extensions.DependencyInjection.Abstractions",
                "id": "Microsoft.Extensions.DependencyInjection.Abstractions",
                "version": "10.0.0",
                "sha512": "sha512-R1JUmDhx81zXARj7/3QwSexiO9lNE2PBPXyK47sblSGIOl4Jd60iLY8wtmJ/NzhpXtPBiSOTMn2KFYuf7QaRIw==",
                "sources": ["https://api.nuget.org/v3/index.json"],
                "dependencies": {
                    "net10.0": [],
                    "net9.0": [],
                    "net8.0": [],
                    "netstandard2.1": [],
                    "netstandard2.0": [],
                },
                "targeting_pack_overrides": [],
                "framework_list": [],
            },
            # --- Microsoft.Extensions.Logging.Abstractions ---
            {
                "name": "Microsoft.Extensions.Logging.Abstractions",
                "id": "Microsoft.Extensions.Logging.Abstractions",
                "version": "10.0.0",
                "sha512": "sha512-CElGLz6i7loG2KuKixPwXzz0Zt5m67xqCpysS+/JHOsYCuA8QgiasMp6Jsp/5bTtGo9z4jXhMI2Zl8lSnDad0Q==",
                "sources": ["https://api.nuget.org/v3/index.json"],
                "dependencies": {
                    "net10.0": [],
                    "net9.0": [],
                    "net8.0": [],
                    "netstandard2.0": [],
                },
                "targeting_pack_overrides": [],
                "framework_list": [],
            },
            # --- Newtonsoft.Json: JSON serialization ---
            {
                "name": "Newtonsoft.Json",
                "id": "Newtonsoft.Json",
                "version": "13.0.4",
                "sha512": "sha512-bR+v+E/yJ6g7GV2uXw2OrUSjYYfjLkOLC8JD4kCS23msLapnKtdJPBJA75fwHH++ErIffeIqzYITLxAur4KAXA==",
                "sources": ["https://api.nuget.org/v3/index.json"],
                "dependencies": {
                    "net6.0": [],
                    "netstandard2.0": [],
                },
                "targeting_pack_overrides": [],
                "framework_list": [],
            },
            # --- FluentValidation: validation framework ---
            {
                "name": "FluentValidation",
                "id": "FluentValidation",
                "version": "12.1.1",
                "sha512": "sha512-5Y2Ck1Clwnlz5gLNHtQr7FaHr+bvTDvj+J6HJ+RDyjYhgmOCMCSKm2aNY3ysMSym+Adk2yeTW/p7qKyN8e2BPQ==",
                "sources": ["https://api.nuget.org/v3/index.json"],
                "dependencies": {
                    "net8.0": [],
                    "netstandard2.1": [],
                    "netstandard2.0": [],
                },
                "targeting_pack_overrides": [],
                "framework_list": [],
            },
            # --- Humanizer.Core: string humanization ---
            {
                "name": "Humanizer.Core",
                "id": "Humanizer.Core",
                "version": "3.0.1",
                "sha512": "sha512-lcQ2HfNqHljfbalRLMKc8j4M0Og3qIvMSeyLp7KY58aCcgcZwiR0s5Uf2vrJ3p7OFGoWjcgbWATTpxqzrbuBSw==",
                "sources": ["https://api.nuget.org/v3/index.json"],
                "dependencies": {
                    "net8.0": [],
                    "netstandard2.0": [],
                },
                "targeting_pack_overrides": [],
                "framework_list": [],
            },
            # --- Mapster: object mapping ---
            {
                "name": "Mapster",
                "id": "Mapster",
                "version": "7.4.0",
                "sha512": "sha512-e+7Vqu/4Wz1SOJcicxGbYL6QkOnD5f2NQgf/wn1ZnwbQsoCI46bZLuIGDWkf28jx3vgOPrJbUEs/rCFnQ7lNbw==",
                "sources": ["https://api.nuget.org/v3/index.json"],
                "dependencies": {
                    "netstandard2.0": ["Mapster.Core"],
                },
                "targeting_pack_overrides": [],
                "framework_list": [],
            },
            # --- IdGen: distributed ID generation ---
            {
                "name": "IdGen",
                "id": "IdGen",
                "version": "3.0.7",
                "sha512": "sha512-NIjdUOjt1gZbRPODrnHL7YZYZw794ESIP7nolSfPdDUabzD/vW/v/TcCAp0L5c91e6uqI3CzLWnnICBfV/8S2w==",
                "sources": ["https://api.nuget.org/v3/index.json"],
                "dependencies": {
                    "netstandard2.1": [],
                },
                "targeting_pack_overrides": [],
                "framework_list": [],
            },
            # --- Polly: resilience/retry policies ---
            {
                "name": "Polly",
                "id": "Polly",
                "version": "8.6.5",
                "sha512": "sha512-ELlRs71GW+fPR1ehXUsAh6B20/89vzfFWTP+htAkTHNYnPPUqtg6vz0kpKTEa0IwRYIzHyoZr9vzCwlxDuRNlg==",
                "sources": ["https://api.nuget.org/v3/index.json"],
                "dependencies": {
                    "net8.0": ["Polly.Core"],
                    "netstandard2.0": ["Polly.Core"],
                },
                "targeting_pack_overrides": [],
                "framework_list": [],
            },
        ],
    )
