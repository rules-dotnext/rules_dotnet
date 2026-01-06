"""Well-known protobuf type mappings for C#.

In C#, all well-known types (Timestamp, Duration, Any, Struct, etc.) are
provided by the Google.Protobuf NuGet package. Unlike Go where each WKT
has its own import path, C# uses a single assembly.

The WELL_KNOWN_PROTO_DIR_PREFIX is used to skip code generation for
protos that are already compiled into the Google.Protobuf assembly.
"""

# The directory prefix used to match and skip WKT protos
WELL_KNOWN_PROTO_DIR_PREFIX = "google/protobuf"

def is_well_known_proto(proto_path):
    """Returns True if the given proto import path is a well-known type.

    Args:
        proto_path: The import path of the proto file.

    Returns:
        True if this proto is a well-known type provided by Google.Protobuf.
    """
    return proto_path.startswith(WELL_KNOWN_PROTO_DIR_PREFIX)
