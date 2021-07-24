class PopularTab : PluginListTab
{
	string GetLabel() override { return Icons::Fire + " Popular###Popular"; }

	void GetRequestParams(dictionary@ params) override
	{
		PluginListTab::GetRequestParams(params);
		params.Set("order", "d");
	}
}
