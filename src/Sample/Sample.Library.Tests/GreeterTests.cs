using Sample.Library;

namespace Sample.Library.Tests;

public class GreeterTests
{
    [Fact]
    public void Greet_ReturnsGreeting_ForName()
    {
        Assert.Equal("Hello, Ada!", Greeter.Greet("Ada"));
    }

    [Fact]
    public void Greet_TrimsSurroundingWhitespace()
    {
        Assert.Equal("Hello, Ada!", Greeter.Greet("  Ada  "));
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData(null)]
    public void Greet_Throws_ForBlankName(string? name)
    {
        Assert.Throws<ArgumentException>(() => Greeter.Greet(name!));
    }
}
