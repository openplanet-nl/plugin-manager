class Tab
{
	bool IsVisible() { return true; }
	bool CanClose() { return false; }

	string GetLabel() { return ""; }

	vec4 GetColor() { return vec4(0.2f, 0.4f, 0.8f, 1); }

	void PushTabStyle()
	{
		vec4 color = GetColor();
		UI::PushStyleColor(UI::Col::Tab, color * vec4(0.8f, 0.8f, 0.8f, 1));
		UI::PushStyleColor(UI::Col::TabHovered, color * vec4(1.1f, 1.1f, 1.1f, 1));
		UI::PushStyleColor(UI::Col::TabActive, color);
	}

	void PopTabStyle()
	{
		UI::PopStyleColor(3);
	}

	void Render() {}
}
