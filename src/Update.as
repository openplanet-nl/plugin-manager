void PluginUninstallAsync(ref@ metaPlugin)
{
	auto plugin = cast<Meta::Plugin@>(metaPlugin);
	string pluginSourcePath = plugin.SourcePath;

	warn("Uninstalling plugin " + plugin.Name);

	Meta::UnloadPlugin(plugin);
	@plugin = null;

	// Yield once to make sure the plugin is really unloaded, as UnloadPlugin only queues plugins to be unloaded rather than immediately
	yield();

	IO::Delete(pluginSourcePath);
}

void PluginInstallAsync(int siteID, const string &in filename, bool load = true)
{
	warn("Installing plugin with site ID " + siteID + " and filename \"" + filename + "\"");

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
	string savePath = IO::FromDataFolder("Plugins/" + filename);
	req.SaveToFile(savePath);

	if (load) {
		// Load the plugin
		Meta::LoadPlugin(savePath, Meta::PluginSource::UserFolder, Meta::PluginType::Zip);
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

	auto installedPlugin = Meta::GetPluginFromSiteID(au.m_siteID);

	// Gather dependency index
	auto index = Meta::PluginIndex();
	index.AddTree(installedPlugin);
	index.DependencySort();

	// Uninstall the plugin (this will also unload dependents)
	PluginUninstallAsync(installedPlugin);
	@installedPlugin = null;

	// Install the plugin without loading it
	PluginInstallAsync(au.m_siteID, au.m_filename, false);

	// Load all plugins in the sorted index
	int count = index.GetCount();
	for (int i = 0; i < count; i++) {
		auto item = index.GetItem(i);
		Meta::LoadPlugin(item.Path, item.Source, item.Type);
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
		index.AddTree(Meta::GetPluginFromSiteID(au.m_siteID));
	}
	index.DependencySort();

	// Uninstall and install the new version of each plugin
	for (uint i = 0; i < g_availableUpdates.Length; i++) {
		auto au = g_availableUpdates[i];
		PluginUninstallAsync(Meta::GetPluginFromSiteID(au.m_siteID));
		PluginInstallAsync(au.m_siteID, au.m_filename, false);
	}

	// Load all plugins in the sorted index
	int count = index.GetCount();
	for (int i = 0; i < count; i++) {
		auto item = index.GetItem(i);
		Meta::LoadPlugin(item.Path, item.Source, item.Type);
	}

	// Clear list of available updates
	g_availableUpdates.RemoveRange(0, g_availableUpdates.Length);
}
