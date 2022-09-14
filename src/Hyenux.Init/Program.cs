namespace Hyenux.Init;

internal class Program
{
    private static async Task Main(string[] args)
    {
        IHost host = Host.CreateDefaultBuilder(args)
        .ConfigureServices(services =>
        {
            services.AddHostedService<FileSystemService>();
            services.AddHostedService<LoginShellService>();
        })
        .Build();

        await host.RunAsync();
    }
}
