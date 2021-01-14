// 
#include "global_define.inc"

#include "csgowiki/utils.sp"
#include "csgowiki/menus.sp"

#include "csgowiki/steam_bind.sp"
#include "csgowiki/server_monitor.sp"
#include "csgowiki/utility_submit.sp"
#include "csgowiki/utility_wiki.sp"
#include "csgowiki/utility_modify.sp"

public Plugin:myinfo = {
    name = "[CSGO Wiki] Plugin-Pack",
    author = "CarOL",
    description = "Provide interactive method between www.csgowiki.top and game server",
    version = "v1.0",
    url = "https://github.com/hx-w/CSGOWiki-Plugins"
};

public OnPluginStart() {
    // event
    HookEvent("grenade_thrown", Event_GrenadeThrown);
    HookEvent("hegrenade_detonate", Event_HegrenadeDetonate);
    HookEvent("flashbang_detonate", Event_FlashbangDetonate);
    HookEvent("smokegrenade_detonate", Event_SmokegrenadeDetonate);
    HookEvent("molotov_detonate", Event_MolotovDetonate);

    // command define
    RegConsoleCmd("sm_bsteam", Command_BindSteam);
    RegConsoleCmd("sm_submit", Command_Submit);
    RegConsoleCmd("sm_wiki", Command_Wiki);
    RegConsoleCmd("sm_modify", Command_Modify);
    // global timer
    CreateTimer(10.0, ServerMonitorTimerCallback, _, TIMER_REPEAT);

    

    // post fix
    g_iServerTickrate = GetServerTickrate();


    HintColorMessageFixStart();

    // convar
    g_hCSGOWikiEnable = FindOrCreateConvar("sm_csgowiki_enable", "0", "set wether enable csgowiki plugins or not. set 0 will disable all modules belong to CSGOWiki.");
    g_hOnUtilitySubmit = FindOrCreateConvar("sm_utility_submit_on", "1", "set module: <utility_submit> on/off.");
    g_hOnUtilityWiki = FindOrCreateConvar("sm_utility_wiki_on", "1", "set module: <utility_wiki> on/off.");
    g_hOnServerMonitor = FindOrCreateConvar("sm_server_monitor_on", "1", "set module: <server_monitor> on/off");
    g_hCSGOWikiToken = FindOrCreateConvar("sm_csgowiki_token", "", "make sure csgowiki token valid. some modules will be disabled if csgowiki token invalid");

    AutoExecConfig(true, "csgowiki-pack");
}

public OnMapStart() {
    g_iServerTickrate = GetServerTickrate();
    GetCurrentMap(g_sCurrentMap, LENGTH_MAPNAME);

    CreateTimer(10.0, GetUtilityCollectionTimerCallback, _, TIMER_REPEAT);
    // reset for map start
    ResetUtilitySubmitState();
    ResetUtilityWikiState();
}

public OnClientPutInServer(client) {

    // timer define
    if (IsPlayer(client)) {
        CreateTimer(3.0, QuerySteamTimerCallback, client);
    }
    ResetSingleClientWikiState(client);
    ResetSingleClientSubmitState(client);
    ClearPlayerToken(client);
    updateServerMonitor();
}

public OnClientDisconnect(client) {

    // ResetSingleClientWikiState(client);
    ResetSingleClientSubmitState(client);
    updateServerMonitor(-1);
    ClearPlayerToken(client);
    // reset bind_flag
    ResetSteamBindFlag(client);
}

public OnPluginEnd() {
    updateServerMonitor(-1);
}


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[DATA_DIM], Float:angles[DATA_DIM], &weapon) {
    // for utility submit
    if (!buttons) return;
    if (GetConVarBool(g_hOnUtilitySubmit)) {
        OnPlayerRunCmdForUtilitySubmit(client, buttons);
    }

}

public Action:Event_GrenadeThrown(Handle:event, const String:name[], bool:dontBroadcast) { 
    if (GetConVarBool(g_hOnUtilitySubmit)) {
        Event_GrenadeThrownForUtilitySubmit(event);
    }
}


public Action:Event_HegrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast) {
    if (GetConVarBool(g_hOnUtilitySubmit)) {
        Event_HegrenadeDetonateForUtilitySubmit(event);
    }
}


public Action:Event_FlashbangDetonate(Handle:event, const String:name[], bool:dontBroadcast) {
    if (GetConVarBool(g_hOnUtilitySubmit)) {
        Event_FlashbangDetonateForUtilitySubmit(event);
    }
}


public Action:Event_SmokegrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast) {
    if (GetConVarBool(g_hOnUtilitySubmit)) {
        Event_SmokegrenadeDetonateForUtilitySubmit(event);
    }
}



public Action:Event_MolotovDetonate(Handle:event, const String:name[], bool:dontBroadcast) { 
    if (GetConVarBool(g_hOnUtilitySubmit)) {
        Event_MolotovDetonateForUtilitySubmit(event);
    }
}