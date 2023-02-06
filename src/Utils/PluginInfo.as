class TagInfo
{
	string m_type;
	string m_name;
	string m_class;
	string m_tooltip;

	TagInfo(const Json::Value &in js)
	{
		m_type = js["type"];
		m_name = js["name"];
		m_class = js["class"];
		m_tooltip = js["tooltip"];
	}
}

class Changelog
{
	int m_siteID;
	int64 m_postTime;
	Version m_version;
    bool m_isSigned;
    string m_changeMessage;

	Changelog(const Json::Value &in js)
	{
		m_siteID = js["id"];
		m_postTime = js["posttime"];
		m_version = Version(js["version"]);
		m_isSigned = js["signed"];
		m_changeMessage = js["changes"];
	}
}

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

	uint m_filesize;
	bool m_signed;

	int64 m_postTime;
	int64 m_updateTime;
	int m_downloads;

	string m_image;
	string m_url;

	array<string> m_screenshots;

	array<TagInfo@> m_tags;
	array<Changelog@> m_changelogs;

	bool m_isInstalled;

	Net::HttpRequest@ m_changelogRequest;

	PluginInfo(const Json::Value &in js)
	{
		m_siteID = js["id"];
		m_id = js["identifier"];

		m_name = js["name"];
		m_author = js["author"];
		m_version = Version(js["version"]);

		m_shortDescription = js["shortdescription"];
		if (js.HasKey("description")) {
			m_description = js["description"];
		}
		m_donateURL = js["donateurl"];

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

	void LoadChangelog() {
		@m_changelogRequest = API::Get("plugin/" + m_siteID + "/versions");
	}

	void CheckChangelog() {
		if (!m_changelogRequest.Finished()) {
			return;
		}

		Json::Value js = Json::Parse(m_changelogRequest.String());
		if (js.GetType() == Json::Type::Object) {
			error("Unable to fetch changelog for " + m_name + ": \"" + string(js["error"]) + "\"");
			return;
		} else if (js.GetType() != Json::Type::Array) {
			error("Unable to check for updates, unexpected response from server!");
			return;
		}

		for (uint i = 0; i < js.Length; i++) {
			m_changelogs.InsertLast(Changelog(js[i]));
		}
		return;
	}

	Version GetInstalledVersion()
	{
		auto _plugin = Meta::GetPluginFromSiteID(m_siteID);
		if (!m_isInstalled || _plugin is null) {
			return Version("0.0.0");
		}
		return Version(_plugin.Version);
	}
}
