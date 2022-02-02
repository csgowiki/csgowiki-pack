// 
#include <csgowiki>

#include "csgowiki/utils.sp"
#include "csgowiki/panel.sp"

#include "csgowiki/steam_bind.sp"
#include "csgowiki/utility_submit.sp"
#include "csgowiki/utility_wiki.sp"
#include "csgowiki/utility_modify.sp"
#include "csgowiki/kicker.sp"
#include "csgowiki/replay.sp"


public Plugin:myinfo = {
    name = "[CSGOWiki] Plugin-Pack",
    author = "CarOL",
    description = "An Sourcemod Instance For [CSGOWiki-Web] Service",
    version = "v1.4.4",
    url = "https://docs.csgowiki.top/plugins"
};

public OnPluginStart() {
    // event
    HookEvent("hegrenade_detonate", Event_HegrenadeDetonate);
    HookEvent("flashbang_detonate", Event_FlashbangDetonate);
    HookEvent("smokegrenade_detonate", Event_SmokegrenadeDetonate);
    HookEvent("molotov_detonate", Event_MolotovDetonate);

    // command define
    // RegConsoleCmd("sm_bsteam", Command_BindSteam);
    RegAdminCmd("sm_srec", Command_Record, ADMFLAG_CHEATS);
    RegAdminCmd("sm_frec", Command_StopRecord, ADMFLAG_CHEATS);

    RegConsoleCmd("sm_submit", Command_Submit);
    RegConsoleCmd("sm_wiki", Command_Wiki);
    RegConsoleCmd("sm_abort", Command_SubmitAbort);

    RegConsoleCmd("sm_m", Command_Panel);

    RegConsoleCmd("sm_option", Command_Option);
    RegConsoleCmd("sm_wikipro", Command_WikiPro);

    RegConsoleCmd("sm_refresh", Command_Refresh);

    RegAdminCmd("sm_modify", Command_Modify, ADMFLAG_CHEATS);
    RegAdminCmd("sm_wikiop", Command_Wikiop, ADMFLAG_CHEATS);
    RegAdminCmd("sm_vel", Command_Velocity, ADMFLAG_GENERIC);

    // post fix
    g_iServerTickrate = GetServerTickrate();

    HintColorMessageFixStart();

    // convar
    g_hWikiAutoKicker = FindOrCreateConvar("sm_wiki_auto_kick", "0", "Set how long(min) can the player stay in server without binding csgowiki account. Set 0 to disable this kicker", 0.0, 10.0);
    g_hCSGOWikiEnable = FindOrCreateConvar("sm_csgowiki_enable", "0", "Set wether enable csgowiki plugins or not. Set 0 will disable all modules belong to CSGOWiki.");
    g_hOnUtilitySubmit = FindOrCreateConvar("sm_utility_submit_on", "1", "Set module: <utility_submit> on/off.");
    g_hOnUtilityWiki = FindOrCreateConvar("sm_utility_wiki_on", "1", "Set module: <utility_wiki> on/off.");
    g_hCSGOWikiToken = FindOrCreateConvar("sm_csgowiki_token", "", "Make sure csgowiki token valid. Some modules will be disabled if csgowiki token invalid", -1.0, -1.0, true);
    g_hWikiReqLimit = FindOrCreateConvar("sm_wiki_request_limit", "1", "Limit cooling time(second) for each player's `!wiki` request. Set 0 to unlimit", 0.0, 10.0);
    g_hApiHost = FindOrCreateConvar("sm_csgowiki_apihost", "http://121.40.123.93:2333", "Alternative option for this setting is `https://api.mycsgolab.com` which source in Hongkong");
	g_hLocalCacheEnable = FindOrCreateConvar("sm_csgowiki_cache_enable", "1", "Enable local cache.");
	g_hLocalCacheFileLimit = FindOrCreateConvar("sm_csgowiki_cache_limit","500","Set the limit of the cache files. set -1 for unlimit.");


    HookOpConVarChange();

    AutoExecConfig(true, "csgowiki-pack");
}

public OnPluginEnd() {
}

public void OnLibraryAdded(const char[] name) {
    g_bBotMimicLoaded = LibraryExists("botmimic_fix");
}

public void OnLibraryRemoved(const char[] name) {
    g_bBotMimicLoaded = LibraryExists("botmimic_fix");
}

public OnMapStart() {
    g_iServerTickrate = GetServerTickrate();
    GetCurrentMap(g_sCurrentMap, LENGTH_MAPNAME);

    // reset for map start
    ResetUtilitySubmitState();
    ResetUtilityWikiState();
    ResetReqLock();

    // init collection
    GetAllCollection();

	// initialize cache
    EnforceDirExists("data/csgowiki/cache/replays");
    EnforceDirExists("data/csgowiki/cache/path");
	if (check_function_on(g_hLocalCacheEnable,"")) {
        EnforceDirExists("data/csgowiki/cache/detail");
	}
}

public OnMapEnd() {
    // delete g_aProMatchInfo;
}

public OnConfigsExecuted() {
    PluginVersionCheck();
}

public OnClientPutInServer(client) {
    // timer define
    if (IsPlayer(client) && GetConVarBool(g_hCSGOWikiEnable)) {
        CreateTimer(3.0, QuerySteamTimerCallback, client);
    }
    ResetSingleClientWikiState(client);
    ResetSingleClientSubmitState(client);
    ClearPlayerToken(client);
    ResetReqLock(client);
    ClearPlayerProMatchInfo(client);
    ResetDefaultOption(client);
}

public OnClientDisconnect(client) {
    ResetSingleClientWikiState(client);
    ResetSingleClientSubmitState(client);
    ClearPlayerToken(client);
    ResetReqLock(client);
    // reset bind_flag
    ResetSteamBindFlag(client);
    ClearPlayerProMatchInfo(client);
    ResetDefaultOption(client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[DATA_DIM], Float:angles[DATA_DIM], &weapon) {
    // for utility submit
    // if (!buttons) return;
    if (GetConVarBool(g_hOnUtilitySubmit)) {
        OnPlayerRunCmdForUtilitySubmit(client, buttons);
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

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) {
    if (!IsPlayer(client)) {
        return Plugin_Continue;
    }
    
    if (GetConVarFloat(g_hWikiAutoKicker) != 0.0) {
        if (g_aPlayerStateBind[client] == e_bUnbind) {
            PrintToChat(client, "%s \x02请前往mycsgolab.com绑定steam账号，有疑问请加群：762993431", PREFIX);
            PrintCenterText(client, "\x02请前往<font color='#0CED26'>mycsgolab.com<font color='#ffffff'>绑定Steam账号，从而获得更多权限，有疑问加群：762993431");
            return Plugin_Handled;
        }
    }
	
    return Plugin_Continue;
}
