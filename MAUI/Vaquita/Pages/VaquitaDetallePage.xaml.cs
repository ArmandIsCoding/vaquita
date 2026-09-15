using Vaquita.Converters;
using Vaquita.Models;
using Vaquita.Services;

namespace Vaquita.Pages;

public partial class VaquitaDetallePage : ContentPage
{
    private readonly VaquitaEvento _vaquita;
    private readonly VaquitaRepository _repository;

    public IReadOnlyList<Participante> Participantes { get; private set; } = [];

    public IReadOnlyList<Transaccion> Transacciones { get; private set; } = [];

    public VaquitaDetallePage(VaquitaEvento vaquita, VaquitaRepository repository)
    {
        InitializeComponent();
        _vaquita = vaquita;
        _repository = repository;
        BindingContext = this;

        NombreVaquitaLabel.Text = vaquita.Nombre;
        FechaLabel.Text = vaquita.FechaTexto;
        ActualizarVista();
    }

    private void ActualizarVista()
    {
        Participantes = _vaquita.Participantes
            .OrderBy(participante => participante.Nombre, StringComparer.CurrentCultureIgnoreCase)
            .ToList();
        Transacciones = CalculadoraVaquita.CalcularLiquidacion(Participantes);
        OnPropertyChanged(nameof(Participantes));
        OnPropertyChanged(nameof(Transacciones));

        var tieneParticipantes = Participantes.Count > 0;
        EmptyState.IsVisible = !tieneParticipantes;
        Contenido.IsVisible = tieneParticipantes;
        CompartirButton.IsVisible = tieneParticipantes;
        ToolbarSeparator.IsVisible = tieneParticipantes;
        LiquidacionSection.IsVisible = Transacciones.Count > 0;

        var total = Participantes.Sum(participante => participante.MontoPagado);
        var porParticipante = tieneParticipantes ? total / Participantes.Count : 0;
        TotalLabel.Text = MonedaConverter.Formatear(total);
        PorParticipanteLabel.Text = MonedaConverter.Formatear(porParticipante);
    }

    private async void OnVolverClicked(object? sender, EventArgs e) => await Navigation.PopAsync();

    private async void OnAgregarClicked(object? sender, EventArgs e) => await AbrirEditorAsync(null);

    private async void OnParticipanteTapped(object? sender, TappedEventArgs e)
    {
        if (e.Parameter is Participante participante)
            await AbrirEditorAsync(participante);
    }

    private async Task AbrirEditorAsync(Participante? participante)
    {
        var nombresConocidos = await _repository.ObtenerNombresConocidosAsync();
        await Navigation.PushModalAsync(new NavigationPage(
            new ParticipantePage(participante, nombresConocidos, GuardarParticipanteAsync)));
    }

    private async Task GuardarParticipanteAsync(Participante participante)
    {
        var indice = _vaquita.Participantes.FindIndex(actual => actual.Id == participante.Id);
        if (indice >= 0)
            _vaquita.Participantes[indice] = participante;
        else
            _vaquita.Participantes.Add(participante);

        await _repository.GuardarAsync(_vaquita);
        ActualizarVista();
    }

    private async void OnEliminarParticipanteInvoked(object? sender, EventArgs e)
    {
        if ((sender as SwipeItem)?.CommandParameter is not Participante participante)
            return;

        if (!await DisplayAlertAsync("¿Eliminar participante?", $"Se eliminará a {participante.Nombre} de esta vaquita.", "Eliminar", "Cancelar"))
            return;

        _vaquita.Participantes.RemoveAll(actual => actual.Id == participante.Id);
        await _repository.GuardarAsync(_vaquita);
        ActualizarVista();
    }

    private async void OnCompartirClicked(object? sender, EventArgs e)
    {
        var mensaje = CalculadoraVaquita.GenerarMensajeWhatsApp(_vaquita.Nombre, Participantes, Transacciones);
        await Share.Default.RequestAsync(new ShareTextRequest { Text = mensaje, Title = $"{_vaquita.Nombre}: resumen de gastos" });
    }
}
