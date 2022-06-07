// implement steam_bind function

public Action QuerySteamTimerCallback(Handle timer, int client) {
    if (GetConVarFloat(g_hWikiAutoKicker) == 0.0) {
        return; // 非公用服务器
    }
    char steamid[LENGTH_STEAMID64];
    char token[LENGTH_TOKEN] = "";
    GetClientAuthId(client, AuthId_SteamID64, steamid, LENGTH_STEAMID64);
    GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);
    // GET
    char apiHost[LENGTH_TOKEN];
    GetConVarString(g_hApiHost, apiHost, sizeof(apiHost));
    char url[LENGTH_MESSAGE];
    Format(url, sizeof(url), "%s/user/steambind", apiHost);
    HTTPRequest httpRequest = new HTTPRequest(url);
    httpRequest.AppendQueryParam("steamid", steamid);
    httpRequest.AppendQueryParam("token", token);
    httpRequest.Get(QuerySteamResponseCallback, client);
}

void QuerySteamResponseCallback(HTTPResponse response, int client) {
    if (response.Status == HTTPStatus_OK) {
        char status[LENGTH_STATUS];
        char aliasname[LENGTH_NAME];
        JSONObject json_obj = view_as<JSONObject>(response.Data);
        json_obj.GetString("status", status, LENGTH_STATUS);
        if (StrEqual(status, "ok")) {
            json_obj.GetString("aliasname", aliasname, LENGTH_NAME);
            int client_level = json_obj.GetInt("level");
            PrintToChat(client, "%s \x09您已绑定网站账户: \x04%s\x01(\x05等级%d\x01)",  PREFIX, aliasname, client_level);
            g_aPlayerStateBind[client] = e_bBinded;
        }
        else {
            char message[LENGTH_MESSAGE];
            json_obj.GetString("message", message, sizeof(message));
            if (StrEqual(message, "banned")) {
                char name[LENGTH_NAME];
                GetClientName(client, name, sizeof(name));
                PrintToChatAll("%s 玩家[\x02%s\x01] 被CSGOWiki封禁，已被踢出服务器", PREFIX, name);
                KickClient(client, "你已被CSGOWiki封禁，如有疑问请加群：762993431申诉");
            }
            else {
                PrintToChat(client, "%s \x02您还没有在mycsgolab绑定steam账号~", PREFIX);
                g_aPlayerStateBind[client] = e_bUnbind;
                // set kicker
                float kicker_timer = GetConVarFloat(g_hWikiAutoKicker);
                if (kicker_timer > 0.0) {
                    CreateTimer(kicker_timer * 60, AutoKickerCallback, client);
                    PrintToChat(client, "%s \x0f由于你未绑定mycsgolab账号，根据设置，将在\x04%.2f\x0f分钟内将您踢出服务器", PREFIX, kicker_timer);
                    PrintToChat(client, "%s 请前往\x04mycsgolab.com\x01绑定账号，以获得服务器内所有权限~", PREFIX);
                    PrintToChat(client, "%s \x05绑定账号请前往\x09mycsgolab", PREFIX);
                }
            }
        }
        delete json_obj;
        // test
        ClientCommand(client, "sm_m");
    }
    else {
        PrintToChat(client, "%s \x02连接至mycsgolab失败", PREFIX);
    }
}

void ResetSteamBindFlag(int client) {
    g_aPlayerStateBind[client] = e_bUnknown;
}
