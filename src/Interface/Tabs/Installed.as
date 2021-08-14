class InstalledTab : PluginListTab
{
	string GetLabel() override { return Icons::Home + " Installed###Installed"; }

	vec4 GetColor() override { return Tab::GetColor(); }

	bool HasPluginsInstalled()
	{
		auto plugins = Meta::AllPlugins();
		for (uint i = 0; i < plugins.Length; i++) {
			auto au = plugins[i];
			if (au.SiteID > 0) {
				return true;
			}
		}
		return false;
	}

	void GetRequestParams(dictionary@ params) override
	{
		PluginListTab::GetRequestParams(params);

		auto plugins = Meta::AllPlugins();

		array<int> ids;
		for (uint i = 0; i < plugins.Length; i++) {
			auto au = plugins[i];
			if (au.SiteID > 0) {
				ids.InsertLast(au.SiteID);
			}
		}

		string listIds = "";
		for (uint i = 0; i < ids.Length; i++) {
			if (i > 0) {
				listIds += ",";
			}
			listIds += tostring(ids[i]);
		}
		params.Set("ids", listIds);
	}

	void StartRequest() override
	{
		if (!HasPluginsInstalled()) {
			return;
		}

		PluginListTab::StartRequest();
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
