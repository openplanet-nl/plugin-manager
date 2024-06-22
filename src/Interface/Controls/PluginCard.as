namespace Controls
{
	void PluginCard(PluginInfo@ plugin, float width)
	{
		if (width <= 0.0f) { return; }

		float scale = UI::GetScale();

		float tagRowHeight = 30 * scale;

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

		// Draw an installed tag on top of the image if it's installed
		uint tagRow = 0;
		vec2 tagPos;
		if (plugin.GetInstalledPlugin() !is null) {
			tagPos = windowPos + imagePos + vec2(6, 6 + (tagRowHeight * tagRow));
			DrawTag(tagPos, Icons::CheckCircle + " Installed", Controls::TAG_COLOR_PRIMARY);
			tagRow++;

			// Draw an updatable tag on top of the image if it's installed and updatable
			if (GetAvailableUpdate(plugin.m_siteID) !is null) {
				tagPos = windowPos + imagePos + vec2(6, 6 + (tagRowHeight * tagRow));
				string text = Icons::ArrowCircleUp + " Update!";
				DrawTagWithInvisButton(tagPos, windowPos, text, Controls::TAG_COLOR_WARNING);
				tagRow++;

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

		// draw alert if unsigned
		if (!plugin.m_signed) {
			tagPos = windowPos + imagePos + vec2(6, 6 + (tagRowHeight * tagRow));
			string text = Icons::Code + " Unsigned";
			DrawTagWithInvisButton(tagPos, windowPos, text, Controls::TAG_COLOR_DARK);
			tagRow++;

			if (UI::IsItemHovered()) {
				UI::BeginTooltip();
				UI::Text("This plugin is unsigned and requires developer mode.");
				UI::EndTooltip();
			}
		}

		// also draw alert on broken plugins
		if (plugin.m_broken) {
			tagPos = windowPos + imagePos + vec2(6, 6 + (tagRowHeight * tagRow));
			string text = Icons::ExclamationTriangle + " Broken";
			DrawTagWithInvisButton(tagPos, windowPos, text, Controls::TAG_COLOR_DANGER);
			tagRow++;

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
