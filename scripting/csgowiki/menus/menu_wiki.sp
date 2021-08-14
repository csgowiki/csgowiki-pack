// implement menus

// 道具分类  第一层menu
void Menu_UtilityWiki_v1(client) {
    if (!IsPlayer(client)) return;
    new Handle:menuhandle = CreateMenu(Menu_UtilityWiki_v1_CallBack);
    SetMenuTitle(menuhandle, "CSGOWiki道具分类");

    AddMenuItem(menuhandle, "smoke", "烟雾弹");
    AddMenuItem(menuhandle, "flash", "闪光弹");
    AddMenuItem(menuhandle, "grenade", "手雷");
    AddMenuItem(menuhandle, "molotov", "燃烧弹");

    AddMenuItem(menuhandle, "startspot", ">>附近起点道具<<");
    AddMenuItem(menuhandle, "endspot", ">>附近落点道具<<");

    SetMenuExitBackButton(menuhandle, true);
    SetMenuExitButton(menuhandle, true);
    DisplayMenu(menuhandle, client, MENU_TIME_FOREVER);
}


public Menu_UtilityWiki_v1_CallBack(Handle:menuhandle, MenuAction:action, client, Position) {
    if (!IsPlayer(client)) return;
    if (action == MenuAction_Select) {
        decl String:Item[10];
        GetMenuItem(menuhandle, Position, Item, sizeof(Item));
        if (StrEqual(Item, "endspot")) {
            GetFilterCollection(client, "end");
        }
        else if (StrEqual(Item, "startspot")) {
            GetFilterCollection(client, "start");
        }
        else {
            Menu_UtilityWiki_v2(client, Item);
        }
    }
    else if (MenuAction_Cancel == action) {
        ClientCommand(client, "sm_m");
    }
}

// 单个道具汇总菜单
void Menu_UtilityWiki_v2(client, char[] utTinyName) {
    if (!IsPlayer(client)) return;
    new Handle:menuhandle = CreateMenu(Menu_UtilityWiki_v2_CallBack);
    char utNameZh[LENGTH_UTILITY_ZH];
    char menuTitle[LENGTH_UTILITY_ZH];
    Utility_TinyName2Zh(utTinyName, "%s", utNameZh);
    Format(menuTitle, LENGTH_UTILITY_ZH, "==== %s合集 ====", utNameZh);
    SetMenuTitle(menuhandle, menuTitle);

    int typeCount = 0;
    for (new idx = 0; idx < g_jaUtilityCollection.Length; idx++) {
        JSON_Array arrval = view_as<JSON_Array>(g_jaUtilityCollection.GetObject(idx));
        char utId[LENGTH_UTILITY_ID], utTitle[LENGTH_NAME], utType[LENGTH_UTILITY_TINY];
        int specFlag = 0;
        arrval.GetString(0, utId, LENGTH_UTILITY_ID);
        arrval.GetString(1, utTitle, LENGTH_NAME);
        arrval.GetString(2, utType, LENGTH_UTILITY_TINY);
        specFlag = arrval.GetInt(3);
        if (StrEqual(utType, utTinyName)) {
            char msg[LENGTH_NAME + LENGTH_UTILITY_ZH + 8];
            Format(msg, sizeof(msg), "[%s] %s", utNameZh, utTitle);
            if (specFlag == 1) Format(msg, sizeof(msg), "%s *走投*", msg);
            else if (specFlag == 2) Format(msg, sizeof(msg), "%s *跑投*", msg);
            AddMenuItem(menuhandle, utId, msg);
            typeCount ++;
        }
        // delete arrval;
    }
    if (typeCount == 0) {
        PrintToChat(client, "%s CSGOWiki目前未收录该种类道具", PREFIX);
        Menu_UtilityWiki_v1(client);
        return;
    }

    SetMenuPagination(menuhandle, 7);
    SetMenuExitBackButton(menuhandle, true);
    SetMenuExitButton(menuhandle, true);
    DisplayMenu(menuhandle, client, MENU_TIME_FOREVER);
}


public Menu_UtilityWiki_v2_CallBack(Handle:menuhandle, MenuAction:action, client, Position) {
    if (!IsPlayer(client)) return;
    if (MenuAction_Select == action) {
        decl String:utId[LENGTH_UTILITY_ID];
        GetMenuItem(menuhandle, Position, utId, LENGTH_UTILITY_ID);

        if (e_cDefault != g_aPlayerStatus[client]) {
            PrintToChat(client, "%s \x02道具上传过程中，无法使用wiki功能", PREFIX);
            return;
        }
        GetUtilityDetail(client, utId);
        DisplayMenuAtItem(menuhandle, client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
    }
    else if (MenuAction_Cancel == action) {
        Menu_UtilityWiki_v1(client);
    }
}

public Action:ReqLockTimerCallback(Handle:timer, client) {
    g_aReqLock[client] = false;
}

// 用户搜索结果菜单
void Menu_UtilityWiki_v3(client) {
    if (!IsPlayer(client)) return;
    if (g_aUtFilterCollection[client].Length == 0) {
        PrintToChat(client, "%s \x10你所在区域没有找到道具记录", PREFIX);
        Menu_UtilityWiki_v1(client);
        return;
    }

    new Handle:menuhandle = CreateMenu(Menu_UtilityWiki_v3_CallBack);
    SetMenuTitle(menuhandle, "=== 查询到的道具 ===");

    for (new idx = 0; idx < g_aUtFilterCollection[client].Length; idx ++) {
        if (g_aUtFilterCollection[client].GetKeyType(idx) == JSON_Type_Object) {
            JSON_Array arrval = view_as<JSON_Array>(g_aUtFilterCollection[client].GetObject(idx));
            char utId[LENGTH_UTILITY_ID], utTitle[LENGTH_NAME], utType[LENGTH_UTILITY_TINY];
            int specFlag = 0;
            char utNameZh[LENGTH_UTILITY_ZH];
            arrval.GetString(0, utId, LENGTH_UTILITY_ID);
            arrval.GetString(1, utTitle, LENGTH_NAME);
            arrval.GetString(2, utType, LENGTH_UTILITY_TINY);
            specFlag = arrval.GetInt(3);
            Utility_TinyName2Zh(utType, "%s", utNameZh);
            char msg[LENGTH_NAME + LENGTH_UTILITY_ZH + 8];
            Format(msg, sizeof(msg), "[%s] %s", utNameZh, utTitle);
            if (specFlag == 1) Format(msg, sizeof(msg), "%s *走投*", msg);
            else if (specFlag == 2) Format(msg, sizeof(msg), "%s *跑投*", msg);
            AddMenuItem(menuhandle, utId, msg);
            json_cleanup_and_delete(arrval);
        }
    }
    SetMenuPagination(menuhandle, 7);
    SetMenuExitBackButton(menuhandle, true);
    SetMenuExitButton(menuhandle, true);
    DisplayMenu(menuhandle, client, MENU_TIME_FOREVER);
}

public Menu_UtilityWiki_v3_CallBack(Handle:menuhandle, MenuAction:action, client, Position) {
    if (!IsPlayer(client)) return;
    if (MenuAction_Select == action) {
        decl String:utId[LENGTH_UTILITY_ID];
        GetMenuItem(menuhandle, Position, utId, LENGTH_UTILITY_ID);
        GetUtilityDetail(client, utId);
        DisplayMenuAtItem(menuhandle, client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
    }
    else if (MenuAction_Cancel == action) {
        Menu_UtilityWiki_v1(client);
    }
}