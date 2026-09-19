using Microsoft.Extensions.Logging;
using Vaquita.Controls;

namespace Vaquita;

public static class MauiProgram
{
	public static MauiApp CreateMauiApp()
	{
		var builder = MauiApp.CreateBuilder();
		builder
			.UseMauiApp<App>()
			.ConfigureMauiHandlers(handlers =>
			{
#if ANDROID
				Microsoft.Maui.Handlers.EntryHandler.Mapper.AppendToMapping("VaquitaDecimalEntry", (handler, view) =>
				{
					if (view is DecimalEntry)
						handler.PlatformView.InputType = Android.Text.InputTypes.ClassNumber | Android.Text.InputTypes.NumberFlagDecimal;
				});
#endif
#if IOS
				Microsoft.Maui.Handlers.EntryHandler.Mapper.AppendToMapping("VaquitaBorderlessEntry", (handler, _) =>
				{
					handler.PlatformView.BorderStyle = UIKit.UITextBorderStyle.None;
					handler.PlatformView.BackgroundColor = UIKit.UIColor.Clear;
					handler.PlatformView.Layer.BorderWidth = 0;
				});
				Microsoft.Maui.Handlers.EntryHandler.Mapper.AppendToMapping("VaquitaDecimalEntry", (handler, view) =>
				{
					if (view is DecimalEntry)
						handler.PlatformView.KeyboardType = UIKit.UIKeyboardType.DecimalPad;
				});
				Microsoft.Maui.Handlers.DatePickerHandler.Mapper.AppendToMapping("VaquitaBorderlessDatePicker", (handler, _) =>
				{
					handler.PlatformView.BorderStyle = UIKit.UITextBorderStyle.None;
					handler.PlatformView.BackgroundColor = UIKit.UIColor.Clear;
					handler.PlatformView.Layer.BorderWidth = 0;
				});
#endif
			})
			.ConfigureFonts(fonts =>
			{
				fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
				fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
			});

#if DEBUG
		builder.Logging.AddDebug();
#endif

		return builder.Build();
	}
}
