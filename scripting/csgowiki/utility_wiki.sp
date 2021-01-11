// implement wiki

public Action:Command_Wiki(client, args) {
    if (!check_function_on(g_hOnUtilityWiki, "\x02道具学习插件已关闭，请联系服务器管理员", client)) {
        return;
    }
    if (args >= 1) {
        char utId[LENGTH_TOKEN];
        GetCmdArgString(utId, LENGTH_TOKEN);
        TrimString(utId);
        PrintToChat(client, "%s 正在请求道具<\x0E%s\x01>", PREFIX, utId);
        GetUtilityDetail(client, utId);
    }
    GetAllCollection(client);
}

public Action:GetUtilityCollectionTimerCallback(Handle:timer) {
    GetAllCollection(-1);
    return Plugin_Continue;
}

void GetAllCollection(client=-1) {
    char token[LENGTH_TOKEN];
    GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);
    System2HTTPRequest httpRequest = new System2HTTPRequest(
        AllCollectionResponseCallback, 
        "https://test.csgowiki.top/api/utility/collection/?token=%s&map=%s&tickrate=%d",
        token, g_sCurrentMap, g_iServerTickrate
    );
    httpRequest.Any = client;
    httpRequest.GET();
}

void GetFilterCollection(client, char[] method) {
    float playerPos[DATA_DIM];
    char token[LENGTH_TOKEN];
    GetClientAbsOrigin(client, playerPos);
    GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);

    System2HTTPRequest httpRequest = new System2HTTPRequest(
        FilterCollectionResponseCallback, 
        "https://test.csgowiki.top/api/utility/spot_filter/?token=%s&map=%s&tickrate=%d&method=%s&x=%f&y=%f",
        token, g_sCurrentMap, g_iServerTickrate, method, playerPos[0], playerPos[1]
    );
    httpRequest.Any = client;
    httpRequest.GET();
}

void GetUtilityDetail(client, char[] utId) {
    char token[LENGTH_TOKEN];
    GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);
    System2HTTPRequest httpRequest = new System2HTTPRequest(
        UtilityDetailResponseCallback, 
        "https://test.csgowiki.top/api/utility/detail_info/?token=%s&id=%s",
        token, utId
    );
    httpRequest.Any = client;
    httpRequest.GET();
}

void ResetSingleClientWikiState(client) {
    strcopy(g_aLastUtilityId[client], LENGTH_UTILITY_ID, "");
    if (g_aUtFilterCollection[client] != INVALID_HANDLE)
        g_aUtFilterCollection[client].Cleanup();
}

void ResetUtilityWikiState() {
    if (g_jaUtilityCollection != INVALID_HANDLE)
        g_jaUtilityCollection.Cleanup();
    for (new client = 0; client <= MAXPLAYERS; client++) {
        ResetSingleClientWikiState(client);
    }
}


public AllCollectionResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    new client = request.Any;
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        char[] status = new char[LENGTH_STATUS];
        response.GetContent(content, response.ContentLength + 1);
        JSON_Object resp_json = json_decode(content);
        resp_json.GetString("status", status, LENGTH_STATUS);
        if (!StrEqual(status, "ok")) {
            if (client == -1) PrintToChatAll("%s \x02服务器数据请求失败，可能是token无效", PREFIX);
            else PrintToChat(client, "%s \x02服务器数据请求失败，可能是token无效", PREFIX);
            return;
        }
        g_jaUtilityCollection = view_as<JSON_Array>(resp_json.GetObject("utility_collection"));
        // show menu for Command_Wiki
        if (client != -1) {
            Menu_UtilityWiki_v1(client);
        }
    }
    else {
        if (client == -1) PrintToChatAll("%s \x02连接至www.csgowiki.top失败", PREFIX);
        else PrintToChat(client, "%s \x02连接至www.csgowiki.top失败", PREFIX);
    }
}


public FilterCollectionResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    new client = request.Any;
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        char[] status = new char[LENGTH_STATUS];
        response.GetContent(content, response.ContentLength + 1);
        JSON_Object resp_json = json_decode(content);
        resp_json.GetString("status", status, LENGTH_STATUS);
        if (StrEqual(status, "error")) {
            PrintToChat(client, "%s \x02服务器数据请求失败，可能是token无效", PREFIX);
            return;
        }
        else if (StrEqual(status, "warning")) {
            PrintToChat(client, "%s \x02服务器数据请求失败，等级限制2级及以上", PREFIX);
            return;
        }
        else if (StrEqual(status, "ok")) {
            g_aUtFilterCollection[client] = view_as<JSON_Array>(resp_json.GetObject("utility_collection"));
            // show menu for Command_Wiki
            Menu_UtilityWiki_v3(client);
        }
    }
    else {
        PrintToChat(client, "%s \x02连接至www.csgowiki.top失败", PREFIX);
    }
}


public UtilityDetailResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    new client = request.Any;
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        char[] status = new char[LENGTH_STATUS];
        response.GetContent(content, response.ContentLength + 1);
        JSON_Object resp_json = json_decode(content);
        resp_json.GetString("status", status, LENGTH_STATUS);
        if (StrEqual(status, "error")) {
            PrintToChat(client, "%s \x02服务器数据请求失败，可能是token无效", PREFIX);
            return;
        }
        else if (StrEqual(status, "warning")) {
            PrintToChat(client, "%s \x02服务器数据请求失败，已超过当日请求次数限制", PREFIX);
            return;
        }
        else if (StrEqual(status, "ok")) {
            JSON_Object json_obj = resp_json.GetObject("utility_detail");
            ShowUtilityDetail(client, json_obj)       
        }
    }
    else {
        PrintToChat(client, "%s \x02连接至www.csgowiki.top失败", PREFIX);
    }
}

void ShowUtilityDetail(client, JSON_Object detail_json) {
    // var define
    char utId[LENGTH_UTILITY_ID], utType[LENGTH_UTILITY_TINY], utTitle[LENGTH_NAME];
    char utBrief[LENGTH_UTILITY_BRIEF], author[LENGTH_NAME];
    char actionBody[LENGTH_UTILITY_ZH], actionMouse[LENGTH_UTILITY_ZH];
    float startPos[DATA_DIM], startAngle[DATA_DIM];

    detail_json.GetString("id", utId, sizeof(utId));
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

    // set last ut record
    strcopy(g_aLastUtilityId[client], LENGTH_UTILITY_ID, utId);
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