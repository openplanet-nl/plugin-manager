void PluginUninstallAsync(ref@ metaPlugin)
{
	auto plugin = cast<Meta::Plugin@>(metaPlugin);
	if (plugin.Type != Meta::PluginType::Zip) {
		warn("Can't uninstall plugin, not a zip: " + plugin.Name);
		return;
	}

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

	// Download the plugin to disk
	auto req = Net::HttpRequest();
	req.Method = Net::HttpMethod::Get;
	req.Url = Setting_ApiBaseUrl + "/plugin/" + siteID + "/download";
	await(req.StartToFile(savePath));

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
		if (installedPlugin.Type != Meta::PluginType::Zip) {
			warn("Unable to update plugin " + installedPlugin.Name + " because it is not a zip!");
			return;
		}

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
		if (installedPlugin !is null && installedPlugin.Type == Meta::PluginType::Zip) {
			index.AddTree(installedPlugin);
		}
	}
	auto sortedPlugins = index.TopologicalSort();

	uint[] removeIndices;

	// Uninstall and install the new version of each plugin
	for (uint i = 0; i < g_availableUpdates.Length; i++) {
		auto au = g_availableUpdates[i];
		auto installedPlugin = Meta::GetPluginFromSiteID(au.m_siteID);
		if (installedPlugin !is null) {
			if (installedPlugin.Type != Meta::PluginType::Zip) {
				warn("Unable to update plugin " + installedPlugin.Name + " because it is not a zip!");
				removeIndices.InsertLast(i);
				continue;
			}

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

	for (uint i = 0; i < removeIndices.Length; i++) {
		g_availableUpdates.RemoveAt(removeIndices[i]);
	}

	// Load all plugins in the sorted index
	for (uint i = 0; i < sortedPlugins.Length; i++) {
		auto item = sortedPlugins[i];
		Meta::LoadPlugin(item.Path, item.Source, item.Type);
	}

	// Clear list of available updates
	g_availableUpdates.RemoveRange(0, g_availableUpdates.Length);
}
