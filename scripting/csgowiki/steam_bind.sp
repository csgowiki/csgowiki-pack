// implement steam_bind function

public Action:Command_BindSteam(client, args) {
    if (!args) {
        PrintToChat(client, "%s \x02请前往www.csgowiki.top个人主页获取steam绑定指令", PREFIX);
    }
    else {
        char token[LENGTH_TOKEN];
        char steamid[LENGTH_STEAMID64];
        GetCmdArgString(token, LENGTH_TOKEN);
        TrimString(token);
        GetClientAuthId(client, AuthId_SteamID64, steamid, LENGTH_STEAMID64);
        System2HTTPRequest httpRequest = new System2HTTPRequest(
            SteamBindResponseCallback,
            "https://test.csgowiki.top/api/server/steambind/"
        )
        httpRequest.SetData("steamid=%s&token=%s", steamid, token);
        httpRequest.Any = client;
        httpRequest.POST();
    }
}

public SteamBindResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    int client = request.Any;
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        char[] status = new char[LENGTH_STATUS];
        char[] aliasname = new char[LENGTH_NAME];
        int client_level = 0;
        response.GetContent(content, response.ContentLength + 1);
        JSON_Object json_obj = json_decode(content);
        json_obj.GetString("status", status, LENGTH_STATUS);
        if (StrEqual(status, "ok")) {
            json_obj.GetString("aliasname", aliasname, LENGTH_NAME);
            char[] message = new char[LENGTH_NAME];
            json_obj.GetString("message", message, LENGTH_NAME);
            client_level = json_obj.GetInt("level");
            PrintToChat(client, "%s \x09账号绑定成功: \x04%s\x01(\x05Lv%d\x01)", PREFIX, aliasname, client_level);
            PrintToChat(client, "%s ip: %s", PREFIX, message);
            g_aPlayerStateBind[client] = e_bBinded;
        }
        else {
            char[] message = new char[LENGTH_NAME];
            json_obj.GetString("message", message, LENGTH_NAME);
            PrintToChat(client, "%s \x02%s", PREFIX, message);
            g_aPlayerStateBind[client] = e_bUnbind;
        }
    }
    else {
        PrintToChat(client, "%s \x02连接至www.csgowiki.top失败", PREFIX);
    }
}

public Action:QuerySteamTimerCallback(Handle:timer, client) {
    char steamid[LENGTH_STEAMID64];
    GetClientAuthId(client, AuthId_SteamID64, steamid, LENGTH_STEAMID64);
    // GET
    System2HTTPRequest httpRequest = new System2HTTPRequest(
        QuerySteamResponseCallback, 
        "https://test.csgowiki.top/api/server/steambind/?steamid=%s",
        steamid
    );
    httpRequest.Any = client;
    httpRequest.GET();
}

public QuerySteamResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    int client = request.Any;
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        char[] status = new char[LENGTH_STATUS];
        char[] aliasname = new char[LENGTH_NAME];
        response.GetContent(content, response.ContentLength + 1);
        JSON_Object json_obj = json_decode(content);
        json_obj.GetString("status", status, LENGTH_STATUS);
        if (StrEqual(status, "ok")) {
            json_obj.GetString("aliasname", aliasname, LENGTH_NAME);
            int client_level = json_obj.GetInt("level");
            PrintToChat(client, "%s \x09您已绑定网站账户: \x04%s\x01(\x05Lv%d\x01)",  PREFIX, aliasname, client_level);
            g_aPlayerStateBind[client] = e_bBinded;
        }
        else {
            PrintToChat(client, "%s \x02您还没有在csgowiki绑定steam账号~", PREFIX);
            g_aPlayerStateBind[client] = e_bUnbind;
        }
    }
    else {
        PrintToChat(client, "%s \x02连接至www.csgowiki.top失败", PREFIX);
    }
}

void ResetSteamBindFlag(client) {
    g_aPlayerStateBind[client] = e_bUnkown;
}