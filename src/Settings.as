[Setting category="Updates" name="Check for plugin updates every 30 minutes"]
bool Setting_AutoCheckUpdates = true;

[Setting category="Interface" name="Show colored user names"]
bool Setting_ColoredUsernames = true;

[Setting category="Interface" name="Plugins per row" min=1 max=10]
int Setting_PluginsPerRow = 3;

[Setting category="Interface" name="Display changelog when hovering over updatable plugins."]
bool Setting_ChangelogTooltips = true;

[Setting category="Interface" name="Enable tabs pagination"]
bool Setting_TabsPagination = false;

[Setting category="Advanced" name="Base URL" description="Only change if you know what you're doing!"]
string Setting_BaseURL = "https://openplanet.dev/";

[Setting category="Advanced" name="Verbose logging (useful for development)"]
bool Setting_VerboseLog = false;

[Setting category="Advanced" name="Auto-update plugins on game startup"]
bool Setting_PerformAutoUpdates = false;
