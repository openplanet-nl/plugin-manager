class UpdatesTab : PluginListTab
{
	bool IsVisible() override
	{
		return g_availableUpdates.Length > 0;
	}

	string GetLabel() override
	{
		return "\\$f77" + Icons::ArrowCircleUp + " " + g_availableUpdates.Length + "\\$z Updates###Updates";
	}

	string GetRequestParams() override
	{
		string ret = "?ids=";
		for (uint i = 0; i < g_availableUpdates.Length; i++) {
			auto au = g_availableUpdates[i];
			if (i > 0) {
				ret += ",";
			}
			ret += "" + au.m_siteID;
		}
		return ret;
	}
}
