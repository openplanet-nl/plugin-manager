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
}
