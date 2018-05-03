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
Specifically the :param:`deps` and :param:`transitive` fields on DotnetLibrary_ only work because
it is immutable.

API
---


DotnetLibrary
~~~~~~~~~~~~~

DotnetLibrary is a provider that exposes a compiled library along with it's full transitive
dependencies.
This represents a compile dotnet binary.

+--------------------------------+-----------------------------------------------------------------+
| **Name**                       | **Type**                                                        |
+--------------------------------+-----------------------------------------------------------------+
| :param:`deps`                | :type:`list of DotnetLibrary`                                     |
+--------------------------------+-----------------------------------------------------------------+
| The direct dependencies of this library.                                                         |
+--------------------------------+-----------------------------------------------------------------+
| :param:`transitive`            | :type:`depset of DotnetLibrary`                                 |
+--------------------------------+-----------------------------------------------------------------+
| The full set of transitive dependencies. This includes ``deps`` for this                         |
| library and all ``deps`` members transitively reachable through ``deps``.                        |
+--------------------------------+-----------------------------------------------------------------+

