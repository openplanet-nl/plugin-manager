class TagInfo
{
	string m_type;
	string m_name;
	string m_class;
	string m_tooltip;

	TagInfo(const Json::Value &in js)
	{
		m_type = js["type"];
		m_name = js["name"];
		m_class = js["class"];
		m_tooltip = js["tooltip"];
	}
}
