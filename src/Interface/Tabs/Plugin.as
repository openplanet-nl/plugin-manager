class PluginTab : Tab
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

	bool CanClose() override { return !m_updating; }

	string GetLabel() override
	{
		string ret;
		if (m_plugin !is null) {
			ret = Icons::CodeFork + " " + m_plugin.m_name;
		} else {
			ret = "...";
		}
		return ret + "###Plugin " + m_siteID;
	}

	void StartRequest(int siteID)
	{
		m_error = false;
		m_errorMessage = "";

		@m_request = API::Get("plugin/" + siteID);
	}

	void CheckRequest()
	{
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
		@m_plugin = PluginInfo(js);
	}

	void HandleErrorResponse(const string &in message, int code)
	{
		m_error = true;
		m_errorMessage = message;

		error("Unable to get plugin: " + message + " (code " + code + ")");
	}

	bool IsInstallable()
	{
		if (m_plugin is null) {
			return false;
		}

		// See if this plugin is already installed
		auto installedPlugin = m_plugin.GetInstalledPlugin();
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

		return true;
	}

	void InstallAsync()
	{
		m_updating = true;

		PluginInstallAsync(m_plugin.m_siteID, m_plugin.m_id);

		m_plugin.m_downloads++;
		m_plugin.CheckIfInstalled();
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

	void UninstallAsync()
	{
		m_updating = true;

		auto installedPlugin = m_plugin.GetInstalledPlugin();
		if (installedPlugin !is null) {
			// Remember site ID
			int pluginSiteID = installedPlugin.SiteID;

			// If the plugin is loaded we can uninstall normally
			PluginUninstallAsync(installedPlugin);
		} else {
			// If the plugin is not loaded (but it is installed) we can just delete the file
			// This can happen when a plugin is unsigned or there's some other permission-related error
			string path = IO::FromDataFolder("Plugins/" + m_plugin.m_id + ".op");
			if (IO::FileExists(path)) {
				IO::Delete(path);
			}
		}

		// Remove from list of available updates, if it exists
		for (uint i = 0; i < g_availableUpdates.Length; i++) {
			auto au = g_availableUpdates[i];
			if (au.m_identifier == m_plugin.m_id) {
				RemoveAvailableUpdate(au);
				break;
			}
		}

		m_plugin.m_isInstalled = false;
		m_updating = false;
	}

	void RenderUpdatebuttons()
	{
		// If the plugin is not installable, don't show any buttons
		if (!IsInstallable()) {
			UI::TextDisabled("Not installable");
			return;
		}

		// Updating status text
		if (m_updating) {
			UI::Text("\\$f39" + Icons::Heartbeat + "\\$z Updating..");
			return;
		}

		// If the plugin is not installed yet, we can only install it
		if (!m_plugin.m_isInstalled) {
			if (UI::GreenButton(Icons::Download + " Install")) {
				startnew(CoroutineFunc(InstallAsync));
			}
			return;
		}

		// If there's an update available, show the update button
		if (GetAvailableUpdate(m_plugin.m_siteID) !is null) {
			if (UI::GreenButton(Icons::ArrowCircleUp + " Update")) {
				startnew(CoroutineFunc(UpdateAsync));
			}
			UI::SameLine();
		}

		// Show the uninstall button
		if (UI::RedButton(Icons::Stop + " Uninstall")) {
			startnew(CoroutineFunc(UninstallAsync));
		}
	}

	void Render() override
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

		const int SCREENSHOTS_PER_ROW = 3;

		// Left side of the window
		UI::BeginChild("Summary", vec2(THUMBNAIL_WIDTH, 0));

		auto imgThumbnail = Images::CachedFromURL(m_plugin.m_image);
		if (imgThumbnail.m_texture !is null) {
			vec2 thumbSize = imgThumbnail.m_texture.GetSize();
			UI::Image(imgThumbnail.m_texture, vec2(
				THUMBNAIL_WIDTH,
				thumbSize.y / (thumbSize.x / THUMBNAIL_WIDTH)
			));
		}

		RenderUpdatebuttons();

		UI::Text("Filename: \\$f77" + m_plugin.m_id + ".op");
		UI::Text("Downloads: \\$f77" + m_plugin.m_downloads);
		UI::Text("Last updated: \\$f77" + Time::FormatString("%F %R", m_plugin.m_updateTime));
		UI::Text("Posted: \\$f77" + Time::FormatString("%F %R", m_plugin.m_postTime));

		if (UI::Button(Icons::Link + " Open on website")) {
			OpenBrowserURL(Setting_BaseURL + m_plugin.m_url);
		}

		if (m_plugin.m_donateURL != "" && UI::ColoredButton(Icons::Heart + " Support the author", 0.8f)) {
			OpenBrowserURL(m_plugin.m_donateURL);
		}

		UI::EndChild();

		// Right side of the window
		UI::SetCursorPos(posTop + vec2(THUMBNAIL_WIDTH + THUMBNAIL_PADDING, 0));
		UI::BeginChild("Details");

		UI::PushFont(g_fontHeader);
		UI::Text(m_plugin.m_name);
		UI::PopFont();

		UI::TextDisabled("Version " + m_plugin.m_version.ToString() + " by " + TransformUsername(m_plugin.m_author));

		for (uint i = 0; i < m_plugin.m_tags.Length; i++) {
			Controls::PluginTag(m_plugin.m_tags[i]);
			UI::SameLine();
		}
		UI::NewLine();

		if (m_plugin.m_screenshots.Length > 0) {
			UI::Separator();

			if (UI::BeginTable("Screenshots", SCREENSHOTS_PER_ROW, UI::TableColumnFlags::WidthStretch)) {
				const float WINDOW_PADDING = 8;
				const float COL_SPACING = 4;

				float colWidth = (UI::GetWindowSize().x - WINDOW_PADDING * 2 - COL_SPACING * (SCREENSHOTS_PER_ROW - 1)) / float(SCREENSHOTS_PER_ROW);

				for (uint i = 0; i < m_plugin.m_screenshots.Length; i++) {
					string screenshot = m_plugin.m_screenshots[i];
					UI::TableNextColumn();
					auto imgScreenshot = Images::CachedFromURL(screenshot);
					if (imgScreenshot.m_texture !is null) {
						vec2 imgSize = imgScreenshot.m_texture.GetSize();
						UI::Image(imgScreenshot.m_texture, vec2(
							colWidth,
							imgSize.y / (imgSize.x / colWidth)
						));

						if (UI::IsItemHovered()) {
							UI::BeginTooltip();
							UI::Image(imgScreenshot.m_texture, imgSize / 2.0f);
							UI::EndTooltip();
						}
					}
				}

				UI::EndTable();
			}
		}

		UI::Separator();

		UI::Markdown(m_plugin.m_description);
		UI::EndChild();
	}
}
