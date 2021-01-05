// 
#include "csgowiki/global_define.sp"
#include "csgowiki/utils.sp"

#include "csgowiki/steam_bind.sp"

public Plugin:myinfo = {
    name = "[CSGO Wiki] Plugin-Pack",
    author = "CarOL",
    description = "Provide interactive method between www.csgowiki.top and game server",
    version = "v0.9",
    url = "https://github.com/hx-w/CSGOWiki-Plugins"
};

public void OnPluginsLoaded() {
    // convar
    g_hCSGOWikiEnable = FindConVar("sm_csgowiki_enable");
    g_hOnUtilitySubmit = FindConVar("sm_utility_submit_on");   
    g_hOnUtilityWiki = FindConVar("sm_utility_wiki_on");   
    g_hOnServerMonitor = FindConVar("sm_server_monitor_on"); 
    g_hCSGOWikiToken = FindConVar("sm_csgowiki_token");
    if (g_hCSGOWikiEnable == null) {
        g_hCSGOWikiEnable = CreateConVar("sm_csgowiki_enable", "1", "set wether enable csgowiki plugin or not. set 0 will disable all functions belong to CSGOWiki.");
    } 
    if (g_hOnUtilitySubmit == null) {
        g_hOnUtilitySubmit = CreateConVar("sm_utility_submit_on", "1", "set function: <utility_submit> on/off");
    }
    if (g_hOnUtilityWiki == null) {
        g_hOnUtilityWiki = CreateConVar("sm_utility_wiki_on", "1", "set function: <utility_wiki> on/off");
    }
    if (g_hOnServerMonitor == null) {
        g_hOnServerMonitor = CreateConVar("sm_server_monitor_on", "1", "set function: <server_monitor> on/off");
    }
    if (g_hCSGOWikiToken == null) {
        g_hCSGOWikiToken = CreateConVar("sm_csgowiki_token", "", "set csgowiki token. csgowiki functions will disabled if not set.");
    }
    AutoExecConfig(true, "csgowiki-pack");
}

public OnPluginStart() {
    // command define
    RegConsoleCmd("sm_bsteam", Command_BindSteam);
    

}

public OnClientPutInServer(client) {

    // timer define
    if (IsPlayer(client)) {
        CreateTimer(3.0, QuerySteamTimerCallback, client);
    }
}

public OnClientDisconnect(client) {

    // reset bind_flag
    resetSteamBindFlag(client);
}