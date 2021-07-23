Resources::Font@ g_fontHeader;

void Main()
{
	// Load header font
	@g_fontHeader = Resources::GetFont("DroidSans-Bold.ttf", 24);

	// Start checking for updates immediately
	CheckForUpdatesAsync();

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
