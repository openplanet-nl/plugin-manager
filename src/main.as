UI::Font@ g_fontHeader;
UI::Font@ g_fontSubHeader;
UI::Font@ g_fontBold;

void Main()
{
	// Load fonts
	@g_fontHeader = UI::LoadFont("DroidSans.ttf", 26);
	@g_fontSubHeader = UI::LoadFont("DroidSans.ttf", 20);
	@g_fontBold = UI::LoadFont("DroidSans-Bold.ttf", 16);

	// Load plugin cache
	PluginCache::Initialize();

	// Start checking for updates immediately
	CheckForUpdatesAsyncStartUp();

	// Every 30 minutes, check for updates again
	while (true) {
		sleep(30 * 60 * 1000);
		if (Setting_AutoCheckUpdates) {
			CheckForUpdatesAsync();
		}
	}
}

void RenderInterface()
{
	g_window.Render();
}
