namespace Controls
{
	void PluginChangelogList(PluginInfo@ plugin, bool onlyUpdates = false)
	{
		for (uint i = 0; i < plugin.m_changelogs.Length; i++) {
			PluginChangelog@ v = plugin.m_changelogs[i];
			Version installedVersion = plugin.GetInstalledVersion();

			if (onlyUpdates && v.m_version <= installedVersion) {
				continue;
			}

			string date;
			if (v.m_postTime > Time::Stamp - 86400) {
				date = Time::FormatString("%X", v.m_postTime); // use time for plugins released today
			} else {
				date = Time::FormatString("%x", v.m_postTime); // otherwise use date
			}
			string title = v.m_version.ToString() + " - " + date;

			if (i > 0) {
				UI::Separator();
			}

			UI::PushFont(g_fontSubHeader);
			if (plugin.m_isInstalled && installedVersion == v.m_version) {
				UI::Text(title + " (installed)");
			} else {
				UI::Text(title);
			}
			if (!v.m_isSigned) {
				UI::SameLine();
				UI::TextDisabled(Icons::Code + " Unsigned");
			}
			UI::PopFont();
			if (!v.m_isSigned && UI::IsItemHovered()) {
				UI::BeginTooltip();
				UI::Text("This release is unsigned and requires developer mode.");
				UI::EndTooltip();
			}

			if (v.m_changeMessage.Length == 0 && i == (plugin.m_changelogs.Length-1)) {
				UI::Markdown("*Initial release*");
			} else {
				UI::Markdown(v.m_changeMessage);
			}
		}
	}
}
