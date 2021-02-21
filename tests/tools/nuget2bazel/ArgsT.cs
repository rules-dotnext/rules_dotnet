using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using CommandLine;
using CommandLine.Text;
using nuget2bazel;
using nuget2bazel.rules;
using Xunit;

namespace nuget2bazel_test
{
    public class ArgsT
    {
        [Theory]
        [InlineData("add", typeof(AddVerb))]
        [InlineData("update", typeof(UpdateVerb))]
        public void Verbs_SupportTargetNameArgument(string verb, Type verbType)
        {
            var parsed = Parser.Default.ParseArguments<AddVerb, UpdateVerb>(new[] { verb, "xunit", "2.4.1", "-t", "foo" });

            Assert.Equal(ParserResultType.Parsed, parsed.Tag);

            parsed.WithParsed<object>(verbObj =>
            {
                Assert.IsType(verbType, verbObj);
                var typed = (AddOrUpdateVerb)verbObj;
                Assert.Equal("\"foo\"", typed.CustomTargetName);
                Assert.Equal("foo", typed.TargetName);
            });

            parsed.WithNotParsed((IEnumerable<Error> errs) =>
            {
                Assert.Empty(errs);
            });
        }

        [Theory]
        [InlineData("add", typeof(AddVerb))]
        [InlineData("update", typeof(UpdateVerb))]
        public void Verbs_HaveTargetNameAndVariableName_AsMutuallyExclusive(string verb, Type verbType)
        {
            var parsed = Parser.Default.ParseArguments<AddVerb, UpdateVerb>(new[] { verb, "xunit", "2.4.1", "-t", "foo", "-v", "bar" });

            Assert.Equal(ParserResultType.NotParsed, parsed.Tag);

            var passed = false;

            parsed.WithNotParsed<object>((IEnumerable<Error> errs) =>
            {
                Assert.Collection(errs,
                    err =>
                    {
                        var typed = Assert.IsType<MutuallyExclusiveSetError>(err);
                        Assert.Equal("variable", typed.SetName);
                    }, err =>
                    {
                        var typed = Assert.IsType<MutuallyExclusiveSetError>(err);
                        Assert.Equal("target_name", typed.SetName);
                    });

                passed = true;
            });
            Assert.True(passed, "Errors should have been recorded by the parser");
        }

        [Theory]
        [InlineData("-t", "\"foo\"")]
        [InlineData("-v", "foo")]
        public void VariableName_Works(string argName, string customValue)
        {
            var parsed = Parser.Default.ParseArguments<AddVerb, UpdateVerb>(new[] { "add", "xunit", "2.4.1", argName, "foo" });

            Assert.Equal(ParserResultType.Parsed, parsed.Tag);

            parsed.WithParsed<object>(verbObj =>
            {
                var typed = Assert.IsType<AddVerb>(verbObj);
                Assert.Equal(customValue, typed.CustomTargetName);
            });

            parsed.WithNotParsed((IEnumerable<Error> errs) =>
            {
                Assert.Empty(errs);
            });
        }
    }
}