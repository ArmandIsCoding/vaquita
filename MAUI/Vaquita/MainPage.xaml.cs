using Vaquita.Converters;
using Vaquita.Models;
using Vaquita.Pages;
using Vaquita.Services;

namespace Vaquita;

public partial class MainPage : ContentPage
{
    private readonly ParticipanteRepository _repository = new();
    private List<Participante> _participantes = [];

    public IReadOnlyList<Participante> Participantes { get; private set; } = [];

    public IReadOnlyList<Transaccion> Transacciones { get; private set; } = [];

    public MainPage()
    {
        InitializeComponent();
        BindingContext = this;
    }

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
        Participantes = _participantes;
        Transacciones = CalculadoraVaquita.CalcularLiquidacion(_participantes);
        OnPropertyChanged(nameof(Participantes));
        OnPropertyChanged(nameof(Transacciones));

        var tieneParticipantes = _participantes.Count > 0;
        EmptyState.IsVisible = !tieneParticipantes;
        Contenido.IsVisible = tieneParticipantes;
        LimpiarContainer.IsVisible = tieneParticipantes;
        CompartirButton.IsVisible = tieneParticipantes;
        ToolbarSeparator.IsVisible = tieneParticipantes;
        LiquidacionSection.IsVisible = Transacciones.Count > 0;

        var total = _participantes.Sum(participante => participante.MontoPagado);
        var porInvitado = tieneParticipantes ? total / _participantes.Count : 0;
        TotalLabel.Text = MonedaConverter.Formatear(total);
        PorInvitadoLabel.Text = MonedaConverter.Formatear(porInvitado);
    }

    private async void OnAgregarClicked(object? sender, EventArgs e) => await AbrirEditorAsync(null);

    private async void OnParticipanteTapped(object? sender, TappedEventArgs e)
    {
        if (e.Parameter is Participante participante)
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

    private async void OnEliminarSwipeInvoked(object? sender, EventArgs e)
    {
        if ((sender as SwipeItem)?.CommandParameter is Participante participante)
            await EliminarAsync(participante);
    }

    private async Task EliminarAsync(Participante participante)
    {
        if (!await DisplayAlertAsync("¿Eliminar invitado?", $"Se eliminará a {participante.Nombre}.", "Eliminar", "Cancelar"))
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
        var mensaje = CalculadoraVaquita.GenerarMensajeWhatsApp(_participantes, Transacciones);
        await Share.Default.RequestAsync(new ShareTextRequest { Text = mensaje, Title = "Vaquita: resumen del asado" });
    }
}
