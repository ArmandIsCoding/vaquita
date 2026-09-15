using System.Globalization;
using Vaquita.Models;

namespace Vaquita.Pages;

public partial class ParticipantePage : ContentPage
{
    private readonly Participante? _original;
    private readonly Func<Participante, Task> _onGuardar;

    public ParticipantePage(Participante? participante, Func<Participante, Task> onGuardar)
    {
        InitializeComponent();
        _original = participante;
        _onGuardar = onGuardar;
        Title = participante is null ? "Nuevo invitado" : "Editar invitado";

        if (participante is not null)
        {
            NombreEntry.Text = participante.Nombre;
            MontoEntry.Text = participante.MontoPagado.ToString("0", CultureInfo.CurrentCulture);
        }
    }

    private async void OnGuardarClicked(object? sender, EventArgs e)
    {
        var nombre = NombreEntry.Text?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(nombre))
        {
            await DisplayAlertAsync("Falta el nombre", "Ingresá el nombre del invitado.", "Aceptar");
            return;
        }

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
        await _onGuardar(participante);
        await Navigation.PopModalAsync();
    }

    private async void OnCancelarClicked(object? sender, EventArgs e) => await Navigation.PopModalAsync();
}
