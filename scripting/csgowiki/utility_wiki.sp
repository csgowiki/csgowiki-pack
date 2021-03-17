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

    if (g_jaUtilityCollection.Length < 3) {
        PrintToChat(client, "%s 道具合集初始化失败，正在重新请求数据...", PREFIX);
        GetAllCollection(client);
    }
    else {
        Menu_UtilityWiki_v1(client);
    }
}

void GetAllCollection(client=-1) {
    if (!check_function_on(g_hOnUtilityWiki, "")) return;
    char token[LENGTH_TOKEN];
    GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);
    System2HTTPRequest AllCollectionRequest = new System2HTTPRequest (
        AllCollectionResponseCallback, 
        "https://api.csgowiki.top/api/utility/collection/?token=%s&map=%s&tickrate=%d&type=%s",
        token, g_sCurrentMap, g_iServerTickrate, "common"
    );
    AllCollectionRequest.Any = client;
    AllCollectionRequest.GET();

    System2HTTPRequest ProCollectionRequest = new System2HTTPRequest (
        ProCollectionResponseCallback, 
        "https://api.csgowiki.top/api/utility/collection/?token=%s&map=%s&type=%s",
        token, g_sCurrentMap, "pro"
    );
    ProCollectionRequest.Any = client;
    ProCollectionRequest.GET();

    delete AllCollectionRequest;
    delete ProCollectionRequest;
}

void GetFilterCollection(client, char[] method) {
    float playerPos[DATA_DIM];
    char token[LENGTH_TOKEN];
    GetClientAbsOrigin(client, playerPos);
    GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);

    System2HTTPRequest httpRequest = new System2HTTPRequest(
        FilterCollectionResponseCallback, 
        "https://api.csgowiki.top/api/utility/spot_filter/?token=%s&map=%s&tickrate=%d&method=%s&x=%f&y=%f",
        token, g_sCurrentMap, g_iServerTickrate, method, playerPos[0], playerPos[1]
    );
    httpRequest.Any = client;
    httpRequest.GET();
    delete httpRequest;
}

void GetUtilityDetail(client, char[] utId, char[] type="common") {
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

    if (StrEqual(type, "common")) {
        System2HTTPRequest httpRequest = new System2HTTPRequest(
            UtilityDetailResponseCallback, 
            "https://api.csgowiki.top/api/utility/detail_info/?token=%s&id=%s&type=common",
            token, utId
        );
        httpRequest.Any = client;
        httpRequest.GET();
        delete httpRequest;
    }
    else if (StrEqual(type, "pro")) {
        System2HTTPRequest httpRequest = new System2HTTPRequest(
            ProUtilityDetailResponseCallback, 
            "https://api.csgowiki.top/api/utility/detail_info/?token=%s&id=%s&type=pro",
            token, utId
        );
        httpRequest.Any = client;
        httpRequest.GET();
        delete httpRequest;
    }

}

void ResetSingleClientWikiState(client) {
    strcopy(g_aLastUtilityId[client], LENGTH_UTILITY_ID, "");
    // if (g_aUtFilterCollection[client] != INVALID_HANDLE)
    //     g_aUtFilterCollection[client].Cleanup();
}

void ResetUtilityWikiState() {
    // if (g_jaUtilityCollection != INVALID_HANDLE)
    //     g_jaUtilityCollection.Cleanup();
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
        // delete resp_json;
        // json_cleanup_and_delete(resp_json);
    }
    else {
        if (client == -1) PrintToChatAll("%s \x02连接至www.csgowiki.top失败：%s", PREFIX, error);
        else PrintToChat(client, "%s \x02连接至www.csgowiki.top失败：%s", PREFIX, error);
    }
}

public ProCollectionResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
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
        JSON_Object tmp_ = resp_json.GetObject("utility_collection");
        g_joProMatchInfo = tmp_.GetObject("match_info");
        g_jaProUtilityInfo = view_as<JSON_Array>(tmp_.GetObject("utility_info"));
        // show menu for Command_Wiki
        if (client != -1) {
            Menu_UtilityWiki_v1(client);
        }
        // delete resp_json;
        // json_cleanup_and_delete(resp_json);
    }
    else {
        if (client == -1) PrintToChatAll("%s \x02连接至www.csgowiki.top失败：%s", PREFIX, error);
        else PrintToChat(client, "%s \x02连接至www.csgowiki.top失败：%s", PREFIX, error);
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
        PrintToChat(client, "%s \x02连接至www.csgowiki.top失败：%s", PREFIX, error);
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
        PrintToChat(client, "%s \x02连接至www.csgowiki.top失败：%s", PREFIX, error);
    }
}

public ProUtilityDetailResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
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
            ShowProUtilityDetail(client, json_obj);
        }
        json_cleanup_and_delete(resp_json);
    }
    else {
        PrintToChat(client, "%s \x02连接至www.csgowiki.top失败：%s", PREFIX, error);
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
    if (GetConVarBool(g_hWikiAutoThrow)) {
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

void ShowProUtilityDetail(client, JSON_Object detail_json) {
    char utType[LENGTH_UTILITY_TINY], playerName[LENGTH_NAME], teamName[LENGTH_NAME];
    char eventName[LENGTH_MESSAGE], result[LENGTH_MESSAGE];
    char actionBody[LENGTH_UTILITY_ZH], actionMouse[LENGTH_UTILITY_ZH];
    float throwPos[DATA_DIM], startAngle[DATA_DIM];

    detail_json.GetString("type", utType, sizeof(utType));
    detail_json.GetString("player_name", playerName, sizeof(playerName));
    detail_json.GetString("player_team", teamName, sizeof(teamName));
    int round = detail_json.GetInt("round");
    int round_time = detail_json.GetInt("round_time");
    detail_json.GetString("event", eventName, sizeof(eventName));
    detail_json.GetString("result", result, sizeof(result));
    throwPos[0] = detail_json.GetFloat("throw_x");
    throwPos[1] = detail_json.GetFloat("throw_y");
    throwPos[2] = detail_json.GetFloat("throw_z");
    startAngle[0] = detail_json.GetFloat("aim_pitch");
    startAngle[1] = detail_json.GetFloat("aim_yaw");
    startAngle[2] = 0.0;
    detail_json.GetString("action_body", actionBody, sizeof(actionBody));
    detail_json.GetString("action_mouse", actionMouse, sizeof(actionMouse));
    JSON_Array related_utility = view_as<JSON_Array>(detail_json.GetObject("related_utility"));

    char utNameZh[LENGTH_UTILITY_ZH], utWeaponCmd[LENGTH_UTILITY_ZH];
    Utility_TinyName2Zh(utType, "%s", utNameZh);
    Utility_TinyName2Weapon(utType, utWeaponCmd, client);
    int round_remain_secs = 55 + 60 - round_time;
    int round_remain_min = round_remain_secs / 60;
    round_remain_secs %= 60;
    // tp player and get utility
    TeleportEntity(client, throwPos, startAngle, NULL_VECTOR);
    GivePlayerItem(client, utWeaponCmd);
    Format(utWeaponCmd, sizeof(utWeaponCmd), "use %s", utWeaponCmd);
    SetEntProp(client, Prop_Send, "m_iAmmo", 1);
    FakeClientCommand(client, utWeaponCmd);

    // printout
    PrintToChat(client, "\x09 ------------------------------------- ");
    PrintToChat(client, "%s 赛事: \x0B%s", PREFIX, eventName);
    PrintToChat(client, "%s %s", PREFIX, result);
    PrintToChat(client, "%s \x01<\x03%s\x01> 由 *\x04%s\x01* 在第\x04%d\x01回合 \x04%2d:%2d\x01投掷", PREFIX, utNameZh, playerName, round, round_remain_min, round_remain_secs);

    if (related_utility.Length > 0) {
        PrintToChat(client, "%s 相似的CSGOWiki收录道具：", PREFIX);
        for (new idx = 0; idx < related_utility.Length; idx ++) {
            char utId[LENGTH_UTILITY_ID];
            related_utility.GetString(idx, utId, sizeof(utId));
            PrintToChat(client, "%s \x09!wiki %s", PREFIX, utId);
        }
    }

    PrintToChat(client, "\x09 ------------------------------------- ");
    //
    PrintCenterText(client, "身体动作：<font color='#ED0C39'>%s\n<font color='#ffffff'>鼠标动作：<font color='#0CED26'>%s\n以上信息不一定准确", actionBody, actionMouse);
}
