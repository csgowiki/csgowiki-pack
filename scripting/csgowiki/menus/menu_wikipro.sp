public Action:Command_WikiPro(client, args) {
    if (g_aProMatchIndex[client] == -1) { // not set
        PrintToChat(client, "%s \x05请先选择职业比赛场次，已自动跳转选择菜单，如未跳转，请输入\x02!option\x05选择。", PREFIX);
        GetAllProMatchStat(client);
        return;
    }
    CreateProRoundMenu(client);
}

void CreateProRoundMenu(client) {
    JSON_Object picked_info = g_aProMatchInfo.GetObject(g_aProMatchIndex[client]);
    char team1[LENGTH_NAME], team2[LENGTH_NAME];
    JSON_Object teamInfo_1 = picked_info.GetObject("team1");
    JSON_Object teamInfo_2 = picked_info.GetObject("team2");
    teamInfo_1.GetString("name", team1, sizeof(team1));
    teamInfo_2.GetString("name", team2, sizeof(team2));
    int score1 = teamInfo_1.GetInt("result");
    int score2 = teamInfo_2.GetInt("result");
    char title[LENGTH_NAME * 4];
    Format(title, sizeof(title), "[%s] %d : %d [%s] 回合选择", team1, score1, score2, team2);
    
    new Handle:menuhandle = CreateMenu(ProMatchRoundMenuCallback);
    SetMenuTitle(menuhandle, title);

    int maxround_int = picked_info.GetInt("maxround");
    for (new round_count = 1; round_count <= maxround_int; round_count++) {
        char round_str[4];
        IntToString(round_count, round_str, sizeof(round_str));
        char item[LENGTH_MESSAGE];
        Format(item, sizeof(item), "第%s回合", round_str);
        AddMenuItem(menuhandle, round_str, item);
    }

    SetMenuPagination(menuhandle, 7);
    SetMenuExitBackButton(menuhandle, true);
    SetMenuExitButton(menuhandle, true);
    DisplayMenu(menuhandle, client, MENU_TIME_FOREVER);
}

public ProMatchRoundMenuCallback(Handle:menuhandle, MenuAction:action, client, Position) {
    if (MenuAction_Select == action) {
        decl String:round_str[4];
        GetMenuItem(menuhandle, Position, round_str, sizeof(round_str));

        ShowProListInRound(client, round_str);
    }
    else if (MenuAction_Cancel == action) {
        ClientCommand(client, "sm_m");
    }
}

void ShowProListInRound(client, char round_str[4]) {
    if (g_aProMatchIndex[client] == -1) {
        return;
    }
    char _matchId[LENGTH_NAME];
    JSON_Object arrval = g_aProMatchInfo.GetObject(g_aProMatchIndex[client]);
    arrval.GetString("matchId", _matchId, sizeof(_matchId));
    System2HTTPRequest ProDetailRequest = new System2HTTPRequest(
        ProRoundResponseCallback, 
        "https://api.hx-w.top/%s/%s/round%s",
        g_sCurrentMap, _matchId, round_str
    );
    DataPack pack = new DataPack();
    pack.WriteCell(client);
    pack.WriteString(round_str);
    ProDetailRequest.Any = pack;
    ProDetailRequest.GET();
    delete ProDetailRequest;
}

public ProRoundResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    DataPack pack = request.Any;
    pack.Reset();
    int client = pack.ReadCell();
    char round_str[4];
    pack.ReadString(round_str, sizeof(round_str));
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        response.GetContent(content, response.ContentLength + 1);
        g_aProMatchDetail[client] = view_as<JSON_Array>(json_decode(content));
        CreateProDetailMenu(client, round_str);
    }
    else {
        PrintToChatAll("%s \x02连接至api.hx-w.top失败：%s", PREFIX, error);
    }
}

void CreateProDetailMenu(client, char round_str[4]) {
    if (g_aProMatchDetail[client].Length == 0) {
        PrintToChat(client, "%s \x0F请求的数据出错，请重新选择比赛数据", PREFIX);
        GetAllProMatchStat(client);
        return;
    }

    char title[LENGTH_NAME];
    Format(title, sizeof(title), "第%s回合道具记录", round_str);
    
    new Handle:menuhandle = CreateMenu(ProMatchDetailMenuCallback);
    SetMenuTitle(menuhandle, title);

    char playerName[LENGTH_NAME];
    char utFullName[LENGTH_UTILITY_FULL];
    char utZhName[LENGTH_UTILITY_ZH];
    char item[LENGTH_NAME * 4];
    char round_throw_time_str[12];
    char utId[LENGTH_UTILITY_ID];
    for (new idx = 0; idx < g_aProMatchDetail[client].Length; idx++) {
        JSON_Array curr = view_as<JSON_Array>(g_aProMatchDetail[client].GetObject(idx));
        curr.GetString(11, playerName, sizeof(playerName));
        curr.GetString(17, utFullName, sizeof(utFullName));
        curr.GetString(10, round_throw_time_str, sizeof(round_throw_time_str));
        int round_throw_time = StringToInt(round_throw_time_str);
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
    SetMenuExitButton(menuhandle, true);
    DisplayMenu(menuhandle, client, MENU_TIME_FOREVER);
}

public ProMatchDetailMenuCallback(Handle:menuhandle, MenuAction:action, client, Position) {
    if (MenuAction_Select == action) {
        decl String:utId[LENGTH_UTILITY_ID];
        GetMenuItem(menuhandle, Position, utId, sizeof(utId));
        PrintToChat(client, "utid=%d", utId);
        int utId_int = StringToInt(utId);
        // ShowProUtilityDetail(client, utId_int);
        DisplayMenuAtItem(menuhandle, client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
    }
    else if (MenuAction_Cancel == action) {
        CreateProRoundMenu(client);
    }
}

// void ShowProUtilityDetail(client, int utId) {
//     char utType[LENGTH_UTILITY_FULL], playerName[LENGTH_NAME], teamName[LENGTH_NAME];
//     char eventName[LENGTH_MESSAGE];
//     char actionBody[LENGTH_UTILITY_ZH], actionMouse[LENGTH_UTILITY_ZH];
//     float throwPos[DATA_DIM], startAngle[DATA_DIM];

//     JSON_Array detail_json = view_as<JSON_Array>(g_aProMatchDetail[client].GetObject(utId));
//     JSON_Object match_json = g_aProMatchInfo.GetObject(g_aProMatchIndex[client]);

//     detail_json.GetString(17, utType, sizeof(utType));
//     detail_json.GetString(11, playerName, sizeof(playerName));
//     detail_json.GetString(13, teamName, sizeof(teamName));
//     match_json.GetString("event", eventName, sizeof(eventName));
//     throwPos[0] = detail_json.GetFloat("throw_x");
//     throwPos[1] = detail_json.GetFloat("throw_y");
//     throwPos[2] = detail_json.GetFloat("throw_z");
//     startAngle[0] = detail_json.GetFloat("aim_pitch");
//     startAngle[1] = detail_json.GetFloat("aim_yaw");
//     startAngle[2] = 0.0;
//     detail_json.GetString("action_body", actionBody, sizeof(actionBody));
//     detail_json.GetString("action_mouse", actionMouse, sizeof(actionMouse));
//     JSON_Array related_utility = view_as<JSON_Array>(detail_json.GetObject("related_utility"));

//     char utNameZh[LENGTH_UTILITY_ZH], utWeaponCmd[LENGTH_UTILITY_ZH];
//     Utility_TinyName2Zh(utType, "%s", utNameZh);
//     Utility_TinyName2Weapon(utType, utWeaponCmd, client);
//     int round_remain_secs = 55 + 60 - round_time;
//     int round_remain_min = round_remain_secs / 60;
//     round_remain_secs %= 60;
//     // tp player and get utility
//     TeleportEntity(client, throwPos, startAngle, NULL_VECTOR);
//     GivePlayerItem(client, utWeaponCmd);
//     Format(utWeaponCmd, sizeof(utWeaponCmd), "use %s", utWeaponCmd);
//     SetEntProp(client, Prop_Send, "m_iAmmo", 1);
//     FakeClientCommand(client, utWeaponCmd);


//     if (GetConVarBool(g_hWikiAutoThrow)) {
//         if (velocity[0] == 0.0 && velocity[1] == 0.0 && velocity[2] == 0.0) {
//             PrintToChat(client, "%s \x06当前道具没有记录初始速度，无法自动投掷", PREFIX);
//         }
//         else {
//             GrenadeType grenadeType = TinyName_2_GrenadeType(utType, client);
//             CSU_ThrowGrenade(client, grenadeType, throwPos, velocity);
//             PrintToChat(client, "%s \x05已自动投掷道具", PREFIX);
//         }
//     }

//     // printout
//     PrintToChat(client, "\x09 ------------------------------------- ");
//     PrintToChat(client, "%s 赛事: \x0B%s", PREFIX, eventName);
//     PrintToChat(client, "%s %s", PREFIX, result);
//     PrintToChat(client, "%s \x01<\x03%s\x01> 由 *\x04%s\x01* 在第\x04%d\x01回合 \x04%2d:%2d\x01投掷", PREFIX, utNameZh, playerName, round, round_remain_min, round_remain_secs);

//     if (related_utility.Length > 0) {
//         PrintToChat(client, "%s 相似的CSGOWiki收录道具：", PREFIX);
//         for (new idx = 0; idx < related_utility.Length; idx ++) {
//             char utId[LENGTH_UTILITY_ID];
//             related_utility.GetString(idx, utId, sizeof(utId));
//             PrintToChat(client, "%s \x09!wiki %s", PREFIX, utId);
//         }
//     }

//     PrintToChat(client, "\x09 ------------------------------------- ");
//     //
//     PrintCenterText(client, "身体动作：<font color='#ED0C39'>%s\n<font color='#ffffff'>鼠标动作：<font color='#0CED26'>%s\n以上信息不一定准确", actionBody, actionMouse);
// }
