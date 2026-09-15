using Microsoft.Extensions.Logging;

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
#if IOS
				Microsoft.Maui.Handlers.EntryHandler.Mapper.AppendToMapping("VaquitaBorderlessEntry", (handler, _) =>
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
