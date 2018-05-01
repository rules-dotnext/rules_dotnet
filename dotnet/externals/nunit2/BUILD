load("@io_bazel_rules_dotnet//dotnet/private:rules/library.bzl", "dotnet_library")

dotnet_library(
    name = "nunit.core.interfaces",
    srcs = [":NUnitCore_Interfaces_files"],
    visibility = ["//visibility:public"],
    deps = ["//dotnet/stdlib:System.dll"]
)

filegroup(
  name = "common_assembly_info_files",
  srcs = ["//dotnet/externals/nunit2/nunitv2:src/CommonAssemblyInfo.cs"],
)

filegroup(
  name = "NUnitCore_Interfaces_files",
  srcs = [":common_assembly_info_files",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitFramework/framework/ITestCaseData.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/EventListener.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/IAgency.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/IService.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/ITest.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/ITestFilter.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/LoggingThreshold.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/OSPlatform.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/PropertyNames.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/ResultState.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/RunState.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/RuntimeFramework.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Test.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/TestAgent.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/TestAssemblyInfo.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/TestFilter.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/TestID.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/TestInfo.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/TestName.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/TestNode.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/TestOutput.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/TestPackage.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/TestResult.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/TestRunner.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Extensibility/Addin.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Extensibility/AddinStatus.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Extensibility/ExtensionType.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Extensibility/IAddin.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Extensibility/IAddinRegistry.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Extensibility/IDataPointProvider.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Extensibility/IExtensionHost.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Extensibility/IExtensionPoint.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Extensibility/IFrameworkRegistry.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Extensibility/ISuiteBuilder.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Extensibility/ITestCaseBuilder.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Extensibility/ITestCaseProvider.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Extensibility/ITestDecorator.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Extensibility/NUnitAddinAttribute.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Extensibility/ParameterSet.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Extensibility/TestFramework.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Filters/AndFilter.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Filters/CategoryFilter.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Filters/NameFilter.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Filters/NotFilter.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Filters/OrFilter.cs",
        "//dotnet/externals/nunit2/nunitv2:src/NUnitCore/interfaces/Filters/SimpleNameFilter.cs",      
  ]
)

