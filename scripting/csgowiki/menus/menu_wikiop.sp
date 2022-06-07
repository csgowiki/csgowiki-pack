// csgowiki operator tools

public Action Command_Wikiop(int client, any args) {
    Panel panel = new Panel();

    panel.SetTitle("CSGOWiki管理员工具");

    if (GetConVarBool(g_hCSGOWikiEnable))
        panel.DrawItem("CSGOWiki总开关：开");
    else
        panel.DrawItem("CSGOWiki总开关：关");

    int Flag = ITEMDRAW_DEFAULT;
    if (!GetConVarBool(g_hCSGOWikiEnable))
        Flag = ITEMDRAW_DISABLED;

    if (GetConVarBool(g_hOnUtilitySubmit)) 
        panel.DrawItem("道具上传功能：开", Flag);
    else
        panel.DrawItem("道具上传功能：关", Flag);

    if (GetConVarBool(g_hOnUtilityWiki))
        panel.DrawItem("道具学习功能：开", Flag);
    else
        panel.DrawItem("道具学习功能：关", Flag);

    panel.DrawText("   ");
    panel.DrawItem("第三方插件设置");

    panel.DrawItem("   ", ITEMDRAW_SPACER);
    panel.DrawItem("   ", ITEMDRAW_SPACER);

    panel.DrawItem("返回", ITEMDRAW_CONTROL);
    panel.DrawItem("退出", ITEMDRAW_CONTROL);
    
    panel.Send(client, WikiopPanelHandler, MENU_TIME_FOREVER);

    delete panel;
    return Plugin_Handled;
}


public int WikiopPanelHandler(Handle menu, MenuAction action, int client, int Position) {
    if (action == MenuAction_Select) {
        switch(Position) {
            case 1: SetConVarBool(g_hCSGOWikiEnable, !GetConVarBool(g_hCSGOWikiEnable), true, true), ClientCommand(client, "sm_wikiop");
            case 2: SetConVarBool(g_hOnUtilitySubmit, !GetConVarBool(g_hOnUtilitySubmit), true, true), ClientCommand(client, "sm_wikiop");
            case 3: SetConVarBool(g_hOnUtilityWiki, !GetConVarBool(g_hOnUtilityWiki), true, true), ClientCommand(client, "sm_wikiop");
            case 4: PrintToChat(client, "%s \x0E功能未开放，敬请期待...", PREFIX), ClientCommand(client, "sm_wikiop");
            case 7: ClientCommand(client, "sm_m");
            case 8: CloseHandle(menu);
        }
    }
}