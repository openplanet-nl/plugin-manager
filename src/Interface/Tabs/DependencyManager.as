class DependencyManagerTab : Tab
{

	string GetLabel() override { return "Dependencies"; }

	vec4 GetColor() override { return vec4(0, 0.6f, 0.2f, 1); }

	void RenderEmpty()
	{
	}

	void Render() override
	{

		Meta::Plugin@[] loaded = Meta::AllPlugins();
		for (uint i = 0; i < loaded.Length; i++) {
			Meta::Plugin@ v = loaded[i];

			if (v.Dependencies.Length == 0 && v.OptionalDependencies.Length == 0) {
				continue;
			} else {
				string[] inChain;
				DepLeaf(v, inChain, true, false);
			}
		}
	}

	void DepLeaf(Meta::Plugin@ plugin, string[]@ inChain, bool topLevel, bool isOptional)
	{
		if (plugin.Dependencies.Length == 0 && plugin.OptionalDependencies.Length == 0) {
			_DepLeafNoChilds(plugin, isOptional, topLevel);
			return;
		}

		int flags = topLevel ? UI::TreeNodeFlags::DefaultOpen : UI::TreeNodeFlags::None;
		if (UI::TreeNode(_GetPluginTitleString(plugin, isOptional, topLevel), flags)) {
			if (inChain.Find(plugin.ID) >= 0) {
				UI::TreeAdvanceToLabelPos();
				UI::Text("Circular dependency detected...");
				UI::TreePop();
				return;
			}
			inChain.InsertLast(plugin.ID);

			for (uint i = 0; i < plugin.Dependencies.Length; i++) {
				_DepLeaf(plugin.Dependencies[i], inChain, false);
			}
			for (uint i = 0; i < plugin.OptionalDependencies.Length; i++) {
				_DepLeaf(plugin.OptionalDependencies[i], inChain, true);
			}
			UI::TreePop();
		}
	}

	void _DepLeafNoChilds(Meta::Plugin@ plugin, bool isOptional, bool isTopLevel)
	{	
		UI::TreeAdvanceToLabelPos();
		UI::Text(_GetPluginTitleString(plugin, isOptional, isTopLevel));
	}

	string _GetPluginTitleString(Meta::Plugin@ plugin, bool isOptional, bool isTopLevel) {
		string name = plugin.Name;
		if (isOptional) {
			name = "\\$666" + name;
		}
		name += " \\$999by " + plugin.Author;
		if (isTopLevel) {
			name += " (v" + plugin.Version + " installed)";
		}
		return name;
	}

	void _DepLeaf(const string &in dep, string[]@ inChain, bool isOptional)
	{
		Meta::Plugin@ child = Meta::GetPluginFromID(dep);
		if (child !is null) {
			DepLeaf(child, inChain, false, isOptional);
		} else {
			string name = dep;
			int siteID = PluginIdentToSiteID(dep);
			if (isOptional) {
				name = "\\$666" + name;
			}
			UI::TreeAdvanceToLabelPos();
			UI::Text(name + " \\$f00(not installed)\\$z");
			UI::SameLine();
			if (siteID == -1) { // could not find in api cache
				if (UI::ColoredButton(Icons::ExclamationTriangle, 0.f)) {
					OpenBrowserURL("https://openplanet.dev/plugin/"+dep);
				}
				if (UI::IsItemHovered()) {
					UI::BeginTooltip();
					UI::Text("Plugin identifier not found. Click to search on Openplanet.dev.");
					UI::EndTooltip();
				}
			} else {
				if (UI::Button(Icons::InfoCircle + "###"+dep, vec2(0, UI::GetTextLineHeight()))) {
					g_window.AddTab(PluginTab(siteID), true);
				}
			}
		}
	}

	int PluginIdentToSiteID(const string &in ident) {
		for (uint i = 0; i < g_cachedAPIPluginList.Length; i++) {
			if (g_cachedAPIPluginList[i]["identifier"] == ident) {
				return g_cachedAPIPluginList[i]["id"];
			}
		}
		return -1;
	}
}
