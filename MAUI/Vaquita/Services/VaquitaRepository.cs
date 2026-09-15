using System.Text.Json;
using Vaquita.Models;

namespace Vaquita.Services;

public sealed class VaquitaRepository
{
    private const string FileName = "vaquitas.json";
    private const string LegacyFileName = "participantes.json";
    private static readonly SemaphoreSlim Gate = new(1, 1);
    private static readonly JsonSerializerOptions JsonOptions = new() { WriteIndented = true };

    private string FilePath => Path.Combine(FileSystem.AppDataDirectory, FileName);

    private string LegacyFilePath => Path.Combine(FileSystem.AppDataDirectory, LegacyFileName);

    public async Task<List<VaquitaEvento>> ObtenerTodasAsync()
    {
        await Gate.WaitAsync();
        try
        {
            if (File.Exists(FilePath))
                return await LeerSinBloqueoAsync();

            if (!File.Exists(LegacyFilePath))
                return [];

            await using var legacyStream = File.OpenRead(LegacyFilePath);
            var participantes = await JsonSerializer.DeserializeAsync<List<Participante>>(legacyStream) ?? [];
            if (participantes.Count == 0)
                return [];

            var vaquitas = new List<VaquitaEvento>();
            vaquitas.Add(new VaquitaEvento
            {
                Nombre = "Vaquita anterior",
                Fecha = DateTime.Today,
                UltimaModificacion = DateTime.Now,
                Participantes = participantes
            });
            await EscribirSinBloqueoAsync(vaquitas);
            return vaquitas;
        }
        finally
        {
            Gate.Release();
        }
    }

    public async Task GuardarAsync(VaquitaEvento vaquita)
    {
        await Gate.WaitAsync();
        try
        {
            var vaquitas = await LeerSinBloqueoAsync();
            var indice = vaquitas.FindIndex(actual => actual.Id == vaquita.Id);
            vaquita.UltimaModificacion = DateTime.Now;
            if (indice >= 0)
                vaquitas[indice] = vaquita;
            else
                vaquitas.Add(vaquita);

            await EscribirSinBloqueoAsync(vaquitas);
        }
        finally
        {
            Gate.Release();
        }
    }

    public async Task EliminarAsync(Guid id)
    {
        await Gate.WaitAsync();
        try
        {
            var vaquitas = await LeerSinBloqueoAsync();
            vaquitas.RemoveAll(vaquita => vaquita.Id == id);
            await EscribirSinBloqueoAsync(vaquitas);
        }
        finally
        {
            Gate.Release();
        }
    }

    public async Task<IReadOnlyList<string>> ObtenerNombresConocidosAsync()
    {
        var vaquitas = await ObtenerTodasAsync();
        return vaquitas
            .SelectMany(vaquita => vaquita.Participantes)
            .Select(participante => participante.Nombre.Trim())
            .Where(nombre => nombre.Length > 0)
            .Distinct(StringComparer.CurrentCultureIgnoreCase)
            .OrderBy(nombre => nombre, StringComparer.CurrentCultureIgnoreCase)
            .ToList();
    }

    private async Task<List<VaquitaEvento>> LeerSinBloqueoAsync()
    {
        if (!File.Exists(FilePath))
            return [];

        await using var stream = File.OpenRead(FilePath);
        return await JsonSerializer.DeserializeAsync<List<VaquitaEvento>>(stream) ?? [];
    }

    private async Task EscribirSinBloqueoAsync(IEnumerable<VaquitaEvento> vaquitas)
    {
        Directory.CreateDirectory(FileSystem.AppDataDirectory);
        var temporal = FilePath + ".tmp";
        await using (var stream = File.Create(temporal))
            await JsonSerializer.SerializeAsync(stream, vaquitas, JsonOptions);

        File.Move(temporal, FilePath, true);
    }
}
