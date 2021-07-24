class FeaturedTab : PluginListTab
{
	string GetLabel() override { return Icons::Star + " Featured###Featured"; }

	void GetRequestParams(dictionary@ params) override
	{
		PluginListTab::GetRequestParams(params);
		params.Set("order", "f");
	}
}
