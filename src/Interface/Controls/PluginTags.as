namespace Controls
{
	void PluginTags(PluginInfo@ plugin)
	{
		float scale = UI::GetScale();

		// Draw tag when the plugin is installed
		if (plugin.m_isInstalled) {
			TagPrimary(Icons::CheckCircle + " Installed");
			UI::SameLine();
		}

		// Draw an updatable tag on top of the image if it's installed and updatable
		if (GetAvailableUpdate(plugin.m_siteID) !is null) {
			TagLink(Icons::ArrowCircleUp + " Update!");

			UI::SetNextWindowSize(int(400 * scale), -1, UI::Cond::Always);
			if(Setting_ChangelogTooltips && UI::BeginItemTooltip()) {
				PluginChangelogList(plugin, true);
				UI::EndTooltip();
			}
			UI::SetNextWindowSize(0, 0);

			UI::SameLine();
		}

		if (!plugin.m_signed) {
			// Draw tag for unsigned plugins
			Tag(Icons::Code + " Unsigned");
			UI::SetItemTooltip("This plugin is unsigned and requires Developer Mode.");
			UI::SameLine();
		} else {
			// Draw tag for school mode plugins
			if (plugin.m_signType == "school") {
				TagWarning(Icons::University + " School Mode");
				UI::SetItemTooltip("This plugin requires School Mode.");
				UI::SameLine();
			}
		}

		// Draw tag on broken plugins
		if (plugin.m_broken) {
			TagDanger(Icons::ExclamationTriangle + " Broken");
			UI::SetItemTooltip("This plugin is been marked as broken! It may no longer be working as intended, might be broken, or might be very unstable.");
			UI::SameLine();
		}

		UI::NewLine();
	}
}
