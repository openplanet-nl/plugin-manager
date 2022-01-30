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

	bool m_isInstalled;

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
}
