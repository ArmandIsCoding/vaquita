using System.Text.Json;
using Vaquita.Models;

namespace Vaquita.Services;

public sealed class ParticipanteRepository
{
    private const string FileName = "participantes.json";
    private static readonly SemaphoreSlim Gate = new(1, 1);
    private static readonly JsonSerializerOptions JsonOptions = new() { WriteIndented = true };

    private string FilePath => Path.Combine(FileSystem.AppDataDirectory, FileName);

    public async Task<List<Participante>> ObtenerTodosAsync()
    {
        await Gate.WaitAsync();
        try
        {
            if (!File.Exists(FilePath))
            {
                return [];
            }

            await using var stream = File.OpenRead(FilePath);
            return await JsonSerializer.DeserializeAsync<List<Participante>>(stream) ?? [];
        }
        finally
        {
            Gate.Release();
        }
    }

    public async Task GuardarAsync(IEnumerable<Participante> participantes)
    {
        await Gate.WaitAsync();
        try
        {
            Directory.CreateDirectory(FileSystem.AppDataDirectory);
            var temporal = FilePath + ".tmp";
            await using (var stream = File.Create(temporal))
            {
                await JsonSerializer.SerializeAsync(stream, participantes, JsonOptions);
            }

            File.Move(temporal, FilePath, true);
        }
        finally
        {
            Gate.Release();
        }
    }
}
