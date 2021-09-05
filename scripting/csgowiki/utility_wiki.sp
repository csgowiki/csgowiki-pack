// implement wiki

public Action:Command_Wiki(client, args) {
    PluginVersionHint(client);

    if (!check_function_on(g_hOnUtilityWiki, "\x02道具学习插件关闭，请联系服务器管理员", client)) {
        return;
    }
    if (BotMimicFix_IsPlayerMimicing(client)) {
        PrintToChat(client, "%s \x02正在播放录像", PREFIX);
        return;
    }
    if (args >= 1) {
        char utId[LENGTH_TOKEN];
        GetCmdArgString(utId, LENGTH_TOKEN);
        TrimString(utId);
        PrintToChat(client, "%s 正在请求道具<\x0E%s\x01>", PREFIX, utId);
        GetUtilityDetail(client, utId);
    }
    if (g_jaUtilityCollection == INVALID_HANDLE || g_jaUtilityCollection.Length < 10) {
        PrintToChat(client, "%s 道具合集初始化失败，正在重新请求数据...", PREFIX);
        GetAllCollection(client);
    }
    else {
        Menu_UtilityWiki_v1(client);
    }
}

public Action:Command_Refresh(client, args) {
    GetAllCollection(client);
}

void GetAllCollection(client=-1) {
    if (!check_function_on(g_hOnUtilityWiki, "")) return;
    char token[LENGTH_TOKEN];
    GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);
    
    char apiHost[LENGTH_TOKEN];
    GetConVarString(g_hApiHost, apiHost, sizeof(apiHost));

    char url[LENGTH_MESSAGE];
    Format(url, sizeof(url), "%s/v2/utility/filter", apiHost);
    HTTPRequest AllCollectionRequest = new HTTPRequest(url);
    AllCollectionRequest.AppendQueryParam("token", token);
    AllCollectionRequest.AppendQueryParam("mapname", g_sCurrentMap);
    AllCollectionRequest.AppendQueryParam("tickrate", "%d", g_iServerTickrate);

    AllCollectionRequest.Get(AllCollectionResponseCallback, client);

    // pro
    // if (g_aProMatchInfo == INVALID_HANDLE || g_aProMatchInfo.Length < 1) {
    Format(url, sizeof(url), "https://api.hx-w.top/%s", g_sCurrentMap);
    HTTPRequest ProCollectionRequest = new HTTPRequest(url);
    ProCollectionRequest.SetHeader("Content-Type", "application/json");
    ProCollectionRequest.Get(ProCollectionResponseCallback, client);
    // }
}

void GetFilterCollection(client, char[] method) {
    float playerPos[DATA_DIM];
    char token[LENGTH_TOKEN];
    GetClientAbsOrigin(client, playerPos);
    GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);

    char apiHost[LENGTH_TOKEN];
    char url[LENGTH_MESSAGE];
    GetConVarString(g_hApiHost, apiHost, sizeof(apiHost));
    Format(url, sizeof(url), "%s/v2/utility/filter", apiHost);

    HTTPRequest httpRequest = new HTTPRequest(url);
    httpRequest.AppendQueryParam("token", token);
    httpRequest.AppendQueryParam("mapname", g_sCurrentMap);
    httpRequest.AppendQueryParam("tickrate", "%d", g_iServerTickrate);
    // httpRequest.AppendQueryParam("method", method);
    if (StrEqual(method, "start")) {
        httpRequest.AppendQueryParam("start_x", "%f", playerPos[0]);
        httpRequest.AppendQueryParam("start_y", "%f", playerPos[1]);
    }
    else if (StrEqual(method, "end")) {
        httpRequest.AppendQueryParam("end_x", "%f", playerPos[0]);
        httpRequest.AppendQueryParam("end_y", "%f", playerPos[1]);
    }
    httpRequest.Get(FilterCollectionResponseCallback, client);
}

void GetUtilityDetail(client, char[] utId) {
    // lock
    float fWikiLimit = GetConVarFloat(g_hWikiReqLimit);
    if (BotMimicFix_IsPlayerMimicing(client)) {
        PrintToChat(client, "%s \x02正在播放录像", PREFIX);
        return;
    }
    if (g_aReqLock[client]) {
        PrintToChat(client, "%s \x07请求过快！\x01冷却时间：\x09%.2f\x01秒", PREFIX, fWikiLimit);
        return;
    }
    else {
        if (fWikiLimit != 0.0) {
            g_aReqLock[client] = true;
            CreateTimer(fWikiLimit, ReqLockTimerCallback, client);
        }
    }

    char token[LENGTH_TOKEN];
    GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);
    char apiHost[LENGTH_TOKEN];
    GetConVarString(g_hApiHost, apiHost, sizeof(apiHost));
    char steamid_[LENGTH_STEAMID64];
    GetClientAuthId(client, AuthId_SteamID64, steamid_, LENGTH_STEAMID64);
    char player_name[LENGTH_NAME];
    GetClientName(client, player_name, sizeof(player_name));
    char url[LENGTH_MESSAGE];
    Format(url, sizeof(url), "%s/v2/utility/detail", apiHost);

    HTTPRequest httpRequest = new HTTPRequest(url);
    httpRequest.AppendQueryParam("token", token);
    httpRequest.AppendQueryParam("article_id", utId);
    httpRequest.Get(UtilityDetailResponseCallback, client);

    // =====================================================
    HTTPRequest postRequest = new HTTPRequest("http://ci.csgowiki.top:2333/trigger/wiki-player");
    postRequest.SetHeader("Content-Type", "application/json");

    JSONObject postData = new JSONObject();
    postData.SetString("map_name", g_sCurrentMap);
    postData.SetString("steamid", steamid_);
    postData.SetString("player_name", player_name);
    
    postRequest.Post(postData, WikiPlayerTriggerResponseCallback);
    delete postData;
}

void ResetSingleClientWikiState(client, bool force_del=false) {
    if (strlen(g_aLastArticleId[client]) == 0) return;
    if (strlen(g_aLastUtilityId[client]) == 0) return;
    if (force_del) {
        DeleteReplayFileFromUtid(g_aLastUtilityId[client]);
    }
    else {
        bool candelete = true;
        for (int i = 0; i <= MaxClients; i++) {
            if (IsPlayer(i) && i != client && StrEqual(g_aLastUtilityId[client], g_aLastUtilityId[i])) {
                candelete = false;
                break;
            }
        }
        if (candelete) {
            DeleteReplayFileFromUtid(g_aLastUtilityId[client]);
        }
    }
    strcopy(g_aLastUtilityId[client], LENGTH_UTILITY_ID, "");
    strcopy(g_aLastArticleId[client], LENGTH_UTILITY_ID, "");
}

void ResetUtilityWikiState() {
    for (new client = 0; client <= MAXPLAYERS; client++) {
        ResetSingleClientWikiState(client, true);
    }
}

void AllCollectionResponseCallback(HTTPResponse response, int client) {
    if (response.Status == HTTPStatus_OK) {
        char status[LENGTH_STATUS];
        JSONObject resp_json = view_as<JSONObject>(response.Data);
        resp_json.GetString("status", status, LENGTH_STATUS);
        if (!StrEqual(status, "ok")) {
            if (client == -1) PrintToChatAll("%s \x02服务器数据请求失败，可能是token无效", PREFIX);
            else PrintToChat(client, "%s \x02服务器数据请求失败，可能是token无效", PREFIX);
            return;
        }

        g_jaUtilityCollection = view_as<JSONArray>(resp_json.Get("utility_collection"));
        // show menu for Command_Wiki
        if (IsPlayer(client)) {
            Menu_UtilityWiki_v1(client);
        }
        // need delete?
    }
    else {
        if (client == -1) PrintToChatAll("%s \x02连接至mycsgolab失败：%d", PREFIX, response.Status);
        else PrintToChat(client, "%s \x02连接至mycsgolab失败：%d", PREFIX, response.Status);
    }
}


void ProCollectionResponseCallback(HTTPResponse response, int client) {
    if (IsPlayer(client)) {
        PrintToChat(client, "%s 职业比赛道具获取：%d", PREFIX, response.Status);
    }
    if (response.Status == HTTPStatus_OK) {
        JSONArray resp_json = view_as<JSONArray>(response.Data);
        g_aProMatchInfo = new JSONArray();
        for (int idx = 0; idx < resp_json.Length; idx++) {
            JSONObject arrval = view_as<JSONObject>(resp_json.Get(idx));
            g_aProMatchInfo.Push(arrval);
        }
        // g_aProMatchInfo = view_as<JSONArray>(response.Data);
    }
    else {
        PrintToChatAll("%s \x02连接至api.hx-w.top失败：%d", PREFIX, response.Status);
        PrintToServer("%s \x02连接至api.hx-w.top失败：%d", PREFIX, response.Status);
    }
}

void FilterCollectionResponseCallback(HTTPResponse response, int client) {
    if (response.Status == HTTPStatus_OK) {
        char status[LENGTH_STATUS];
        JSONObject resp_json = view_as<JSONObject>(response.Data);
        resp_json.GetString("status", status, LENGTH_STATUS);
        if (StrEqual(status, "error")) {
            PrintToChat(client, "%s \x02服务器数据请求失败，可能是token无效", PREFIX);
            Menu_UtilityWiki_v1(client);
        }
        else if (StrEqual(status, "warning")) {
            PrintToChat(client, "%s \x02服务器数据请求失败，等级限制2级及以上", PREFIX);
            Menu_UtilityWiki_v1(client);
        }
        else if (StrEqual(status, "ok")) {
            g_aUtFilterCollection[client] = view_as<JSONArray>(resp_json.Get("utility_collection"));
            // show menu for Command_Wiki
            Menu_UtilityWiki_v3(client);
        }
        delete resp_json;
    }
    else {
        PrintToChat(client, "%s \x02连接至mycsgolab失败：%d", PREFIX, response.Status);
    }
}

void UtilityDetailResponseCallback(HTTPResponse response, int client) {
    if (response.Status == HTTPStatus_OK) {
        char status[LENGTH_STATUS];
        JSONObject resp_json = view_as<JSONObject>(response.Data);
        resp_json.GetString("status", status, LENGTH_STATUS);
        char detail[1024];
        resp_json.ToString(detail, sizeof(detail));
        if (StrEqual(status, "error")) {
            PrintToChat(client, "%s \x02服务器数据请求失败，可能是token无效", PREFIX);
        }
        else if (StrEqual(status, "warning")) {
            PrintToChat(client, "%s \x02服务器数据请求失败，已超过当日请求次数限制", PREFIX);
        }
        else if (StrEqual(status, "ok")) {
            JSONObject json_obj = view_as<JSONObject>(resp_json.Get("utility_detail"));
            ShowUtilityDetail(client, json_obj);
        }
        delete resp_json;
    }
    else {
        PrintToChat(client, "%s \x02连接至mycsgolab失败：%d", PREFIX, response.Status);
    }
}


void WikiPlayerTriggerResponseCallback(HTTPResponse response, any data) {
    if (response.Status != HTTPStatus_OK) {
        PrintToServer("wiki-player trigger error: %d", response.Status);
    }
}

void ShowUtilityDetail(client, JSONObject detail_json) {
    if (!IsPlayer(client)) return;
    // var define
    char utId[LENGTH_UTILITY_ID], utType[LENGTH_UTILITY_TINY], utTitle[LENGTH_NAME];
    char utBrief[LENGTH_UTILITY_BRIEF], author[LENGTH_NAME];
    char actionBody[LENGTH_UTILITY_ZH], actionMouse[LENGTH_UTILITY_ZH];
    float startPos[DATA_DIM], startAngle[DATA_DIM], velocity[DATA_DIM];
    float throwPos[DATA_DIM];
    char trueUtId[LENGTH_UTILITY_ID];

    detail_json.GetString("id", utId, sizeof(utId));
    detail_json.GetString("utility_id", trueUtId, sizeof(trueUtId));
    detail_json.GetString("type", utType, sizeof(utType));
    detail_json.GetString("title", utTitle, sizeof(utTitle));
    detail_json.GetString("brief", utBrief, sizeof(utBrief));
    detail_json.GetString("author", author, sizeof(author));
    detail_json.GetString("action_body", actionBody, sizeof(actionBody));
    detail_json.GetString("action_mouse", actionMouse, sizeof(actionMouse));
    startPos[0] = detail_json.GetFloat("start_x");
    startPos[1] = detail_json.GetFloat("start_y");
    startPos[2] = detail_json.GetFloat("start_z");
    startAngle[0] = detail_json.GetFloat("aim_pitch");
    startAngle[1] = detail_json.GetFloat("aim_yaw");
    startAngle[2] = 0.0;
    velocity[0] = detail_json.GetFloat("velocity_x");
    velocity[1] = detail_json.GetFloat("velocity_y");
    velocity[2] = detail_json.GetFloat("velocity_z");
    throwPos[0] = detail_json.GetFloat("throw_x");
    throwPos[1] = detail_json.GetFloat("throw_y");
    throwPos[2] = detail_json.GetFloat("throw_z");

    // set last ut record
    // clear pre-recfile
    if (!StrEqual(g_aLastUtilityId[client], trueUtId)) {
        bool candelete = true;
        for (int i = 0; i <= MaxClients; i++) {
            if (IsPlayer(i) && i != client && StrEqual(g_aLastUtilityId[client], g_aLastUtilityId[i])) {
                candelete = false;
                break;
            }
        }
        if (candelete) {
            DeleteReplayFileFromUtid(g_aLastUtilityId[client]);
        }
        strcopy(g_aLastUtilityId[client], LENGTH_UTILITY_ID, trueUtId);
    }

    if (!StrEqual(g_aLastArticleId[client], utId)) {
        strcopy(g_aLastArticleId[client], LENGTH_UTILITY_ID, utId);
    }
    // decode ut name
    char utNameZh[LENGTH_UTILITY_ZH], utWeaponCmd[LENGTH_UTILITY_ZH];
    Utility_TinyName2Zh(utType, "%s", utNameZh);
    Utility_TinyName2Weapon(utType, utWeaponCmd, client);
    // tp player and get utility
    TeleportEntity(client, startPos, startAngle, NULL_VECTOR);
    GivePlayerItem(client, utWeaponCmd);
    Format(utWeaponCmd, sizeof(utWeaponCmd), "use %s", utWeaponCmd);
    SetEntProp(client, Prop_Send, "m_iAmmo", 1);
    FakeClientCommand(client, utWeaponCmd);
    // auto throw
    if (g_bAutoThrow[client]) {
        if (!StartRequestReplayFile(client, utId, trueUtId)) {
            if (velocity[0] == 0.0 && velocity[1] == 0.0 && velocity[2] == 0.0) {
                PrintToChat(client, "%s \x06当前道具没有记录初始速度，无法自动投掷", PREFIX);
            }
            else {
                GrenadeType grenadeType = TinyName_2_GrenadeType(utType, client);
                CSU_ThrowGrenade(client, grenadeType, throwPos, velocity);
                PrintToChat(client, "%s \x05已自动投掷道具", PREFIX);
            }
        }
        else {
            // cache utility init velocity & throw pos
            g_aUtilityVelocity[client][0] = velocity[0];
            g_aUtilityVelocity[client][1] = velocity[1];
            g_aUtilityVelocity[client][2] = velocity[2];
            g_aThrowPositions[client][0] = throwPos[0];
            g_aThrowPositions[client][1] = throwPos[1];
            g_aThrowPositions[client][2] = throwPos[2];
            g_aStartPositions[client][0] = startPos[0];
            g_aStartPositions[client][1] = startPos[1];
            g_aStartPositions[client][2] = startPos[2];
            g_aStartAngles[client][0] = startAngle[0];
            g_aStartAngles[client][1] = startAngle[1];
            g_aStartAngles[client][2] = startAngle[2];
        }
    }

    // printout
    PrintToChat(client, "\x09 ------------------------------------- ");
    PrintToChat(client, "%s ID: \x10%s", PREFIX, utId);
    PrintToChat(client, "%s 名称: \x10%s", PREFIX, utTitle);
    if (strlen(utBrief) != 0 && !StrEqual(utTitle, utBrief))
        PrintToChat(client, "%s 简介: \x10%s", PREFIX, utBrief);
    PrintToChat(client, "%s 种类: \x10%s", PREFIX, utNameZh);
    if (strlen(author) != 0)
        PrintToChat(client, "%s 作者: \x10%s", PREFIX, author);
    PrintToChat(client, "\x09 ------------------------------------- ");
    //
    PrintCenterText(client, "身体动作：<font color='#ED0C39'>%s\n<font color='#ffffff'>鼠标动作：<font color='#0CED26'>%s\n", actionBody, actionMouse);
}