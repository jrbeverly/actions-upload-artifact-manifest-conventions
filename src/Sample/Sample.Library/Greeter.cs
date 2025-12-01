namespace Sample.Library;

public static class Greeter
{
    public static string Greet(string name)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Name must not be empty.", nameof(name));
        return $"Hello, {name.Trim()}!";
    }
}
