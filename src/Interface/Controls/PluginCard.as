namespace Controls
{
	void PluginCard(PluginInfo@ plugin, float width)
	{
		if (width <= 0.0f) { return; }

		float scale = UI::GetScale();

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
			float extraPixels = 6.0f * scale;
			UI::SetCursorPos(UI::GetCursorPos() + vec2(0, 270.0f / (480.0f / width) + extraPixels));
		}

		// Start drawing tags on this card
		vec2 tagPos = windowPos + imagePos + vec2(6, 6);
		float tagRowHeight = 30 * scale;

		// Draw an installed tag on top of the image if it's installed
		if (plugin.GetInstalledPlugin() !is null) {
			DrawTag(tagPos, Icons::CheckCircle + " Installed", Controls::TAG_COLOR_PRIMARY);
			tagPos.y += tagRowHeight;

			// Draw an updatable tag on top of the image if it's installed and updatable
			if (GetAvailableUpdate(plugin.m_siteID) !is null) {
				string text = Icons::ArrowCircleUp + " Update!";
				DrawTagWithInvisButton(tagPos, windowPos, text, Controls::TAG_COLOR_LINK);
				tagPos.y += tagRowHeight;

				if(Setting_ChangelogTooltips) {
					if (UI::IsItemHovered()) {
						UI::SetNextWindowSize(int(400 * scale), -1, UI::Cond::Always);
						UI::BeginTooltip();
						PluginChangelogList(plugin, true);
						UI::EndTooltip();
					}
				}
			}
		}

		// Draw tag when unsigned
		if (!plugin.m_signed) {
			DrawTagWithInvisButton(tagPos, windowPos, Icons::Code + " Unsigned", Controls::TAG_COLOR_DARK);
			tagPos.y += tagRowHeight;

			if (UI::IsItemHovered()) {
				UI::BeginTooltip();
				UI::Text("This plugin is unsigned and requires developer mode.");
				UI::EndTooltip();
			}
		}

		// Draw tag for irregular signature types
		if (plugin.m_signed) {
			if (plugin.m_signType == "school") {
				DrawTag(tagPos, Icons::University + " School Mode", Controls::TAG_COLOR_WARNING);
				tagPos.y += tagRowHeight;
			}
		}

		// Draw tag on broken plugins
		if (plugin.m_broken) {
			DrawTagWithInvisButton(tagPos, windowPos, Icons::ExclamationTriangle + " Broken", Controls::TAG_COLOR_DANGER);
			tagPos.y += tagRowHeight;

			if (UI::IsItemHovered()) {
				UI::BeginTooltip();
				UI::Text("This plugin is been marked as broken! It may no longer be working as intended, might be broken, or might be very unstable.");
				UI::EndTooltip();
			}
		}

		// Remember where our text will go
		vec2 textPos = UI::GetCursorPos();

		UI::Text(plugin.m_name);
		UI::TextDisabled("By " + plugin.GetAuthorNames());

		UI::SetCursorPos(textPos + vec2(width - 40 * scale, 5 * scale));
		if (UI::Button("Info")) {
			g_window.AddTab(PluginTab(plugin.m_siteID), true);
		}

		UI::PopID();
	}
}
