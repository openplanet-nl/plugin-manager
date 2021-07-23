class FeaturedTab : PluginListTab
{
	string GetLabel() override { return Icons::Star + " Featured###Featured"; }
	string GetRequestParams() override { return "?order=f"; }
}
