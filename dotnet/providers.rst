Dotnet providers
================

.. _providers: https://docs.bazel.build/versions/master/skylark/rules.html#providers
.. _runfiles: https://docs.bazel.build/versions/master/skylark/lib/runfiles.html
.. _File: https://docs.bazel.build/versions/master/skylark/lib/File.html

.. role:: param(emphasis)
.. role:: type(emphasis)
.. role:: value(code)
.. |mandatory| replace:: **mandatory value**


The providers_ are the outputs of the rules, you generaly get them by having a dependency on a rule,
and then asking for a provider of a specific type.

.. contents:: :depth: 2

-----

Design
------

The Dotnet providers are designed primarily for the efficiency of the Dotnet rules, the information
they share is mostly there because it is required for the core rules to work.

All the providers are designed to hold only immutable data. This is partly because its a cleaner
design choice to be able to assume a provider will never change, but also because only immutable
objects are allowed to be stored in a depset, and it's really useful to have depsets of providers.
Specifically the :param:`direct` and :param:`transitive` fields on DotnetLibrary_ only work because
it is immutable.

API
---


DotnetSource
~~~~~~~~~~~~

DotnetSource represents a set of source files, ready to build a DotnetLibrary. In general, 
only rules_dotnet should need to build or handle these.

+--------------------------------+-----------------------------------------------------------------+
| **Name**                       | **Type**                                                        |
+--------------------------------+-----------------------------------------------------------------+
| :param:`srcs`                  | :type:`list of File`                                            |
+--------------------------------+-----------------------------------------------------------------+
| The sources to compile into the archive.                                                         |
+--------------------------------+-----------------------------------------------------------------+
| :param:`deps`                  | :type:`list of DotnetLibrary`                                   |
+--------------------------------+-----------------------------------------------------------------+
| The direct dependencies needed by the :param:`srcs`.                                             |
+--------------------------------+-----------------------------------------------------------------+
| :param:`extra_opts`             | :type:`list of string`                                         |
+--------------------------------+-----------------------------------------------------------------+
| Compilation options that should be used when compiling these sources.                            |
+--------------------------------+-----------------------------------------------------------------+
| :param:`runfiles`              | :type:`Runfiles`                                                |
+--------------------------------+-----------------------------------------------------------------+
| The set of files needed by code in these sources at runtime.                                     |
+--------------------------------+-----------------------------------------------------------------+


DotnetLibrary
~~~~~~~~~~~~~

DotnetLibrary is a provider that exposes a compiled library along with it's full transitive
dependencies.
This represents a compile dotnet binary.

+--------------------------------+-----------------------------------------------------------------+
| **Name**                       | **Type**                                                        |
+--------------------------------+-----------------------------------------------------------------+
| :param:`source`                | :type:`DotnetSource`                                            |
+--------------------------------+-----------------------------------------------------------------+
| The source provider this DotnetLibrary was compiled from.                                        |
+--------------------------------+-----------------------------------------------------------------+
| :param:`direct`                | :type:`list of DotnetLibrary`                                   |
+--------------------------------+-----------------------------------------------------------------+
| The direct dependencies of this archive.                                                         |
+--------------------------------+-----------------------------------------------------------------+
| :param:`transitive`            | :type:`depset of DotnetLibrary`                                 |
+--------------------------------+-----------------------------------------------------------------+
| The full set of transitive dependencies. This includes ``direct`` for this                       |
| library and all ``direct`` members transitively reachable through ``direct``.                    |
+--------------------------------+-----------------------------------------------------------------+
| :param:`runfiles`              | runfiles_                                                       |
+--------------------------------+-----------------------------------------------------------------+
| The files needed to run anything that includes this library.                                     |
+--------------------------------+-----------------------------------------------------------------+

