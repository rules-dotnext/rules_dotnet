load("@rules_dotnet//dotnet:defs.bzl", "nuget_repo")

def coverlet():
    "coverlet"
    nuget_repo(
        name = "dotnet.coverlet",
        packages = [
            {"name": "coverlet.console", "id": "coverlet.console", "version": "6.0.4", "sha512": "sha512-vf8Eso1jIgSdEJ0YJdcx8U4PgZZScdVBpqAejwT0ZEic+aYnzXpQ3juPzhmn0tvTXmlNLnGpsxCfnUyRbJJrcQ==", "sources": ["https://api.nuget.org/v3/index.json"], "dependencies": {}, "targeting_pack_overrides": [], "framework_list": [], "tools": {"net6.0": [{"name": "coverlet", "entrypoint": "coverlet.console.dll", "runner": "dotnet"}]}},
        ],
    )
