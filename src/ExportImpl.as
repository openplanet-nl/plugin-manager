namespace PluginManager
{
	void PluginUninstall(Meta::Plugin@ plugin)
	{
		startnew(PluginUninstallAsync, plugin);
	}

	void PluginUninstallAsync(ref@ metaPlugin)
	{
		auto plugin = cast<Meta::Plugin>(metaPlugin);
		if (plugin is null) {
			error("tried to uninstall a plugin but it was null!");
			return;
		}

		// Grab ID now since handle will be invalid after uninstalling
		const string id = plugin.ID;

		::PluginUninstallAsync(metaPlugin);
		@metaPlugin = null;
		@plugin = null;

		// Make sure plugin tab (if open) updates correctly
		for (int i = g_window.m_tabs.Length - 1; i >= 0; i--) {
			auto tab = cast<PluginTab>(g_window.m_tabs[i]);
			if (tab !is null && tab.m_plugin !is null && tab.m_plugin.m_id == id) {
				tab.m_plugin.CheckIfInstalled();
				break;
			}
		}
	}
}
