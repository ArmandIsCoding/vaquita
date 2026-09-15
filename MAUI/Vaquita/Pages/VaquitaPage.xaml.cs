using Vaquita.Models;

namespace Vaquita.Pages;

public partial class VaquitaPage : ContentPage
{
    private readonly Func<VaquitaEvento, Task> _onGuardar;

    public VaquitaPage(Func<VaquitaEvento, Task> onGuardar)
    {
        InitializeComponent();
        _onGuardar = onGuardar;
        FechaPicker.Date = DateTime.Today;
    }

    private void OnNombreTextChanged(object? sender, TextChangedEventArgs e)
    {
        CrearContainer.Opacity = string.IsNullOrWhiteSpace(e.NewTextValue) ? 0.35 : 1;
    }

    private async void OnGuardarClicked(object? sender, EventArgs e)
    {
        var nombre = NombreEntry.Text?.Trim() ?? string.Empty;
        if (nombre.Length == 0)
            return;

        var vaquita = new VaquitaEvento
        {
            Nombre = nombre,
            Fecha = FechaPicker.Date ?? DateTime.Today,
            UltimaModificacion = DateTime.Now
        };

        await Navigation.PopModalAsync();
        await _onGuardar(vaquita);
    }

    private async void OnCancelarClicked(object? sender, EventArgs e) => await Navigation.PopModalAsync();
}
