namespace Controls
{
	const vec4 TAG_COLOR         = vec4( 30/255.0f,  32/255.0f,  33/255.0f, 1);
	const vec4 TAG_COLOR_PRIMARY = vec4(219/255.0f,   0/255.0f, 110/255.0f, 1);
	const vec4 TAG_COLOR_INFO    = vec4( 62/255.0f, 142/255.0f, 208/255.0f, 1);
	const vec4 TAG_COLOR_LINK    = vec4( 72/255.0f,  95/255.0f, 199/255.0f, 1);
	const vec4 TAG_COLOR_SUCCESS = vec4( 72/255.0f, 199/255.0f, 142/255.0f, 1);
	const vec4 TAG_COLOR_WARNING = vec4(255/255.0f, 224/255.0f, 138/255.0f, 1);
	const vec4 TAG_COLOR_DARK    = vec4( 22/255.0f,  32/255.0f,  42/255.0f, 1);
	const vec4 TAG_COLOR_DANGER  = vec4(241/255.0f,  70/255.0f, 104/255.0f, 1);
	const vec4 TAG_TEXT_COLOR_LIGHT = vec4(1, 1, 1, 1);
	const vec4 TAG_TEXT_COLOR_DARK  = vec4(0, 0, 0, 0.95f);

	const vec2 TAG_PADDING = vec2(8, 4);
	const float TAG_ROUNDING = 4;

	vec4 DrawTag(const vec4 &in rect, const string &in text, const vec4 &in color = TAG_COLOR)
	{
		auto dl = UI::GetWindowDrawList();
		dl.AddRectFilled(rect, color, TAG_ROUNDING);

		if ((color.x + color.y + color.z) / 3.0f > 0.5f) {
			dl.AddText(vec2(rect.x, rect.y) + TAG_PADDING, TAG_TEXT_COLOR_DARK, text);
		} else {
			dl.AddText(vec2(rect.x, rect.y) + TAG_PADDING, TAG_TEXT_COLOR_LIGHT, text);
		}
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

	void TagPrimary(const string &in text) { Tag(text, TAG_COLOR_PRIMARY); }
	void TagInfo(const string &in text) { Tag(text, TAG_COLOR_INFO); }
	void TagLink(const string &in text) { Tag(text, TAG_COLOR_LINK); }
	void TagSuccess(const string &in text) { Tag(text, TAG_COLOR_SUCCESS); }
	void TagWarning(const string &in text) { Tag(text, TAG_COLOR_WARNING); }
	void TagDark(const string &in text) { Tag(text, TAG_COLOR_DARK); }
	void TagDanger(const string &in text) { Tag(text, TAG_COLOR_DANGER); }
}
