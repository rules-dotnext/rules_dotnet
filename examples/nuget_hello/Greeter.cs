using Newtonsoft.Json;

namespace NuGetHello;

public static class Greeter
{
    public static string Hello(string name)
    {
        var greeting = new { Message = $"Hello, {name}!" };
        return JsonConvert.SerializeObject(greeting);
    }
}
