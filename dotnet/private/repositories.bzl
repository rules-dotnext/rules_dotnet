def dotnet_repositories():
  native.http_file(
      name = "nuget",
      url = "https://dist.nuget.org/win-x86-commandline/v4.6.2/nuget.exe",
      sha256 = "2c562c1a18d720d4885546083ec8eaad6773a6b80befb02564088cc1e55b304e",
  )
    