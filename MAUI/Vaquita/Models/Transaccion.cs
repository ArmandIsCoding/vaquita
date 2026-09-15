namespace Vaquita.Models;

public sealed record Transaccion(string De, string A, decimal Monto)
{
    public string Descripcion => $"{De} paga a {A}";
}
