
public Action:Command_WikiPro(client, args) {
    if (g_aProMatchIndex[client] == -1) { // not set
        PrintToChat(client, "%s \x05请先选择职业比赛场次，已自动跳转选择菜单，如未跳转，请输入\x02!option\x05选择。", PREFIX);
        GetAllProMatchStat(client);
        return Plugin_Handled;
    }
    if (g_aProMatchDetail[client].Length <= 1) {
        PrintToChat(client, "%s \x02比赛数据出错，请选择其他场次");
        GetAllProMatchStat(client);
        return Plugin_Handled;
    }

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
    
    new Handle:menuhandle = CreateMenu(ProMatchDetailMenuCallback);
    SetMenuTitle(menuhandle, title);

    PrintToChat(client, "%s", title);
    JSON_Array last = view_as<JSON_Array>(g_aProMatchDetail[client].GetObject(g_aProMatchDetail[client].Length - 1));

    char maxround_str[4];
    last.GetString(9, maxround_str, sizeof(maxround_str));
    int maxround_int = StringToInt(maxround_str);
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
    return Plugin_Handled;
}


public ProMatchDetailMenuCallback(Handle:menuhandle, MenuAction:action, client, Position) {
    if (MenuAction_Select == action) {
        decl String:round_str[4];
        GetMenuItem(menuhandle, Position, round_str, sizeof(round_str));

        ShowProListInRound(round_str);
    }
    else if (MenuAction_Cancel == action) {
        ClientCommand(client, "sm_m");
    }
}

void ShowProListInRound(char round_str[4]) {

}