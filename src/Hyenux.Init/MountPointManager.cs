namespace Hyenux.Init;

using System.Text;
using Tmds.Linux;

public class MountPointManager(ILogger<MountPointManager> logger)
{
    private readonly ILogger<MountPointManager> _logger = logger;

    public async Task MountAsync(MountPointConfiguration configuration)
    {
        _logger.LogInformation("Mounting {source} to {target} as {type}", configuration.Source ?? "none", configuration.Target, configuration.Type);
        Mount(configuration.Source ?? "none", configuration.Target, configuration.Type, configuration.Flags, configuration.Data ?? "");
        await Task.CompletedTask;
    }

    private unsafe void Mount(string source, string target, string type, ulong flags, string data)
    {
        var sourceBuff = Encoding.UTF8.GetBytes(source + "\0");
        var targetBuff = Encoding.UTF8.GetBytes(target + "\0");
        var typeBuff = Encoding.UTF8.GetBytes(type + "\0");
        var dataBuff = Encoding.UTF8.GetBytes(data + "\0");

        fixed (byte* sourcePtr = sourceBuff, targetPtr = targetBuff, typePtr = typeBuff, dataPtr = dataBuff)
        {
            if (LibC.mount(sourcePtr, targetPtr, typePtr, (ulong_t)flags, dataPtr) != 0)
            {
                throw PlatformException.FromErrno();
            }
        }
    }
}
