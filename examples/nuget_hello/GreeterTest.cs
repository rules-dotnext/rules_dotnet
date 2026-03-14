using NUnit.Framework;
using NuGetHello;

[TestFixture]
public class GreeterTest
{
    [Test]
    public void Hello_ReturnsJsonWithGreeting()
    {
        var result = Greeter.Hello("World");
        Assert.That(result, Does.Contain("Hello, World!"));
        Assert.That(result, Does.StartWith("{"));
    }
}
