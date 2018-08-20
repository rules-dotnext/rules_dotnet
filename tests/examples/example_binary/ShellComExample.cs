using System;
using Shell32;

namespace ShellComExample
{
    class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            var test = (Shell)Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("13709620-C279-11CE-A49E-444553540000")));
            test.Open("shell:::{26EE0668-A00A-44D7-9371-BEB064C98683}");
        }
    }
}