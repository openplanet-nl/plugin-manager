class Version
{
	array<int> m_versions;

	Version()
	{
	}

	Version(const string &in str)
	{
		auto parse = str.Split(".");
		for (uint i = 0; i < parse.Length; i++) {
			m_versions.InsertLast(Text::ParseInt(parse[i]));
		}
	}

	Version(const Version &in other)
	{
		m_versions = other.m_versions;
	}

	string ToString()
	{
		string ret;
		for (uint i = 0; i < m_versions.Length; i++) {
			if (i > 0) {
				ret += ".";
			}
			ret += "" + m_versions[i];
		}
		return ret;
	}

	int opCmp(const Version &in other)
	{
		uint num = m_versions.Length;
		if (other.m_versions.Length > num) {
			num = other.m_versions.Length;
		}

		for (uint i = 0; i < num; i++) {
			int s = 0;
			int o = 0;

			if (i < m_versions.Length) {
				s = m_versions[i];
			}

			if (i < other.m_versions.Length) {
				o = other.m_versions[i];
			}

			if (s > o) {
				return 1;
			} else if (s < o) {
				return -1;
			}
		}

		return 0;
	}
}
