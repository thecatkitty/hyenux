namespace Hyenux.Init;

public interface IInitStep
{
    Task ExecuteAsync(CancellationToken cancellationToken);
}
