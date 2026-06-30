namespace Hyenux.Init;

public class MountPointConfiguration
{
    public string? Source { get; init; }
    public required string Target { get; init; }
    public required string Type { get; init; }
    public ulong Flags { get; init; }
    public string? Data { get; init; }
}
