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

	string m_name;
	string m_author;
	Version m_version;

	string m_shortDescription;
	string m_description;
	string m_donateURL;

	string m_filename;
	uint m_filesize;

	int64 m_postTime;
	int64 m_updateTime;
	int m_downloads;

	string m_id;

	array<TagInfo@> m_tags;

	PluginInfo(const Json::Value &in js)
	{
		m_siteID = js["id"];

		m_name = js["name"];
		m_author = js["author"];
		m_version = Version(js["version"]);

		m_shortDescription = js["shortdescription"];
		if (js.HasKey("description")) {
			m_description = js["description"];
		}
		m_donateURL = js["donateurl"];

		m_filename = js["filename"];
		m_filesize = js["filesize"];

		m_postTime = js["posttime"];
		m_updateTime = js["updatetime"];
		m_downloads = js["downloads"];

		auto jsTags = js["tags"];
		for (uint i = 0; i < jsTags.Length; i++) {
			m_tags.InsertLast(TagInfo(jsTags[i]));
		}

		if (m_filename.EndsWith(".op")) {
			m_id = m_filename.SubStr(0, m_filename.Length - 3);
		} else if (m_filename.EndsWith(".as") && m_filename.StartsWith("Plugin_")) {
			m_id = m_filename.SubStr(7, m_filename.Length - 7 - 3);
		}
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
}
