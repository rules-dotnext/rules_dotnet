using NUnit.Framework;

namespace ParityApp.Tests;

/// <summary>
/// NUnit test — exercises:
///   spec-testing-infra #207 (configurable test runner)
///   spec-testing-infra #359 (coverage via InstrumentedFilesInfo)
///   spec-testing-infra #450 (flatten_deps for custom DLL locations)
/// </summary>
[TestFixture]
public class GreeterTest
{
    [Test]
    public void Hello_ReturnsGreeting()
    {
        Assert.That(Greeter.Hello("World"), Is.EqualTo("Hello, World!"));
    }

    // FromResources test moved to //integration — requires platform-features (#466)
    // for resx_resource compilation, which is a cross-spec dependency.
}
