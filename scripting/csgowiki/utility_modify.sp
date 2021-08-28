// implement utility modify
public Action:Command_Modify(client, args) {
    if (!check_function_on(g_hOnUtilitySubmit, "\x02道具上传功能关闭，请联系服务器管理员", client)) {
        return;
    }
    if (e_cDefault != g_aPlayerStatus[client]) {
        PrintToChat(client, "%s \x02已在道具上传状态，操作无效", PREFIX);
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
    PrintToChat(client, "%s 输入\x04!abort\x01终止上传", PREFIX);
    GetClientAbsOrigin(client, g_aStartPositions[client]);
    GetClientEyeAngles(client, g_aStartAngles[client]);
    g_aPlayerStatus[client] = e_cM_ThrowReady;
    g_aPlayerUtilityPath[client] = new JSONArray();
}

public Action:Command_Velocity(client, args) {
    PrintToChat(client, "%s \x02该接口已关闭", PREFIX);
    if (!check_function_on(g_hOnUtilitySubmit, "\x02道具上传功能关闭，请联系服务器管理员", client)) {
        return;
    }
    if (e_cDefault != g_aPlayerStatus[client]) {
        PrintToChat(client, "%s \x02已在道具上传状态，操作无效", PREFIX);
        return;
    }
    if (strlen(g_aLastUtilityId[client]) == 0) {
        PrintToChat(client, "%s \x02没有缓存的道具可以修改", PREFIX);
        return;
    }
    PrintToChat(client, "%s \x06道具速度添加功能开启", PREFIX);
    PrintToChat(client, "%s 你正在修改道具<\x04%s\x01>", PREFIX, g_aLastUtilityId[client]);
    PrintToChat(client, "%s 输入\x04!abort\x01终止上传", PREFIX);
    g_aPlayerStatus[client] = e_cV_ThrowReady;
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
    char steamid[LENGTH_STEAMID64] = "";
    // param fix
    GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);
    GrenadeType_2_Tinyname(g_aUtilityType[client], utTinyName);
    Action_Int2Array(client, wikiAction);
    TicktagGenerate(tickTag, wikiAction);
    GetClientAuthId(client, AuthId_SteamID64, steamid, LENGTH_STEAMID64);

    // PrintToChat(client, "total frame: %d; sampled frame: %d", g_iPlayerUtilityPathFrameCount[client], g_iPlayerUtilityPathFrameCount[client] / g_iUtilityPathInterval);
    // request
    char url[LENGTH_MESSAGE];
    char apiHost[LENGTH_TOKEN];
    GetConVarString(g_hApiHost, apiHost, sizeof(apiHost));
    Format(url, sizeof(url), "%s/utility/utility/modify/?token=%s", apiHost, token);
    HTTPRequest httpRequest = new HTTPRequest(url);
    httpRequest.SetHeader("Content-Type", "application/json");

    JSONObject postData = new JSONObject();
    postData.SetString("utility_id", g_aLastUtilityId[client]);
    postData.SetString("steam_id", steamid);
    postData.SetFloat("start_x", g_aStartPositions[client][0]);
    postData.SetFloat("start_y", g_aStartPositions[client][1]);
    postData.SetFloat("start_z", g_aStartPositions[client][2]);
    postData.SetFloat("end_x", g_aEndspotPositions[client][0]);
    postData.SetFloat("end_y", g_aEndspotPositions[client][1]);
    postData.SetFloat("end_z", g_aEndspotPositions[client][2]);
    postData.SetFloat("aim_pitch", g_aStartAngles[client][0]);
    postData.SetFloat("aim_yaw", g_aStartAngles[client][1]);
    postData.SetBool("is_run", view_as<bool>(wikiAction[e_wRun]));
    postData.SetBool("is_walk", view_as<bool>(wikiAction[e_wWalk]));
    postData.SetBool("is_jump", view_as<bool>(wikiAction[e_wJump]));
    postData.SetBool("is_duck", view_as<bool>(wikiAction[e_wDuck]));
    postData.SetBool("is_left", view_as<bool>(wikiAction[e_wLeftclick]));
    postData.SetBool("is_right", view_as<bool>(wikiAction[e_wRightclick]));
    postData.SetString("map_belong", g_sCurrentMap);
    postData.SetString("tickrate", tickTag);
    postData.SetString("utility_type", utTinyName);
    postData.SetFloat("throw_x", g_aThrowPositions[client][0]);
    postData.SetFloat("throw_y", g_aThrowPositions[client][1]);
    postData.SetFloat("throw_z", g_aThrowPositions[client][2]);
    postData.SetFloat("air_time", g_aUtilityAirtime[client]);
    postData.SetFloat("velocity_x", g_aUtilityVelocity[client][0]);
    postData.SetFloat("velocity_y", g_aUtilityVelocity[client][1]);
    postData.SetFloat("velocity_z", g_aUtilityVelocity[client][2]);
    char path[302400];
    g_aPlayerUtilityPath[client].ToString(path, sizeof(path));
    PrintToChat(client, "len: %d", strlen(path));
    postData.SetString("path", path);

    httpRequest.Post(postData, WikiModifyResponseCallback, client);

    delete postData;
}

void WikiModifyResponseCallback(HTTPResponse response, int client) {
    if (response.Status == HTTPStatus_OK) {
        char status[LENGTH_STATUS];
        JSONObject json_obj = view_as<JSONObject>(response.Data);
        json_obj.GetString("status", status, LENGTH_STATUS);
        if (StrEqual(status, "ok")) {
            ShowModifyResult(client);
        }
        else {
            char message[LENGTH_NAME];
            json_obj.GetString("detail", message, LENGTH_NAME);
            PrintToChat(client, "%s error: \x02%s", PREFIX, message);
        }
        delete json_obj;
    }
    else {
        PrintToChat(client, "%s error：\x02连接至mycsgolab失败 %d", PREFIX, response.Status);
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
