class LastUpdatedTab : PluginListTab
{
	string GetLabel() override { return Icons::CloudUploadAlt + " Last Updated###Last Updated"; }

	void GetRequestParams(dictionary@ params) override
	{
		PluginListTab::GetRequestParams(params);
		params.Set("order", "u");
	}
}
