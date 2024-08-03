class PluginTab : Tab
{
	Net::HttpRequest@ m_requestMain;
	Net::HttpRequest@ m_requestChangelog;

	bool m_error = false;
	string m_errorMessage;
	string m_changelogFillerMessage = "Loading changelog...";

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

		@m_requestMain = API::Get("plugin/" + siteID);
		@m_requestChangelog = API::Get("plugin/" + siteID + "/versions");
	}

	void CheckRequestMain()
	{
		// If there's a request, check if it has finished
		if (m_requestMain !is null && m_requestMain.Finished()) {
			// Parse the response
			string res = m_requestMain.String();
			int resCode = m_requestMain.ResponseCode();
			@m_requestMain = null;
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

	void CheckRequestChangelog()
	{
		// If there's a request, check if it has finished
		if (m_requestChangelog !is null && m_requestChangelog.Finished() && m_plugin !is null) {
			// Parse the response
			string res = m_requestChangelog.String();
			int resCode = m_requestChangelog.ResponseCode();
			@m_requestChangelog = null;
			auto js = Json::Parse(res);

			// Handle the response
			if (js.GetType() != Json::Type::Array) {
				m_changelogFillerMessage = "Error fetching changelog. :(";
			} else if (js.GetType() == Json::Type::Object && js.HasKey("error")) {
				m_changelogFillerMessage = "Error fetching changelog. :(";
				warn(js["error"]);
			} else {
				for (uint i = 0; i < js.Length; i++) {
					m_plugin.m_changelogs.InsertLast(PluginChangelog(js[i]));
				}
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
		}

		return true;
	}

	void InstallAsync()
	{
		m_updating = true;

		PluginInstallAsync(m_plugin.m_siteID, m_plugin.m_id, m_plugin.m_version);

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
		float scale = UI::GetScale();

		CheckRequestMain();
		CheckRequestChangelog();

		if (m_requestMain !is null) {
			UI::Text("Loading plugin..");
			return;
		}

		if (m_error) {
			UI::Text("\\$f77" + Icons::ExclamationTriangle + "\\$z Unable to get plugin! " + m_errorMessage);
			return;
		}

		vec2 posTop = UI::GetCursorPos();

		const float THUMBNAIL_WIDTH = 250 * scale;
		const float THUMBNAIL_PADDING = 8 * scale;

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

		if (m_plugin.m_sourceURL != "" && UI::Button(Icons::Code + " Source code")) {
			OpenBrowserURL(m_plugin.m_sourceURL);
		}

		if (m_plugin.m_issuesURL != "" && UI::Button(Icons::ExclamationTriangle + " Report an issue")) {
			OpenBrowserURL(m_plugin.m_issuesURL);
		}

		if (m_plugin.m_donateURL != "" && UI::ButtonColored(Icons::Heart + " Support the author", 0.8f)) {
			OpenBrowserURL(m_plugin.m_donateURL);
		}

		UI::EndChild();

		// Right side of the window
		UI::SetCursorPos(posTop + vec2(THUMBNAIL_WIDTH + THUMBNAIL_PADDING, 0));
		UI::BeginChild("Details");

		UI::PushFont(g_fontHeader);
		UI::Text(m_plugin.m_name);
		UI::PopFont();

		UI::TextDisabled("Version " + m_plugin.m_version.ToString() + " by " + m_plugin.GetAuthorNames());

		Controls::PluginTags(m_plugin);

		/*
		for (uint i = 0; i < m_plugin.m_games.Length; i++) {
			Controls::TagLink(m_plugin.m_games[i]);
			UI::SameLine();
		}
		UI::NewLine();
		*/

		if (m_plugin.m_screenshots.Length > 0) {
			UI::Separator();

			if (UI::BeginTable("Screenshots", SCREENSHOTS_PER_ROW, UI::TableColumnFlags::WidthStretch)) {
				const float WINDOW_PADDING = 8 * scale;
				const float COL_SPACING = 4 * scale;

				float colWidth = (UI::GetWindowSize().x - WINDOW_PADDING * 2 - COL_SPACING * (SCREENSHOTS_PER_ROW - 1)) / float(SCREENSHOTS_PER_ROW);
				float colHeight = (270.0f / (480.0f / colWidth));

				for (uint i = 0; i < m_plugin.m_screenshots.Length; i++) {
					string screenshot = m_plugin.m_screenshots[i];
					UI::TableNextColumn();
					auto imgScreenshot = Images::CachedFromURL(screenshot);
					if (imgScreenshot.m_texture !is null) {
						vec2 imgSize = imgScreenshot.m_texture.GetSize();

						float r_width = colWidth / imgSize.x;
						float r_height = colHeight / imgSize.y;
						float coverRatio = Math::Min(r_width, r_height);
						vec2 dst = imgSize * coverRatio;
						float r_diff = r_width - r_height;

						if (r_diff > -0.01 && r_diff < 0.01) { // close enough to 16:9
							UI::Image(imgScreenshot.m_texture, dst);
						} else if (r_diff >= 0.01) { // tall
							int sideShift = int((colWidth - dst.x) / 2.0f);
							UI::Dummy(vec2(sideShift - (6.0f * scale), 1));
							UI::SameLine();
							UI::Image(imgScreenshot.m_texture, dst);
						} else { // thicc
							int sideShift = int((colHeight - dst.y) / 2.0f);
							UI::Dummy(vec2(1, sideShift - (6.0f * scale)));
							UI::Image(imgScreenshot.m_texture, dst);
						}

						if (UI::BeginItemTooltip()) {
							UI::Image(imgScreenshot.m_texture, imgSize / 2.0f);
							if (m_plugin.m_screenshotDescriptions[i].Length > 0) {
								UI::TextWrapped(m_plugin.m_screenshotDescriptions[i]);
							}
							UI::EndTooltip();
						}
					}
				}

				UI::EndTable();
			}
		}

		UI::Separator();

		UI::Markdown(m_plugin.m_description);

		UI::Separator();

		UI::Dummy(vec2(1, UI::GetTextLineHeightWithSpacing()));
		UI::PushFont(g_fontSubHeader);
		UI::Text("Versions");
		UI::PopFont();

		UI::Separator();
		if (m_plugin.m_changelogs.Length == 0) {
			UI::Text(m_changelogFillerMessage);
		} else {
			Controls::PluginChangelogList(m_plugin, false);
		}

		UI::EndChild();
	}
}
