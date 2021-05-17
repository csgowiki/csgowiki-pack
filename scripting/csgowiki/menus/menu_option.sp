
void GetAllProMatchStat(client) {
    new Handle:menuhandle = CreateMenu(ProMatchInfoMenuCallback);
    SetMenuTitle(menuhandle, "职业比赛合集");

    for (new idx = 0; idx < g_aProMatchInfo.Length; idx++) {
        char team1[LENGTH_NAME], team2[LENGTH_NAME], time[LENGTH_NAME];
        char matchId[LENGTH_NAME];
        JSON_Object arrval = g_aProMatchInfo.GetObject(idx);
        JSON_Object teamInfo_1 = arrval.GetObject("team1");
        JSON_Object teamInfo_2 = arrval.GetObject("team2");
        teamInfo_1.GetString("name", team1, sizeof(team1));
        teamInfo_2.GetString("name", team2, sizeof(team2));
        int score1 = teamInfo_1.GetInt("result");
        int score2 = teamInfo_2.GetInt("result");
        arrval.GetString("time", time, sizeof(time));
        arrval.GetString("matchId", matchId, sizeof(matchId));
        char msg[LENGTH_NAME * 4];
        Format(msg, sizeof(msg), "[%s] %d : %d [%s] (%s)", team1, score1, score2, team2, time);
        AddMenuItem(menuhandle, matchId, msg);
    }
    SetMenuPagination(menuhandle, 7);
    SetMenuExitBackButton(menuhandle, true);
    SetMenuExitButton(menuhandle, true);
    DisplayMenu(menuhandle, client, MENU_TIME_FOREVER);
}


public ProMatchInfoMenuCallback(Handle:menuhandle, MenuAction:action, client, Position) {
    if (MenuAction_Select == action) {
        decl String:matchId[LENGTH_NAME];
        GetMenuItem(menuhandle, Position, matchId, sizeof(matchId));

        // checkstatus
        PrintToChat(client, "%s \x04正在请求比赛数据: [\x02%s\x01] \x04可能需要一段时间，请耐心等待", PREFIX, matchId);
        // set index
        for (new idx = 0; idx < g_aProMatchInfo.Length; idx++) {
            char _matchId[LENGTH_NAME];
            JSON_Object arrval = g_aProMatchInfo.GetObject(idx);
            arrval.GetString("matchId", _matchId, sizeof(_matchId));
            if (StrEqual(matchId, _matchId)) {
                g_aProMatchIndex[client] = idx;
                break;
            }
        }

        // temp
        DisplayMenuAtItem(menuhandle, client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);

        System2HTTPRequest httpRequest = new System2HTTPRequest(
            ProMatchDetailResponseCallback,
            "https://api.hx-w.top/%s/%s",
            g_sCurrentMap, matchId
        );
        httpRequest.Any = client;
        httpRequest.GET();
        delete httpRequest;
    }
    else if (MenuAction_Cancel == action) {
        ClientCommand(client, "sm_m");
    }
}

public ProMatchDetailResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    new client = request.Any;
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        response.GetContent(content, response.ContentLength + 1);
        PrintToChat(client, "%s \x04比赛道具数据请求成功", PREFIX);
        g_aProMatchDetail[client] = view_as<JSON_Array>(json_decode(content));
        ClientCommand(client, "sm_wikipro");
    }
    else {
        PrintToChatAll("%s \x02连接至api.hx-w.top失败：%s", PREFIX, error);
    }
}


public Action:Command_Option(client, args) {
    Panel panel = new Panel();

    panel.SetTitle("个人设置")

    panel.DrawItem("道具开启自动投掷：开", ITEMDRAW_DISABLED);
    panel.DrawItem("快捷道具上传(双击E)：开", ITEMDRAW_DISABLED);
    panel.DrawItem("qq聊天触发方式：单次触发", ITEMDRAW_DISABLED);
    panel.DrawItem("职业道具场次选择");
    panel.DrawItem("   ", ITEMDRAW_SPACER);
    panel.DrawItem("   ", ITEMDRAW_SPACER);
    panel.DrawItem("返回", ITEMDRAW_CONTROL);
    panel.DrawItem("退出", ITEMDRAW_CONTROL);
    
    panel.Send(client, OptionPanelHandler, MENU_TIME_FOREVER);

    delete panel;
    return Plugin_Handled;
}

public OptionPanelHandler(Handle:menu, MenuAction:action, client, Position) {
    if (action == MenuAction_Select) {
        switch(Position) {
            case 1: PrintToChat(client, "%s \x0E功能未开放，敬请期待...", PREFIX), ClientCommand(client, "sm_option");
            case 2: PrintToChat(client, "%s \x0E功能未开放，敬请期待...", PREFIX), ClientCommand(client, "sm_option");
            case 3: PrintToChat(client, "%s \x0E功能未开放，敬请期待...", PREFIX), ClientCommand(client, "sm_option");
            case 4: GetAllProMatchStat(client);
            case 7: ClientCommand(client, "sm_m");
            case 8: CloseHandle(menu);
        }
    }
}

