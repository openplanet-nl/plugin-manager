class SearchTab : PluginListTab
{
	string m_search;
	bool m_closable = false;
	uint64 m_typingStart;

	SearchTab() {}
	SearchTab(const string &in ident)
	{
		m_search = ident;
		m_closable = true;
		StartRequest();
	}

	bool CanClose() override { return m_closable; }

	string GetLabel() override
	{
		if (m_closable) {
			return Icons::Search + " " + m_search + "###Search";
		} else {
			return Icons::Search + " Search###Search";
		}
	}

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
		UI::Text("Search:");
		m_search = UI::InputText("##Search", m_search, changed);
		if (changed) {
			m_typingStart = Time::Now;
			Clear();
		}

		PluginListTab::Render();
	}
}
