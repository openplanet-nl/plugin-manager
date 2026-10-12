namespace PluginManager
{
	/*
	Queues a plugin for deletion. Note that this will invalidate the plugin object
	passed in on the next frame! Do not use the Plugin handle after calling this!
	*/
	import void PluginUninstall(Meta::Plugin@ plugin) from "PluginManager";
}
