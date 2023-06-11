namespace API
{
	Net::HttpRequest@ Get(const string &in path)
	{
		if (!Setting_BaseURL.EndsWith("/")) {
			Setting_BaseURL += "/";
		}

		auto ret = Net::HttpRequest();
		ret.Method = Net::HttpMethod::Get;
		ret.Url = Setting_BaseURL + "api/" + path;
		if (Setting_VerboseLog) {
			trace("API request: " + ret.Url);
		}
		ret.Start();
		return ret;
	}

	Json::Value GetAsync(const string &in path)
	{
		auto req = Get(path);
		while (!req.Finished()) {
			yield();
		}
		return Json::Parse(req.String());
	}

	void GetPluginListAsync(string[] missing)
	{
		uint pages = 1;

		string fetchMissing = string::Join(missing, ',');
		if (fetchMissing.Length > 0) {
			for (uint i = 0; i < pages; i++) {
				Json::Value req = GetAsync("plugins?idents=" + fetchMissing + "&page=" + i);

				if (pages == 1 && req["pages"] != 1) {
					pages = req["pages"];
				}

				for (uint ii = 0; ii < req["items"].Length; ii++) {
					// kill any existing values
					for (uint iii = 0; iii < g_cachedAPIPluginList.Length; iii++) { // how deep can we go
						if (string(g_cachedAPIPluginList[iii]['identifier']) == string(req["items"][ii]['identifier'])) {
							g_cachedAPIPluginList.RemoveAt(iii);
						}
					}

					g_cachedAPIPluginList.InsertLast(req["items"][ii]);
				}

				// nap a bit so we dont wreck the Openplanet API...
				sleep(500);
			}
		}
	}

	/**
	 * special version of GetPluginListAsync for use in Render contexts
	 *
	 * only supports a single page, but its only use case is in PluginTab
	 * and if there's enough deps to cause pagination you can fuck right off.
	 */
	Net::HttpRequest@ GetPluginList(string[] missing)
	{
		string fetchMissing = string::Join(missing, ',');
		Net::HttpRequest@ req = Get("plugins?idents=" + fetchMissing);
		return req;
	}

	void GetPluginListPost(Net::HttpRequest@ request)
	{
		Json::Value req = Json::Parse(request.String());
		for (uint ii = 0; ii < req["items"].Length; ii++) {
				// kill any existing values
				for (uint iii = 0; iii < g_cachedAPIPluginList.Length; iii++) { // how deep can we go
					if (string(g_cachedAPIPluginList[iii]['identifier']) == string(req["items"][ii]['identifier'])) {
						g_cachedAPIPluginList.RemoveAt(iii);
					}
				}

				g_cachedAPIPluginList.InsertLast(req["items"][ii]);
			}
	}

	PluginInfo@ getCachedPluginInfo(const string &in ident)
	{
		Json::Value@ js;
		for (uint i = 0; i < g_cachedAPIPluginList.Length; i++) {
			if (string(g_cachedAPIPluginList[i]['identifier']).ToLower() == ident.ToLower()) {
				@js = g_cachedAPIPluginList[i];
			}
		}
		if (js !is null) {
			// not installed but we have info
			return PluginInfo(js);
		} else {
			return null;
		}
	}
}
