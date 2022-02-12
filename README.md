# TODO: Rewrite this readme
.Net Rules for Bazel
===================
[![Gitpod ready-to-code](https://img.shields.io/badge/Gitpod-ready--to--code-908a85?logo=gitpod)](https://gitpod.io/#https://github.com/bazelbuild/rules_dotnet)

Build status
------------

  | Bazel CI |
  | --------------- |
  | [![Build status](https://badge.buildkite.com/703775290818dcb2af754f503ed54dc11bb124fce2a6bf1606.svg?branch=master)](https://buildkite.com/bazel/rules-dotnet-edge)|


Documentation
-------------
TODO: Rewrite this section

Overview
--------

This is a minimal viable set of C#/F# bindings for building C#/F# code with
[Core](https://en.wikipedia.org/wiki/.NET_Core)

Caveats
-------

[Bazel](https://bazel.build/) creates long paths. Therefore it is recommended to increase the length limit 
using newer version of Windows. Please see 
[here](https://docs.microsoft.com/en-us/windows/desktop/fileio/naming-a-file#maximum-path-length-limitation).

However, some Windows programs do not handle long path names. Most notably - Microsoft 
C compiler (cl.exe). Therefore TMP env variable should be set to something 
short (like X:\\ or c:\\TEMP). 

[Bazel](https://bazel.build/) and dotnet_rules rely on symbolic linking. On Windows it, typically, requires 
elevated permissions. However, newer versions of Windows have a [workaround](https://blogs.windows.com/buildingapps/2016/12/02/symlinks-windows-10/#IJuxPHWEkSSRqC7w.97).

Setup
-----
TODO: Rewrite this section
