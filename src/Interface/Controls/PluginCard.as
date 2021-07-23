namespace Controls
{
	void PluginCard(PluginInfo@ plugin, float width)
	{
		UI::PushID(plugin);

		auto img = Images::CachedFromURL("imgu/" + plugin.m_siteID + ".jpg?t=" + plugin.m_updateTime);

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
