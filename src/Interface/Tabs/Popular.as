class PopularTab : PluginListTab
{
	string GetLabel() override { return Icons::Fire + " Popular###Popular"; }
	string GetRequestParams() override { return "?order=d"; }
}
