string TransformUsername(const string &in username)
{
	if (Setting_ColoredUsernames) {
		return ColoredString(username);
	} else {
		return StripFormatCodes(username);
	}
}
