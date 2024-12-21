namespace Controls
{
	const vec4 TAG_COLOR = vec4(0, 0, 0, 0.7f);
	const vec2 TAG_PADDING = vec2(8, 4);
	const float TAG_ROUNDING = 4;

	vec4 DrawTag(const vec4 &in rect, const string &in text, const vec4 &in color = TAG_COLOR)
	{
		auto dl = UI::GetWindowDrawList();
		dl.AddRectFilled(rect, color, TAG_ROUNDING);
		dl.AddText(vec2(rect.x, rect.y) + TAG_PADDING, GetTextColorForBackground(color), text);
		return rect;
	}

	vec4 DrawTag(const vec2 &in pos, const string &in text, const vec4 &in color = TAG_COLOR)
	{
		vec2 textSize = Draw::MeasureString(text);
		vec2 tagSize = textSize + TAG_PADDING * 2;
		return DrawTag(vec4(pos.x, pos.y, tagSize.x, tagSize.y), text, color);
	}

	vec4 DrawTagWithInvisButton(const vec2 &in pos, const vec2 &in windowPos, const string &in text, const vec4 &in color = TAG_COLOR)
	{
		vec4 ret = DrawTag(pos, text, color);

		vec2 cursor = UI::GetCursorPos();
		UI::SetCursorPos(pos - windowPos);
		UI::InvisibleButton("", ret.zw);
		UI::SetCursorPos(cursor);

		return ret;
	}

	void Tag(const string &in text, const vec4 &in color = TAG_COLOR)
	{
		vec2 textSize = Draw::MeasureString(text);
		UI::Dummy(textSize + TAG_PADDING * 2);
		DrawTag(UI::GetItemRect(), text, color);
	}

	void TagPrimary(const string &in text) { Tag(text, COLOR_PRIMARY); }
	void TagInfo(const string &in text) { Tag(text, COLOR_INFO); }
	void TagLink(const string &in text) { Tag(text, COLOR_LINK); }
	void TagSuccess(const string &in text) { Tag(text, COLOR_SUCCESS); }
	void TagWarning(const string &in text) { Tag(text, COLOR_WARNING); }
	void TagDanger(const string &in text) { Tag(text, COLOR_DANGER); }
}
