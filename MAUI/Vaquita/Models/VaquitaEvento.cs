using System.Text.Json.Serialization;
using System.Globalization;

namespace Vaquita.Models;

public sealed class VaquitaEvento
{
    private static readonly CultureInfo CulturaArgentina = CultureInfo.GetCultureInfo("es-AR");

    public Guid Id { get; set; } = Guid.NewGuid();

    public string Nombre { get; set; } = string.Empty;

    public DateTime Fecha { get; set; } = DateTime.Today;

    public DateTime UltimaModificacion { get; set; } = DateTime.Now;

    public List<Participante> Participantes { get; set; } = [];

    [JsonIgnore]
    public decimal Total => Participantes.Sum(participante => participante.MontoPagado);

    [JsonIgnore]
    public string FechaTexto => Fecha.ToString("d 'de' MMMM 'de' yyyy", CulturaArgentina);

    [JsonIgnore]
    public string ParticipantesTexto => Participantes.Count == 1
        ? "1 participante"
        : $"{Participantes.Count} participantes";
}
