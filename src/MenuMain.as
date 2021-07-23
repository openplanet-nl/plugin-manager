void RenderMenuMain()
{
	string menuText;
	if (g_availableUpdates.Length > 0) {
		menuText = "\\$f77" + Icons::ArrowCircleUp + " " + g_availableUpdates.Length;
	} else {
		menuText = Icons::ShoppingCart;
	}
	menuText += "\\$z Plugin Manager";

	if (UI::BeginMenu(menuText)) {
		if (UI::MenuItem("\\$f39" + Icons::ShoppingCart + "\\$z Open manager", "", g_window.m_visible)) {
			g_window.m_visible = !g_window.m_visible;
		}

		if (UI::MenuItem(Icons::UndoAlt + " Check for updates")) {
			startnew(CheckForUpdatesAsync);
		}

		UI::Separator();

		if (g_availableUpdates.Length == 0) {
			UI::TextDisabled("No updates available!");
		} else {
			if (UI::MenuItem("\\$9f3" + Icons::ArrowCircleUp + " Update all plugins")) {
				for (uint i = 0; i < g_availableUpdates.Length; i++) {
					auto au = g_availableUpdates[i];
					startnew(PluginUpdateAsync, au);
				}
			}

			for (uint i = 0; i < g_availableUpdates.Length; i++) {
				auto au = g_availableUpdates[i];
				if (UI::MenuItem(Icons::ArrowCircleUp + " Update " + au.m_name + " to " + au.m_newVersion)) {
					startnew(PluginUpdateAsync, au);
				}
			}
		}

		UI::EndMenu();
	}
}
