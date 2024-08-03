class PluginInfo
{
	int m_siteID;
	string m_id;

	string m_name;
	array<AuthorInfo@> m_authors;
	Version m_version;

	string m_shortDescription;
	string m_description;
	string m_donateURL;
	string m_sourceURL;
	string m_issuesURL;

	uint m_filesize;
	bool m_signed;
	string m_signType;
	bool m_broken;

	int64 m_postTime;
	int64 m_updateTime;
	int m_downloads;

	string m_image;
	string m_url;

	array<string> m_screenshots;
	array<string> m_screenshotDescriptions;

	array<string> m_games;
	array<PluginChangelog@> m_changelogs;

	bool m_isInstalled;

	Net::HttpRequest@ m_changelogRequest;

	PluginInfo(const Json::Value &in js)
	{
		m_siteID = js["id"];
		m_id = js["identifier"];

		m_name = js["name"];

		if (js.HasKey("authors")) {
			auto jsAuthors = js["authors"];
			for (uint i = 0; i < jsAuthors.Length; i++) {
				m_authors.InsertLast(AuthorInfo(jsAuthors[i]));
			}
		}

		m_version = Version(js["version"]);

		m_shortDescription = js["shortdescription"];
		if (js.HasKey("description")) {
			m_description = js["description"];
		}

		if (js.HasKey("links")) {
			auto jsLinks = js["links"];
			m_donateURL = NullCoalesce(jsLinks["donate"]);
			m_sourceURL = NullCoalesce(jsLinks["source"]);
			m_issuesURL = NullCoalesce(jsLinks["issues"]);
		}

		m_filesize = js["filesize"];
		m_signed = js["signed"];
		m_signType = js["signtype"];
		m_broken = js["broken"];

		m_postTime = js["posttime"];
		m_updateTime = js["updatetime"];
		m_downloads = js["downloads"];

		m_image = js["image"];
		m_url = js["url"];

		auto jsScreenshots = js["screenshots"];
		for (uint i = 0; i < jsScreenshots.Length; i++) {
			auto jsScreenshot = jsScreenshots[i];
			if (jsScreenshot.GetType() == Json::Type::Object) {
				m_screenshots.InsertLast(jsScreenshot["uri"]);
				m_screenshotDescriptions.InsertLast(NullCoalesce(jsScreenshot["description"]));
			} else if (jsScreenshot.GetType() == Json::Type::String) {
				m_screenshots.InsertLast(string(jsScreenshot));
				m_screenshotDescriptions.InsertLast("");
			}
		}

		auto jsGames = js["games"];
		for (uint i = 0; i < jsGames.Length; i++) {
			m_games.InsertLast(jsGames[i]);
		}

		CheckIfInstalled();
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

	string GetAuthorNames()
	{
		switch (m_authors.Length) {
			case 0: return "n/a";
			case 1: return m_authors[0].GetDisplayName();
			case 2: return m_authors[0].GetDisplayName() + " and " + m_authors[1].GetDisplayName();
			default:
				{
					string ret;
					for (uint i = 0; i < m_authors.Length - 1; i++) {
						auto author = m_authors[i];
						if (i > 0) {
							ret += ", ";
						}
						ret += author.GetDisplayName();
					}
					ret += ", and " + m_authors[m_authors.Length - 1].GetDisplayName();
					return ret;
				}
		}
	}

	bool IsManagedByManager()
	{
		if (!m_isInstalled) {
			return false;
		}
		auto plugin = GetInstalledPlugin();
		return plugin !is null && plugin.Type == Meta::PluginType::Zip;
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

	Version GetInstalledVersion()
	{
		auto plugin = GetInstalledPlugin();
		if (!m_isInstalled || plugin is null) {
			return Version("0.0.0");
		}
		return Version(plugin.Version);
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

	/**
	 * one day ?? my beloved will return from the war
	 */
	string NullCoalesce(Json::Value j, const string &in ncVal = "")
	{
		if (j.GetType() == Json::Type::Null) return ncVal;
		return j;
	}
}
