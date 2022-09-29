class AvailableUpdate
{
	string m_name;
	int m_siteID;
	string m_oldVersion;
	string m_newVersion;
	string m_filename;
}

array<AvailableUpdate@> g_availableUpdates;

AvailableUpdate@ GetAvailableUpdate(int siteId)
{
	for (uint i = 0; i < g_availableUpdates.Length; i++) {
		auto au = g_availableUpdates[i];
		if (au.m_siteID == siteId) {
			return au;
		}
	}
	return null;
}

void RemoveAvailableUpdate(AvailableUpdate@ update)
{
	int index = g_availableUpdates.FindByRef(update);
	if (index != -1) {
		g_availableUpdates.RemoveAt(index);
	}
}

void CheckForUpdatesAsync()
{
	trace("Checking for plugin updates..");

	// Clear list of available updates
	g_availableUpdates.RemoveRange(0, g_availableUpdates.Length);

	// Make a list of plugin site ID's to check
	string ids = "";
	auto plugins = Meta::AllPlugins();
	for (uint i = 0; i < plugins.Length; i++) {
		auto plugin = plugins[i];
		if (plugin.SiteID > 0) {
			ids += plugin.SiteID + ",";
		}
	}

	// No plugins with a site ID, nothing to do
	if (ids.Length == 0) {
		return;
	}

	// Request version numbers from server
	ids = ids.SubStr(0, ids.Length - 1);
	auto js = API::GetAsync("versions?ids=" + ids);
	if (js.GetType() == Json::Type::Object) {
		error("Unable to check for updates: \"" + string(js["error"]) + "\"");
		return;
	} else if (js.GetType() != Json::Type::Array) {
		error("Unable to check for updates, unexpected response from server!");
		return;
	}

	// Go through returned list of versions
	for (uint i = 0; i < js.Length; i++) {
		auto jsVersion = js[i];

		int siteId = jsVersion["id"];
		string siteVersion = jsVersion["version"];
		string siteIdentifier = jsVersion["identifier"];

		auto plugin = Meta::GetPluginFromSiteID(siteId);
		if (plugin is null) {
			continue;
		}

		if (Version(siteVersion) <= Version(plugin.Version)) {
			continue;
		}

		warn("New plugin update available for " + plugin.Name + ": " + plugin.Version + " -> " + siteVersion);

		UI::ShowNotification(
			"\\$ff7" + Icons::ArrowCircleUp + "\\$z Plugin update available",
			"Version \\$ff7" + siteVersion + "\\$z is available for \\$ff7" + plugin.Name + "\\$z. You can install it through the plugin manager.",
			vec4(0.27f, 0.27f, 0, 1)
		);

		auto au = AvailableUpdate();
		au.m_name = plugin.Name;
		au.m_siteID = siteId;
		au.m_oldVersion = plugin.Version;
		au.m_newVersion = siteVersion;
		au.m_filename = siteIdentifier + ".op";
		g_availableUpdates.InsertLast(au);
	}

	if (g_availableUpdates.Length == 0) {
		trace("No plugin updates found!");
	}
}

void CheckForUpdatesAsyncStartUp()
{
	CheckForUpdatesAsync();

	if (g_availableUpdates.Length > 0 && Setting_PerformAutoUpdates) {
		for (uint i = 0; i < g_availableUpdates.Length; i++) {
			auto au = g_availableUpdates[i];
			startnew(PluginUpdateAsync, au);
		}
	}
}
