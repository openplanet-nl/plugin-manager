class LastUpdatedTab : PluginListTab
{
	string GetLabel() override { return Icons::CloudUploadAlt + " Last Updated###Last Updated"; }
	string GetRequestParams() override { return "?order=u"; }
}
