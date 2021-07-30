// check handle function on/off
bool check_function_on(Handle: ghandle, char[] errorMsg, client = -1) {
    bool benable = GetConVarBool(ghandle) && GetConVarBool(g_hCSGOWikiEnable);
    if (!benable && client != -1) {
        PrintToChat(client, "%s %s", PREFIX, errorMsg);
    }
    return benable;
}

// check player valid
stock bool IsPlayer(int client) {
    return IsValidClient(client) && !IsFakeClient(client) && !IsClientSourceTV(client);
}

stock bool IsValidClient(int client) {
    return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}


int GetServerTickrate() {
    return RoundToZero(1.0 / GetTickInterval());
}

// convar handle function
Handle FindOrCreateConvar(char[] cvName, char[] cvDefault, char[] cvDescription, float fMin=-1.0, float fMax=-1.0, bool flag=false) {
    Handle cvHandle = FindConVar(cvName);
    if (cvHandle == INVALID_HANDLE) {
        if (fMin == -1.0 && fMax == -1.0)
            if (flag)
                cvHandle = CreateConVar(cvName, cvDefault, cvDescription, FCVAR_PROTECTED);
            else
                cvHandle = CreateConVar(cvName, cvDefault, cvDescription);
        else if (fMin != -1.0 && fMax != -1.0)
            if (flag)
                cvHandle = CreateConVar(cvName, cvDefault, cvDescription, FCVAR_PROTECTED, true, fMin, true, fMax);
            else
                cvHandle = CreateConVar(cvName, cvDefault, cvDescription, _, true, fMin, true, fMax);
        else return INVALID_HANDLE;
    }
    return cvHandle;
}

void HookOpConVarChange() {
    HookConVarChange(g_hCSGOWikiEnable, ConVar_CSGOWikiEnableChange);
    HookConVarChange(g_hOnUtilitySubmit, ConVar_OnUtilitySubmitChange);
    HookConVarChange(g_hOnUtilityWiki, ConVar_OnUtilityWikiChange);
    HookConVarChange(g_hChannelEnable, ConVar_ChannelEnableChange);
    HookConVarChange(g_hChannelQQgroup, ConVar_ChannelQQgroupChange);
    HookConVarChange(g_hChannelServerRemark, ConVar_ChannelRemarkChange);
}

public ConVar_CSGOWikiEnableChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
    if (GetConVarBool(g_hCSGOWikiEnable)) {
        PrintToChatAll("%s \x09CSGOWiki插件总功能\x01 => \x04已开启", PREFIX);
    }
    else {
        PrintToChatAll("%s \x09CSGOWiki插件总功能\x01 => \x02已关闭", PREFIX);
    }
}

public ConVar_OnUtilitySubmitChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
    if (GetConVarBool(g_hOnUtilitySubmit)) {
        PrintToChatAll("%s \x09道具上传功能\x01 => \x04已开启", PREFIX);
    }
    else {
        PrintToChatAll("%s \x09道具上传功能\x01 => \x02已关闭", PREFIX);
    }
}

public ConVar_OnUtilityWikiChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
    if (GetConVarBool(g_hOnUtilityWiki)) {
        PrintToChatAll("%s \x09道具学习功能\x01 => \x04已开启", PREFIX);
    }
    else {
        PrintToChatAll("%s \x09道具学习功能\x01 => \x02已关闭", PREFIX);
    }
}

public ConVar_ChannelEnableChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
    if (GetConVarBool(g_hChannelEnable)) {
        PrintToChatAll("%s \x09QQ聊天功能\x01 => \x04已开启", PREFIX);
        TcpCreate();
    }
    else {
        PrintToChatAll("%s \x09QQ聊天功能\x01 => \x02已关闭", PREFIX);
        TcpClose();
    }
}

public ConVar_ChannelQQgroupChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
    PrintToServer("qq group change");
    TcpCreate();
}

public ConVar_ChannelRemarkChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
    PrintToServer("server remark change");
    TcpCreate();
}

void GetServerHost(char []str, int size) {
    GetConVarString(g_hChannelSvHost, str, size);
    if (strlen(str) != 0) {
        return;
    }
    Handle hServerHost = INVALID_HANDLE;
    if(hServerHost == INVALID_HANDLE) {
        if( (hServerHost = FindConVar("net_public_adr")) == INVALID_HANDLE) {
            return;
        }
    }
    GetConVarString(hServerHost, str, size);
} 

// utils for utility submit
void GrenadeType_2_Tinyname(GrenadeType utCode, char[] utTinyName) {
    switch (utCode) {
    case GrenadeType_HE:
        strcopy(utTinyName, LENGTH_UTILITY_TINY, "grenade");
    case GrenadeType_Flash:
        strcopy(utTinyName, LENGTH_UTILITY_TINY, "flash");
    case GrenadeType_Smoke:
        strcopy(utTinyName, LENGTH_UTILITY_TINY, "smoke");
    case GrenadeType_Molotov:
        strcopy(utTinyName, LENGTH_UTILITY_TINY, "molotov");
    case GrenadeType_Incendiary:
        strcopy(utTinyName, LENGTH_UTILITY_TINY, "molotov");
    }
}

void Action_Int2Array(client, bool[] wikiAction) {
    for (new idx = 0; idx < CSGO_ACTION_NUM; idx++) {
        if (g_aActionRecord[client] & (1 << idx)) {
            switch(g_aCsgoActionMap[idx]) {
            case IN_JUMP:   wikiAction[e_wJump] = true;
            case IN_DUCK:   wikiAction[e_wDuck] = true;
            case IN_ATTACK: wikiAction[e_wLeftclick] = true;
            case IN_ATTACK2:    wikiAction[e_wRightclick] = true;
            case IN_MOVELEFT:   wikiAction[e_wRun] = true;
            case IN_MOVERIGHT:  wikiAction[e_wRun] = true;
            case IN_BACK:       wikiAction[e_wRun] = true;   
            case IN_FORWARD:    wikiAction[e_wRun] = true;
            case IN_SPEED:  wikiAction[e_wWalk] = true;
            }
        }
    }
    // post fix
    if (!wikiAction[e_wRun] && wikiAction[e_wWalk]) {
        wikiAction[e_wWalk] = false; // 没有移动只按shift
    }
    if (wikiAction[e_wRun] && wikiAction[e_wWalk]) {
        wikiAction[e_wRun] = false; // just shift
    }
    if (wikiAction[e_wRun] && wikiAction[e_wDuck]) {
        wikiAction[e_wWalk] = true;
        wikiAction[e_wRun] = false;
    }
    if (!(wikiAction[e_wRun] || wikiAction[e_wWalk] 
        || wikiAction[e_wJump] || wikiAction[e_wDuck])) {
        wikiAction[e_wStand] = true;
    }
}

void Action_Int2Str(client, char[] strAction) {
    bool wikiAction[CSGOWIKI_ACTION_NUM] = {};
    Action_Int2Array(client, wikiAction);
    char StrTemp[CSGOWIKI_ACTION_NUM][6] = {
        "跳 ", "蹲 ", "跑 ", "走 ", "站 ", "左键 ", "右键 "
    };
    for (new idx = 0; idx < CSGOWIKI_ACTION_NUM; idx ++) {
        if (!wikiAction[idx]) continue;
        StrCat(strAction, LENGTH_MESSAGE, StrTemp[idx]);
    }
}

void TicktagGenerate(char[] tickTag, const bool[] wikiAction) {
    strcopy(tickTag, LENGTH_STATUS, "64/128");
    if (wikiAction[e_wJump]) {
        IntToString(g_iServerTickrate, tickTag, LENGTH_STATUS);
    }
}

void Utility_TinyName2Zh(char[] utTinyName, char[] format, char[] zh) {
    if (StrEqual(utTinyName, "smoke")) {
        Format(zh, LENGTH_UTILITY_ZH, format, "烟雾弹");
    }
    else if (StrEqual(utTinyName, "grenade")) {
        Format(zh, LENGTH_UTILITY_ZH, format, "手雷");
    }
    else if (StrEqual(utTinyName, "flash")) {
        Format(zh, LENGTH_UTILITY_ZH, format, "闪光弹");
    }
    else if (StrEqual(utTinyName, "molotov")) {
        Format(zh, LENGTH_UTILITY_ZH, format, "燃烧弹");
    }
}

void Utility_FullName2Zh(char[] utFullName, char[] format, char[] zh) {
    if (StrEqual(utFullName, "smokegrenade")) {
        Format(zh, LENGTH_UTILITY_ZH, format, "烟雾弹");
    }
    else if (StrEqual(utFullName, "hegrenade")) {
        Format(zh, LENGTH_UTILITY_ZH, format, "手雷");
    }
    else if (StrEqual(utFullName, "flashbang")) {
        Format(zh, LENGTH_UTILITY_ZH, format, "闪光弹");
    }
    else if (StrEqual(utFullName, "molotov")) {
        Format(zh, LENGTH_UTILITY_ZH, format, "燃烧弹");
    }
    else if (StrEqual(utFullName, "incgrenade")) {
        Format(zh, LENGTH_UTILITY_ZH, format, "燃烧瓶");
    }
}

void Utility_TinyName2Weapon(char[] utTinyName, char[] weaponName, client) {
    if (StrEqual(utTinyName, "smoke") || StrEqual(utTinyName, "smokegrenade")) {
        strcopy(weaponName, LENGTH_UTILITY_ZH, "weapon_smokegrenade");
    }
    else if (StrEqual(utTinyName, "grenade") || StrEqual(utTinyName, "hegrenade")) {
        strcopy(weaponName, LENGTH_UTILITY_ZH, "weapon_hegrenade");
    }
    else if (StrEqual(utTinyName, "flash") || StrEqual(utTinyName, "flashbang")) {
        strcopy(weaponName, LENGTH_UTILITY_ZH, "weapon_flashbang");
    }
    else if (StrEqual(utTinyName, "molotov") || StrEqual(utTinyName, "incgrenade")) {
        new teamFlag = GetClientTeam(client);
        if (CS_TEAM_T == teamFlag) {
            strcopy(weaponName, LENGTH_UTILITY_ZH, "weapon_molotov");
        }
        else if (CS_TEAM_CT == teamFlag){  // [TODO]  spec
            strcopy(weaponName, LENGTH_UTILITY_ZH, "weapon_incgrenade");
        }
    }
}

GrenadeType TinyName_2_GrenadeType(char[] utTinyName, client) {
    if (StrEqual(utTinyName, "smoke") || StrEqual(utTinyName, "smokegrenade")) {
        return GrenadeType_Smoke;
    }
    else if (StrEqual(utTinyName, "grenade") || StrEqual(utTinyName, "hegrenade")) {
        return GrenadeType_HE;
    }
    else if (StrEqual(utTinyName, "flash") || StrEqual(utTinyName, "flashbang")) {
        return GrenadeType_Flash;
    }
    else if (StrEqual(utTinyName, "molotov") || StrEqual(utTinyName, "incgrenade")) {
        new teamFlag = GetClientTeam(client);
        if (CS_TEAM_T == teamFlag) {
            return GrenadeType_Molotov;
        }
        else if (CS_TEAM_CT == teamFlag){  // [TODO]  spec
            return GrenadeType_Incendiary;
        }
    }
    return GrenadeType_None;
}


void ResetReqLock(pclient = -1) {
    if (pclient != -1) {
        g_aReqLock[pclient] = false;
        return;
    }
    for (new client = 0; client <= MAXPLAYERS; client++) {
        g_aReqLock[client] = false;
    }
}


// ----------------- server monitor json generator -------
JSON_Array encode_json_server_monitor(int exclient, bool inctoken=true, bool authType=true, bool incmap=false, bool incid=false) {
    JSON_Array monitor_json = new JSON_Array();
    if (inctoken) {
        char token[LENGTH_TOKEN];
        GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);
        monitor_json.PushString(token);
    }
    if (exclient == -1) {
        monitor_json.PushObject(new JSON_Array());
        return monitor_json;
    }
    if (incmap) {
        monitor_json.PushString(g_sCurrentMap);
    }
    for (int client_id = 0; client_id <= MaxClients; client_id++) {
        if(!IsPlayer(client_id) || client_id == exclient) continue;
        char client_name[LENGTH_NAME], steamid[LENGTH_STEAMID64], str_ping[4];
        GetClientName(client_id, client_name, LENGTH_NAME);
        if (authType) {
            GetClientAuthId(client_id, AuthId_SteamID64, steamid, LENGTH_STEAMID64)
        } else {
            GetClientAuthId(client_id, AuthId_Steam2, steamid, LENGTH_STEAMID64)
        }
        float latency = GetClientAvgLatency(client_id, NetFlow_Both);
        IntToString(RoundToNearest(latency * 500), str_ping, sizeof(str_ping));
        // json encode
        JSON_Array client_arr = new JSON_Array();
        if (incid) {
            client_arr.PushInt(client_id);
        }
        client_arr.PushString(client_name);
        client_arr.PushString(steamid);
        client_arr.PushString(str_ping);
        monitor_json.PushObject(client_arr);
    }
    return monitor_json;
}

// ----------------- check version ----------------------
void PluginVersionHint(client) {
    if (StrEqual(g_sLatestVersion, "")) {
        PrintToChat(client, "%s 获取版本信息失败：[\x02%s\x01]", PREFIX, g_sLatestInfo);
    }
    else if (StrEqual(g_sCurrentVersion, g_sLatestVersion)) {
        PrintToChat(client, "%s 当前csgowiki插件已为最新版本<\x09%s\x01>", PREFIX, g_sCurrentVersion);
    }
    else {
        PrintToChat(client, "%s 当前服务器csgowiki插件版本<\x0F%s\x01>，最新版本为<\x09%s\x01>", PREFIX, g_sCurrentVersion, g_sLatestVersion);
        PrintToChat(client, "%s \x06%s\x01", PREFIX, g_sLatestInfo);
        PrintToChat(client, "%s 请及时更新插件避免已有功能失效", PREFIX);
    }
}

void PluginVersionCheck(client = -1) {
    GetPluginInfo(INVALID_HANDLE, PlInfo_Version, g_sCurrentVersion, LENGTH_VERSION);
    System2HTTPRequest PluginVersionCheckRequest = new System2HTTPRequest (
        PluginVersionCheckCallback, 
        "https://api.github.com/repos/hx-w/CSGOWiki-Plugins/releases/latest"
    );
    PluginVersionCheckRequest.SetHeader("User-Agent", "request");
    PluginVersionCheckRequest.Any = client;
    PluginVersionCheckRequest.GET();
    delete PluginVersionCheckRequest;
}

public PluginVersionCheckCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        int statusCode = response.StatusCode;
        if (statusCode != 200) {
            Format(g_sLatestInfo, sizeof(g_sLatestInfo), "github-api访问失败：状态码<%d>", statusCode);
        }
        else {
            response.GetContent(content, response.ContentLength + 1);
            JSON_Object resp_json = json_decode(content);
            resp_json.GetString("tag_name", g_sLatestVersion, sizeof(g_sLatestVersion));
            resp_json.GetString("name", g_sLatestInfo, sizeof(g_sLatestInfo));
            json_cleanup_and_delete(resp_json);
        }
    }
    else {
        g_sLatestInfo = "github-api访问失败";
    }
    new client = request.Any;
    if (client != -1) {
        PluginVersionHint(client);
    }
}

void ClearPlayerProMatchInfo(client) {
    if (IsPlayer(client)) {
        g_aProMatchIndex[client] = -1;
    }
}

// ----------------- hint color message fix --------------
UserMsg g_TextMsg, g_HintText, g_KeyHintText;
static char g_sSpace[1024];

void HintColorMessageFixStart() {
    for(int i = 0; i < sizeof g_sSpace - 1; i++) {
        g_sSpace[i] = ' ';
    }

    g_TextMsg = GetUserMessageId("TextMsg");
    g_HintText = GetUserMessageId("HintText");
    g_KeyHintText = GetUserMessageId("KeyHintText");

    HookUserMessage(g_TextMsg, TextMsgHintTextHook, true);
    HookUserMessage(g_HintText, TextMsgHintTextHook, true);
    HookUserMessage(g_KeyHintText, TextMsgHintTextHook, true);
}

Action TextMsgHintTextHook(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init) {
    static char sBuf[sizeof(g_sSpace)];
    if(msg_id == g_HintText) {
        msg.ReadString("text", sBuf, sizeof(sBuf));
    }
    else if(msg_id == g_KeyHintText) {
        msg.ReadString("hints", sBuf, sizeof(sBuf), 0);
    }
    else if(msg.ReadInt("msg_dst") == 4) {
        msg.ReadString("params", sBuf, sizeof(sBuf), 0);
    }
    else {
        return Plugin_Continue;
    }

    if(StrContains(sBuf, "<font") != -1 || StrContains(sBuf, "<span") != -1) {
        DataPack hPack = new DataPack();
        hPack.WriteCell(playersNum);
        for(int i = 0; i < playersNum; i++) {
            hPack.WriteCell(players[i]);
        }
        hPack.WriteString(sBuf);
        hPack.Reset();
        RequestFrame(TextMsgFix, hPack);
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

void TextMsgFix(DataPack hPack) {
    int iCount = hPack.ReadCell();
    static int iPlayers[MAXPLAYERS + 1];

    for(int i = 0; i < iCount; i++) {
        iPlayers[i] = hPack.ReadCell();
    }

    int[] newClients = new int[MaxClients];
    int newTotal = 0;

    for (int i = 0; i < iCount; i++) {
        int client = iPlayers[i];
        if (IsClientInGame(client)) {
            newClients[newTotal] = client;
            newTotal++;
        }
    }
    if (newTotal == 0) {
        delete hPack;
        return;
    }
    static char sBuf[sizeof g_sSpace];
    hPack.ReadString(sBuf, sizeof sBuf);
    delete hPack;

    Protobuf hMessage = view_as<Protobuf>(StartMessageEx(g_TextMsg, newClients, newTotal, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));

    if(hMessage) {
        hMessage.SetInt("msg_dst", 4);
        hMessage.AddString("params", "#SFUI_ContractKillStart");

        Format(sBuf, sizeof sBuf, "</font>%s%s", sBuf, g_sSpace);
        hMessage.AddString("params", sBuf);

        hMessage.AddString("params", NULL_STRING);
        hMessage.AddString("params", NULL_STRING);
        hMessage.AddString("params", NULL_STRING);
        hMessage.AddString("params", NULL_STRING);

        EndMessage();
    }
}