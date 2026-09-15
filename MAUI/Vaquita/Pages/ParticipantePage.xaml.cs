using System.Globalization;
using Vaquita.Models;

namespace Vaquita.Pages;

public partial class ParticipantePage : ContentPage
{
    private readonly Participante? _original;
    private readonly IReadOnlyList<string> _nombresConocidos;
    private readonly HashSet<string> _nombresNoDisponibles;
    private readonly Func<Participante, Task<bool>> _onGuardar;

    public IReadOnlyList<string> NombresSugeridos { get; private set; } = [];

    public ParticipantePage(
        Participante? participante,
        IReadOnlyList<string> nombresConocidos,
        IEnumerable<string> nombresNoDisponibles,
        Func<Participante, Task<bool>> onGuardar)
    {
        InitializeComponent();
        _original = participante;
        _nombresConocidos = nombresConocidos;
        _nombresNoDisponibles = nombresNoDisponibles
            .Select(nombre => nombre.Trim())
            .ToHashSet(StringComparer.CurrentCultureIgnoreCase);
        _onGuardar = onGuardar;
        BindingContext = this;
        Title = participante is null ? "Nuevo participante" : "Editar participante";
        TituloLabel.Text = Title;

        if (participante is not null)
        {
            NombreEntry.Text = participante.Nombre;
            MontoEntry.Text = participante.MontoPagado.ToString("0", CultureInfo.CurrentCulture);
        }
    }

    private void OnNombreTextChanged(object? sender, TextChangedEventArgs e)
    {
        var busqueda = e.NewTextValue?.Trim() ?? string.Empty;
        var duplicado = _nombresNoDisponibles.Contains(busqueda);
        ErrorNombreLabel.IsVisible = duplicado;
        GuardarLabel.Opacity = busqueda.Length > 0 && !duplicado ? 1 : 0.35;
        if (busqueda.Length == 0)
        {
            OcultarSugerencias();
            return;
        }

        MostrarSugerencias(_nombresConocidos
            .Where(nombre => nombre.StartsWith(busqueda, StringComparison.CurrentCultureIgnoreCase)));
    }

    private void OnMostrarNombresClicked(object? sender, EventArgs e)
    {
        if (SugerenciasContainer.IsVisible)
            OcultarSugerencias();
        else
            MostrarSugerencias(_nombresConocidos);
    }

    private void OnSugerenciaTapped(object? sender, TappedEventArgs e)
    {
        if (e.Parameter is not string nombre)
            return;

        NombreEntry.Text = nombre;
        NombreEntry.CursorPosition = nombre.Length;
        OcultarSugerencias();
        MontoEntry.Focus();
    }

    private void MostrarSugerencias(IEnumerable<string> nombres)
    {
        NombresSugeridos = nombres.ToList();
        OnPropertyChanged(nameof(NombresSugeridos));
        SugerenciasContainer.IsVisible = NombresSugeridos.Count > 0;
    }

    private void OcultarSugerencias()
    {
        NombresSugeridos = [];
        OnPropertyChanged(nameof(NombresSugeridos));
        SugerenciasContainer.IsVisible = false;
    }

    private async void OnGuardarClicked(object? sender, EventArgs e)
    {
        var nombre = NombreEntry.Text?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(nombre) || _nombresNoDisponibles.Contains(nombre))
            return;

        var textoMonto = MontoEntry.Text?.Trim() ?? string.Empty;
        if (!decimal.TryParse(textoMonto, NumberStyles.Number, CultureInfo.CurrentCulture, out var monto) || monto < 0)
        {
            await DisplayAlertAsync("Monto inválido", "Ingresá un número mayor o igual a cero.", "Aceptar");
            return;
        }

        var participante = new Participante
        {
            Id = _original?.Id ?? Guid.NewGuid(),
            Nombre = nombre,
            MontoPagado = monto
        };
        if (await _onGuardar(participante))
            await Navigation.PopModalAsync();
    }

    private async void OnCancelarClicked(object? sender, EventArgs e) => await Navigation.PopModalAsync();
}
