#include <sourcemod>
#include <regex>
#include <sdktools>
#include <system2>

#define UTILITY_DIM 3
#define ID_LENGTH 6
#define ACTION_NUM 9
#define WIKI_ACTION 7
#define TINYTAG 10
#define BRIEFLENGTH 30
#define STEAMID64 20
#define CLIENTARG_MAXLENGTH 16
#define MAPNAME_MAXLENGTH 16
#define NUMBASE
#define CLASS_LENGTH 64
#define MESSAGE_MAXLENGTH 256


enum ClientStatus {
    s_Default = 0,
    s_ThrowReady = 1,
    s_ThrowEnd = 2,
    s_AlreadyThrown = 5,
};

enum UtilityEncode {
    u_Grenade = 0,
    u_Flashbang = 1,
    u_Smoke = 2,
    u_Molotov = 3,
};

enum WikiAction {
    w_Jump = 0,
    w_Duck = 1,
    w_Run = 2,
    w_Walk = 3,
    w_Stand = 4,
    w_LeftClick = 5,
    w_RightClick = 6,
};

new g_ActionList[ACTION_NUM] = {
    IN_JUMP, IN_DUCK, IN_ATTACK, IN_ATTACK2, IN_MOVELEFT, IN_MOVERIGHT, IN_FORWARD, IN_BACK, IN_SPEED
}

ClientStatus g_PlayerStatus[MAXPLAYERS + 1];
UtilityEncode g_UtilityName[MAXPLAYERS + 1];
char g_UtilityBrief[MAXPLAYERS + 1][BRIEFLENGTH];
float g_OriginPositions[MAXPLAYERS + 1][UTILITY_DIM];
float g_OriginAngles[MAXPLAYERS + 1][UTILITY_DIM]; // pitch yaw [-roll]
float g_ThrowPositions[MAXPLAYERS + 1][UTILITY_DIM];
float g_EndspotPositions[MAXPLAYERS + 1][UTILITY_DIM];
int g_ActionRecord[MAXPLAYERS + 1];
char g_CurrentMap[MAPNAME_MAXLENGTH];
int g_ServerTickRate; // "64"  "64/128"  "128"
char g_ClientLastCode[MAXPLAYERS + 1][ID_LENGTH];
float g_UtilityAirtime[MAXPLAYERS + 1];
char g_HistoryCode[MAXPLAYERS + 1][CLASS_LENGTH][ID_LENGTH];
char g_HistoryBrief[MAXPLAYERS + 1][CLASS_LENGTH][BRIEFLENGTH];
int g_PointerOfHistoryCode[MAXPLAYERS + 1];
Handle upload_timer = INVALID_HANDLE;
bool is_on = true;

new Hangle:h_Enable = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "Utility Uploader",
    author = "CarOL",
    description = "Upload utility record to www.csgowiki.top",
    url = "www.csgowiki.top"
};

public OnPluginStart() {
    HookEvent("grenade_thrown", Event_GrenadeThrown);
    HookEvent("hegrenade_detonate", Event_HegrenadeDetonate);
    HookEvent("flashbang_detonate", Event_FlashbangDetonate);
    HookEvent("smokegrenade_detonate", Event_SmokeDetonate);
    HookEvent("molotov_detonate", Event_MolotovDetonate);
    // 捕捉道具路径
    HookEvent("grenade_bounce", Event_GrenadeBounce);

    RegConsoleCmd("sm_submit", Command_SubmitOn);
    RegConsoleCmd("sm_list", Command_ShowList);
    RegConsoleCmd("sm_tphere", Command_TeleportHere);
    RegConsoleCmd("sm_tp", Command_Teleport);

    RegAdminCmd("sm_disable", Command_Disable_Uploader, ADMFLAG_GENERIC);
    RegAdminCmd("sm_enable", Command_Enable_Uploader, ADMFLAG_GENERIC);

    // upload_timer = CreateTimer(120.0, HelperTimerCallback, _, TIMER_REPEAT);    
    g_ServerTickRate = RoundToZero(1.0 / GetTickInterval());
}

public OnMapStart() {
    GetCurrentMap(g_CurrentMap, MAPNAME_MAXLENGTH);
    // init
    for (new client = 0; client <= MAXPLAYERS; client++) {
        g_PlayerStatus[client] = s_Default;
        g_ActionRecord[client] = 0;
        g_UtilityBrief[client] = "";
    }
}

public OnClientDisconnect(client) {
    g_PointerOfHistoryCode[client] = 0;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[UTILITY_DIM], Float:angles[UTILITY_DIM], &weapon) {
    if (is_on == false)
        return Plugin_Continue;
    if (g_PlayerStatus[client] != s_ThrowReady) {
        return Plugin_Continue;
    }
    for (new idx = 0; idx < ACTION_NUM; idx++) {
        if ((g_ActionList[idx] & buttons) && !(g_ActionRecord[client] & (1 << idx))) {
            g_ActionRecord[client] |= 1 << idx;
        }
    }
    return Plugin_Continue;
}


public Action:Event_GrenadeThrown(Handle:event, const String:name[], bool:dontBroadcast) {
    if (is_on == false)
        return Plugin_Continue;
	new String:nade[CLASS_LENGTH];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "weapon", nade, sizeof(nade));
	if (g_PlayerStatus[client] == s_ThrowReady && !StrEqual(nade, "decoy") && IsPlayer(client)) {
		GetClientAbsOrigin(client, g_ThrowPositions[client]);
        g_UtilityAirtime[client] = GetEngineTime();
        g_UtilityName[client] = encode_utility(nade);
        // next status
        g_PlayerStatus[client] = s_AlreadyThrown;
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x08已经成功记录你的动作，等待道具爆开...");
	}
	return Plugin_Continue;
}

public Action:Event_HegrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast) {
    if (is_on == false)
        return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (g_PlayerStatus[client] == s_AlreadyThrown && g_UtilityName[client] == u_Grenade) {
        g_PlayerStatus[client] = s_ThrowEnd;
        g_UtilityAirtime[client] = GetEngineTime() - g_UtilityAirtime[client];
        g_EndspotPositions[client][0] = GetEventFloat(event, "x");
        g_EndspotPositions[client][1] = GetEventFloat(event, "y");
        g_EndspotPositions[client][2] = GetEventFloat(event, "z");
        send_to_server(client);
    }
	return Plugin_Continue;
}

public Action:Event_FlashbangDetonate(Handle:event, const String:name[], bool:dontBroadcast) {
    if (is_on == false)
        return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (g_PlayerStatus[client] == s_AlreadyThrown && g_UtilityName[client] == u_Flashbang) {
        g_PlayerStatus[client] = s_ThrowEnd;
        g_UtilityAirtime[client] = GetEngineTime() - g_UtilityAirtime[client];
        g_EndspotPositions[client][0] = GetEventFloat(event, "x");
        g_EndspotPositions[client][1] = GetEventFloat(event, "y");
        g_EndspotPositions[client][2] = GetEventFloat(event, "z");
        send_to_server(client);
    }
	return Plugin_Continue;
}

public Action:Event_SmokeDetonate(Handle:event, const String:name[], bool:dontBroadcast) {
    if (is_on == false)
        return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (g_PlayerStatus[client] == s_AlreadyThrown && g_UtilityName[client] == u_Smoke) {
        g_PlayerStatus[client] = s_ThrowEnd;
        g_UtilityAirtime[client] = GetEngineTime() - g_UtilityAirtime[client];
        g_EndspotPositions[client][0] = GetEventFloat(event, "x");
        g_EndspotPositions[client][1] = GetEventFloat(event, "y");
        g_EndspotPositions[client][2] = GetEventFloat(event, "z");
        send_to_server(client);
    }
	return Plugin_Continue;
}

public Action:Event_MolotovDetonate(Handle:event, const String:name[], bool:dontBroadcast) {
    if (is_on == false)
        return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (g_PlayerStatus[client] == s_AlreadyThrown && g_UtilityName[client] == u_Molotov) {
        g_PlayerStatus[client] = s_ThrowEnd;
        g_UtilityAirtime[client] = GetEngineTime() - g_UtilityAirtime[client];
        g_EndspotPositions[client][0] = GetEventFloat(event, "x");
        g_EndspotPositions[client][1] = GetEventFloat(event, "y");
        g_EndspotPositions[client][2] = GetEventFloat(event, "z");
        send_to_server(client);
    }
	return Plugin_Continue;
}

public Action:Event_GrenadeBounce(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (g_PlayerStatus[client] == s_AlreadyThrown) {
        
    }
}

public Action:Command_SubmitOn(client, args) {
    if (is_on == false) {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02插件已关闭，请输入!enbale uploader 或只输入!enable (开启上传道具和学习道具两个插件)")
        return Plugin_Continue;
    }
    if (g_PlayerStatus[client] != s_Default) {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02操作无效：尚未获取道具信息");
    } 
    else {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x04道具上传功能开启");
		GetClientAbsOrigin(client, g_OriginPositions[client]);
		GetClientEyeAngles(client, g_OriginAngles[client]);
        if (args >= 1) {
            GetCmdArgString(g_UtilityBrief[client], BRIEFLENGTH);
            TrimString(g_UtilityBrief[client]);
            PrintToChat(client, "\x01[\x05CSGO Wiki\01] 正在录制<\x0E%s\x01>", g_UtilityBrief[client]);
        }
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] 您接下来投掷的道具记录将会被自动上传至\x09www.csgowiki.top\x01");
        g_PlayerStatus[client] = s_ThrowReady;
    }
    return Plugin_Continue;
}

public Action:Command_TeleportHere(client, args) {
    if (is_on == false) {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02插件已关闭，请输入!enbale uploader 或只输入!enable (开启上传道具和学习道具两个插件)")
        return Plugin_Continue;
    }
    if (args < 1) {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02格式错误\x01：!tphere <玩家姓名> 支持正则表达式");
        return Plugin_Continue;
    }
    char clientName[CLASS_LENGTH];
    char tarName[CLASS_LENGTH];
    float OriginPosition[UTILITY_DIM];
    float OriginAngle[UTILITY_DIM];
    GetClientName(client, clientName, sizeof(clientName));
    GetCmdArgString(tarName, sizeof(tarName));
    TrimString(tarName);
    GetClientAbsOrigin(client, OriginPosition);
    GetClientEyeAngles(client, OriginAngle);
    Regex regex = new Regex(tarName);
    int counter = 0;
    for (new t_client = 0; t_client <= MAXPLAYERS; t_client++) {
        if (t_client != client && IsPlayer(t_client)) {
            char t_name[CLASS_LENGTH];
            GetClientName(t_client, t_name, sizeof(t_name));
            if (regex.Match(t_name) > 0) {
                PrintToChatAll("\x01[\x05CSGO Wiki\x01] 已经将\x06%s\x01传送至\x03%s", t_name, clientName);
                TeleportEntity(t_client, OriginPosition, OriginAngle, NULL_VECTOR);
                counter++;
            }
        }
    }
    if (counter == 0) {
        PrintToChatAll("\x01[\x05CSGO Wiki\x01] 没有匹配到玩家，无人被传送")
    }
    return Plugin_Continue;
}

public Action:Command_Teleport(client, args) {
    if (is_on == false) {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02插件已关闭，请输入!enbale uploader 或只输入!enable (开启上传道具和学习道具两个插件)")
        return Plugin_Continue;
    }
    if (args < 1) {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02格式错误\x01：!tp <玩家姓名> 支持正则表达式(第一个匹配到的)");
        return Plugin_Continue;
    }
    char clientName[CLASS_LENGTH];
    char tarName[CLASS_LENGTH];
    float OriginPosition[UTILITY_DIM];
    float OriginAngle[UTILITY_DIM];
    GetClientName(client, clientName, sizeof(clientName));
    GetCmdArgString(tarName, sizeof(tarName));
    TrimString(tarName);
    Regex regex = new Regex(tarName);
    int counter = 0;
    for (new t_client = 0; t_client <= MAXPLAYERS && counter == 0; t_client++) {
        if (t_client != client && IsPlayer(t_client)) {
            char t_name[CLASS_LENGTH];
            GetClientName(t_client, t_name, sizeof(t_name));
            if (regex.Match(t_name) > 0) {
                GetClientEyePosition(t_client, OriginPosition);
                GetClientEyeAngles(t_client, OriginAngle);
                PrintToChatAll("\x01[\x05CSGO Wiki\x01] 已经将\x06%s\x01传送至\x03%s", clientName, t_name);
                TeleportEntity(client, OriginPosition, OriginAngle, NULL_VECTOR);
                counter++;
            }
        }
    }
    if (counter == 0) {
        PrintToChatAll("\x01[\x05CSGO Wiki\x01] 没有匹配到玩家，未被传送")
    }
    return Plugin_Continue;
}

public Action:Command_ShowList(client, args) {
    if (is_on == false) {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02插件已关闭，请输入!enbale uploader 或只输入!enable (开启上传道具和学习道具两个插件)")
        return Plugin_Continue;
    }
    PrintToChat(client, "\x09 ------------------------------------- ");
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] |\x03 道具名称 \x01|\x03 道具代码 \x01|");
    for (int pointer = 0; pointer < g_PointerOfHistoryCode[client]; pointer++) {
        if (strlen(g_UtilityBrief[client]) > 0) {
            PrintToChat(client, "\x01[\x05CSGO Wiki\x01] |\x04 %s \x01|\x04 %s \x01|", g_HistoryBrief[client][pointer], g_HistoryCode[client][pointer]);
        }
        else {
            PrintToChat(client, "\x01[\x05CSGO Wiki\x01] |\x04 空 \x01|\x04 %s \x01|", g_HistoryCode[client][pointer]);
        }
    }
    PrintToChat(client, "\x09 ------------------------------------- ");
    return Plugin_Continue;
}

public Action:Command_Disable_Uploader(client, args) {
    if (args < 1 && is_on) {
        ServerCommand("sm_disable uploader");
        ServerCommand("sm_disable wiki");
    }
    if (args >= 1 && is_on) {
        char tarName[CLASS_LENGTH];
        GetCmdArgString(tarName, sizeof(tarName));
        TrimString(tarName);
        if (StrEqual(tarName, "uploader")) {
            CloseHandle(upload_timer);
            is_on = false;
            PrintToChatAll("\x01[\x05CSGO Wiki\x01] 道具上传插件已关闭");
        }
    }
}

public Action:Command_Enable_Uploader(client, args) {
    if (args < 1 && !is_on) {
        ServerCommand("sm_enable uploader");
        ServerCommand("sm_enable wiki");
    }
    if (args >= 1 && !is_on) {
        char tarName[CLASS_LENGTH];
        GetCmdArgString(tarName, sizeof(tarName));
        TrimString(tarName);
        if (StrEqual(tarName, "uploader")) {
            upload_timer = CreateTimer(120.0, HelperTimerCallback, _, TIMER_REPEAT);    
            is_on = true;
            PrintToChatAll("\x01[\x05CSGO Wiki\x01] 道具上传插件已开启");
        }
    }
}

void decode_action(int client, bool[WIKI_ACTION] actions) {
    for (new idx = 0; idx < ACTION_NUM; idx ++) {
        if ((g_ActionRecord[client] & (1 << idx))) {
            switch(g_ActionList[idx]) {
                case IN_JUMP:
                    actions[w_Jump] = true;
                case IN_DUCK:
                    actions[w_Duck] = true;
                case IN_ATTACK:
                    actions[w_LeftClick] = true;
                case IN_ATTACK2:
                    actions[w_RightClick] = true;
                case IN_MOVELEFT:
                    actions[w_Run] = true;
                case IN_MOVERIGHT:
                    actions[w_Run] = true;
                case IN_BACK:
                    actions[w_Run] = true;
                case IN_FORWARD:
                    actions[w_Run] = true;
                case IN_SPEED:
                    actions[w_Walk] = true;
            }
        }
    }
    // postprocess
    if (!actions[w_Run] && actions[w_Walk]) {
        actions[w_Walk] = false;
    }
    if (actions[w_Run] && actions[w_Walk]) {
        actions[w_Run] = false;
    }
    if (actions[w_Run] && actions[w_Duck]) {
        actions[w_Walk] = true;
        actions[w_Run] = false;
    }
    if (!(actions[w_Run] || actions[w_Walk] || actions[w_Jump] || actions[w_Duck])) {
        actions[w_Stand] = true;
    }
}

void showInChat(int client) {
    bool actions[WIKI_ACTION]; 
    char actionMessage[CLASS_LENGTH];
    decode_action(client, actions);

    for (new idx = 0; idx < WIKI_ACTION; idx ++) {
        if (actions[idx]) {
            switch(idx) {
                case w_Jump:
                    StrCat(actionMessage, sizeof(actionMessage), "跳 ")
                case w_Duck:
                    StrCat(actionMessage, sizeof(actionMessage),"蹲 ")
                case w_Run:
                    StrCat(actionMessage, sizeof(actionMessage), "跑 ")
                case w_Walk:
                    StrCat(actionMessage, sizeof(actionMessage), "走 ")
                case w_Stand:
                    StrCat(actionMessage, sizeof(actionMessage), "站 ")
                case w_LeftClick:
                    StrCat(actionMessage, sizeof(actionMessage), "左键 ")
                case w_RightClick:
                    StrCat(actionMessage, sizeof(actionMessage), "右键 ")
            }
        }
    }

    PrintToChat(client, "\x09 ------------------------------------- ");
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x04道具分析结果：");
    if (strlen(g_UtilityBrief[client]) > 0) {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x06道具名称\x01 <\x0E%s\x01>", g_UtilityBrief[client]);
    }
    else {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x06道具名称\x01 <\x0E空\x01>", g_UtilityBrief[client]);
    }
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x06起点\x01 %f,%f,%f", g_OriginPositions[client][0], g_OriginPositions[client][1], g_OriginPositions[client][2]);
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x06角度\x01 %f,%f,%f", g_OriginAngles[client][0], g_OriginAngles[client][1], g_OriginAngles[client][2]);
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x06出手点\x01 %f,%f,%f", g_ThrowPositions[client][0], g_ThrowPositions[client][1], g_ThrowPositions[client][2]);
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x06落点\x01 %f,%f,%f", g_EndspotPositions[client][0], g_EndspotPositions[client][1], g_EndspotPositions[client][2]);
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x06道具飞行时间\x01 %f", g_UtilityAirtime[client]);
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x06动作列表\x01 %s", actionMessage);
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x06当前地图\x01 %s", g_CurrentMap);
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x06当前tickrate\x01 %d", g_ServerTickRate);
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] 服务器已将道具记录上传至\x09www.csgowiki.top\x01");
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] 该道具记录的短期标识为\x04%s\x01", g_ClientLastCode[client]);
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] 请在\x0224h\x01内登陆网站补全信息(图片和文字描述)");
    PrintToChat(client, "\x09 ------------------------------------- ");

}

/**
 * steamid: char[STEAMID64]
 * start_x: float, start_y: float, start_z, float
 * end_x: float, end_y: float, end_z: float
 * throw_x y z
 * aim_pitch: float, aim_yaw: float
 * is_run, is_walk, is_jump, is_duck, is_left, is_right:bool   [is_stand?]
 * map_belong: char[]
 * tick_tag: char[]
 * utility_tag: char[]
 * brief: char[]
 */
bool send_to_server(client) {
    char steamid[STEAMID64];
    char utility_tag[TINYTAG];
    char tick_tag[TINYTAG];
    bool actions[WIKI_ACTION];
    decode_utility(g_UtilityName[client], utility_tag);
    decode_action(client, actions);
    generate_ticktag(tick_tag, actions);
    GetClientAuthId(client, AuthId_SteamID64, steamid, STEAMID64);

    System2HTTPRequest httpRequest = new System2HTTPRequest(HttpResponseCallback, "https://www.csgowiki.top/api/utility/submit/");
    httpRequest.SetData(
        "steamid=%s&start_x=%f&start_y=%f&start_z=%f&end_x=%f&end_y=%f&end_z=%f&aim_pitch=%f&aim_yaw=%f&is_run=%d&is_walk=%d&is_jump=%d&is_duck=%d&is_left=%d&is_right=%d&map_belong=%s&tickrate=%s&utility_type=%s&brief=%s&throw_x=%f&throw_y=%f&throw_z=%f&air_time=%f",
        steamid, g_OriginPositions[client][0], g_OriginPositions[client][1], 
        g_OriginPositions[client][2], g_EndspotPositions[client][0], g_EndspotPositions[client][1],
        g_EndspotPositions[client][2], g_OriginAngles[client][0], g_OriginAngles[client][1],
        actions[w_Run], actions[w_Walk], actions[w_Jump], actions[w_Duck], actions[w_LeftClick], actions[w_RightClick],
        g_CurrentMap, tick_tag, utility_tag, g_UtilityBrief[client],
        g_ThrowPositions[client][0], g_ThrowPositions[client][1], g_ThrowPositions[client][2],
        g_UtilityAirtime[client]
    );
    httpRequest.Any = client;
    httpRequest.POST();
    return true;
}

generate_ticktag(char[] tick_tag, const bool[] actions) {
    StrCat(tick_tag, TINYTAG, "64/128");
    for (int idx = 0; idx < WIKI_ACTION; idx ++) {
        if (actions[idx] && idx == w_Jump) {
            IntToString(g_ServerTickRate, tick_tag, TINYTAG);
        }
    }
}

void decode_utility(UtilityEncode uecode, char[] utility_tag) {
    switch (uecode) {
        case u_Grenade:
            StrCat(utility_tag, TINYTAG, "grenade");
        case u_Flashbang:
            StrCat(utility_tag, TINYTAG, "flash");
        case u_Smoke:
            StrCat(utility_tag, TINYTAG, "smoke");
        case u_Molotov:
            StrCat(utility_tag, TINYTAG, "molotov");
    }
}

UtilityEncode encode_utility(const char[] utilityName) {
    if (StrEqual(utilityName, "hegrenade")) {
        return u_Grenade;
    }
    else if (StrEqual(utilityName, "flashbang")) {
        return u_Flashbang;
    }
    else if (StrEqual(utilityName, "smokegrenade")) {
        return u_Smoke;
    }
    else {
        PrintToChatAll("%s", utilityName);
        return u_Molotov;
    }
}  

public void HttpResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    int client = request.Any;
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        response.GetContent(content, response.ContentLength + 1);
        int code_index = StrContains(content, "code");
        for (new idx = 0; idx < ID_LENGTH; idx ++) {
            g_ClientLastCode[client][idx] = content[code_index + 8 + idx];
            g_HistoryCode[client][g_PointerOfHistoryCode[client]][idx] = content[code_index + 8 + idx];
        }
        strcopy(g_HistoryBrief[client][g_PointerOfHistoryCode[client]], BRIEFLENGTH, g_UtilityBrief[client]);
        g_PointerOfHistoryCode[client] ++;
        if (g_PointerOfHistoryCode[client] == CLASS_LENGTH) 
            g_PointerOfHistoryCode[client] --;
        showInChat(client);
    }
    else {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02连接至www.csgowiki.top失败\x01，请反馈情况至\x09feedback@csgowiki.top");
    }
    g_PlayerStatus[client] = s_Default;
    g_ActionRecord[client] = 0;
    g_UtilityBrief[client] = "";
} 

public Action:HelperTimerCallback(Handle timer) {
    PrintToChatAll("\x01[\x05CSGO Wiki\x01] \x02准备上传道具时，请先确保准星已经瞄好瞄点，再输入!submit");
    return Plugin_Continue;
}

stock bool IsPlayer(int client) {
  	return IsValidClient(client) && !IsFakeClient(client) && !IsClientSourceTV(client);
}

stock bool IsValidClient(int client) {
	  return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}
