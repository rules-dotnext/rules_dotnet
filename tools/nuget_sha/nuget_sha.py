"""Fetch a NuGet package and print its SRI SHA-512 hash.

Usage:
    bazel run //tools/nuget_sha -- <PackageId> <Version>

Example:
    bazel run //tools/nuget_sha -- Newtonsoft.Json 13.0.3
    # prints: sha512-mbJSvHfRxfX3tR/U6n1WU+mWHXswYc+SB/hkOpx8yZZe68hNZGfymJu0cjsaJEkVzCMqePiU6LdIyogqfIn7kg==
"""

import base64
import hashlib
import sys
import urllib.request


def main():
    if len(sys.argv) != 3:
        print("Usage: nuget_sha <PackageId> <Version>", file=sys.stderr)
        sys.exit(1)

    package_id = sys.argv[1]
    version = sys.argv[2]

    url = (
        f"https://api.nuget.org/v3-flatcontainer"
        f"/{package_id.lower()}/{version}/{package_id.lower()}.{version}.nupkg"
    )

    try:
        with urllib.request.urlopen(url) as resp:
            data = resp.read()
    except urllib.error.HTTPError as e:
        print(f"Error: failed to download {url}: {e}", file=sys.stderr)
        sys.exit(1)

    digest = hashlib.sha512(data).digest()
    sri = "sha512-" + base64.b64encode(digest).decode("ascii")
    print(sri)


if __name__ == "__main__":
    main()
