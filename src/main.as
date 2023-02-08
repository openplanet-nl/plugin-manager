UI::Font@ g_fontHeader;
Json::Value@[] g_cachedAPIPluginList;
UI::Font@ g_fontSubHeader;

void Main()
{
	// Load header font
	@g_fontHeader = UI::LoadFont("DroidSans.ttf", 26);
	@g_fontSubHeader = UI::LoadFont("DroidSans.ttf", 20);

	// Load plugin cache
	PluginCache::Initialize();

	// Start checking for updates immediately
	CheckForUpdatesAsyncStartUp();

	// load a list of plugins from the API for later use...
	API::GetPluginListAsync();

	// Every 30 minutes, check for updates again
	while (true) {
		sleep(30 * 60 * 1000);
		if (Setting_AutoCheckUpdates) {
			CheckForUpdatesAsync();
			API::GetPluginListAsync();
		}
	}
}

void RenderInterface()
{
	g_window.Render();
}
