namespace Vaquita.Models;

public sealed class Participante
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public string Nombre { get; set; } = string.Empty;

    public decimal MontoPagado { get; set; }
}
