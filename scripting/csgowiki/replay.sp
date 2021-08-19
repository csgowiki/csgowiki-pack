public Action Command_Record(client, args) {
    if (e_cDefault != g_aPlayerStatus[client]) {
        PrintToChat(client, "%s \x02已在道具上传状态，操作无效", PREFIX);
        return;
    }
    if (strlen(g_aLastUtilityId[client]) == 0) {
        PrintToChat(client, "%s \x02没有缓存的道具可以修改", PREFIX);
        return;
    }
    if (BotMimic_IsPlayerMimicing(client)) {
        PrintToChat(client, "%s \x02正在播放录像", PREFIX);
        return;
    }
    if (BotMimic_IsPlayerRecording(client)) {
        PrintToChat(client, "%s \x02正在录像", PREFIX);
        return;
    }
    PrintToChat(client, "%s \x04开始录像", PREFIX);
    BotMimic_StartRecording(client, g_aLastUtilityId[client], "csgowiki");
}

public Action Command_StopRecord(client, args) {
    if (!IsPlayer(client)) {
        return;
    }
    if (!BotMimic_IsPlayerRecording(client)) {
        PrintToChat(client, "%s \x02还未开始录像", PREFIX);
        return;
    }
    PrintToChat(client, "%s \x02停止录像", PREFIX);
    if (strlen(g_aLastUtilityId[client]) != 0) {
        BotMimic_StopRecording(client, true, g_aLastUtilityId[client]);
        char command[256];
        Format(command, sizeof(command), "mv /home/csgo/steamcmd/games/csgo/csgo/addons/sourcemod/data/botmimic/csgowiki/%s/%s.rec /home/csgo/csgowiki-cache/files/", g_sCurrentMap, g_aLastUtilityId[client]);
        System2_ExecuteThreaded(ExecuteCallback, command);
    }
    else {
        BotMimic_StopRecording(client, false);
    }
}

public void ExecuteCallback(bool success, const char[] command, System2ExecuteOutput output, any data) {
    if (!success || output.ExitStatus != 0) {
        PrintToChatAll("Couldn't execute commands successfully");
    } else {
        char outputString[128];
        output.GetOutput(outputString, sizeof(outputString));
        PrintToChatAll("Output of the command: %s", outputString);
    }
} 

bool StartRequestReplayFile(int client, char utility_id[LENGTH_UTILITY_ID]) {
    if (!IsPlayer(client)) return false;
    char filepath[84];
    BuildPath(Path_SM, filepath, sizeof(filepath), "data/csgowiki/replays/%s.rec", utility_id);
    if (FileExists(filepath)) { // bug
        PrintToChat(client, "%s \x04命中缓存，开始播放录像", PREFIX);
        StartReplay(client, utility_id);
        return false;
    }

    System2HTTPRequest httpRequest = new System2HTTPRequest(
        BotMimicResponseCallback,
        "http://ci.csgowiki.top:2333/botmimic/query/?utility_id=%s",
        utility_id
    );
    DataPack pack = new DataPack();
    pack.WriteCell(client);
    pack.WriteString(utility_id);
    httpRequest.Any = pack;
    httpRequest.GET(); 
    delete httpRequest;
    return true;
}

public BotMimicResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    DataPack pack = request.Any;
    pack.Reset();
    int client = pack.ReadCell();
    if (success) {
        if (response.StatusCode == 200 && DirExists("addons/sourcemod/data/csgowiki/replays")) {
            char url[84], utid[LENGTH_UTILITY_ID];
            request.GetURL(url, sizeof(url));
            ReplaceString(url, sizeof(url), "query", "download");
            // strcopy(utid, sizeof(utid), url[strlen(url) - sizeof(utid) + 2]);
            pack.ReadString(utid, sizeof(utid));
            System2HTTPRequest httpRequest = new System2HTTPRequest(BotMimicDownloadCallback, url);
            Format(url, sizeof(url), "addons/sourcemod/data/csgowiki/replays/%s.rec", utid);
            httpRequest.SetOutputFile(url);
            httpRequest.Any = pack;
            httpRequest.GET();
            delete httpRequest;
            if (IsPlayer(client))
                PrintToChat(client, "%s \x09正在请求录像文件...", PREFIX);
        }
        else if (response.StatusCode != 200) {
            PrintToChat(client, "%s \x0A该道具的录像文件不存在，请联系管理员上传", PREFIX);
        }
    }
    else {
        PrintToServer("%s botmimic resp error：%s", PREFIX, error);
    }
}

public BotMimicDownloadCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    DataPack pack = request.Any;
    pack.Reset();
    int client = pack.ReadCell();
    char utid[LENGTH_UTILITY_ID];
    pack.ReadString(utid, sizeof(utid));
    delete pack;
    if (!IsPlayer(client)) {  // remove if client disconnected
        DeleteReplayFileFromUtid(utid);
        return;
    }
    if (success && response.StatusCode == 200) {
        PrintToChat(client, "%s \x04录像文件获取成功", PREFIX);
        if (BotMimic_IsPlayerMimicing(client)) {
            PrintToChat(client, "%s \x02请等待当前回放结束", client);
        }
        else {
            StartReplay(client, utid);
        }
    }
    else {
        PrintToChat(client, "%s \x02录像文件下载失败", PREFIX);
        PrintToServer("%s \x04录像文件下载失败", PREFIX);
        DeleteReplayFileFromUtid(utid);
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
    Format(filepath, sizeof(filepath), "addons/sourcemod/data/csgowiki/replays/%s.rec", utid);
    fpack.WriteString(filepath);
    RequestFrame(BotMimicStartReplay, fpack);
}

public void DeleteReplayFileFromUtid(char utid[LENGTH_UTILITY_ID]) {
    char filepath[84];
    BuildPath(Path_SM, filepath, sizeof(filepath), "data/csgowiki/replays/%s.rec", utid);
    // Format(filepath, sizeof(filepath), "addons/sourcemod/data/csgowiki/replays/%s.rec", utid);
    if (FileExists(filepath)) {
        DeleteFile(filepath);
    }
}

public void BotMimicStartReplay(DataPack pack) {
    pack.Reset();
    int client = pack.ReadCell();
    char filepath[84];
    pack.ReadString(filepath, sizeof(filepath));

    BMError err = BotMimic_PlayRecordFromFile(client, filepath);
    if (err != BM_NoError) {
        char errString[128];
        BotMimic_GetErrorString(err, errString, sizeof(errString));
        LogError("Error playing record %s on client %d: %s", filepath, client, errString);
    }
    delete pack;
}