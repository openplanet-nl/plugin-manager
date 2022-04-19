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

void PluginInstallAsync(int siteID, const string &in filename)
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

	// Load the plugin
	Meta::LoadPlugin(savePath, Meta::PluginSource::UserFolder, Meta::PluginType::Zip);
}

void PluginUpdateAsync(ref@ update)
{
	auto au = cast<AvailableUpdate>(update);
	warn("Updating " + au.m_name + " from " + au.m_oldVersion + " to " + au.m_newVersion + "..");

	if (au.m_siteID == 0) {
		error("Unable to update plugin " + au.m_name + " because it has no site ID!");
		return;
	}

	Meta::PluginSource pluginSource;
	Meta::PluginType pluginType;
	string pluginPath;

	auto installedPlugin = Meta::GetPluginFromSiteID(au.m_siteID);
	if (installedPlugin !is null) {
		// Remember where the plugin came from
		pluginSource = installedPlugin.Source;
		pluginType = installedPlugin.Type;
		pluginPath = installedPlugin.SourcePath;
	}

	// Uninstall the plugin
	PluginUninstallAsync(installedPlugin);
	@installedPlugin = null;

	// Install the plugin
	PluginInstallAsync(au.m_siteID, au.m_filename);

	// Unmark this available update
	RemoveAvailableUpdate(au);
}
