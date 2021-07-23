class PluginTab : ITab
{
	Net::HttpRequest@ m_request;

	bool m_error = false;
	string m_errorMessage;

	int m_siteID;
	PluginInfo@ m_plugin;

	bool m_updating = false;

	PluginTab(int siteID)
	{
		m_siteID = siteID;
		StartRequest(m_siteID);
	}

	bool IsVisible() { return true; }
	bool CanClose() { return !m_updating; }

	string GetLabel()
	{
		string ret;
		if (m_plugin !is null) {
			ret = Icons::CodeBranch + " " + m_plugin.m_name;
		} else {
			ret = "...";
		}
		return ret + "###Plugin " + m_siteID;
	}

	void StartRequest(int siteID)
	{
		m_error = false;
		m_errorMessage = "";

		@m_request = API::Get("file/" + siteID);
	}

	void CheckRequest()
	{
		// If there's a request, check if it has finished
		if (m_request !is null && m_request.Finished()) {
			// Parse the response
			string res = m_request.String();
			@m_request = null;
			auto js = Json::Parse(res);

			// Handle the response
			if (js.HasKey("error")) {
				HandleErrorResponse(js["error"]);
			} else {
				HandleResponse(js);
			}
		}
	}

	void HandleResponse(const Json::Value &in js)
	{
		@m_plugin = PluginInfo(js);
	}

	void HandleErrorResponse(const string &in message)
	{
		m_error = true;
		m_errorMessage = message;

		error("Unable to get plugin: " + message);
	}

	bool IsInstallable()
	{
		if (m_plugin is null) {
			return false;
		}

		// See if this plugin is already installed
		auto installedPlugin = Meta::GetPluginFromSiteID(m_plugin.m_siteID);
		if (installedPlugin !is null) {
			// If the installed plugin is a folder type, it's not installable
			if (installedPlugin.Type == Meta::PluginType::Folder) {
				return false;
			}

			// If the installed plugin comes from a titlepack, it's not installable
			if (installedPlugin.Source == Meta::PluginSource::TitlePack) {
				return false;
			}
		}

		// Must be a packaged plugin or a legacy script
		return m_plugin.m_filename.EndsWith(".op") ||
		       m_plugin.m_filename.EndsWith(".as");
	}

	void InstallAsync()
	{
		m_updating = true;

		PluginInstallAsync(m_plugin.m_siteID, m_plugin.m_filename);

		m_plugin.m_downloads++;
		m_updating = false;
	}

	void UpdateAsync()
	{
		m_updating = true;

		auto au = GetAvailableUpdate(m_plugin.m_siteID);
		PluginUpdateAsync(au);

		m_plugin.m_downloads++;
		m_updating = false;
	}

	void RenderUpdatebuttons()
	{
		// If the plugin is not installable, don't show any buttons
		if (!IsInstallable()) {
			return;
		}

		// Updating status text
		if (m_updating) {
			UI::Text("\\$f39" + Icons::Heartbeat + "\\$z Updating..");
			return;
		}

		// Get installed plugin info
		auto installedPlugin = Meta::GetPluginFromSiteID(m_plugin.m_siteID);

		// If the plugin is not installed yet, we can only install it
		if (installedPlugin is null) {
			if (UI::GreenButton("Install")) {
				startnew(CoroutineFunc(InstallAsync));
			}
			return;
		}

		// If there's an update available, show the update button
		if (GetAvailableUpdate(m_plugin.m_siteID) !is null) {
			if (UI::GreenButton("Update")) {
				startnew(CoroutineFunc(UpdateAsync));
			}
			UI::SameLine();
		}

		// Show the uninstall button
		if (UI::RedButton("Uninstall")) {
			PluginUninstall(installedPlugin);
			@installedPlugin = null;
		}
	}

	void Render()
	{
		CheckRequest();

		if (m_request !is null) {
			UI::Text("Loading plugin..");
			return;
		}

		if (m_error) {
			UI::Text("\\$f77" + Icons::ExclamationTriangle + "\\$z Unable to get plugin! " + m_errorMessage);
			return;
		}

		vec2 posTop = UI::GetCursorPos();

		const float THUMBNAIL_WIDTH = 250;
		const float THUMBNAIL_PADDING = 8;

		UI::BeginChild("Summary", vec2(THUMBNAIL_WIDTH, 0));

		auto img = Images::CachedFromURL("imgu/" + m_plugin.m_siteID + ".jpg?t=" + m_plugin.m_updateTime);
		if (img.m_texture !is null) {
			vec2 thumbSize = img.m_texture.GetSize();
			UI::Image(img.m_texture, vec2(
				THUMBNAIL_WIDTH,
				thumbSize.y / (thumbSize.x / THUMBNAIL_WIDTH)
			));
		}

		RenderUpdatebuttons();

		UI::Text("Filename: \\$f77" + m_plugin.m_filename);
		UI::Text("Downloads: \\$f77" + m_plugin.m_downloads);
		UI::Text("Last updated: \\$f77" + Time::FormatString("%F %R", m_plugin.m_updateTime));
		UI::Text("Posted: \\$f77" + Time::FormatString("%F %R", m_plugin.m_postTime));

		UI::EndChild();

		UI::SetCursorPos(posTop + vec2(THUMBNAIL_WIDTH + THUMBNAIL_PADDING, 0));
		UI::BeginChild("Details");

		UI::PushFont(g_fontHeader);
		UI::Text(m_plugin.m_name);
		UI::PopFont();

		UI::TextDisabled("By " + TransformUsername(m_plugin.m_author));

		UI::Separator();

		//TODO: Tags
		/*
		for (uint i = 0; i < m_plugin.m_tags.Length; i++) {
			Controls::PluginTag(m_plugin.m_tags[i]);
			UI::SameLine();
		}
		UI::NewLine();
		*/

		UI::Markdown(m_plugin.m_description);
		UI::EndChild();
	}
}
