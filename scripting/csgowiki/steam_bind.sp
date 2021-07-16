// implement steam_bind function

// **** 不用再指令绑定了 *****
// public Action:Command_BindSteam(client, args) {
//     if (!GetConVarBool(g_hCSGOWikiEnable)) {
//         PrintToChat(client, "%s \x02CSGOWiki插件关闭，请联系服务器管理员", PREFIX);
//         return;
//     }
//     if (!args) {
//         PrintToChat(client, "%s \x02请前往mycsgolab绑定你的steam账号", PREFIX);
//     }
//     else {
//         char token[LENGTH_TOKEN];
//         char steamid[LENGTH_STEAMID64];
//         GetCmdArgString(token, LENGTH_TOKEN);
//         TrimString(token);
//         GetClientAuthId(client, AuthId_SteamID64, steamid, LENGTH_STEAMID64);
//         System2HTTPRequest httpRequest = new System2HTTPRequest(
//             SteamBindResponseCallback,
//             "https://api.mycsgolab.com/user/steambind/"
//         )
//         httpRequest.SetData("steamid=%s&token=%s", steamid, token);
//         httpRequest.Any = client;
//         httpRequest.POST();
//         delete httpRequest;
//     }
// }

// public SteamBindResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
//     int client = request.Any;
//     if (success) {
//         char[] content = new char[response.ContentLength + 1];
//         char[] status = new char[LENGTH_STATUS];
//         char[] aliasname = new char[LENGTH_NAME];
//         int client_level = 0;
//         response.GetContent(content, response.ContentLength + 1);
//         JSON_Object json_obj = json_decode(content);
//         json_obj.GetString("status", status, LENGTH_STATUS);
//         if (StrEqual(status, "ok")) {
//             json_obj.GetString("aliasname", aliasname, LENGTH_NAME);
//             client_level = json_obj.GetInt("level");
//             PrintToChat(client, "%s \x09账号绑定成功: \x04%s\x01(\x05Lv%d\x01)", PREFIX, aliasname, client_level);
//             g_aPlayerStateBind[client] = e_bBinded;
//         }
//         else {
//             char[] message = new char[LENGTH_NAME];
//             json_obj.GetString("message", message, LENGTH_NAME);
//             PrintToChat(client, "%s \x02%s", PREFIX, message);
//             g_aPlayerStateBind[client] = e_bUnbind;
//         }
//         json_cleanup_and_delete(json_obj);
//     }
//     else {
//         PrintToChat(client, "%s \x02连接至mycsgolab失败", PREFIX);
//     }
// }

public Action:QuerySteamTimerCallback(Handle:timer, client) {
    if (GetConVarFloat(g_hWikiAutoKicker) == 0.0) {
        return; // 非公用服务器
    }
    char steamid[LENGTH_STEAMID64];
    char token[LENGTH_TOKEN] = "";
    GetClientAuthId(client, AuthId_SteamID64, steamid, LENGTH_STEAMID64);
    GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);
    // GET
    System2HTTPRequest httpRequest = new System2HTTPRequest(
        QuerySteamResponseCallback, 
        "https://api.mycsgolab.com/user/steambind?steamid=%s&token=%s",
        steamid, token
    );
    httpRequest.Any = client;
    httpRequest.GET();
    delete httpRequest;
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
            PrintToChat(client, "%s \x09您已绑定网站账户: \x04%s\x01(\x05等级%d\x01)",  PREFIX, aliasname, client_level);
            g_aPlayerStateBind[client] = e_bBinded;
        }
        else {
            PrintToChat(client, "%s \x02您还没有在mycsgolab绑定steam账号~", PREFIX);
            g_aPlayerStateBind[client] = e_bUnbind;
            // set kicker
            float kicker_timer = GetConVarFloat(g_hWikiAutoKicker);
            if (kicker_timer > 0.0) {
                CreateTimer(kicker_timer * 60, AutoKickerCallback, client);
                PrintToChat(client, "%s \x0f由于你未绑定mycsgolab账号，根据设置，将在\x04%.2f\x0f分钟内将您踢出服务器", PREFIX, kicker_timer);
                PrintToChat(client, "%s \x05绑定账号请前往\x09mycsgolab", PREFIX);
            }
        }
        json_cleanup_and_delete(json_obj);
        // test
        ClientCommand(client, "sm_m");
    }
    else {
        PrintToChat(client, "%s \x02连接至mycsgolab失败", PREFIX);
    }
}

void ResetSteamBindFlag(client) {
    g_aPlayerStateBind[client] = e_bUnknown;
}
