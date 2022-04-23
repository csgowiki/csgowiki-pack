public Action Command_Demo(int client, any args) {
    if (!IsPlayer(client)) return;
    if (g_iDemoLeader != -1 && g_iDemoLeader != client) {
        PrintToChat(client, "%s \x02请等待当前demo操作玩家释放锁", PREFIX);
        ClientCommand(client, "sm_m");
        return;
    }
    if (g_iMinidemoStatus != e_mDefault && g_iMinidemoStatus != e_mPicking) {
        PrintToChat(client, "%s \x02请等待demo回放结束", PREFIX);
        ClientCommand(client, "sm_m");
        return;
    }
    if (g_MinidemoCollection == null) {
        PrintToChat(client, "%s \x02该地图demo信息获取失败，正在尝试重新获取...", PREFIX);
        GetDemoCollection(client);
        return;
    }
    g_iDemoLeader = client;
    CreateDemoCollectionMenu(client);
}

// called when a player selects a match from the menu
// `g_sDemoPickedMatch` should be set
public Action Command_DemoRound(int client, any args) {
    if (!IsPlayer(client)) return;
    if (g_iDemoLeader != -1 && g_iDemoLeader != client) {
        PrintToChat(client, "%s \x02请等待当前demo操作玩家释放锁", PREFIX);
        ClientCommand(client, "sm_m");
        return;
    }
    if (g_iMinidemoStatus != e_mPicking) {
        PrintToChat(client, "%s \x02请等待demo回放结束", PREFIX);
        ClientCommand(client, "sm_m");
        return;
    }
    JSONObject info = view_as<JSONObject>(g_MinidemoCollection.Get(g_sDemoPickedMatch));
    int maxround = info.GetInt("maxround"); // round index max: `maxround - 1`
    if (maxround <= 0 || maxround >= 128) {
        PrintToChat(client, "%s \x02数据损坏，请选择其他比赛场次", PREFIX);
        ClientCommand(client, "sm_demo");
        return;
    }
    CreateDemoRoundMenu(client, maxround);
}

void CreateDemoCollectionMenu(int client) {
    g_iMinidemoStatus = e_mPicking;
    strcopy(g_sDemoPickedMatch, sizeof(g_sDemoPickedMatch), "");
    strcopy(g_sDemoPickedMatchName, sizeof(g_sDemoPickedMatchName), "");
    g_iDemoPickedRound = -1;
    Handle menuhandle = CreateMenu(DemoCollectionMenuCallback);
    SetMenuTitle(menuhandle, "职业Demo合集");

    JSONObjectKeys keys = g_MinidemoCollection.Keys();
    char key[LENGTH_NAME];

    while (keys.ReadKey(key, sizeof(key))) {
        char team1[LENGTH_NAME], team2[LENGTH_NAME], time[LENGTH_NAME];
        JSONObject info = view_as<JSONObject>(g_MinidemoCollection.Get(key));
        info.GetString("date", time, sizeof(time));
        JSONObject teaminfo_1 = view_as<JSONObject>(info.Get("team1"));
        teaminfo_1.GetString("teamName", team1, sizeof(team1));
        int score1 = teaminfo_1.GetInt("score");
        JSONObject teaminfo_2 = view_as<JSONObject>(info.Get("team2"));
        teaminfo_2.GetString("teamName", team2, sizeof(team2));
        int score2 = teaminfo_2.GetInt("score");
        char msg[LENGTH_NAME * 4];
        Format(msg, sizeof(msg), "[%s] %d : %d [%s]", team1, score1, score2, team2);
        char msg2[LENGTH_NAME * 4];
        Format(msg2, sizeof(msg2), "%s vs %s", team1, team2);
        char keymsg[LENGTH_NAME * 5];
        Format(keymsg, sizeof(keymsg), "%s@%s", key, msg2); // encode matchId@msg for callback decode
        AddMenuItem(menuhandle, keymsg, msg);
    }
    delete keys;
    SetMenuPagination(menuhandle, 7);
    SetMenuExitBackButton(menuhandle, true);
    SetMenuExitButton(menuhandle, true);
    DisplayMenu(menuhandle, client, MENU_TIME_FOREVER);
}

public int DemoCollectionMenuCallback(Handle menuhandle, MenuAction action, int client, int Position) {
    if (MenuAction_Select == action) {
        char keymsg[LENGTH_MESSAGE * 5];
        char msgs[2][LENGTH_MESSAGE * 4];
        GetMenuItem(menuhandle, Position, keymsg, sizeof(keymsg));
        ExplodeString(keymsg, "@", msgs, 2, LENGTH_MESSAGE * 4);
        strcopy(g_sDemoPickedMatch, sizeof(g_sDemoPickedMatch), msgs[0]);
        strcopy(g_sDemoPickedMatchName, sizeof(g_sDemoPickedMatchName), msgs[1]);
        PrintToChat(client, "%s 选中比赛：\x06%s", PREFIX, g_sDemoPickedMatchName);
        ClientCommand(client, "sm_demoround");
    }
    else if (MenuAction_Cancel == action) {
        g_iDemoLeader = -1;
        g_iMinidemoStatus = e_mDefault;
        ClientCommand(client, "sm_m");
    }
}

void CreateDemoRoundMenu(int client, int maxround) {
    Handle menuhandle = CreateMenu(DemoMatchRoundMenuCallback);
    SetMenuTitle(menuhandle, "选择回合");
    for (int round_count = 0; round_count < maxround; ++round_count) {
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

public int DemoMatchRoundMenuCallback(Handle menuhandle, MenuAction action, int client, int Position) {
    if (MenuAction_Select == action) {
        char round_str[4];
        GetMenuItem(menuhandle, Position, round_str, sizeof(round_str));
        PrintToChat(client, "%s 选中回合：%s", PREFIX, round_str);
        g_iDemoPickedRound = StringToInt(round_str);
        // download
        DownloadMinidemoStart(client);
    }
    else if (MenuAction_Cancel == action) {
        ClientCommand(client, "sm_demo");
    }
}

public void OnPlayerRunCmdForMinidemo(int client, int& buttons, float angles[DATA_DIM]) {
    if (g_iMinidemoStatus == e_mDefault) return;
    char name[LENGTH_NAME];
    if (IsPlayer(g_iDemoLeader)) {
        GetClientName(g_iDemoLeader, name, sizeof(name));
    }
    else {
        strcopy(name, sizeof(name), "未知");
    }
    PrintCenterText(client, "<font color='#87CEFA'>demo回放开启</font><br/>所属玩家：<font color='#FF0000'>%s</font><br/>比赛：<font color='#87CEFA'>%s</font><br/>回合：<font color='#87CEFA'>%d</font>",
        name,
        strlen(g_sDemoPickedMatchName) > 0 ? g_sDemoPickedMatchName : "未选择",
        g_iDemoPickedRound
    );
    if (g_bMinidemoPlaying) {
        for (int idx = 0; idx < g_iMinidemoCount; ++idx) {
            if (!g_bMinidemoBotsOn[idx] && g_iMinidemoBots[idx] == client) {
                SetEntityRenderColor(g_iMinidemoBots[idx], 255, 0, 0, 255);
                SetEntityMoveType(g_iMinidemoBots[idx], MOVETYPE_NONE);
                buttons = 0;
                angles[0] = 0.0;
                angles[1] = 0.0;
                angles[2] = 0.0;
            }
        }
    }
}