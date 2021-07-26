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

	vec4 GetColor() override { return vec4(0.6f, 0.2f, 0, 1); }

	void GetRequestParams(dictionary@ params) override
	{
		PluginListTab::GetRequestParams(params);

		string ids;
		for (uint i = 0; i < g_availableUpdates.Length; i++) {
			auto au = g_availableUpdates[i];
			if (i > 0) {
				ids += ",";
			}
			ids += "" + au.m_siteID;
		}
		params.Set("ids", ids);
	}
}
