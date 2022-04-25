public Action Command_Record(int client, any args) {
    if (client < 0) return;
    if (e_cDefault != g_aPlayerStatus[client]) {
        PrintToChat(client, "%s \x02已在道具上传状态，操作无效", PREFIX);
        return;
    }
    if (strlen(g_aLastUtilityId[client]) == 0) {
        PrintToChat(client, "%s \x02没有缓存的道具可以修改", PREFIX);
        return;
    }
    if (BotMimicFix_IsPlayerMimicing(client)) {
        PrintToChat(client, "%s \x02正在播放录像", PREFIX);
        return;
    }
    if (BotMimicFix_IsPlayerRecording(client)) {
        PrintToChat(client, "%s \x02正在录像", PREFIX);
        return;
    }
    PrintToChat(client, "%s \x04开始录像", PREFIX);
    BotMimicFix_StartRecording(client, g_aLastUtilityId[client], "csgowiki");
}

public Action Command_StopRecord(int client, any args) {
    if (!IsPlayer(client)) {
        return;
    }
    if (!BotMimicFix_IsPlayerRecording(client)) {
        PrintToChat(client, "%s \x02还未开始录像", PREFIX);
        return;
    }
    PrintToChat(client, "%s \x02停止录像", PREFIX);
    if (strlen(g_aLastUtilityId[client]) != 0) {
        PrintToChat(client, "[DEBUG] %s", g_aLastUtilityId[client]);
        BotMimicFix_StopRecording(client, true, g_aLastUtilityId[client]);
        
        UploadPlayBack(client, g_aLastUtilityId[client]);
    }
    else {
        BotMimicFix_StopRecording(client, false);
    }
}

void UploadPlayBack(int client, char utid[LENGTH_UTILITY_ID]) {
    char filepath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, filepath, sizeof(filepath), "data/botmimic/csgowiki/%s/%s.rec", g_sCurrentMap, utid);
    if (!FileExists(filepath)) {
        PrintToChat(client, "%s \x02待上传文件不存在", PREFIX);
        return;
    }

    char apiHost[LENGTH_TOKEN] = "https://api.mycsgolab.com";
    char token[LENGTH_TOKEN];
    char url[LENGTH_URL];
    GetConVarString(g_hApiHost, apiHost, sizeof(apiHost));
    GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);
    PrintToChat(client, "%s \x04开始上传录像：%s", PREFIX, utid);

    Format(url, sizeof(url), "%s/v2/utility/upload-playback/%s/?token=%s", apiHost, utid, token);
    HTTPRequest request = new HTTPRequest(url);
    DataPack pack = new DataPack();
    pack.WriteCell(client);
    pack.WriteString(utid);
    request.UploadFile(filepath, BotMimicUploadCallback, pack);
    
}

void BotMimicUploadCallback(HTTPStatus status, DataPack pack) {
    pack.Reset();
    int client = pack.ReadCell();
    char utid[LENGTH_UTILITY_ID];
    pack.ReadString(utid, sizeof(utid));
    if (status != HTTPStatus_OK) {
        // Upload failed
        PrintToChat(client, "%s \x02录像文件上传失败：%d", PREFIX, status);
        DeleteReplayFileFromUtid(utid, false);
        return;
    }
    PrintToChat(client, "%s \x0A录像文件已上传CSGOLab", PREFIX);
    DeleteReplayFileFromUtid(utid, false);
} 


bool StartRequestReplayFile(int client, char utility_id[LENGTH_UTILITY_ID], char utid[LENGTH_UTILITY_ID]) {
    if (!IsPlayer(client)) return false;
    char filepath[84];
    BuildPath(Path_SM, filepath, sizeof(filepath), "data/csgowiki/replays/%s.rec", utid);
    if (FileExists(filepath)) { // bug
        PrintToChat(client, "%s \x04命中缓存，开始播放录像", PREFIX);
        StartReplay(client, utid);
        return false;
    }
    if (IsPlayer(client))
        PrintToChat(client, "%s \x09正在请求录像文件...", PREFIX);

    char apiHost[LENGTH_TOKEN];
    char token[LENGTH_TOKEN];
    GetConVarString(g_hApiHost, apiHost, sizeof(apiHost));
    GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);
    char url[LENGTH_URL];
    Format(url, sizeof(url), "%s/v2/utility/download-playback/?token=%s&article_id=%s", apiHost, token, utility_id);
    HTTPRequest request = new HTTPRequest(url);
    // request.AppendQueryParam("article_id", utility_id);
    DataPack pack = new DataPack();
    pack.WriteCell(client);
    pack.WriteString(utid);
    request.DownloadFile(filepath, BotMimicDownloadCallback, pack);
    return true;
}

void BotMimicDownloadCallback(HTTPStatus status, DataPack pack) {
    pack.Reset();
    int client = pack.ReadCell();
    char utid[LENGTH_UTILITY_ID];
    pack.ReadString(utid, sizeof(utid));

    if (!IsPlayer(client)) {
        // client disconnected
        DeleteReplayFileFromUtid(utid);
        return;
    }
    if (status == HTTPStatus_NotFound || status == HTTPStatus_InternalServerError) {
        DeleteReplayFileFromUtid(utid);
        PrintToChat(client, "%s \x0A该道具的录像文件不存在，请联系管理员上传", PREFIX);
        return;
    }
    if (status != HTTPStatus_OK) {
        // Download failed
        DeleteReplayFileFromUtid(utid);
        PrintToChat(client, "%s \x02录像文件下载失败：%d", PREFIX, status);
        PrintToServer("%s \x04录像文件下载失败：%d", PREFIX, status);
        return;
    }
    PrintToChat(client, "%s \x04录像文件获取成功", PREFIX);
    if (BotMimicFix_IsPlayerMimicing(client)) {
        PrintToChat(client, "%s \x02请等待当前回放结束", client);
    }
    else {
        StartReplay(client, utid);
    }
}

public void StartReplay(int client, char utid[LENGTH_UTILITY_ID]) {
    if (!g_bBotMimicLoaded) {
        PrintToChat(client, "\x02BotMimic未加载，请联系管理员");
        return;
    }
    DataPack fpack = new DataPack();
    fpack.WriteCell(client);
    char filepath[84];
    BuildPath(Path_SM, filepath, sizeof(filepath), "data/csgowiki/replays/%s.rec", utid);
    fpack.WriteString(filepath);
    RequestFrame(BotMimicStartReplay, fpack);
}

void DeleteReplayFileFromUtid(char utid[LENGTH_UTILITY_ID], bool type=true) {
    char filepath[84];
    if (type) {
        BuildPath(Path_SM, filepath, sizeof(filepath), "data/csgowiki/replays/%s.rec", utid);
    }
    else {
        BuildPath(Path_SM, filepath, sizeof(filepath), "data/botmimic/csgowiki/%s/%s.rec", g_sCurrentMap, utid);
    }
    if (FileExists(filepath)) {
        DeleteFile(filepath);
    }
}

public void BotMimicStartReplay(DataPack pack) {
    pack.Reset();
    int client = pack.ReadCell();
    char filepath[84];
    pack.ReadString(filepath, sizeof(filepath));

    BMError err = BotMimicFix_PlayRecordFromFile(client, filepath);
    if (err != BM_NoError) {
        char errString[128];
        BotMimicFix_GetErrorString(err, errString, sizeof(errString));
        LogError("Error playing record %s on client %d: %s", filepath, client, errString);
    }
    delete pack;
}

public void BotMimicFix_OnPlayerStopsMimicing(int client, char[] name, char[] category, char[] path) {
    if (IsPlayer(client) && !IsMinidemoBot(client)) {
        TeleportEntity(client, g_aStartPositions[client], g_aStartAngles[client], NULL_VECTOR);
    }
    if (IsMinidemoBot(client)) {
        PrintToChatAll("%s bot %d 停止播放", PREFIX, client);
        int idx_client = -1;
        for (int idx = 0; idx < g_iMinidemoCount; ++idx) {
            if (g_iMinidemoBots[idx] == client) {
                idx_client = idx;
                break;
            }
        }

        g_bMinidemoBotsOn[idx_client] = false;
        KillBot(client);
        bool sumbit = false;
        for (int idx = 0; idx < g_iMinidemoCount; ++idx) {
            if (g_iMinidemoBots[idx] < 0) {
                continue;
            }
            sumbit |= g_bMinidemoBotsOn[idx];
        }
        if (!sumbit) {
            ClientCommand(g_iDemoLeader, "sm_m");
            g_bMinidemoPlaying = sumbit;
            ServerCommand("bot_kick");
            ResetMinidemoState();
        }
    }
}