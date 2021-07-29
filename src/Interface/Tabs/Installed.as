class InstalledTab : PluginListTab
{
	string GetLabel() override { return Icons::Home + " Installed###Installed"; }

	vec4 GetColor() override { return Tab::GetColor(); }

	void GetRequestParams(dictionary@ params) override
	{
		PluginListTab::GetRequestParams(params);

		auto plugins = Meta::AllPlugins();

		string ids;
		for (uint i = 0; i < plugins.Length; i++) {
			auto au = plugins[i];
			if (i > 0) {
				ids += ",";
			}
			ids += "" + au.SiteID;
		}
		params.Set("ids", ids);
	}

	void RenderEmpty() override
	{
		UI::Text("\\$f39" + Icons::Heartbeat + "\\$z No plugins installed yet. Try some of the plugins on the \\$f39Featured\\$z tab!");
	}

	void Render() override
	{
		PluginListTab::Render();

		if (m_plugins.Length > 0) {
			UI::Separator();
			UI::Text(Icons::ExclamationTriangle + " \\$f77Note\\$z: This list only includes plugins that exist on the Openplanet website.");
		}
	}
}
