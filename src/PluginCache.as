namespace PluginCache
{
	const int CurrentVersion = 1;

	class @Info
	{
		string m_name;
		int m_siteID = 0;
		Version m_version;

		Info() {}
		Info(Json::Value@ js)
		{
			m_name = js.Get("name", "");
			m_siteID = js.Get("siteid", 0);
			m_version = Version(js.Get("version", ""));
		}

		Json::Value@ Serialize()
		{
			auto ret = Json::Object();
			ret["name"] = m_name;
			ret["siteid"] = m_siteID;
			ret["version"] = m_version.ToString();
			return ret;
		}
	}

	dictionary g_infos;
	bool g_dirty = false;

	string GetPath()
	{
		return IO::FromStorageFolder("PluginCache.json");
	}

	void Initialize()
	{
		Load();
		startnew(Loop);
	}

	void Loop()
	{
		while (true) {
			yield();
			if (g_dirty) {
				g_dirty = false;
				Save();
			}
		}
	}

	void Save()
	{
		auto pathInstalled = GetPath();

		auto js = Json::Object();
		js["version"] = 1;

		auto jsInstalled = Json::Object();
		auto arrInfosKeys = g_infos.GetKeys();
		for (uint i = 0; i < arrInfosKeys.Length; i++) {
			string key = arrInfosKeys[i];
			auto info = cast<Info>(g_infos[key]);
			jsInstalled[key] = info.Serialize();
		}
		js["installed"] = jsInstalled;

		Json::ToFile(pathInstalled, js);

		if (Setting_VerboseLog) {
			trace("Saved PluginCache.json");
		}
	}

	void Load()
	{
		g_infos.DeleteAll();

		auto pathInstalled = GetPath();
		if (!IO::FileExists(pathInstalled)) {
			return;
		}

		auto js = Json::FromFile(pathInstalled);
		if (js is null) {
			return;
		}

		if (js.GetType() != Json::Type::Object) {
			error("PluginCache.json: Root is not an object!");
			return;
		}

		auto jsVersion = js.Get("version");
		if (jsVersion is null || jsVersion.GetType() != Json::Type::Number) {
			error("PluginCache.json: \"version\" is not a number!");
			return;
		}

		if (int(jsVersion) > CurrentVersion) {
			error("PluginCache.json: Version is too new! (" + int(jsVersion) + ", we only support up to " + CurrentVersion + ")");
			return;
		}

		auto jsInstalled = js.Get("installed");
		if (jsInstalled is null || jsInstalled.GetType() != Json::Type::Object) {
			error("PluginCache.json: \"installed\" is not an object!");
			return;
		}

		auto installedKeys = jsInstalled.GetKeys();
		for (uint i = 0; i < installedKeys.Length; i++) {
			string key = installedKeys[i];
			auto jsItem = jsInstalled.Get(key);
			auto newItem = Info(jsItem);
			g_infos.Set(key, @newItem);
		}

		if (Setting_VerboseLog) {
			trace("Loaded PluginCache.json");
		}
	}

	Info@ GetInfo(const string &in id)
	{
		Info@ ret = null;
		g_infos.Get(id, @ret);
		return ret;
	}

	void Sync(Meta::Plugin@ plugin)
	{
		Info@ info;
		if (!g_infos.Get(plugin.ID, @info)) {
			@info = Info();
			g_infos.Set(plugin.ID, @info);
		}
		info.m_name = plugin.Name;
		info.m_siteID = plugin.SiteID;
		info.m_version = Version(plugin.Version);

		if (Setting_VerboseLog) {
			trace("Plugin cache: Synchronized " + plugin.ID);
		}

		// Mark the cache as dirty
		g_dirty = true;
	}

	void SyncRemove(const string &in identifier)
	{
		g_infos.Delete(identifier);

		if (Setting_VerboseLog) {
			trace("Plugin cache: Removed " + identifier);
		}

		// Mark the cache as dirty
		g_dirty = true;
	}

	void Sync()
	{
		// First we go through every plugin in the cache to see if we removed or uninstalled any
		auto arrKeys = g_infos.GetKeys();
		for (uint i = 0; i < arrKeys.Length; i++) {
			string identifier = arrKeys[i];
			auto info = cast<Info>(g_infos[identifier]);

			// Check if the plugin is currently loaded
			auto loadedPlugin = Meta::GetPluginFromSiteID(info.m_siteID);
			if (loadedPlugin !is null) {
				continue;
			}

			// The plugin is not loaded right now, check if it's unloaded
			if (IO::FileExists(IO::FromDataFolder("Plugins/" + identifier + ".op"))) {
				continue;
			}

			// The plugin is not unloaded either, so it has been removed entirely
			g_infos.Delete(identifier);

			warn("Plugin cache: Automatically removed " + identifier);
		}

		// Go through all of our loaded plugins and update the plugin cache with its current state
		auto loadedPlugins = Meta::AllPlugins();
		for (uint i = 0; i < loadedPlugins.Length; i++) {
			auto plugin = loadedPlugins[i];

			// We can only manage packaged plugins
			if (plugin.Type == Meta::PluginType::Zip) {
				Sync(plugin);
			}
		}

		// Go through all of our unloaded plugins
		auto unloadedPlugins = Meta::UnloadedPlugins();
		for (uint i = 0; i < unloadedPlugins.Length; i++) {
			auto upi = unloadedPlugins[i];

			// We can only manage packaged plugins
			if (upi.Type != Meta::PluginType::Zip) {
				continue;
			}

			// If we don't already have this plugin in the cache, we add it and assume an empty version
			if (!g_infos.Exists(upi.ID)) {
				auto newItem = Info();
				newItem.m_name = upi.ID;
				g_infos.Set(upi.ID, @newItem);
			}
		}

		// Mark the cache as dirty
		g_dirty = true;
	}
}
