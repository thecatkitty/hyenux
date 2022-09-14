using System.Diagnostics;
using System.Runtime.InteropServices;
using Tmds.Linux;

namespace Hyenux.Init;

public class LoginShellService : BackgroundService
{
    private readonly ILogger<LoginShellService> _logger;

    public LoginShellService(ILogger<LoginShellService> logger)
    {
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        try
        {
            SetWindowSize(new winsize(25, 80));
        }
        catch (PlatformException pex)
        {
            _logger.LogError(pex, "Could not set terminal size!");
        }

        while (!stoppingToken.IsCancellationRequested)
        {
            var process = new Process()
            {
                StartInfo = new ProcessStartInfo("/opt/microsoft/powershell/7/pwsh")
                {
                    UseShellExecute = false
                }
            };

            process.Start();
            process.WaitForExit();

            if (process.ExitCode == 0)
            {
                _logger.LogWarning("There's nothing here!");
            }
            else
            {
                _logger.LogError("The login shell died with code {code}", process.ExitCode);
            }
        }

        await Task.CompletedTask;
    }

    private unsafe void SetWindowSize(winsize sz)
    {
        if (LibC.ioctl(LibC.STDOUT_FILENO, LibC.TIOCSWINSZ, &sz) != 0)
        {
            PlatformException.Throw();
        }
    }

    [StructLayout(LayoutKind.Sequential)]
    struct winsize
    {
        ushort ws_row;
        ushort ws_col;
        ushort ws_xpixel;
        ushort ws_ypixel;

        public winsize(ushort row, ushort col, ushort x = 0, ushort y = 0)
        {
            ws_row = row;
            ws_col = col;
            ws_xpixel = x;
            ws_ypixel = y;
        }
    }
}
