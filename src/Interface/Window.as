class Window
{
	bool m_visible = false;

	array<ITab@> m_tabs;
	ITab@ m_selectTab;

	Window()
	{
		AddTab(UpdatesTab());

		AddTab(FeaturedTab());
		AddTab(PopularTab());
		AddTab(LastUpdatedTab());
		AddTab(NewestTab());
	}

	void AddTab(ITab@ tab, bool select = false)
	{
		m_tabs.InsertLast(tab);
		if (select) {
			@m_selectTab = tab;
		}
	}

	void RenderTabContents(ITab@ tab)
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

				if (tab.CanClose()) {
					bool open = true;
					if (UI::BeginTabItem(tab.GetLabel(), open, flags)) {
						RenderTabContents(tab);
					}
					if (!open) {
						m_tabs.RemoveAt(i--);
					}
				} else {
					if (UI::BeginTabItem(tab.GetLabel(), flags)) {
						RenderTabContents(tab);
					}
				}

				UI::PopID();
			}

			UI::EndTabBar();
		}
		UI::End();
	}
}

Window g_window;
