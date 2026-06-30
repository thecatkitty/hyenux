namespace Hyenux.Init;

internal class Program
{
    private static async Task Main(string[] args)
    {
        IHost host = Host.CreateDefaultBuilder(args)
        .ConfigureServices(services =>
        {
            services.AddSingleton<MountPointManager>();
            services.AddSingleton<IInitStep, MountKernelFileSystemsStep>();
            services.AddHostedService<LoginShellService>();
        })
        .Build();

        foreach (var step in host.Services.GetServices<IInitStep>())
        {
            await step.ExecuteAsync(CancellationToken.None);
        }

        await host.RunAsync();
    }
}
