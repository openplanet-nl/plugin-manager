class DepLeaf {
	Json::Value@ m_apiObj;
	Meta::Plugin@ m_plugin;

    string m_ident;
    int m_siteID;

    string m_name;
    string m_author;
    string m_version;

	DepLeaf@[] m_requiredChilds;
	DepLeaf@[] m_optionalChilds;

    DepLeaf() {}

    DepLeaf(Json::Value@ req)
    {
        @m_apiObj = req;

        m_ident = req["identifier"];
        m_siteID = req["id"];
        m_name = req["name"];
        m_author = req["author"];
    }

    DepLeaf(Meta::Plugin@ plug)
    {
        @m_plugin = plug;

        m_ident = plug.ID;
        m_siteID = plug.SiteID;
        m_name = plug.Name;
        m_author = plug.Author;
        m_version = plug.Version;
    }

    void PopulateChilds(DepLeaf@[]@ seen)
    {
        if (m_plugin is null) {
            return;
        }

        _PopulateChilds(seen, m_plugin.Dependencies, m_requiredChilds);
        _PopulateChilds(seen, m_plugin.OptionalDependencies, m_optionalChilds);
    }

    void _PopulateChilds(DepLeaf@[]@ seen, string[]@ deps, DepLeaf@[]@ childsArray)
    {
        for (uint i = 0; i < deps.Length; i++) {
            int seenID = GetSeenID(deps[i], seen);
            if (seenID >= 0) {
                // we've already seen this plugin, so just add a reference to the array and fuck off
                childsArray.InsertLast(seen[seenID]);
                return;
            }

            // all installed plugins are already "seen" so we gotta get from API
            int APIcacheRef = PluginIdentToSiteIDRef(deps[i]);
            DepLeaf x;
            if (APIcacheRef == -1) { // could not find in api cache
                x.m_ident = deps[i];
            } else {
                Json::Value apiRet = g_cachedAPIPluginList[APIcacheRef];
                x = DepLeaf(apiRet);
            }
            seen.InsertLast(x);
            childsArray.InsertLast(x);
            x.PopulateChilds(seen);
        }
    }

    int PluginIdentToSiteIDRef(const string &in ident)
    {
		for (uint i = 0; i < g_cachedAPIPluginList.Length; i++) {
			if (g_cachedAPIPluginList[i]["identifier"] == ident) {
				return i;
			}
		}
		return -1;
	}

    int GetSeenID(const string &in ident, DepLeaf@[]@ seen)
    {
		for (uint i = 0; i < seen.Length; i++) {
			if (seen[i].m_ident == ident) {
				return i;
			}
		}
		return -1;
	}

}
