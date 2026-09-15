using System.Globalization;

namespace Vaquita.Converters;

public sealed class MonedaConverter : IValueConverter
{
    private static readonly CultureInfo CulturaArgentina = CultureInfo.GetCultureInfo("es-AR");

    public static string Formatear(decimal monto) => monto.ToString("C0", CulturaArgentina);

    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture) =>
        value is decimal monto ? Formatear(monto) : string.Empty;

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture) =>
        throw new NotSupportedException();
}
