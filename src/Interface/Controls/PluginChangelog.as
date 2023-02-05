namespace Controls {
    void PluginChangelog(PluginInfo@ plugin, bool onlyUpdates = false) {
		for (uint i = 0; i < plugin.m_changelog.Length; i++) {
			Changelog@ v = plugin.m_changelog[i];
			string title;
            Version installedVersion = plugin.getInstalledVersion();

            if (onlyUpdates && v.m_version <= installedVersion) {
                continue;
            }

            if (v.m_postTime > Time::Stamp - 86400) {
                title = v.m_version.ToString() + " - " + Time::FormatString("%X", v.m_postTime); // use time for plugins released today
            } else {
                title = v.m_version.ToString() + " - " + Time::FormatString("%x", v.m_postTime); // otherwise use date
            }
            
            if (i > 0) UI::Separator();
			UI::PushFont(g_fontSubHeader);
            if (plugin.m_isInstalled && installedVersion == v.m_version) {
                UI::Text(title + " (installed)");
            } else {
                UI::Text(title);
            }
            if (!v.m_isSigned) {
                UI::SameLine();
                UI::TextDisabled(Icons::Code + " Unsigned");
                UI::PopFont();
                if (UI::IsItemHovered()) {
                    UI::BeginTooltip();
                    UI::Text("This release is unsigned and requires developer mode.");
                    UI::EndTooltip();
                }
            } else {
                UI::PopFont();
            }

            if (v.m_changeMessage.Length == 0 && i == (plugin.m_changelog.Length-1)) {
                UI::Markdown("*Initial release*");
            } else {
                UI::Markdown(v.m_changeMessage);
            }
        }
    }
}
