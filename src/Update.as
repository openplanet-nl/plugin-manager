void PluginUninstall(Meta::Plugin@ plugin)
{
	string pluginSourcePath = plugin.SourcePath;

	Meta::UnloadPlugin(plugin);
	@plugin = null;

	trace("Deleting plugin file: \"" + pluginSourcePath + "\"");

	IO::Delete(pluginSourcePath);
}

void PluginInstallAsync(int siteID, const string &in filename)
{
	warn("Installing plugin with site ID " + siteID + " and filename \"" + filename + "\"");

	// Start downloading the plugin
	auto req = Net::HttpRequest();
	req.Method = Net::HttpMethod::Get;
	req.Url = Setting_BaseURL + "files/get/" + siteID;
	req.Start();

	// Wait for the download to finish
	while (!req.Finished()) {
		yield();
	}

	// Find out where to save it to
	string savePath;
	auto pluginType = Meta::PluginType::Unknown;
	if (filename.EndsWith(".op")) {
		savePath = IO::FromDataFolder("Plugins/" + filename);
		pluginType = Meta::PluginType::Zip;
	} else if (filename.EndsWith(".as")) {
		savePath = IO::FromDataFolder("Scripts/" + filename);
		pluginType = Meta::PluginType::Legacy;
	} else {
		error("Don't know where to install plugin with site ID " + siteID + " to! (Filename: \"" + filename + "\")");
		return;
	}

	// Save the file
	trace("Saving plugin file: \"" + savePath + "\"");
	req.SaveToFile(savePath);

	// Load the plugin
	Meta::LoadPlugin(savePath, Meta::PluginSource::UserFolder, pluginType);
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
	PluginUninstall(installedPlugin);
	@installedPlugin = null;

	// Install the plugin
	PluginInstallAsync(au.m_siteID, au.m_filename);

	// Unmark this available update
	RemoveAvailableUpdate(au);
}
