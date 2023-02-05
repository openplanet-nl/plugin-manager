namespace Controls
{
	void PluginCard(PluginInfo@ plugin, float width)
	{
		UI::PushID(plugin);

		vec2 windowPos = UI::GetWindowPos();
		vec2 imagePos = UI::GetCursorPos();
		imagePos.y -= UI::GetScrollY(); // GetCursorPos doesn't include the scrolling offset

		auto img = Images::CachedFromURL(plugin.m_image);
		if (img.m_texture !is null) {
			vec2 thumbSize = img.m_texture.GetSize();
			UI::Image(img.m_texture, vec2(
				width,
				thumbSize.y / (thumbSize.x / width)
			));
		} else {
			const float EXTRA_PIXELS = 6.0f;
			UI::SetCursorPos(UI::GetCursorPos() + vec2(0, 270.0f / (480.0f / width) + EXTRA_PIXELS));
		}

		// Draw an installed tag on top of the image if it's installed
		if (plugin.GetInstalledPlugin() !is null) {
			vec2 tagPos = windowPos + imagePos + vec2(6, 6);
			DrawTag(tagPos, Icons::CheckCircle + " Installed", Controls::TAG_COLOR_PRIMARY);

			// Draw an updatable tag on top of the image if it's installed and updatable
			if (true) {
				tagPos = windowPos + imagePos + vec2(6, 36);
				DrawTag(tagPos, Icons::ArrowCircleUp + " Update!", Controls::TAG_COLOR_WARNING);

				// if updatable, show changelog in tooltip
				if(Setting_ChangelogTooltips && UI::IsItemHovered()) {
					UI::BeginTooltip();
					UI::Dummy(vec2(512,1)); // SetNextItemWidth wasnt working :(
					PluginChangelog(plugin, true);
					UI::EndTooltip();
				}
			}
		}

		// Remember where our text will go
		vec2 textPos = UI::GetCursorPos();

		UI::Text(plugin.m_name);
		UI::TextDisabled("By " + TransformUsername(plugin.m_author));

		UI::SetCursorPos(textPos + vec2(width - 40, 5));
		if (UI::Button("Info")) {
			g_window.AddTab(PluginTab(plugin.m_siteID), true);
		}

		UI::PopID();
	}
}
