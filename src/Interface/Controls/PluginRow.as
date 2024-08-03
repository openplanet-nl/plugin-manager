namespace Controls
{
	void PluginRow(PluginInfo@ plugin)
	{
		UI::PushID(plugin);

		UI::TableNextColumn();
		float imageWidth = UI::GetContentRegionAvail().x; //TODO: Get width of column
		auto img = Images::CachedFromURL(plugin.m_image);
		if (img.m_texture !is null) {
			vec2 thumbSize = img.m_texture.GetSize();
			UI::Image(img.m_texture, vec2(
				imageWidth,
				thumbSize.y / (thumbSize.x / imageWidth)
			));
			if (UI::BeginItemTooltip()) {
				UI::Image(img.m_texture, img.m_texture.GetSize() / 2);
				UI::EndTooltip();
			}
		}

		UI::TableNextColumn();
		UI::PushFont(g_fontBold);
		UI::Text(plugin.m_name);
		UI::PopFont();

		// Draw author tag
		Tag("By " + plugin.GetAuthorNames());
		UI::SameLine();

		PluginTags(plugin);

		UI::TableNextColumn();
		if (UI::Button(Icons::Eye + " Info")) {
			g_window.AddTab(PluginTab(plugin.m_siteID), true);
		}

		UI::PopID();
	}
}
