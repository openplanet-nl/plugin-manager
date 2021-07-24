class SearchTab : PluginListTab
{
	string m_search;
	uint64 m_typingStart;

	string GetLabel() override { return Icons::Search + " Search###Search"; }

	void GetRequestParams(dictionary@ params) override
	{
		PluginListTab::GetRequestParams(params);
		params.Set("search", m_search);
	}

	void StartRequest() override
	{
		if (m_search.Length < 2) {
			return;
		}

		PluginListTab::StartRequest();
	}

	void CheckStartRequest() override
	{
		if (m_request !is null) {
			return;
		}

		if (m_typingStart == 0) {
			return;
		}

		if (Time::Now > m_typingStart + 1000) {
			m_typingStart = 0;
			StartRequest();
		}
	}

	void Render() override
	{
		bool changed = false;
		m_search = UI::InputText("Search", m_search, changed);
		if (changed) {
			m_typingStart = Time::Now;
			Clear();
		}

		PluginListTab::Render();
	}
}
