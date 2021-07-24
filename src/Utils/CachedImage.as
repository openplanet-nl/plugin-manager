class CachedImage
{
	string m_url;
	Resources::Texture@ m_texture;

	void DownloadFromURLAsync()
	{
		auto req = Net::HttpRequest();
		req.Method = Net::HttpMethod::Get;
		req.Url = m_url;
		req.Start();
		while (!req.Finished()) {
			yield();
		}
		@m_texture = Resources::GetTexture(req.Buffer());
		if (m_texture.GetSize().x == 0) {
			@m_texture = null;
		}
	}
}

namespace Images
{
	dictionary g_cachedImages;

	CachedImage@ FindExisting(const string &in path)
	{
		CachedImage@ ret = null;
		g_cachedImages.Get(path, @ret);
		return ret;
	}

	CachedImage@ CachedFromURL(const string &in path)
	{
		// Return existing image if it already exists
		auto existing = FindExisting(path);
		if (existing !is null) {
			return existing;
		}

		// Create a new cached image object and remember it for future reference
		auto ret = CachedImage();
		ret.m_url = Setting_BaseURL + path;
		g_cachedImages.Set(path, @ret);

		// Begin downloading
		startnew(CoroutineFunc(ret.DownloadFromURLAsync));
		return ret;
	}
}
