// implement wiki

public Action:Command_Wiki(client, args) {
    PluginVersionHint(client);

    if (!check_function_on(g_hOnUtilityWiki, "\x02道具学习插件关闭，请联系服务器管理员", client)) {
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

    System2HTTPRequest AllCollectionRequest = new System2HTTPRequest(
        AllCollectionResponseCallback, 
        // "https://api.mycsgolab.com/utility/utility/collection/?token=%s&current_map=%s&tickrate=%d",
        "%s/utility/utility/collection/?token=%s&current_map=%s&tickrate=%d",
        apiHost, token, g_sCurrentMap, g_iServerTickrate
    );
    AllCollectionRequest.Any = client;
    AllCollectionRequest.GET();
    delete AllCollectionRequest;

    // pro
    System2HTTPRequest ProCollectionRequest = new System2HTTPRequest(
        ProCollectionResponseCallback,
        "https://api.hx-w.top/%s",
        g_sCurrentMap
    )
    if (g_aProMatchInfo == INVALID_HANDLE || g_aProMatchInfo.Length < 1) {
        ProCollectionRequest.GET();
    }
    delete ProCollectionRequest;
}

void GetFilterCollection(client, char[] method) {
    float playerPos[DATA_DIM];
    char token[LENGTH_TOKEN];
    GetClientAbsOrigin(client, playerPos);
    GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);

    System2HTTPRequest httpRequest = new System2HTTPRequest(
        FilterCollectionResponseCallback, 
        "https://api.mycsgolab.com/utility/utility/filter/?token=%s&map=%s&tickrate=%d&method=%s&x=%f&y=%f",
        // "http://ci.csgowiki.top:2333/utility/utility/filter/?token=%s&map=%s&tickrate=%d&method=%s&x=%f&y=%f",
        token, g_sCurrentMap, g_iServerTickrate, method, playerPos[0], playerPos[1]
    );
    httpRequest.Any = client;
    httpRequest.GET();
    delete httpRequest;
}

void GetUtilityDetail(client, char[] utId) {
    // lock
    float fWikiLimit = GetConVarFloat(g_hWikiReqLimit);
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

    System2HTTPRequest httpRequest = new System2HTTPRequest(
        UtilityDetailResponseCallback, 
        // "https://api.mycsgolab.com/utility/utility/detail/?token=%s&utility_id=%s",
        "%s/utility/utility/detail/?token=%s&utility_id=%s",
        apiHost, token, utId
    );
    httpRequest.Any = client;
    httpRequest.GET();
    delete httpRequest;
}

void ResetSingleClientWikiState(client) {
    strcopy(g_aLastUtilityId[client], LENGTH_UTILITY_ID, "");
}

void ResetUtilityWikiState() {
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
        if (client == -1) PrintToChatAll("%s \x02连接至mycsgolab失败：%s", PREFIX, error);
        else PrintToChat(client, "%s \x02连接至mycsgolab失败：%s", PREFIX, error);
    }
}


public ProCollectionResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        response.GetContent(content, response.ContentLength + 1);
        g_aProMatchInfo = view_as<JSON_Array>(json_decode(content));
    }
    else {
        PrintToChatAll("%s \x02连接至api.hx-w.top失败：%s", PREFIX, error);
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
            Menu_UtilityWiki_v1(client);
        }
        else if (StrEqual(status, "warning")) {
            PrintToChat(client, "%s \x02服务器数据请求失败，等级限制2级及以上", PREFIX);
            Menu_UtilityWiki_v1(client);
        }
        else if (StrEqual(status, "ok")) {
            g_aUtFilterCollection[client] = view_as<JSON_Array>(resp_json.GetObject("utility_collection"));
            // show menu for Command_Wiki
            Menu_UtilityWiki_v3(client);
        }
        delete resp_json;
    }
    else {
        PrintToChat(client, "%s \x02连接至mycsgolab失败：%s", PREFIX, error);
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
        }
        else if (StrEqual(status, "warning")) {
            PrintToChat(client, "%s \x02服务器数据请求失败，已超过当日请求次数限制", PREFIX);
        }
        else if (StrEqual(status, "ok")) {
            JSON_Object json_obj = resp_json.GetObject("utility_detail");
            ShowUtilityDetail(client, json_obj);
        }
        json_cleanup_and_delete(resp_json);
    }
    else {
        PrintToChat(client, "%s \x02连接至mycsgolab失败：%s", PREFIX, error);
    }
}

void ShowUtilityDetail(client, JSON_Object detail_json) {
    // var define
    char utId[LENGTH_UTILITY_ID], utType[LENGTH_UTILITY_TINY], utTitle[LENGTH_NAME];
    char utBrief[LENGTH_UTILITY_BRIEF], author[LENGTH_NAME];
    char actionBody[LENGTH_UTILITY_ZH], actionMouse[LENGTH_UTILITY_ZH];
    float startPos[DATA_DIM], startAngle[DATA_DIM], velocity[DATA_DIM];
    float throwPos[DATA_DIM];

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
    velocity[0] = detail_json.GetFloat("velocity_x");
    velocity[1] = detail_json.GetFloat("velocity_y");
    velocity[2] = detail_json.GetFloat("velocity_z");
    throwPos[0] = detail_json.GetFloat("throw_x");
    throwPos[1] = detail_json.GetFloat("throw_y");
    throwPos[2] = detail_json.GetFloat("throw_z");

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
    // auto throw
    if (g_bAutoThrow[client]) {
        if (velocity[0] == 0.0 && velocity[1] == 0.0 && velocity[2] == 0.0) {
            PrintToChat(client, "%s \x06当前道具没有记录初始速度，无法自动投掷", PREFIX);
        }
        else {
            GrenadeType grenadeType = TinyName_2_GrenadeType(utType, client);
            CSU_ThrowGrenade(client, grenadeType, throwPos, velocity);
            PrintToChat(client, "%s \x05已自动投掷道具", PREFIX);
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