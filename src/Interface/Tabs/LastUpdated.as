class LastUpdatedTab : PluginListTab
{
	string GetLabel() override { return Icons::CloudUpload + " Last Updated###Last Updated"; }

	void GetRequestParams(dictionary@ params) override
	{
		PluginListTab::GetRequestParams(params);
		params.Set("order", "u");
	}
}
