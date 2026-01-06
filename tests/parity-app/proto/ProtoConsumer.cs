using ParityApp.Proto;

namespace ParityApp;

public static class ProtoConsumer
{
    public static GreetRequest CreateRequest(string name) =>
        new() { Name = name };

    public static string FormatReply(GreetReply reply) =>
        $"Server said: {reply.Message}";
}
