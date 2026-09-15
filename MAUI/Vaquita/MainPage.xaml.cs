using System.Globalization;
using Vaquita.Models;
using Vaquita.Pages;
using Vaquita.Services;

namespace Vaquita;

public partial class MainPage : ContentPage
{
    private readonly ParticipanteRepository _repository = new();
    private List<Participante> _participantes = [];

    public MainPage() => InitializeComponent();

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await CargarAsync();
    }

    private async Task CargarAsync()
    {
        _participantes = (await _repository.ObtenerTodosAsync())
            .OrderBy(participante => participante.Nombre, StringComparer.CurrentCultureIgnoreCase)
            .ToList();
        ActualizarVista();
    }

    private void ActualizarVista()
    {
        var transacciones = CalculadoraVaquita.CalcularLiquidacion(_participantes);
        ParticipantesView.ItemsSource = _participantes;
        TransaccionesView.ItemsSource = transacciones;

        var tieneParticipantes = _participantes.Count > 0;
        EmptyState.IsVisible = !tieneParticipantes;
        Contenido.IsVisible = tieneParticipantes;
        LimpiarToolbarItem.IsEnabled = tieneParticipantes;
        CompartirToolbarItem.IsEnabled = tieneParticipantes;
        LiquidacionSection.IsVisible = transacciones.Count > 0;

        var total = _participantes.Sum(participante => participante.MontoPagado);
        var porInvitado = tieneParticipantes ? total / _participantes.Count : 0;
        TotalLabel.Text = total.ToString("C0", CultureInfo.CurrentCulture);
        PorInvitadoLabel.Text = porInvitado.ToString("C0", CultureInfo.CurrentCulture);
    }

    private async void OnAgregarClicked(object? sender, EventArgs e) => await AbrirEditorAsync(null);

    private async void OnParticipanteSelectionChanged(object? sender, SelectionChangedEventArgs e)
    {
        if (e.CurrentSelection.FirstOrDefault() is not Participante participante)
        {
            return;
        }

        ParticipantesView.SelectedItem = null;
        await AbrirEditorAsync(participante);
    }

    private async Task AbrirEditorAsync(Participante? participante) =>
        await Navigation.PushModalAsync(new NavigationPage(new ParticipantePage(participante, GuardarParticipanteAsync)));

    private async Task GuardarParticipanteAsync(Participante participante)
    {
        var existente = _participantes.FindIndex(actual => actual.Id == participante.Id);
        if (existente >= 0)
            _participantes[existente] = participante;
        else
            _participantes.Add(participante);

        _participantes = _participantes.OrderBy(actual => actual.Nombre, StringComparer.CurrentCultureIgnoreCase).ToList();
        await _repository.GuardarAsync(_participantes);
        ActualizarVista();
    }

    private async void OnEliminarClicked(object? sender, EventArgs e)
    {
        if ((sender as Button)?.CommandParameter is not Participante participante ||
            !await DisplayAlertAsync("¿Eliminar invitado?", $"Se eliminará a {participante.Nombre}.", "Eliminar", "Cancelar"))
            return;

        _participantes.RemoveAll(actual => actual.Id == participante.Id);
        await _repository.GuardarAsync(_participantes);
        ActualizarVista();
    }

    private async void OnLimpiarClicked(object? sender, EventArgs e)
    {
        if (!await DisplayAlertAsync("¿Borrar todo?", "Se borrarán todos los participantes y gastos. Esta acción no se puede deshacer.", "Limpiar todo", "Cancelar"))
            return;

        _participantes.Clear();
        await _repository.GuardarAsync(_participantes);
        ActualizarVista();
    }

    private async void OnCompartirClicked(object? sender, EventArgs e)
    {
        var mensaje = CalculadoraVaquita.GenerarMensajeWhatsApp(_participantes, CalculadoraVaquita.CalcularLiquidacion(_participantes));
        await Share.Default.RequestAsync(new ShareTextRequest { Text = mensaje, Title = "Vaquita: resumen del asado" });
    }
}
