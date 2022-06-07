public Action Command_WikiPro(int client, any args) {
    if (!check_function_on(g_hOnUtilityWiki, "\x02道具学习插件关闭，请联系服务器管理员", client)) {
        return;
    }
    if (BotMimicFix_IsPlayerMimicing(client)) {
        PrintToChat(client, "%s \x02正在播放录像", PREFIX);
        return;
    }
    if (g_aProMatchIndex[client] == -1) { // not set
        PrintToChat(client, "%s \x05请先选择职业比赛场次，已自动跳转选择菜单，如未跳转，请输入\x02!option\x05选择。", PREFIX);
        GetAllProMatchStat(client);
        return;
    }
    CreateProRoundMenu(client);
}

void CreateProRoundMenu(int client) {
    JSONObject picked_info = view_as<JSONObject>(g_aProMatchInfo.Get(g_aProMatchIndex[client]));
    char team1[LENGTH_NAME], team2[LENGTH_NAME];
    JSONObject teamInfo_1 = view_as<JSONObject>(picked_info.Get("team1"));
    JSONObject teamInfo_2 = view_as<JSONObject>(picked_info.Get("team2"));
    teamInfo_1.GetString("name", team1, sizeof(team1));
    teamInfo_2.GetString("name", team2, sizeof(team2));
    int score1 = teamInfo_1.GetInt("result");
    int score2 = teamInfo_2.GetInt("result");
    char title[LENGTH_NAME * 4];
    Format(title, sizeof(title), "[%s] %d : %d [%s] 回合选择", team1, score1, score2, team2);
    
    Handle menuhandle = CreateMenu(ProMatchRoundMenuCallback);
    SetMenuTitle(menuhandle, title);

    int maxround_int = picked_info.GetInt("maxround");
    for (int round_count = 1; round_count <= maxround_int; round_count++) {
        char round_str[4];
        IntToString(round_count, round_str, sizeof(round_str));
        char item[LENGTH_MESSAGE];
        Format(item, sizeof(item), "第%s回合", round_str);
        AddMenuItem(menuhandle, round_str, item);
    }

    SetMenuPagination(menuhandle, 7);
    SetMenuExitBackButton(menuhandle, true);
    DisplayMenu(menuhandle, client, MENU_TIME_FOREVER);
}

public int ProMatchRoundMenuCallback(Handle menuhandle, MenuAction action, int client, int Position) {
    if (MenuAction_Select == action) {
        char round_str[4];
        GetMenuItem(menuhandle, Position, round_str, sizeof(round_str));

        ShowProListInRound(client, round_str);
    }
    else if (MenuAction_Cancel == action) {
        ClientCommand(client, "sm_m");
    }
}

void ShowProListInRound(int client, char round_str[4]) {
    if (g_aProMatchIndex[client] == -1) {
        return;
    }
    if (BotMimicFix_IsPlayerMimicing(client)) {
        PrintToChat(client, "%s \x02正在播放录像", PREFIX);
        return;
    }
    char _matchId[LENGTH_NAME];
    char url[LENGTH_MESSAGE];
    JSONObject arrval = view_as<JSONObject>(g_aProMatchInfo.Get(g_aProMatchIndex[client]));
    arrval.GetString("matchId", _matchId, sizeof(_matchId));
    Format(url, sizeof(url), "https://api.hx-w.top/%s/%s/round%s", g_sCurrentMap, _matchId, round_str);
    HTTPRequest ProDetailRequest = new HTTPRequest(url);
    DataPack pack = new DataPack();
    pack.WriteCell(client);
    pack.WriteString(round_str);
    ProDetailRequest.Get(ProRoundResponseCallback, pack);
}

void ProRoundResponseCallback(HTTPResponse response, DataPack pack) {
    pack.Reset();
    int client = pack.ReadCell();
    char round_str[4];
    pack.ReadString(round_str, sizeof(round_str));
    if (response.Status == HTTPStatus_OK) {
        delete g_aProMatchDetail[client];
        g_aProMatchDetail[client] = new JSONArray();
        JSONArray resp_json = view_as<JSONArray>(response.Data);
        for (int idx = 0; idx < resp_json.Length; idx++) {
            JSONObject arrval = view_as<JSONObject>(resp_json.Get(idx));
            g_aProMatchDetail[client].Push(arrval);
        }
        // g_aProMatchDetail[client] = view_as<JSONArray>(response.Data);
        CreateProDetailMenu(client, round_str);
    }
    else {
        PrintToChatAll("%s \x02连接至api.hx-w.top失败：%d", PREFIX, response.Status);
    }
}

void CreateProDetailMenu(int client, char round_str[4]) {
    if (g_aProMatchDetail[client].Length == 0) {
        PrintToChat(client, "%s \x0F请求的数据出错，请重新选择比赛数据", PREFIX);
        GetAllProMatchStat(client);
        return;
    }

    char title[LENGTH_NAME];
    Format(title, sizeof(title), "第%s回合道具记录", round_str);
    
    Handle menuhandle = CreateMenu(ProMatchDetailMenuCallback);
    SetMenuTitle(menuhandle, title);

    char playerName[LENGTH_NAME];
    char utFullName[LENGTH_UTILITY_FULL];
    char utZhName[LENGTH_UTILITY_ZH];
    char item[LENGTH_NAME * 4];
    char utId[LENGTH_UTILITY_ID];
    for (int idx = 0; idx < g_aProMatchDetail[client].Length; idx++) {
        JSONArray curr = view_as<JSONArray>(g_aProMatchDetail[client].Get(idx));
        curr.GetString(11, playerName, sizeof(playerName));
        curr.GetString(17, utFullName, sizeof(utFullName));
        int round_throw_time = RoundFloat(curr.GetFloat(10));
        int round_remain_secs = 55 + 60 - round_throw_time;
        int round_remain_min = round_remain_secs / 60;
        round_remain_secs %= 60;
        Utility_FullName2Zh(utFullName, "%s", utZhName);
        IntToString(idx, utId, sizeof(utId));
        Format(item, sizeof(item), "[%s] %2d:%2d <%s>投掷", utZhName, round_remain_min, round_remain_secs, playerName);
        AddMenuItem(menuhandle, utId, item);
    }
    SetMenuPagination(menuhandle, 7);
    SetMenuExitBackButton(menuhandle, true);
    DisplayMenu(menuhandle, client, MENU_TIME_FOREVER);
}

public int ProMatchDetailMenuCallback(Handle menuhandle, MenuAction action, int client, int Position) {
    if (MenuAction_Select == action) {
        char utId[LENGTH_UTILITY_ID];
        GetMenuItem(menuhandle, Position, utId, sizeof(utId));
        int utId_int = StringToInt(utId);
        ShowProUtilityDetail(client, utId_int);
        DisplayMenuAtItem(menuhandle, client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
    }
    else if (MenuAction_Cancel == action) {
        CreateProRoundMenu(client);
    }
}

void ShowProUtilityDetail(int client, int utId) {
    char utType[LENGTH_UTILITY_FULL], playerName[LENGTH_NAME], teamName[LENGTH_NAME];
    char eventName[LENGTH_MESSAGE];
    float throwPos[DATA_DIM], startAngle[DATA_DIM], velocity[DATA_DIM];
    float entityPos[DATA_DIM];

    JSONArray detail_json = view_as<JSONArray>(g_aProMatchDetail[client].Get(utId));
    JSONObject match_json = view_as<JSONObject>(g_aProMatchInfo.Get(g_aProMatchIndex[client]));

    detail_json.GetString(17, utType, sizeof(utType));
    detail_json.GetString(11, playerName, sizeof(playerName));
    detail_json.GetString(13, teamName, sizeof(teamName));
    match_json.GetString("event", eventName, sizeof(eventName));
    throwPos[0] = detail_json.GetFloat(14);
    throwPos[1] = detail_json.GetFloat(15);
    throwPos[2] = detail_json.GetFloat(16);
    velocity[0] = detail_json.GetFloat(18);
    velocity[1] = detail_json.GetFloat(19);
    velocity[2] = detail_json.GetFloat(20);
    entityPos[0] = detail_json.GetFloat(21);
    entityPos[1] = detail_json.GetFloat(22);
    entityPos[2] = detail_json.GetFloat(23);
    startAngle[0] = detail_json.GetFloat(0);
    startAngle[1] = detail_json.GetFloat(1);
    startAngle[2] = 0.0;

    char utNameZh[LENGTH_UTILITY_ZH], utWeaponCmd[LENGTH_UTILITY_ZH];
    Utility_FullName2Zh(utType, "%s", utNameZh);
    Utility_TinyName2Weapon(utType, utWeaponCmd, client);
    // tp player and get utility
    TeleportEntity(client, throwPos, startAngle, NULL_VECTOR);
    GivePlayerItem(client, utWeaponCmd);
    Format(utWeaponCmd, sizeof(utWeaponCmd), "use %s", utWeaponCmd);
    SetEntProp(client, Prop_Send, "m_iAmmo", 1);
    FakeClientCommand(client, utWeaponCmd);

    GrenadeType grenadeType = TinyName_2_GrenadeType(utType, client);
    CSU_ThrowGrenade(client, grenadeType, entityPos, velocity);
}
