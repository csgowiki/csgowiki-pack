
void GetAllProMatchStat(client) {
    new Handle:menuhandle = CreateMenu(GetAllProMatchStatCallback);
    SetMenuTitle(menuhandle, "职业比赛合集");

    for (new idx = 0; idx < g_jAllProMatchStat.Length; idx++) {
        char team1[LENGTH_NAME], team2[LENGTH_NAME], time[LENGTH_NAME];
        char index[LENGTH_NAME];
        JSON_Array arrval = view_as<JSON_Array>(g_jAllProMatchStat.GetObject(idx));
        int iidx = arrval.GetInt(0);
        arrval.GetString(0, index, sizeof(index));
        arrval.GetString(1, team1, sizeof(team1));
        arrval.GetString(2, team2, sizeof(team2));
        int score1 = arrval.GetInt(3);
        int score2 = arrval.GetInt(4);
        arrval.GetString(5, time, sizeof(time));
        char msg[LENGTH_NAME * 4];
        Format(msg, sizeof(msg), "[%s] %d : %d [%s] (%s)", team1, score1, score2, team2, time);
        IntToString(iidx, index, sizeof(index));
        PrintToChat(client, "%s", index);
        AddMenuItem(menuhandle, index, msg);
        json_cleanup_and_delete(arrval);
    }
    SetMenuPagination(menuhandle, 7);
    SetMenuExitBackButton(menuhandle, true);
    SetMenuExitButton(menuhandle, true);
    DisplayMenu(menuhandle, client, MENU_TIME_FOREVER);
}


public GetAllProMatchStatCallback(Handle:menuhandle, MenuAction:action, client, Position) {
    if (MenuAction_Select == action) {
        decl String:index[LENGTH_NAME];
        GetMenuItem(menuhandle, Position, index, sizeof(index));

        // checkstatus
        PrintToChat(client, "正在请求: %s", index);


        DisplayMenuAtItem(menuhandle, client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
    }
    else if (MenuAction_Cancel == action) {
        
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
            case 7: ClientCommand(client, "sm_panel");
            case 8: CloseHandle(menu);
        }
    }
}

