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

	void GetPluginListAsync() {
		uint pages = 1;
		g_cachedAPIPluginList.Resize(0);

		for (uint i = 0; i < pages; i++) {
			Json::Value req = GetAsync("plugins?page=" + i);

			if (pages == 1 && req["pages"] != 1) {
				pages = req["pages"];
			}

			for (uint ii = 0; ii < req["items"].Length; ii++) {
				g_cachedAPIPluginList.InsertLast(req["items"][ii]);
			}

			// nap a bit so we dont wreck the Openplanet API...
			sleep(500);
		}
	}
}
