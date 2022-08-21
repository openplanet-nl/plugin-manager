UI::Font@ g_fontHeader;

void Main()
{
	// Load header font
	@g_fontHeader = UI::LoadFont("DroidSans.ttf", 26);

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
