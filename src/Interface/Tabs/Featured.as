class FeaturedTab : PluginListTab
{
	string GetLabel() override { return Icons::Star + " Featured###Featured"; }

	vec4 GetColor() override { return vec4(0.9f, 0, 0.5f, 1); }

	void GetRequestParams(dictionary@ params) override
	{
		PluginListTab::GetRequestParams(params);
		params.Set("order", "f");
	}
}
