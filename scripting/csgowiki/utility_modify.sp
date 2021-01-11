// implement utility modify
public Action:Command_Modify(client, args) {
    if (!check_function_on(g_hOnUtilitySubmit, "\x02道具上传功能关闭，请联系服务器管理员", client)) {
        return;
    }
    if (e_cDefault != g_aPlayerStatus[client]) {
        PrintToChat(client, "%s \x02已在道具上传状态，操作无效", PREFIX);
        return;
    }
    if (args < 1) {
        PrintToChat(client, "%s 用法\x02/modify <token>", PREFIX);
        return;
    }
    if (strlen(g_aLastUtilityId[client]) == 0) {
        PrintToChat(client, "%s \x02没有缓存的道具可以修改", PREFIX);
        return;
    }
    GetCmdArgString(g_aPlayerToken[client], LENGTH_TOKEN);
    TrimString(g_aPlayerToken[client]);
    PrintToChat(client, "%s \x06道具修改功能开启", PREFIX);
    PrintToChat(client, "%s 你正在修改道具<\x04%s\x01>", PREFIX, g_aLastUtilityId[client]);
    GetClientAbsOrigin(client, g_aStartPositions[client]);
    GetClientEyeAngles(client, g_aStartAngles[client]);
    g_aPlayerStatus[client] = e_cM_ThrowReady;
}


void ClearPlayerToken(client) {
    strcopy(g_aPlayerToken[client], LENGTH_TOKEN, "");
}

void TriggerWikiModify(client) {
    // param define
    char token[LENGTH_TOKEN] = "";
    char utTinyName[LENGTH_UTILITY_TINY] = "";
    bool wikiAction[CSGOWIKI_ACTION_NUM] = {};  // init all false
    char tickTag[LENGTH_STATUS] = "";
    // param fix
    GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);
    Utility_Code2TinyName(g_aUtilityType[client], utTinyName);
    Action_Int2Array(client, wikiAction);
    TicktagGenerate(tickTag, wikiAction);
    // request
    System2HTTPRequest httpRequest = new System2HTTPRequest(
        WikiModifyResponseCallback, "https://api.csgowiki.top/api/utility/modify/"
    );
    httpRequest.SetData(
        "user_token=%s&token=%s&id=%s&start_x=%f&start_y=%f&start_z=%f\
        &end_x=%f&end_y=%f&end_z=%f&aim_pitch=%f&aim_yaw=%f\
        &is_run=%d&is_walk=%d&is_jump=%d&is_duck=%d&is_left=%d&is_right=%d\
        &map_belong=%s&tickrate=%s&utility_type=%s\
        &throw_x=%f&throw_y=%f&throw_z=%f&air_time=%f",
        g_aPlayerToken[client], token, g_aLastUtilityId[client], g_aStartPositions[client][0], g_aStartPositions[client][1],
        g_aStartPositions[client][2], g_aEndspotPositions[client][0],
        g_aEndspotPositions[client][1], g_aEndspotPositions[client][2],
        g_aStartAngles[client][0], g_aStartAngles[client][1],
        wikiAction[e_wRun], wikiAction[e_wWalk], wikiAction[e_wJump],
        wikiAction[e_wDuck], wikiAction[e_wLeftclick], wikiAction[e_wRightclick],
        g_sCurrentMap, tickTag, utTinyName, g_aThrowPositions[client][0],
        g_aThrowPositions[client][1], g_aThrowPositions[client][2], g_aUtilityAirtime[client]
    );
    httpRequest.Any = client;
    httpRequest.POST();

    strcopy(g_aPlayerToken[client], LENGTH_TOKEN, "");
}


public WikiModifyResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    new client = request.Any;
    if (success) {
        char[] status = new char[LENGTH_STATUS];
        char[] content = new char[response.ContentLength + 1];
        response.GetContent(content, response.ContentLength + 1);
        JSON_Object json_obj = json_decode(content);
        json_obj.GetString("status", status, LENGTH_STATUS);
        if (StrEqual(status, "ok")) {
            ShowModifyResult(client);
        }
        else {
            char[] message = new char[LENGTH_NAME];
            json_obj.GetString("message", message, LENGTH_NAME);
            PrintToChat(client, "%s \x02%s", PREFIX, message);
        }
    }
    else {
        PrintToChat(client, "%s \x02连接至www.csgowiki.top失败", PREFIX);
    }
    ResetSingleClientSubmitState(client);
}

void ShowModifyResult(client) { 
    char strAction[LENGTH_MESSAGE] = "";
    Action_Int2Str(client, strAction);
    PrintToChat(client, "\x09 ------------------------------------- ");
    PrintToChat(client, "%s \x04已成功修改道具数据", PREFIX);
    PrintToChat(client, "%s [\x0F起点\x01] \x0D%f,%f,%f", PREFIX, g_aStartPositions[client][0], g_aStartPositions[client][1], g_aStartPositions[client][2]);
    PrintToChat(client, "%s [\x0F角度\x01] \x0D%f,%f, 0.0", PREFIX, g_aStartAngles[client][0], g_aStartAngles[client][1]);
    PrintToChat(client, "%s [\x0F出手点\x01] \x0D%f,%f,%f", PREFIX, g_aThrowPositions[client][0], g_aThrowPositions[client][1], g_aThrowPositions[client][2]);
    PrintToChat(client, "%s [\x0F落点\x01] \x0D%f,%f,%f", PREFIX, g_aEndspotPositions[client][0], g_aEndspotPositions[client][1], g_aEndspotPositions[client][2]);
    PrintToChat(client, "%s [\x0F动作列表\x01] \x0D%s", PREFIX, strAction);
    PrintToChat(client, "\x09 ------------------------------------- ");
}
