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
	}
}
