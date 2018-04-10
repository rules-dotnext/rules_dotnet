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
