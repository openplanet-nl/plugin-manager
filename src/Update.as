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

	// Start downloading the plugin
	auto req = Net::HttpRequest();
	req.Method = Net::HttpMethod::Get;
	req.Url = Setting_BaseURL + "plugin/" + siteID + "/download";
	req.Start();

	// Wait for the download to finish
	while (!req.Finished()) {
		yield();
	}

	// Save the file
	string savePath = IO::FromDataFolder("Plugins/" + identifier + ".op");
	req.SaveToFile(savePath);

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

	// install any unmet dependencies
	for (uint i = 0; i < au.m_requirements.Length; i++) {
		auto plug = Meta::GetPluginFromID(au.m_requirements[i]);
		if (plug is null) {
			PluginInfo@ dep = API::getCachedPluginInfo(au.m_requirements[i]);
			if (dep is null) {
				error("Unable to find required plugin info: " + au.m_requirements[i]);
				continue;
			}
			PluginInstallAsync(dep.m_siteID, dep.m_id, dep.m_version);
		}
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
