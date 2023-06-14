class PluginInfo
{
	int m_siteID;
	string m_id;

	string m_name;
	string m_author;
	Version m_version;

	string m_shortDescription;
	string m_description;
	string m_donateURL;
	string m_sourceURL;
	string m_issuesURL;

	uint m_filesize;
	bool m_signed;

	int64 m_postTime;
	int64 m_updateTime;
	int m_downloads;

	string m_image;
	string m_url;

	array<string> m_screenshots;

	array<TagInfo@> m_tags;
	array<PluginChangelog@> m_changelogs;

	array<string> m_dep_req;
	array<string> m_dep_opt;

	Json::Value@ m_dep_info;

	bool m_isInstalled;

	Net::HttpRequest@ m_changelogRequest;

	PluginInfo(const Json::Value &in js)
	{
		m_siteID = js["id"];
		m_id = js["identifier"];

		m_name = js["name"];

		if (js.HasKey("authoruser")) {
			m_author = js["authoruser"]["displayname"];
		}

		m_version = Version(js["version"]);

		m_shortDescription = js["shortdescription"];
		if (js.HasKey("description")) {
			m_description = js["description"];
		}

		if (js.HasKey("links")) {
				auto jsLinks = js["links"];
				m_donateURL = jsLinks["donate"].GetType() == Json::Type::String ? jsLinks["donate"] : ""; // setting to null instead of "" crashes openplanet compiler
				m_sourceURL = jsLinks["source"].GetType() == Json::Type::String ? jsLinks["source"] : "";
				m_issuesURL = jsLinks["issues"].GetType() == Json::Type::String ? jsLinks["issues"] : "";
		}

		if (js.HasKey("dependencies") && js["dependencies"].GetType() == Json::Type::Array) {
			for (uint i = 0; i < js["dependencies"].Length; i++) {
				m_dep_req.InsertLast(js["dependencies"][i]);
			}
		}

		if (js.HasKey("optional_dependencies") && js["optional_dependencies"].GetType() == Json::Type::Array) {
			for (uint i = 0; i < js["optional_dependencies"].Length; i++) {
				m_dep_opt.InsertLast(js["optional_dependencies"][i]);
			}
		}

		m_filesize = js["filesize"];
		m_signed = js["signed"];

		m_postTime = js["posttime"];
		m_updateTime = js["updatetime"];
		m_downloads = js["downloads"];

		m_image = js["image"];
		m_url = js["url"];

		auto jsScreenshots = js["screenshots"];
		for (uint i = 0; i < jsScreenshots.Length; i++) {
			auto jsScreenshot = jsScreenshots[i];
			if (jsScreenshot.GetType() == Json::Type::String) {
				m_screenshots.InsertLast(jsScreenshot);
			}
		}

		auto jsTags = js["tags"];
		for (uint i = 0; i < jsTags.Length; i++) {
			m_tags.InsertLast(TagInfo(jsTags[i]));
		}

		CheckIfInstalled();
	}

	Meta::Plugin@ GetInstalledPlugin()
	{
		// Try to match the plugin by site ID first
		auto ret = Meta::GetPluginFromSiteID(m_siteID);
		if (ret !is null) {
			return ret;
		}

		// If we can't find it by site ID, check by its expected ID and whether its site ID is 0 (to avoid potential conflicts)
		if (m_id != "") {
			@ret = Meta::GetPluginFromID(m_id);
			if (ret !is null && ret.SiteID == 0) {
				return ret;
			}
		}

		// Found nothing
		return null;
	}

	void CheckIfInstalled()
	{
		m_isInstalled = false;

		// If the plugin is loaded, it's installed
		if (GetInstalledPlugin() !is null) {
			m_isInstalled = true;
			return;
		}

		// If the file exists in the plugin folder, it's installed
		string path = IO::FromDataFolder("Plugins/" + m_id + ".op");
		if (IO::FileExists(path)) {
			m_isInstalled = true;
			return;
		}
	}

	void LoadDependencyInfo()
	{
		string[] missingDeps = GetMissingDeps();
		if (missingDeps.Length > 0) {
			API::GetPluginListAsync(missingDeps);
		}
	}

	string[] GetMissingDeps()
	{
		string[] missingDeps;
		for (uint i = 0; i < m_dep_req.Length; i++) {
			if (Meta::GetPluginFromID(m_dep_req[i]) is null) {
				missingDeps.InsertLast(m_dep_req[i]);
			}
		}

		// copy paste for optionals
		for (uint i = 0; i < m_dep_opt.Length; i++) {
			if (Meta::GetPluginFromID(m_dep_opt[i]) is null) {
				missingDeps.InsertLast(m_dep_opt[i]);
			}
		}
		return missingDeps;
	}

	void LoadChangelog()
	{
		@m_changelogRequest = API::Get("plugin/" + m_siteID + "/versions");
	}

	void CheckChangelog()
	{
		if (m_changelogRequest is null || !m_changelogRequest.Finished()) {
			return;
		}

		string err = m_changelogRequest.Error();
		string response = m_changelogRequest.String();
		@m_changelogRequest = null;

		if (err != "") {
			error("Unable to fetch changelog for " + m_name + ": " + err);
			return;
		}

		Json::Value js = Json::Parse(response);
		if (js.GetType() == Json::Type::Object) {
			error("Unable to fetch changelog for " + m_name + ": \"" + string(js["error"]) + "\"");
			return;
		} else if (js.GetType() != Json::Type::Array) {
			error("Unable to check for updates, unexpected response from server!");
			return;
		}

		for (uint i = 0; i < js.Length; i++) {
			m_changelogs.InsertLast(PluginChangelog(js[i]));
		}
	}

	Version GetInstalledVersion()
	{
		auto plugin = Meta::GetPluginFromSiteID(m_siteID);
		if (!m_isInstalled || plugin is null) {
			return Version("0.0.0");
		}
		return Version(plugin.Version);
	}
}
