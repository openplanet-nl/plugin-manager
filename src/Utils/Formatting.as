string TransformUsername(const string &in username)
{
	if (Setting_ColoredUsernames) {
		return Text::OpenplanetFormatCodes(username);
	} else {
		return Text::StripFormatCodes(username);
	}
}
