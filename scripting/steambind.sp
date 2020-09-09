#include <sourcemod>
#include <sdktools>
#include <system2>
#include <json>

#define CLASS_LENGTH 64
#define INFO_LENGTH 16

enum BindState {
    b_Unknown = 0,
    b_Unbind = 1,
    b_Binded = 2
}

new Handle:h_Enable = INVALID_HANDLE;

BindState g_PlayerBindState[MAXPLAYERS + 1];

public Plugin:myinfo = {
    name = "Steam Bind Helper",
    author = "CarOL",
    description = "bind steamid from server to csgowiki.top",
    url = "csgowiki.top"
};

public OnPluginStart() {
    RegConsoleCmd("sm_bsteam", Command_BindSteam);
}

public OnClientPutInServer(client) {
    if (IsPlayer(client)) {
        CreateTimer(3.0, QuerySteamTimerCallback, client);    
    }
}

public OnClientDisconnect(client) {
    // reset bind_flag
    g_PlayerBindState[client] = b_Unknown;
}

public Action:QuerySteamTimerCallback(Handle timer, client) {
    queryWebSteamId(client);
    return Plugin_Handled;
}

public Action:Command_BindSteam(client, args) {
    if (args == 1) {
        char token[CLASS_LENGTH];
        GetCmdArgString(token, sizeof(token));
        TrimString(token);
        postBindInfo(client, token);
    }
    else {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02请前往www.csgowiki.top获取steam绑定指令");
    }
}

void queryWebSteamId(client) {
    char steamid[CLASS_LENGTH];
    GetClientAuthId(client, AuthId_SteamID64, steamid, CLASS_LENGTH);
    // POST
    System2HTTPRequest httpRequest = new System2HTTPRequest(
        QuerySteamIdCallback, "https://www.csgowiki.top/api/server/steambind/?steamid=%s", steamid);
    httpRequest.Any = client;
    httpRequest.GET();
}


void postBindInfo(client, char[] token) {
    char steamid[CLASS_LENGTH];
    GetClientAuthId(client, AuthId_SteamID64, steamid, CLASS_LENGTH);
    System2HTTPRequest httpRequest = new System2HTTPRequest(
        SteamBindCallback, "https://www.csgowiki.top/api/server/steambind/");
    httpRequest.SetData("steamid=%s&token=%s", steamid, token);
    httpRequest.Any = client;
    httpRequest.POST();
}

public void QuerySteamIdCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    int client = request.Any;
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        char[] status = new char[INFO_LENGTH];
        char[] aliasname = new char[CLASS_LENGTH];
        int client_level = 0;
        response.GetContent(content, response.ContentLength + 1);
        JSON_Object json_obj = json_decode(content);
        json_obj.GetString("status", status, INFO_LENGTH);
        if (StrEqual(status, "ok")) {
            json_obj.GetString("aliasname", aliasname, CLASS_LENGTH);
            client_level = json_obj.GetInt("level");
            PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x09您已绑定网站账户: \x04%s\x01(\x05Lv%d\x01)", aliasname, client_level);
            g_PlayerBindState[client] = b_Binded;
        }
        else {
            PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02您还没有在csgowiki绑定steam账号~");
            g_PlayerBindState[client] = b_Unbind;
        }
    }
    else {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02连接至www.csgowiki.top失败");
    }
}

public void SteamBindCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    int client = request.Any;
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        char[] status = new char[INFO_LENGTH];
        char[] aliasname = new char[CLASS_LENGTH];
        int client_level = 0;
        response.GetContent(content, response.ContentLength + 1);
        JSON_Object json_obj = json_decode(content);
        json_obj.GetString("status", status, INFO_LENGTH);
        if (StrEqual(status, "ok")) {
            json_obj.GetString("aliasname", aliasname, CLASS_LENGTH);
            client_level = json_obj.GetInt("level");
            PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x09账号绑定成功: \x04%s\x01(\x05Lv%d\x01)", aliasname, client_level);
            g_PlayerBindState[client] = b_Binded;
        }
        else {
            char[] message = new char[CLASS_LENGTH];
            json_obj.GetString("message", message, CLASS_LENGTH);
            PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02%s", message);
            g_PlayerBindState[client] = b_Unbind;
        }
    }
    else {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02连接至www.csgowiki.top失败");
    }
}

stock bool IsPlayer(int client) {
    return IsValidClient(client) && !IsFakeClient(client) && !IsClientSourceTV(client);
}

stock bool IsValidClient(int client) {
    return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}