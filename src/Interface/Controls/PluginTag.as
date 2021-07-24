namespace Controls
{
	void PluginTag(TagInfo@ tag)
	{
		vec4 color = TAG_COLOR;
		if (tag.m_class == "is-primary") {
			color = TAG_COLOR_PRIMARY;
		} else if (tag.m_class == "is-info") {
			color = TAG_COLOR_INFO;
		} else if (tag.m_class == "is-success") {
			color = TAG_COLOR_SUCCESS;
		} else if (tag.m_class == "is-warning") {
			color = TAG_COLOR_WARNING;
		} else if (tag.m_class == "is-dark") {
			color = TAG_COLOR_DARK;
		} else if (tag.m_class == "is-danger") {
			color = TAG_COLOR_DANGER;
		}
		Controls::Tag(tag.m_name, color);
	}
}
