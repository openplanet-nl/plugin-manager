class Window
{
	bool m_visible = false;

	array<Tab@> m_tabs;
	Tab@ m_selectTab;
	Tab@ m_lastActiveTab;

	Window()
	{
		AddTab(UpdatesTab());
		AddTab(DependencyManagerTab());
		AddTab(InstalledTab());

		AddTab(FeaturedTab());
		AddTab(PopularTab());
		AddTab(LastUpdatedTab());
		AddTab(NewestTab());
		AddTab(SearchTab());
	}

	void AddTab(Tab@ tab, bool select = false)
	{
		m_tabs.InsertLast(tab);
		if (select) {
			@m_selectTab = tab;
		}
	}

	void RenderTabContents(Tab@ tab)
	{
		UI::BeginChild("Tab");
		tab.Render();
		UI::EndChild();
		UI::EndTabItem();
	}

	void Render()
	{
		if (!m_visible) {
			return;
		}

		UI::SetNextWindowSize(800, 500);
		if (UI::Begin(Icons::ShoppingCart + " Plugin Manager###PluginManager", m_visible)) {
			// Push the last active tab style so that the separator line is colored (this is drawn in BeginTabBar)
			auto lastActiveTab = m_lastActiveTab;
			if (lastActiveTab !is null) {
				lastActiveTab.PushTabStyle();
			}

			UI::BeginTabBar("Tabs");

			for (uint i = 0; i < m_tabs.Length; i++) {
				auto tab = m_tabs[i];
				if (!tab.IsVisible()) {
					continue;
				}

				UI::PushID(tab);

				int flags = 0;
				if (tab is m_selectTab) {
					flags |= UI::TabItemFlags::SetSelected;
					@m_selectTab = null;
				}

				tab.PushTabStyle();

				if (tab.CanClose()) {
					bool open = true;
					if (UI::BeginTabItem(tab.GetLabel(), open, flags)) {
						@m_lastActiveTab = tab;
						RenderTabContents(tab);
					}
					if (!open) {
						m_tabs.RemoveAt(i--);
					}
				} else {
					if (UI::BeginTabItem(tab.GetLabel(), flags)) {
						@m_lastActiveTab = tab;
						RenderTabContents(tab);
					}
				}

				tab.PopTabStyle();

				UI::PopID();
			}

			UI::EndTabBar();

			// We pop the tab style (for the separator line) only after EndTabBar, to satisfy the stack unroller
			if (lastActiveTab !is null) {
				lastActiveTab.PopTabStyle();
			}
		}
		UI::End();
	}
}

Window g_window;
