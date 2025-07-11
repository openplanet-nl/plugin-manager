namespace PluginManager
{
	void PluginUninstallAsync(ref@ metaPlugin) {
		auto plugin = cast<Meta::Plugin>(metaPlugin);
		if (plugin is null) {
			error("tried to uninstall a plugin but it was null!");
			return;
		}

		// Grab ID now since handle will be invalid after uninstalling
		const string id = plugin.ID;

		::PluginUninstallAsync(metaPlugin);

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

void PluginUninstallAsync(ref@ metaPlugin)
{
	auto plugin = cast<Meta::Plugin@>(metaPlugin);
	string pluginSourcePath = plugin.SourcePath;
	string pluginIdentifier = plugin.ID;

	warn("Uninstalling plugin " + plugin.Name);

	Meta::UnloadPlugin(plugin);
	@plugin = null;

	// Yield once to make sure the plugin is really unloaded, as UnloadPlugin only queues plugins to be unloaded rather than immediately
	yield();

	IO::Delete(pluginSourcePath);

	// Sync the plugin cache
	PluginCache::SyncRemove(pluginIdentifier);
}

void PluginInstallAsync(int siteID, const string &in identifier, const Version &in version, bool load = true)
{
	warn("Installing plugin with site ID " + siteID + " and identifier \"" + identifier + "\"");

	string savePath = IO::FromDataFolder("Plugins/" + identifier + ".op");

	// Start downloading the plugin to disk
	auto req = Net::HttpRequest();
	req.Method = Net::HttpMethod::Get;
	req.Url = Setting_BaseURL + "plugin/" + siteID + "/download";
	req.StartToFile(savePath);

	// Wait for the download to finish
	while (!req.Finished()) {
		yield();
	}

	if (load) {
		// Load the plugin
		auto plugin = Meta::LoadPlugin(savePath, Meta::PluginSource::UserFolder, Meta::PluginType::Zip);

		// Sync the plugin cache
		if (plugin !is null) {
			PluginCache::Sync(plugin);
		} else {
			PluginCache::SyncUnloaded(identifier, siteID, version);
		}
	}
}

void PluginUpdateAsync(ref@ update)
{
	auto au = cast<AvailableUpdate>(update);
	warn("Updating " + au.m_name + " from " + au.m_oldVersion + " to " + au.m_newVersion + "..");

	if (au.m_siteID == 0) {
		error("Unable to update plugin " + au.m_name + " because it has no site ID!");
		return;
	}

	// If the plugin is currently loaded
	auto installedPlugin = Meta::GetPluginFromSiteID(au.m_siteID);
	if (installedPlugin !is null) {
		// Gather dependency index and start topological sort
		auto index = Meta::PluginIndex();
		index.AddTree(installedPlugin);
		auto sortedPlugins = index.TopologicalSort();

		// Uninstall the plugin (this will also unload dependents)
		PluginUninstallAsync(installedPlugin);
		@installedPlugin = null;

		// Install the plugin without loading it
		PluginInstallAsync(au.m_siteID, au.m_identifier, Version(au.m_newVersion), false);

		// Load all plugins in the sorted index
		for (uint i = 0; i < sortedPlugins.Length; i++) {
			auto item = sortedPlugins[i];
			Meta::LoadPlugin(item.Path, item.Source, item.Type);
		}

	} else {
		// The plugin is not currently loaded, so we only have to delete the file to uninstall it
		IO::Delete(IO::FromDataFolder("Plugins/" + au.m_identifier + ".op"));

		// Install and load the plugin
		PluginInstallAsync(au.m_siteID, au.m_identifier, Version(au.m_newVersion));
	}

	// Unmark this available update
	RemoveAvailableUpdate(au);
}

void UpdateAllPluginsAsync()
{
	// Gather dependency index for each plugin that we are updating
	auto index = Meta::PluginIndex();
	for (uint i = 0; i < g_availableUpdates.Length; i++) {
		auto au = g_availableUpdates[i];
		auto installedPlugin = Meta::GetPluginFromSiteID(au.m_siteID);
		if (installedPlugin !is null) {
			index.AddTree(installedPlugin);
		}
	}
	auto sortedPlugins = index.TopologicalSort();

	// Uninstall and install the new version of each plugin
	for (uint i = 0; i < g_availableUpdates.Length; i++) {
		auto au = g_availableUpdates[i];
		auto installedPlugin = Meta::GetPluginFromSiteID(au.m_siteID);
		if (installedPlugin !is null) {
			// Uninstall the plugin (this will also unload dependents)
			PluginUninstallAsync(installedPlugin);
			@installedPlugin = null;

			// Install the plugin without loading it
			PluginInstallAsync(au.m_siteID, au.m_identifier, Version(au.m_newVersion), false);

		} else {
			// The plugin is not currently loaded, so we only have to delete the file to uninstall it
			IO::Delete(IO::FromDataFolder("Plugins/" + au.m_identifier + ".op"));

			// Install and load the plugin
			PluginInstallAsync(au.m_siteID, au.m_identifier, Version(au.m_newVersion));
		}
	}

	// Load all plugins in the sorted index
	for (uint i = 0; i < sortedPlugins.Length; i++) {
		auto item = sortedPlugins[i];
		Meta::LoadPlugin(item.Path, item.Source, item.Type);
	}

	// Clear list of available updates
	g_availableUpdates.RemoveRange(0, g_availableUpdates.Length);
}
