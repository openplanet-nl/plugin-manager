interface ITab
{
	bool IsVisible();
	bool CanClose();

	string GetLabel();

	void Render();
}
