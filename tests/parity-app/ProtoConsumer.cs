namespace ParityApp;

/// <summary>
/// Consumes generated protobuf types — exercises spec-proto-grpc parity.
/// If this compiles, protoc C# codegen and compilation worked.
/// </summary>
public static class ProtoConsumer
{
    public static Proto.GreetRequest CreateRequest(string name)
    {
        return new Proto.GreetRequest { Name = name };
    }

    public static string GetMessage(Proto.GreetReply reply)
    {
        return reply.Message;
    }
}
