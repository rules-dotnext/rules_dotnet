using System;
using System.Resources;
using System.Xml.Linq;

#nullable enable

if (args.Length < 2 || args.Length % 2 != 0)
{
    Console.Error.WriteLine("Usage: ResxCompiler <input.resx> <output.resources> [...]");
    return 1;
}

for (int i = 0; i < args.Length; i += 2)
{
    string inputPath = args[i];
    string outputPath = args[i + 1];

    var doc = XDocument.Load(inputPath);
    using var writer = new ResourceWriter(outputPath);

    foreach (var data in doc.Descendants("data"))
    {
        string? name = data.Attribute("name")?.Value;
        string? value = data.Element("value")?.Value;
        if (name != null)
        {
            writer.AddResource(name, value);
        }
    }

    writer.Generate();
}

return 0;
