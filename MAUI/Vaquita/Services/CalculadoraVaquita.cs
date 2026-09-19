using System.Globalization;
using System.Text;
using Vaquita.Models;

namespace Vaquita.Services;

public static class CalculadoraVaquita
{
    private const decimal Precision = 0.01m;

    public static IReadOnlyList<Transaccion> CalcularLiquidacion(IEnumerable<Participante> participantes)
    {
        var lista = participantes.ToList();
        if (lista.Count == 0)
        {
            return [];
        }

        var cuotaPorPersona = lista.Sum(participante => participante.MontoPagado) / lista.Count;
        var balances = lista
            .Select(participante => new Balance(participante.Nombre, participante.MontoPagado - cuotaPorPersona))
            .ToList();
        var transacciones = new List<Transaccion>();

        while (true)
        {
            balances.Sort((left, right) => left.Monto.CompareTo(right.Monto));

            var deudor = balances.First();
            var acreedor = balances.Last();
            if (deudor.Monto >= -Precision || acreedor.Monto <= Precision)
            {
                break;
            }

            var monto = decimal.Min(decimal.Abs(deudor.Monto), acreedor.Monto);
            transacciones.Add(new Transaccion(deudor.Nombre, acreedor.Nombre, monto));
            deudor.Monto += monto;
            acreedor.Monto -= monto;
        }

        return transacciones;
    }

    public static string GenerarMensajeWhatsApp(string nombreVaquita, IEnumerable<Participante> participantes, IEnumerable<Transaccion> transacciones)
    {
        var lista = participantes.ToList();
        var total = lista.Sum(participante => participante.MontoPagado);
        var porParticipante = lista.Count == 0 ? 0 : total / lista.Count;
        var cultura = CultureInfo.GetCultureInfo("es-AR");
        var moneda = cultura.NumberFormat.CurrencySymbol;
        var mensaje = new StringBuilder()
            .AppendLine($"🐮 *{nombreVaquita}*")
            .AppendLine("Resumen de gastos")
            .AppendLine()
            .AppendLine($"💰 Total gastado: {moneda}{total:N2}")
            .AppendLine($"👤 Por participante: {moneda}{porParticipante:N2}")
            .AppendLine()
            .AppendLine("📝 *Liquidación:*");

        var liquidacion = transacciones.ToList();
        if (liquidacion.Count == 0)
        {
            mensaje.AppendLine("✅ ¡Están todos al día!");
        }
        else
        {
            foreach (var transaccion in liquidacion)
            {
                mensaje.AppendLine($"• *{transaccion.De}* le paga {moneda}{transaccion.Monto:N2} a *{transaccion.A}*");
            }
        }

        return mensaje.AppendLine().Append("_Generado por Vaquita_ 🐮").ToString();
    }

    private sealed class Balance(string nombre, decimal monto)
    {
        public string Nombre { get; } = nombre;

        public decimal Monto { get; set; } = monto;
    }
}
