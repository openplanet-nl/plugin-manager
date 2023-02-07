class DependencyManagerTab : Tab
{

	string COLOR_RI = "\\$z";
	string COLOR_OI = "\\$666";
	string COLOR_RN = "\\$f00";
	string COLOR_ON = "\\$f88";

	string GetLabel() override { return "Dependencies"; }

	vec4 GetColor() override { return vec4(0, 0.6f, 0.2f, 1); }

	void RenderEmpty()
	{
	}

	void Render() override
	{

		UI::Text(COLOR_RI + "Required dependency  ");
		UI::SameLine();
		UI::Text(COLOR_OI + "Optional dependency  ");
		UI::SameLine();
		UI::Text(COLOR_RN + "Required dependency (not installed)  ");
		UI::SameLine();
		UI::Text(COLOR_ON + "Optional dependency (not installed)  ");
		UI::Separator();

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

		string nameColorTag = isOptional ? COLOR_OI : COLOR_RI;
		int flags = topLevel ? UI::TreeNodeFlags::DefaultOpen : UI::TreeNodeFlags::None;
		if (UI::TreeNode(nameColorTag + GetPluginTitleString(plugin, topLevel), flags)) {
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
		string nameColorTag = isOptional ? COLOR_OI : COLOR_RI;
		UI::TreeAdvanceToLabelPos();
		UI::Text(nameColorTag + GetPluginTitleString(plugin, isTopLevel));
	}

	string GetPluginTitleString(Meta::Plugin@ plugin, bool isTopLevel) {
		string name = _GetPluginTitleString(plugin.Name, plugin.Author);
		if (isTopLevel) {
			name += " (v" + plugin.Version + " installed)";
		}
		return name;
	}

	string GetPluginTitleString(Json::Value@ plugin) {
		return _GetPluginTitleString(plugin["name"], plugin["author"]);
	}

	string _GetPluginTitleString(const string &in pluginName, const string &in author) {
		return pluginName + " \\$999by " + author;
	}

	void _DepLeaf(const string &in dep, string[]@ inChain, bool isOptional)
	{
		Meta::Plugin@ child = Meta::GetPluginFromID(dep);
		if (child !is null) {
			DepLeaf(child, inChain, false, isOptional);
		} else {
			int APIcacheRef = PluginIdentToSiteIDRef(dep);

			string nameColorTag = isOptional ? COLOR_ON : COLOR_RN;
			UI::TreeAdvanceToLabelPos();
			if (APIcacheRef == -1) { // could not find in api cache
				UI::Text(nameColorTag + dep + "\\$z");
				UI::SameLine();
				if (UI::ColoredButton(Icons::ExclamationTriangle, 0.f)) {
					OpenBrowserURL("https://openplanet.dev/plugin/"+dep);
				}
				if (UI::IsItemHovered()) {
					UI::BeginTooltip();
					UI::Text("Plugin identifier not found. Click to search on Openplanet.dev.");
					UI::EndTooltip();
				}
			} else {
				Json::Value apiRet = g_cachedAPIPluginList[APIcacheRef];
				UI::Text(nameColorTag + GetPluginTitleString(apiRet) + "\\$z");
				UI::SameLine();
				if (UI::Button(Icons::InfoCircle + "###"+dep)) {
					g_window.AddTab(PluginTab(g_cachedAPIPluginList[APIcacheRef]['id']), true);
				}
			}
		}
	}

	int PluginIdentToSiteIDRef(const string &in ident) {
		for (uint i = 0; i < g_cachedAPIPluginList.Length; i++) {
			if (g_cachedAPIPluginList[i]["identifier"] == ident) {
				return i;
			}
		}
		return -1;
	}
}
