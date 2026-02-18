load("@rules_dotnet//dotnet:defs.bzl", "nuget_repo")

def coverlet():
    "coverlet"
    nuget_repo(
        name = "dotnet.coverlet",
        packages = [
            {"name": "coverlet.console", "id": "coverlet.console", "version": "8.0.0", "sha512": "sha512-wYPS2g9CLVdySy9A0MORwCYklMx6d3z0O5DeWLtMDDurmEliicUW9UCGBvlaYNRgnYvHdNzMMtp7LwxIPs3JdQ==", "sources": ["https://api.nuget.org/v3/index.json"], "dependencies": {}, "targeting_pack_overrides": [], "framework_list": [], "tools": {"net8.0": [{"name": "coverlet", "entrypoint": "coverlet.console.dll", "runner": "dotnet"}]}},
        ],
    )
