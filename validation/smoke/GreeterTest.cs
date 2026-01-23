using NUnit.Framework;

namespace SmokeTest;

[TestFixture]
public class GreeterTest
{
    [Test]
    public void Greet_ReturnsExpectedMessage()
    {
        Assert.AreEqual("Hello, Bazel!", Greeter.Greet("Bazel"));
    }
}
