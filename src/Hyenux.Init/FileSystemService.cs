namespace Hyenux.Init;

using System.Text;
using Tmds.Linux;

public class FileSystemService : BackgroundService
{
    private readonly ILogger<FileSystemService> _logger;

    public FileSystemService(ILogger<FileSystemService> logger)
    {
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        try
        {
            Mount("none", "/dev", "devtmpfs");
            Mount("none", "/proc", "proc");
            Mount("none", "/sys", "sysfs");
            Mount("none", "/tmp", "tmpfs");
        }
        catch (PlatformException pex)
        {
            _logger.LogError(pex, "Could not mount!");
        }

        await Task.CompletedTask;
    }

    private unsafe void Mount(string source, string target, string type, ulong flags = 0, string data = "")
    {
        var sourceBuff = Encoding.UTF8.GetBytes(source);
        var targetBuff = Encoding.UTF8.GetBytes(target);
        var typeBuff = Encoding.UTF8.GetBytes(type);
        var dataBuff = Encoding.UTF8.GetBytes(data);

        fixed (byte* sourcePtr = sourceBuff, targetPtr = targetBuff, typePtr = typeBuff, dataPtr = dataBuff)
        {
            if (LibC.mount(sourcePtr, targetPtr, typePtr, (ulong_t)flags, dataPtr) != 0)
            {
                PlatformException.Throw();
            }
        }

        _logger.LogInformation("Mounted {target}", target);
    }
}
