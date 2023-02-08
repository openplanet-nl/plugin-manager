class PluginChangelog
{
	int m_siteID;
	int64 m_postTime;
	Version m_version;
    bool m_isSigned;
    string m_changeMessage;

	PluginChangelog(const Json::Value &in js)
	{
		m_siteID = js["id"];
		m_postTime = js["posttime"];
		m_version = Version(js["version"]);
		m_isSigned = js["signed"];
		m_changeMessage = js["changes"];
	}
}
