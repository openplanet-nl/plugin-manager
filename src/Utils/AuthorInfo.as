class AuthorInfo
{
	string m_userName;
	string m_displayName;
	string m_sponsorURL;
	bool m_isTeam;
	bool m_isVerified;

	AuthorInfo(const Json::Value@ js)
	{
		m_userName = js["username"];
		m_displayName = js["displayname"];
		m_sponsorURL = js["sponsorurl"];
		m_isTeam = js["is_team"];
		m_isVerified = js["is_verified"];
	}

	string GetDisplayName()
	{
		string ret;
		if (m_isTeam) {
			ret += "\\$9f3" + Text::StripFormatCodes(m_displayName) + "\\$z";
		} else {
			ret += Text::StripFormatCodes(m_displayName);
		}
		if (m_isVerified) {
			ret += " " + Icons::CheckCircle;
		}
		return ret;
	}
}
