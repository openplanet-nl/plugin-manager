namespace Controls
{
	const vec4 COLOR_PRIMARY = vec4(219/255.0f,   0/255.0f, 110/255.0f, 1);
	const vec4 COLOR_INFO    = vec4( 62/255.0f, 142/255.0f, 208/255.0f, 1);
	const vec4 COLOR_LINK    = vec4( 72/255.0f,  95/255.0f, 199/255.0f, 1);
	const vec4 COLOR_SUCCESS = vec4( 72/255.0f, 199/255.0f, 142/255.0f, 1);
	const vec4 COLOR_WARNING = vec4(255/255.0f, 224/255.0f, 138/255.0f, 1);
	const vec4 COLOR_DARK    = vec4( 22/255.0f,  32/255.0f,  42/255.0f, 1);
	const vec4 COLOR_DANGER  = vec4(241/255.0f,  70/255.0f, 104/255.0f, 1);

	const vec4 TEXT_COLOR_LIGHT = vec4(1, 1, 1, 1);
	const vec4 TEXT_COLOR_DARK  = vec4(0, 0, 0, 0.95f);

	vec4 GetTextColorForBackground(const vec4 &in backgroundColor)
	{
		if ((backgroundColor.x + backgroundColor.y + backgroundColor.z) / 3.0f > 0.6f) {
			return TEXT_COLOR_DARK;
		}
		return TEXT_COLOR_LIGHT;
	}
}
