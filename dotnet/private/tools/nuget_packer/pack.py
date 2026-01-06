"""Assembles a .nupkg file from constituent parts.

Usage: pack.py --output <nupkg> --nuspec <nuspec> --nuspec-path-in-pkg <rel> --files <rel>=<src> ...
"""

import argparse
import os
import zipfile

# OPC content types required by NuGet
CONTENT_TYPES_XML = """\
<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml" />
  <Default Extension="nuspec" ContentType="application/octet" />
  <Default Extension="dll" ContentType="application/octet" />
  <Default Extension="xml" ContentType="application/octet" />
  <Default Extension="pdb" ContentType="application/octet" />
</Types>
"""

RELS_XML = """\
<?xml version="1.0" encoding="utf-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Type="http://schemas.microsoft.com/packaging/2010/07/manifest" Target="/{nuspec}" Id="nuspec_rel" />
</Relationships>
"""


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    parser.add_argument("--nuspec", required=True)
    parser.add_argument("--nuspec-path-in-pkg", required=True,
                        help="Relative path of .nuspec inside the nupkg")
    parser.add_argument("--files", action="append", default=[],
                        help="relative_path=source_path pairs")
    args = parser.parse_args()

    with zipfile.ZipFile(args.output, "w", zipfile.ZIP_DEFLATED) as zf:
        # Write [Content_Types].xml
        zf.writestr("[Content_Types].xml", CONTENT_TYPES_XML)

        # Write _rels/.rels
        zf.writestr(
            "_rels/.rels",
            RELS_XML.format(nuspec=args.nuspec_path_in_pkg),
        )

        # Write the .nuspec
        zf.write(args.nuspec, args.nuspec_path_in_pkg)

        # Write all other files
        for file_spec in args.files:
            rel_path, src_path = file_spec.split("=", 1)
            zf.write(src_path, rel_path)


if __name__ == "__main__":
    main()
