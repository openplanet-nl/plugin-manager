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
			_DepLeafNoChilds(plugin, isOptional);
			return;
		}

		int flags = topLevel ? UI::TreeNodeFlags::DefaultOpen : UI::TreeNodeFlags::None;
		if (UI::TreeNode(_GetPluginTitleString(plugin, isOptional), flags)) {
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

	void _DepLeafNoChilds(Meta::Plugin@ plugin, bool isOptional)
	{	
		UI::TreeAdvanceToLabelPos();
		UI::Text(_GetPluginTitleString(plugin, isOptional));
	}

	string _GetPluginTitleString(Meta::Plugin@ plugin, bool isOptional) {
		string name = plugin.Name;
		if (isOptional) {
			name = "\\$666" + name;
		}
		name += " by " + plugin.Author + " (v" + plugin.Version + ")";
		return name;
	}

	void _DepLeaf(const string &in dep, string[]@ inChain, bool isOptional)
	{
		Meta::Plugin@ child = Meta::GetPluginFromID(dep);
		if (child !is null) {
			DepLeaf(child, inChain, false, isOptional);
		} else {
			string name = dep;
			if (isOptional) {
				name = "\\$666" + name;
			}
			UI::TreeAdvanceToLabelPos();
			UI::Text(name + " \\$f00(not installed)\\$z");
			UI::SameLine();
			if (UI::Button("Info###"+dep, vec2(0, UI::GetTextLineHeight()))) {
				g_window.AddTab(PluginTab(PluginIdentToSiteID(dep)), true);
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
