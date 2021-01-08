// implement utility submit
public Action:Command_Submit(client, args) {
    if (!check_function_on(g_hOnUtilitySubmit, "\x02道具上传功能关闭，请联系服务器管理员", client)) {
        return;
    }
    if (e_cDefault != g_aPlayerStatus[client] && e_cButtonOn != g_aPlayerStatus[client]) {
        return;
    }
    PrintToChat(client, "%s \x06道具上传功能开启", PREFIX);
    PrintToChat(client, "%s 你接下来的道具投掷记录将会被自动上传至\x09www.csgowiki.top", PREFIX);
    GetClientAbsOrigin(client, g_aStartPositions[client]);
    GetClientEyeAngles(client, g_aStartAngles[client]);
    g_aPlayerStatus[client] = e_cThrowReady;
}

void OnPlayerRunCmdForUtilitySubmit(client, &buttons) {
    // record action => encoded
    if (e_cThrowReady == g_aPlayerStatus[client]) {
        for (new idx = 0; idx < CSGO_ACTION_NUM; idx++) {
            if ((g_aCsgoActionMap[idx] & buttons) && 
                !(g_aActionRecord[client] & (1 << idx))) {
                g_aActionRecord[client] |= 1 << idx;
            }
        }
    }
    // double click <E> to start submit function
    else if (e_cDefault == g_aPlayerStatus[client] && (buttons & IN_USE)) {
        g_aPlayerStatus[client] = e_cButtonOn;
        CreateTimer(0.5, ButtonInUseTimerCallback, client);
    }
    else if (e_cButtonOn == g_aPlayerStatus[client] && (buttons & IN_USE)) {
        ClientCommand(client, "sm_submit");
    }

}


void Event_GrenadeThrownForUtilitySubmit(Handle:event) {
    char nadeName[LENGTH_UTILITY_FULL];
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    GetEventString(event, "weapon", nadeName, LENGTH_UTILITY_FULL);
    if (e_cThrowReady == g_aPlayerStatus[client] && 
        !StrEqual(nadeName, "decoy") && IsPlayer(client)) {
        GetClientAbsOrigin(client, g_aThrowPositions[client]);
        g_aUtilityAirtime[client] = GetEngineTime();
        g_aUtilityType[client] = Utility_FullName2Code(nadeName);
        // set next state
        g_aPlayerStatus[client] = e_cAlreadyThrown;
        PrintToChat(client, "%s \x03已经记录你的动作，等待道具生效...", PREFIX);
    }
}

void Event_HegrenadeDetonateForUtilitySubmit(Handle:event) {
    UtilityDetonateStat(event, e_uHegrenade);
}

void Event_FlashbangDetonateForUtilitySubmit(Handle:event) {
    UtilityDetonateStat(event, e_uFlasbang);
}

void Event_SmokegrenadeDetonateForUtilitySubmit(Handle:event) {
    UtilityDetonateStat(event, e_uSomkegrenade);
}

void Event_MolotovDetonateForUtilitySubmit(Handle:event) {
    UtilityDetonateStat(event, e_uMolotov);
}

public Action:ButtonInUseTimerCallback(Handle timer, client) {
    if (e_cButtonOn == g_aPlayerStatus[client]) {
        g_aPlayerStatus[client] = e_cDefault;
    }
}

// implement utility submit function
void ResetSingleClientSubmitState(client) {
    g_aPlayerStatus[client] = e_cDefault;
    g_aActionRecord[client] = 0;
}

void ResetUtilitySubmitState() {
    for (new client = 0; client <= MAXPLAYERS; client++) {
        ResetSingleClientSubmitState(client);
    }
}

void UtilityDetonateStat(Handle:event, UtilityCode utCode) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (e_cAlreadyThrown == g_aPlayerStatus[client] && utCode == g_aUtilityType[client]) {
        // next state
        g_aPlayerStatus[client] = e_cThrowEnd;
        g_aUtilityAirtime[client] = GetEngineTime() - g_aUtilityAirtime[client];
        g_aEndspotPositions[client][0] = GetEventFloat(event, "x");
        g_aEndspotPositions[client][1] = GetEventFloat(event, "y");
        g_aEndspotPositions[client][2] = GetEventFloat(event, "z");
        TriggerWikiPost(client);
    }
}

void TriggerWikiPost(client) {
    // post api
    // url = "https://api.csgowiki.top/api/utility/submit/"

    // param define
    char token[LENGTH_TOKEN] = "";
    char steamid[LENGTH_STEAMID64] = "";
    char utTinyName[LENGTH_UTILITY_TINY] = "";
    bool wikiAction[CSGOWIKI_ACTION_NUM] = {};  // init all false
    char tickTag[LENGTH_STATUS] = "";
    // param fix
    GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);
    GetClientAuthId(client, AuthId_SteamID64, steamid, LENGTH_STEAMID64);
    Utility_Code2TinyName(g_aUtilityType[client], utTinyName);
    Action_Int2Array(client, wikiAction);
    TicktagGenerate(tickTag, wikiAction);
    // request
    System2HTTPRequest httpRequest = new System2HTTPRequest(
        WikiPostResponseCallback, "https://test.csgowiki.top/api/utility/submit/"
    );
    httpRequest.SetData(
        "token=%s&steamid=%s&start_x=%f&start_y=%f&start_z=%f\
        &end_x=%f&end_y=%f&end_z=%f&aim_pitch=%f&aim_yaw=%f\
        &is_run=%d&is_walk=%d&is_jump=%d&is_duck=%d&is_left=%d&is_right=%d\
        &map_belong=%s&tickrate=%s&utility_type=%s\
        &throw_x=%f&throw_y=%f&throw_z=%f&air_time=%f",
        token, steamid, g_aStartPositions[client][0], g_aStartPositions[client][1],
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
}


public WikiPostResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    new client = request.Any;
    if (success) {
        char[] status = new char[LENGTH_STATUS];
        char[] content = new char[response.ContentLength + 1];
        response.GetContent(content, response.ContentLength + 1);
        JSON_Object json_obj = json_decode(content);
        json_obj.GetString("status", status, LENGTH_STATUS);
        if (StrEqual(status, "ok")) {
            char[] utId = new char[LENGTH_UTILITY_ID];
            json_obj.GetString("code", utId, LENGTH_UTILITY_ID);
            ShowResult(client, utId);
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

void ShowResult(client, char[] utId) {
    char strAction[LENGTH_MESSAGE] = "";
    Action_Int2Str(client, strAction);
    PrintToChat(client, "\x09 ------------------------------------- ");
    PrintToChat(client, "%s 已将道具记录上传至\x09www.csgowiki.top\x01", PREFIX);
    PrintToChat(client, "%s [\x0F起点\x01] \x0D%f,%f,%f", PREFIX, g_aStartPositions[client][0], g_aStartPositions[client][1], g_aStartPositions[client][2]);
    PrintToChat(client, "%s [\x0F角度\x01] \x0D%f,%f, 0.0", PREFIX, g_aStartAngles[client][0], g_aStartAngles[client][1]);
    PrintToChat(client, "%s [\x0F出手点\x01] \x0D%f,%f,%f", PREFIX, g_aThrowPositions[client][0], g_aThrowPositions[client][1], g_aThrowPositions[client][2]);
    PrintToChat(client, "%s [\x0F落点\x01] \x0D%f,%f,%f", PREFIX, g_aEndspotPositions[client][0], g_aEndspotPositions[client][1], g_aEndspotPositions[client][2]);
    PrintToChat(client, "%s [\x0F动作列表\x01] \x0D%s", PREFIX, strAction);
    PrintToChat(client, "%s 该道具记录的唯一标识为<\x04%s\x01>", PREFIX, utId);
    PrintToChat(client, "%s 请在\x02尽快\x01登陆网站补全道具信息(图片和文字描述)", PREFIX);
    PrintToChat(client, "\x09 ------------------------------------- ");
}