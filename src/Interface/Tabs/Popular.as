class PopularTab : PluginListTab
{
	string GetLabel() override
	{
		return Icons::Fire + " Popular###Popular";
	}

	//TODO: This isn't popular yet, we need proper sorting in API
}
