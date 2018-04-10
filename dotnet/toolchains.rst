Dotnet toolchains
=================
The design and implementation is heavily based on rules_go toolchains.

-----

Design
------

The Dotnet toolchain consists of three main layers, `the sdk`_ and `the toolchain`_ and `the context`_.

The SDK
~~~~~~~

At the bottom is the Mono MDK.

This is always bound to ``@dotnet_sdk`` and can be referred to directly if needed, but in general
you should always access it through the toolchain.

The dotnet_download_sdk_, dotnet_host_sdk_ and dotnet_local_sdk_ family of rules are responsible for downloading
these, and adding just enough of a build file to expose the contents to Bazel.

If you don't do anything special, the Dotnet rules will download the most recent official SDK for
your host (if available).
If you need a `forked version of Dotnet`_\, want to `control the version`_ or just use the
`installed sdk`_ then it is easy to do, you just need to make sure you have bound the dotnet_sdk
repository before you call dotnet_register_toolchains_.

The toolchain
~~~~~~~~~~~~~

This a wrapper over the sdk that provides enough extras to match, target and work on a specific
platforms. It should be considered an opaqute type, you only ever use it through `the context`_.

Declaration
^^^^^^^^^^^

Toolchains are declared using the dotnet_toolchain_ macro.

Toolchains are pre-declared for all the known combinations of host and target, and the names
are a predictable
"<**host**>"
So for instance if the rules_dotnet repository is loaded with
it's default name, the following toolchain labels (along with many others) will be available

.. code::

  @io_bazel_rules_dotnet//dotnet/toolchain:linux_amd64
  
The toolchains are not usable until you register_ them.

Registration
^^^^^^^^^^^^

Normally you would just call dotnet_register_toolchains_ from your WORKSPACE to register all the
pre-declared toolchains, and allow normal selection logic to pick the right one.

It is fine to add more toolchains to the available set if you like. Because the normal
toolchain matching mechanism prefers the first declared match, you can also override individual
toolchains by declaring and registering toolchains with the same constraints *before* calling
dotnet_register_toolchains_.

If you wish to have more control over the toolchains you can instead just make direct
calls to register_toolchains_ with only the toolchains you wish to install. You can see an
example of this in `limiting the available toolchains`_.


The context
~~~~~~~~~~~

This is the type you use if you are writing custom rules that need dotnet toochain.

Use
^^^

If you are writing a new rule that wants to use the Dotnet toolchain, you need to do a couple of things.
First, you have to declare that you want to consume the toolchain on the rule declaration.
The easiest way to do this is to use the dotnet_rule wrapper, which adds in the toolchain and some
hidden attributes that it consumes.

.. code:: bzl

  load("@io_bazel_rules_dotnet//dotnet:def.bzl", "dotnet_context", "dotnet_rule")

  my_rule = dotnet_rule(
      _my_rule_impl,
      attrs = {
          ...
      },
  )

And then in the rule body, you need to get the toolchain itself and use it's action generators.

.. code:: bzl

  def _my_rule_impl(ctx):
    dotnet = dotnet_context(ctx)


Customizing
-----------

Normal usage
~~~~~~~~~~~~

This is an example of normal usage for the other examples to be compared against.

WORKSPACE
^^^^^^^^^

.. code:: bzl

    load("@io_bazel_rules_dotnet//dotnet:def.bzl", "dotnet_rules_dependencies", "dotnet_register_toolchains")

    dotnet_rules_dependencies()
    dotnet_register_toolchains()


Forcing the Dotnet version
~~~~~~~~~~~~~~~~~~~~~~

You can select the version of the Mono to use by specifying it when you call
dotnet_register_toolchains_ but you must use a value that matches a known toolchain.

WORKSPACE
^^^^^^^^^

.. code:: bzl

    load("@io_bazel_rules_dotnet//dotnet:def.bzl", "dotnet_rules_dependencies", "dotnet_register_toolchains")

    dotnet_rules_dependencies()
    dotnet_register_toolchains(dotnet_version="4.2.3")


Using the installed Mono 
~~~~~~~~~~~~~~~~~~~~~~~~

The "host" version is a special toolchain that breaks the hermetic seal to use the host installed
toolchain.

WORKSPACE
^^^^^^^^^

.. code:: bzl

    load("@io_bazel_rules_dotnet//dotnet:def.bzl", "dotnet_rules_dependencies", "dotnet_register_toolchains")

    dotnet_rules_dependencies()
    dotnet_register_toolchains(go_version="host")



Registering a custom Mono
~~~~~~~~~~~~~~~~~~~~~~~~~

If you want to register your own toolchain that takes precedence over the pre-declared ones you can
just add it and register it before the normal ones.

WORKSPACE
^^^^^^^^^

.. code:: bzl

    load("@io_bazel_rules_dotnet//dotnet:def.bzl", "dotnet_rules_dependencies", "dotnet_register_toolchains", "dotnet_download_sdk")

    dotnet_download_sdk(name="my_macos_sdk", url="http://bazel-mirror.storage.googleapis.com/download.mono-project.com/archive/4.2.3/macos-10-x86/MonoFramework-MDK-4.2.3.4.macos10.xamarin.x86.tar.gz")
    register_toolchains(
        "@//:my_macos_toolchain",
    )

    dotnet_rules_dependencies()
    dotnet_register_toolchains()


BUILD.bazel
^^^^^^^^^^^

.. code:: bzl

    dotnet_toolchain(name="my_macos_toolchain", sdk="my_macos_sdk")


Limiting the available toolchains
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you wanted to only allow your project to be compiled on mac at Mono version 4.2.3,
instead of calling go_register_toolchains you can put

WORKSPACE
^^^^^^^^^

.. code:: bzl

    load("@io_bazel_rules_dotnet//dotnet:def.bzl", "dotnet_rules_dependencies")

    dotnet_rules_dependencies()
    register_toolchains(
        "@io_bazel_rules_dotnet//dotnet/toolchain:4.2.3_darwin_amd64",
    )


API
---

dotnet_register_toolchains
~~~~~~~~~~~~~~~~~~~~~~~~~~

Installs the Dotnet toolchains. If :param:`dotnet_version` is specified, it sets the
Mono version to use (for example, :value:`"4.2.3"`). By default, the latest
Mono will be used.

+--------------------------------+-----------------------------+-----------------------------------+
| **Name**                       | **Type**                    | **Default value**                 |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`dotnet_version`        | :type:`string`              | :value:`"4.2.3"`                  |
+--------------------------------+-----------------------------+-----------------------------------+
| This specifies the Mono version to select.                                                       |
| It will match the version specification of the toochain which for normal sdk toolchains is       |
| also the string part of the `binary distribution`_ you want to use.                              |
| You can also use it to select the "host" sdk toolchain, or a custom toolchain with a             |
| specialized version string.                                                                      |
+--------------------------------+-----------------------------+-----------------------------------+

dotnet_download_sdk
~~~~~~~~~~~~~~~~~~~

This downloads Mono for use in toolchains.

+--------------------------------+-----------------------------+-----------------------------------+
| **Name**                       | **Type**                    | **Default value**                 |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`name`                  | :type:`string`              | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| A unique name for this sdk. This should almost always be :value:`dotnet_sdk` if you want the SDK |
| to be used by toolchains.                                                                        |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`urls`                  | :type:`string_list`         | :value:`official distributions`   |
+--------------------------------+-----------------------------+-----------------------------------+
| A list of mirror urls to the binary distribution of Mono. These must contain the `{}`        |
| used to substitute the sdk filename being fetched (using `.format`.                              |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`strip_prefix`          | :type:`string`              | :value:`""`                       |
+--------------------------------+-----------------------------+-----------------------------------+
| A directory prefix to strip from the extracted files.                                            |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`sdks`                  | :type:`string_list_dict`    | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| This consists of a set of mappings from the host platform tuple to a list of filename and        |
| sha256 for that file. The filename is combined the :param:`urls` to produce the final download   |
| urls to use.                                                                                     |
|                                                                                                  |
| As an example:                                                                                   |
|                                                                                                  |
| .. code:: bzl                                                                                    |
|                                                                                                  |
|     dotnet_download_sdk(                                                                         |
|         name = "dotnet_sdk",                                                                     |
|         sdks = {                                                                                 |
|             "linux_amd64":   ("go1.8.1.linux-amd64.tar.gz",                                      |
|                 "a579ab19d5237e263254f1eac5352efcf1d70b9dacadb6d6bb12b0911ede8994"),             |
|             "darwin_amd64":      ("go1.8.1.darwin-amd64.tar.gz",                                 |
|                 "25b026fe2f4de7c80b227f69588b06b93787f5b5f134fbf2d652926c08c04bcd"),             |
|         },                                                                                       |
|     )                                                                                            |
|                                                                                                  |
+--------------------------------+-----------------------------+-----------------------------------+


dotnet_host_sdk
~~~~~~~~~~~~~~~

This detects the host Mono for use in toolchains.

It searches the PATH. You can achive the same result by setting
the version to "host" when registering toolchains to select the `installed sdk`_ so it should
never be neccesary to use this feature directly.

+--------------------------------+-----------------------------+-----------------------------------+
| **Name**                       | **Type**                    | **Default value**                 |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`name`                  | :type:`string`              | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| A unique name for this sdk. This should almost always be :value:`dotnet_sdk` if you want the SDK |
| to be used by toolchains.                                                                        |
+--------------------------------+-----------------------------+-----------------------------------+


dotnet_local_sdk
~~~~~~~~~~~~~~~~

This prepares a local path to use as the Mono in toolchains.

+--------------------------------+-----------------------------+-----------------------------------+
| **Name**                       | **Type**                    | **Default value**                 |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`name`                  | :type:`string`              | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| A unique name for this sdk. This should almost always be :value:`dotnet_sdk` if you want the SDK |
| to be used by toolchains.                                                                        |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`path`                  | :type:`string`              | :value:`""`                       |
+--------------------------------+-----------------------------+-----------------------------------+
| The local path to a pre-installed Mono. The path must contain the mcs binary, the tools it       |
| invokes and the standard library sources.                                                        |
+--------------------------------+-----------------------------+-----------------------------------+


dotnet_toolchain
~~~~~~~~~~~~~~~~

This adds a toolchain of type :value:`"@io_bazel_rules_dotnet//dotnet:toolchain"`.

+--------------------------------+-----------------------------+-----------------------------------+
| **Name**                       | **Type**                    | **Default value**                 |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`name`                  | :type:`string`              | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| A unique name for the toolchain.                                                                 |
| You will need to use this name when registering the toolchain in the WORKSPACE.                  |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`target`                | :type:`string`              | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| This specifies the target platform tuple for this toolchain.                                     |
|                                                                                                  |
| It should be in the form *OS*_*ARCH* (as used by Go) and is used for both names and constraint   |
| matching.                                                                                        |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`host`                  | :type:`string`              | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| This is the host platform tuple.                                                                 |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`sdk`                   | :type:`string`              | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| This is the name of the SDK to use for this toolchain.                                           |
| The SDK must have been registered using one of the `dotnet sdk rules`_.                          |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`constraints`           | :type:`label_list`          | :value:`[]`                       |
+--------------------------------+-----------------------------+-----------------------------------+
| This list is added to the host and or target constraints when declaring the toolchains.          |
| It allows the declaration of additional constraints that must be matched for the toolchain to    |
| be automatically selected.                                                                       |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`msc_flags`             | :type:`string_list`         | :value:`[]`                       |
+--------------------------------+-----------------------------+-----------------------------------+
| The compiler flags are directly exposed on the toolchain.                                        |
| They can be used to specify target specific flags that mcs compiling actions should apply when   |
| using this toolchain.                                                                            |
+--------------------------------+-----------------------------+-----------------------------------+

dotnet_context
~~~~~~~~~~

This collects the information needed to form and return a :type:`DotnetContext` from a rule ctx.
It uses the attrbutes and the toolchains.
It can only be used in the implementation of a rule that has the go toolchain attached and
the dotnet context data as an attribute. To do this declare the rule using the dotnet_rule wrapper.

.. code:: bzl

  my_rule = dotnet_rule(
      _my_rule_impl,
      attrs = {
          ...
      },
  )


+--------------------------------+-----------------------------+-----------------------------------+
| **Name**                       | **Type**                    | **Default value**                 |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`ctx`                   | :type:`ctx`                 | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| The Bazel ctx object for the current rule.                                                       |
+--------------------------------+-----------------------------+-----------------------------------+

The context object
~~~~~~~~~~~~~~~~~~

DotnetContext is never returned by a rule, instead you build one using dotnet_context(ctx) in the 
top of any custom skylark rule that wants to interact with the go rules.
It provides all the information needed to create dotnet actions, and create or interact with the 
other dotnet providers.

When you get a DotnetContext from a context (see use_) it exposes a number of fields and methods.

All methods take the DotnetContext as the only positional argument, all other arguments even if
mandatory must be specified by name, to allow us to re-order and deprecate individual parameters
over time.


Methods
^^^^^^^

* Action generators

  * library_

* Helpers

  * args_
  * declare_file_
  * library_to_source_
  * new_library_


Fields
^^^^^^

+--------------------------------+-----------------------------------------------------------------+
| **Name**                       | **Type**                                                        |
+--------------------------------+-----------------------------------------------------------------+
| :param:`toolchain`             | :type:`DotnetToolchain`                                         |
+--------------------------------+-----------------------------------------------------------------+
| The underlying toolchain. This should be considered an opaque type subject to change.            |
+--------------------------------+-----------------------------------------------------------------+
| :param:`mode`                  | :type:`Mode`                                                    |
+--------------------------------+-----------------------------------------------------------------+
| Controls the compilation setup affecting things like enabling profilers and sanitizers.          |
| See `compilation modes`_ for more information about the allowed values.                          |
+--------------------------------+-----------------------------------------------------------------+
| :param:`mcs`                    | :type:`File`                                                   |
+--------------------------------+-----------------------------------------------------------------+
| The main "mcs" binary used.                                                                      |
+--------------------------------+-----------------------------------------------------------------+
| :param:`stdlib`                | :type:`DotnetStdlib`                                            |
+--------------------------------+-----------------------------------------------------------------+
| The standard library and tools to use in this build mode.                                        |
+--------------------------------+-----------------------------------------------------------------+
| :param:`sdk_files`             | :type:`list of File`                                            |
+--------------------------------+-----------------------------------------------------------------+
| This is the full set of files exposed by the sdk. You should never need this, it is mainly used  |
| when compiling the standard library.                                                             |
+--------------------------------+-----------------------------------------------------------------+
| :param:`actions`               | :type:`ctx.actions`                                             |
+--------------------------------+-----------------------------------------------------------------+
| The actions structure from the Bazel context, which has all the methods for building new         |
| bazel actions.                                                                                   |
+--------------------------------+-----------------------------------------------------------------+
| :param:`exe_extension`         | :type:`String`                                                  |
+--------------------------------+-----------------------------------------------------------------+
| The suffix to use for all executables in this build mode. Mostly used when generating the output |
| filenames of binary rules.                                                                       |
+--------------------------------+-----------------------------------------------------------------+


library
~~~~~~~

The library function adds an action that compiles the set of sources into binary.

It does not return anything.

+--------------------------------+-----------------------------+-----------------------------------+
| **Name**                       | **Type**                    | **Default value**                 |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`dotnet`                | :type:`DotnetContext`       | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| This must be the same DotnetContext object you got this function from.                           |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`sources`               | :type:`File iterable`       | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| An iterable of source code artifacts.                                                            |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`deps`                  | :type:`DotnetLibrary iterable`  | :value:`[]`                   |
+--------------------------------+-----------------------------+-----------------------------------+
| An iterable of all directly imported libraries.                                                  |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`out_lib`               | :type:`File`                | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| The output file that should be produced.                                                         |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`extra_opts`            | :type:`string_list`         | :value:`[]`                       |
+--------------------------------+-----------------------------+-----------------------------------+
| Additional flags to pass to the compiler.                                                        |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`warn`                  | :type:`Int`                 | :value:`4`                        |
+--------------------------------+-----------------------------+-----------------------------------+
| Compiler warn level for this binary. (Defaults to 4.)                                            |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`main_class`            | :type:`string`              | :value:`""`                       |
+--------------------------------+-----------------------------+-----------------------------------+
| Name of class with main() method to use as entry point.                                          |
+--------------------------------+-----------------------------+-----------------------------------+


args
~~~~

This creates a new args object, using the ctx.args method, and the populates it with the standard
arguments used by all the go toolchain builders.

+--------------------------------+-----------------------------+-----------------------------------+
| **Name**                       | **Type**                    | **Default value**                 |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`go`                    | :type:`GoContext`           | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| This must be the same GoContext object you got this function from.                               |
+--------------------------------+-----------------------------+-----------------------------------+

declare_file
~~~~~~~~~~~~

This is the equivalent of ctx.actions.declare_file except it uses the current build mode to make
the filename unique between configurations.

+--------------------------------+-----------------------------+-----------------------------------+
| **Name**                       | **Type**                    | **Default value**                 |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`go`                    | :type:`GoContext`           | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| This must be the same GoContext object you got this function from.                               |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`path`                  | :type:`string`              | :value:`""`                       |
+--------------------------------+-----------------------------+-----------------------------------+
| A path for this file, including the basename of the file.                                        |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`ext`                   | :type:`string`              | :value:`""`                       |
+--------------------------------+-----------------------------+-----------------------------------+
| The extension to use for the file.                                                               |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`name`                  | :type:`string`              | :value:`""`                       |
+--------------------------------+-----------------------------+-----------------------------------+
| A name to use for this file. If path is not present, this becomes a prefix to the path.          |
| If this is not set, the current rule name is used in it's place.                                 |
+--------------------------------+-----------------------------+-----------------------------------+

library_to_source
~~~~~~~~~~~~~~~~~

This is used to build a GoSource object for a given GoLibrary in the current build mode.

+--------------------------------+-----------------------------+-----------------------------------+
| **Name**                       | **Type**                    | **Default value**                 |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`go`                    | :type:`GoContext`           | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| This must be the same GoContext object you got this function from.                               |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`attr`                  | :type:`ctx.attr`            | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| The attributes of the rule being processed, in a normal rule implementation this would be        |
| ctx.attr.                                                                                        |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`library`               | :type:`GoLibrary`           | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| The GoLibrary_ that you want to build a GoSource_ object for in the current build mode.          |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`coverage_instrumented` | :type:`bool`                | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| This controls whether cover is enabled for this specific library in this mode.                   |
| This should generally be the value of ctx.coverage_instrumented()                                |
+--------------------------------+-----------------------------+-----------------------------------+

new_library
~~~~~~~~~~~

This creates a new GoLibrary.
You can add extra fields to the go library by providing extra named parameters to this function,
they will be visible to the resolver when it is invoked.

+--------------------------------+-----------------------------+-----------------------------------+
| **Name**                       | **Type**                    | **Default value**                 |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`go`                    | :type:`GoContext`           | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| This must be the same GoContext object you got this function from.                               |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`resolver`              | :type:`function`            | :value:`None`                     |
+--------------------------------+-----------------------------+-----------------------------------+
| This is the function that gets invoked when converting from a GoLibrary to a GoSource.           |
| The function's signature must be                                                                 |
|                                                                                                  |
| .. code:: bzl                                                                                    |
|                                                                                                  |
|     def _testmain_library_to_source(go, attr, source, merge)                                     |
|                                                                                                  |
| attr is the attributes of the rule being processed                                               |
| source is the dictionary of GoSource fields being generated                                      |
| merge is a helper you can call to merge                                                          |
+--------------------------------+-----------------------------+-----------------------------------+
| :param:`importable`            | :type:`bool`                | |mandatory|                       |
+--------------------------------+-----------------------------+-----------------------------------+
| This controls whether the GoLibrary_ is supposed to be importable. This is generally only false  |
| for the "main" libraries that are built just before linking.                                     |
+--------------------------------+-----------------------------+-----------------------------------+
