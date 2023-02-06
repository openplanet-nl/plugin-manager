class PluginListTab : Tab
{
	Net::HttpRequest@ m_request;

	bool m_error = false;
	string m_errorMessage;

	int m_total;
	int m_page;
	int m_pageCount;
	array<PluginInfo@> m_plugins;

	uint m_lastPageRequestFinished = 0;

	string GetLabel() override { return "Plugins"; }

	vec4 GetColor() override { return vec4(0, 0.6f, 0.2f, 1); }

	void GetRequestTags(array<string>@ tags)
	{
		tags.InsertLast("Modern");

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
			m_plugins.InsertLast(PluginInfo(jsItems[i]));
		}

		m_lastPageRequestFinished = Time::Now;
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

		if (UI::BeginTable("Plugins", Setting_PluginsPerRow, UI::TableColumnFlags::WidthStretch)) {
			const float WINDOW_PADDING = 8;
			const float COL_SPACING = 4;
			float colWidth = (UI::GetWindowSize().x - WINDOW_PADDING * 2 - COL_SPACING * (Setting_PluginsPerRow - 1)) / float(Setting_PluginsPerRow);
			for (uint i = 0; i < m_plugins.Length; i++) {
				UI::TableNextColumn();
				Controls::PluginCard(m_plugins[i], colWidth);
			}

			float rowHeight = Math::Ceil(UI::GetScrollMaxY() / (m_plugins.Length / Setting_PluginsPerRow + 1));

			// draw a message before we check for being near the end
			bool haveMorePages = m_page + 1 < m_pageCount;
			if (haveMorePages) {
				UI::TableNextRow(UI::TableRowFlags::None, rowHeight);
				UI::TableNextColumn();
				string infiniteScrollMsg = (m_request is null ? "Scroll to load" : "Loading") + " page " + (m_page + 2);
				UI::Dummy(vec2(0, rowHeight / 3.0));
				UI::Text(infiniteScrollMsg);
			}
			UI::EndTable();

			// after >500ms since the last request, get the next page if there is excess vertical space or when we scroll to just a bit before the final row is in view
			bool waitedLongEnough = m_lastPageRequestFinished + 500 < Time::Now;
			bool scrolledNearEnd = UI::GetScrollMaxY() == 0 || UI::GetScrollY() > (UI::GetScrollMaxY() - rowHeight);
			if (waitedLongEnough && scrolledNearEnd && haveMorePages && m_request is null) {
				StartRequestForPage(m_page + 1);
			}
		}
	}
}
