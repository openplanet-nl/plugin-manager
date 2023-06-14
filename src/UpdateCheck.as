class AvailableUpdate
{
	string m_name;
	int m_siteID;
	string m_identifier;
	string m_oldVersion;
	string m_newVersion;
	string[] m_requirements;

	bool HasMissingRequirements()
	{
		if (m_requirements.Length == 0) return false;

		for (uint i = 0; i < m_requirements.Length; i++) {
			auto plug = Meta::GetPluginFromID(m_requirements[i]);
			if (plug is null) return true;
		}
		return false;
	}
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

	// Make a list of plugin site ID's from the plugin cache to check
	string ids = "";
	auto arrPluginKeys = PluginCache::g_infos.GetKeys();
	for (uint i = 0; i < arrPluginKeys.Length; i++) {
		string identifier = arrPluginKeys[i];
		auto info = cast<PluginCache::Info>(PluginCache::g_infos[identifier]);

		if (info.m_siteID > 0) {
			ids += info.m_siteID + ",";
		} else {
			ids += identifier + ",";
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

	string[] needDepInfo;

	// Go through returned list of versions
	for (uint i = 0; i < js.Length; i++) {
		auto jsVersion = js[i];

		int siteId = jsVersion["id"];
		string siteVersion = jsVersion["version"];
		string siteIdentifier = jsVersion["identifier"];

		PluginCache::Info@ info;
		if (!PluginCache::g_infos.Get(siteIdentifier, @info)) {
			error("Unable to find plugin with identifier \"" + siteIdentifier + "\" in plugin cache! This is a bug, please report!");
			continue;
		}

		if (Version(siteVersion) <= info.m_version) {
			continue;
		}

		warn("New plugin update available for " + info.m_name + ": " + info.m_version.ToString() + " -> " + siteVersion);

		UI::ShowNotification(
			"\\$ff7" + Icons::ArrowCircleUp + "\\$z Plugin update available",
			"Version \\$ff7" + siteVersion + "\\$z is available for \\$ff7" + info.m_name + "\\$z. You can install it through the plugin manager.",
			vec4(0.27f, 0.27f, 0, 1)
		);

		auto au = AvailableUpdate();
		au.m_name = info.m_name;
		au.m_siteID = siteId;
		au.m_identifier = siteIdentifier;
		au.m_oldVersion = info.m_version.ToString();
		au.m_newVersion = siteVersion;

		if (jsVersion["required_dependencies"] == Json::Type::Array) {
			for (uint d = 0; d < jsVersion["required_dependencies"].Length; d++) {
				au.m_requirements.InsertLast(jsVersion["required_dependencies"][d]);
				if (API::getCachedPluginInfo(jsVersion["required_dependencies"][d]) is null) {
					needDepInfo.InsertLast(jsVersion["required_dependencies"][d]);
				}
			}
		}

		g_availableUpdates.InsertLast(au);
	}

	if (needDepInfo.Length > 0) {
		API::GetPluginListAsync(needDepInfo);
	}

	if (g_availableUpdates.Length == 0) {
		trace("No plugin updates found!");
	}
}

void CheckForUpdatesAsyncStartUp()
{
	// Synchronize plugin cache on startup
	PluginCache::Sync();

	// Perform the actual update check
	CheckForUpdatesAsync();

	// Automatically update plugins if we have that enabled in the settings
	if (g_availableUpdates.Length > 0 && Setting_PerformAutoUpdates) {
		for (uint i = 0; i < g_availableUpdates.Length; i++) {
			auto au = g_availableUpdates[i];
			startnew(PluginUpdateAsync, au);
		}
	}
}
