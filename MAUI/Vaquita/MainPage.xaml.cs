using Vaquita.Models;
using Vaquita.Pages;
using Vaquita.Services;

namespace Vaquita;

public partial class MainPage : ContentPage
{
    private readonly VaquitaRepository _repository = new();

    public IReadOnlyList<VaquitaEvento> Vaquitas { get; private set; } = [];

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
        Vaquitas = (await _repository.ObtenerTodasAsync())
            .OrderByDescending(vaquita => vaquita.Fecha)
            .ThenByDescending(vaquita => vaquita.UltimaModificacion)
            .ToList();
        OnPropertyChanged(nameof(Vaquitas));

        EmptyState.IsVisible = Vaquitas.Count == 0;
        Contenido.IsVisible = Vaquitas.Count > 0;
    }

    private async void OnNuevaVaquitaClicked(object? sender, EventArgs e)
    {
        await Navigation.PushModalAsync(new NavigationPage(new VaquitaPage(CrearVaquitaAsync)));
    }

    private async Task CrearVaquitaAsync(VaquitaEvento vaquita)
    {
        await _repository.GuardarAsync(vaquita);
        await CargarAsync();
        await Navigation.PushAsync(new VaquitaDetallePage(vaquita, _repository));
    }

    private async void OnVaquitaTapped(object? sender, TappedEventArgs e)
    {
        if (e.Parameter is VaquitaEvento vaquita)
            await Navigation.PushAsync(new VaquitaDetallePage(vaquita, _repository));
    }

    private async void OnEliminarVaquitaInvoked(object? sender, EventArgs e)
    {
        if ((sender as SwipeItem)?.CommandParameter is not VaquitaEvento vaquita)
            return;

        if (!await DisplayAlertAsync("¿Eliminar vaquita?", $"Se eliminará “{vaquita.Nombre}” y todos sus gastos.", "Eliminar", "Cancelar"))
            return;

        await _repository.EliminarAsync(vaquita.Id);
        await CargarAsync();
    }
}
