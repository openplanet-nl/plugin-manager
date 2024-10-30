class PluginListTab : Tab
{
	Net::HttpRequest@ m_request;

	bool m_error = false;
	string m_errorMessage;

	int m_total;
	int m_page;
	int m_pageCount;
	uint m_lastPageRequestFinished = 0;

	array<PluginInfo@> m_plugins;

	string GetLabel() override { return "Plugins"; }

	vec4 GetColor() override { return vec4(0.3f, 0.3f, 0.3f, 0.7f); }

	void GetRequestTags(array<string>@ tags)
	{
#if TMNEXT || MPD
		tags.InsertLast("Trackmania");
#elif TURBO
		tags.InsertLast("Turbo");
#else
		tags.InsertLast("Maniaplanet");
#endif
	}

	void GetRequestParams(dictionary@ params)
	{
		array<string> tags;
		GetRequestTags(tags);

		string paramTags = "";
		for (uint i = 0; i < tags.Length; i++) {
			if (i > 0) {
				paramTags += ",";
			}
			paramTags += tags[i];
		}

		params.Set("tags", paramTags);
	}

	void Clear()
	{
		m_error = false;
		m_errorMessage = "";

		m_total = 0;
		m_page = 0;
		m_pageCount = 0;
		m_plugins.RemoveRange(0, m_plugins.Length);
	}

	void StartRequest()
	{
		Clear();
		StartRequestForPage(0);
	}

	void StartRequestForPage(int page)
	{
		dictionary params;
		params["page"] = tostring(page);
		GetRequestParams(params);

		string urlParams = "";
		if (!params.IsEmpty()) {
			auto keys = params.GetKeys();
			for (uint i = 0; i < keys.Length; i++) {
				string key = keys[i];
				string value;
				params.Get(key, value);

				urlParams += (i == 0 ? "?" : "&");
				urlParams += key + "=" + Net::UrlEncode(value);
			}
		}

		@m_request = API::Get("plugins" + urlParams);
	}

	void CheckStartRequest()
	{
		// If there's not already a request and the window is appearing, we start a new request
		if (m_request is null && UI::IsWindowAppearing()) {
			StartRequest();
		}
	}

	void CheckRequest()
	{
		CheckStartRequest();

		// If there's a request, check if it has finished
		if (m_request !is null && m_request.Finished()) {
			// Parse the response
			string res = m_request.String();
			int resCode = m_request.ResponseCode();
			@m_request = null;
			auto js = Json::Parse(res);

			// Handle the response
			if (js.GetType() != Json::Type::Object) {
				HandleErrorResponse(res, resCode);
			} else if (js.HasKey("error")) {
				HandleErrorResponse(js["error"], resCode);
			} else {
				HandleResponse(js);
			}
		}
	}

	void HandleResponse(const Json::Value &in js)
	{
		m_total = js["total"];
		m_page = js["page"];
		m_pageCount = js["pages"];

		auto jsItems = js["items"];
		for (uint i = 0; i < jsItems.Length; i++) {
			PluginInfo pi(jsItems[i]);
			if (Setting_ChangelogTooltips && pi.IsManagedByManager() && pi.GetInstalledVersion() < pi.m_version) {
				pi.LoadChangelog();
			}
			m_plugins.InsertLast(pi);
		}

		m_lastPageRequestFinished = Time::Now;
	}

	void CheckChangelogRequests()
	{
		for (uint i = 0; i < m_plugins.Length; i++) {
			m_plugins[i].CheckChangelog();
		}
	}

	void HandleErrorResponse(const string &in message, int code)
	{
		m_error = true;
		m_errorMessage = message;

		error("Unable to get plugin list: " + message + " (code " + code + ")");
	}

	void RenderEmpty()
	{
	}

	void Render() override
	{
		CheckRequest();
		CheckChangelogRequests();

		if (m_request !is null && m_pageCount == 0) {
			UI::Text("Loading list..");
			return;
		}

		if (m_error) {
			UI::Text("\\$f77" + Icons::ExclamationTriangle + "\\$z Unable to get plugin list! " + m_errorMessage);
			return;
		}

		if (m_plugins.Length == 0) {
			RenderEmpty();
			return;
		}

		if (Setting_ViewStyle == ViewStyle::Rows) {
			if (UI::BeginTable("Plugins", 3, UI::TableFlags::RowBg)) {
				UI::TableSetupColumn("##Image", UI::TableColumnFlags::WidthFixed, 95 * UI::GetScale());
				UI::TableSetupColumn("##Plugin");
				UI::TableSetupColumn("##Actions", UI::TableColumnFlags::WidthFixed, 70 * UI::GetScale());
				for (uint i = 0; i < m_plugins.Length; i++) {
					Controls::PluginRow(m_plugins[i]);
				}
				UI::EndTable();
			}
		} else {
			if (UI::BeginTable("Plugins", Setting_PluginsPerRow, UI::TableColumnFlags::WidthStretch)) {
				const float WINDOW_PADDING = 8 * UI::GetScale();
				const float COL_SPACING = 4 * UI::GetScale();
				float colWidth = (UI::GetWindowSize().x - WINDOW_PADDING * 2 - COL_SPACING * (Setting_PluginsPerRow - 1)) / float(Setting_PluginsPerRow);
				for (uint i = 0; i < m_plugins.Length; i++) {
					UI::TableNextColumn();
					Controls::PluginCard(m_plugins[i], colWidth);
				}
				UI::EndTable();
			}
		}

		// Handle automatic page loading
		bool haveMorePages = m_page + 1 < m_pageCount;
		bool waitedLongEnough = m_lastPageRequestFinished + 500 < Time::Now;
		bool scrolledNearEnd = UI::GetScrollMaxY() == 0 || UI::GetScrollY() >= UI::GetScrollMaxY();
		if (waitedLongEnough && scrolledNearEnd && haveMorePages && m_request is null) {
			StartRequestForPage(m_page + 1);
		}
	}
}
