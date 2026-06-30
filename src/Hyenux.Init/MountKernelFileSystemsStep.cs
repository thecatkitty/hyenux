namespace Hyenux.Init;

public class MountKernelFileSystemsStep(MountPointManager manager) : IInitStep
{
    private readonly MountPointManager _manager = manager;

    private readonly MountPointConfiguration[] _mountPoints =
    [
        new() { Target = "/dev", Type = "devtmpfs" },
        new() { Target = "/proc", Type = "proc" },
        new() { Target = "/sys", Type = "sysfs" },
        new() { Target = "/tmp", Type = "tmpfs" }
    ];

    public async Task ExecuteAsync(CancellationToken cancellationToken)
    {
        foreach (var mountPoint in _mountPoints)
        {
            cancellationToken.ThrowIfCancellationRequested();
            await _manager.MountAsync(mountPoint);
        }
    }
}
