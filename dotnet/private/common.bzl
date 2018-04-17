load("//dotnet/private:skylib/lib/paths.bzl", "paths")


def executable_extension(ctx):
  extension = ""
  if ctx.os.name.startswith('windows'):
    extension = ".exe"
  return extension

def bat_extension(ctx):
  extension = ""
  if ctx.os.name.startswith('windows'):
    extension = ".bat"
  return extension

def as_iterable(v):
  if type(v) == "list":
    return v
  if type(v) == "tuple":
    return v
  if type(v) == "depset":
    return v.to_list()
  fail("as_iterator failed on {}".format(v))
