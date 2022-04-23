// minidemo replay

public Action Command_Minidemo(int client, int args) {
    if (g_bMinidemoPlaying) {
        PrintToChat(client, "%s 等待回放结束", PREFIX);
        return Plugin_Handled;
    }
    ResetMinidemoBots();
    ServerCommand("bot_quota_mode normal");

    char buffer[32]; // round2/ct
    GetCmdArgString(buffer, sizeof(buffer));
    TrimString(buffer);

    g_iMinidemoCount = 0;
    if (StrContains(buffer, "/", false) == -1) { // play both side
        g_iMinidemoSide = (1 << 0) | (1 << 1);
    }
    else if (StrContains(buffer, "/ct", false) != -1) {
        g_iMinidemoSide = 1 << 1;
        ReplaceString(buffer, sizeof(buffer), "/ct", "", false);
    }
    else if (StrContains(buffer, "/t", false) != -1) {
        g_iMinidemoSide = 1 << 0;
        ReplaceString(buffer, sizeof(buffer), "/t", "", false);
    }
    else {
        PrintToChat(client, "%s 参数错误", PREFIX);
        return Plugin_Handled;
    }

    BuildPath(Path_SM, g_sMinidemoDirBase, sizeof(g_sMinidemoDirBase), "data/csgowiki/minidemo/%s", buffer);
    if (!DirExists(g_sMinidemoDirBase)) {
        PrintToChat(client, "%s 路径错误", PREFIX);
        return Plugin_Handled;
    }

    g_bMinidemoPlaying = true;
    int teamFlags[2] = {CS_TEAM_T, CS_TEAM_CT};
    for (int i = 0; i < 2; ++i) {
        if (g_iMinidemoSide & (1 << i)) {
            PlayOneSide(client, teamFlags[i]);          
        }
    }

    return Plugin_Handled;
}

public Action Command_Debug(int client, int args) {
    for (int idx = 0; idx < g_iMinidemoCount; ++idx) {
        if (g_bMinidemoBotsOn[idx]) {
            PrintToChat(client, "%s bot %d still on", PREFIX, g_iMinidemoBots[idx]);
        }
    }
}

public void PlayerBothSide(int client) {
    if (g_bMinidemoPlaying) {
        PrintToChat(client, "%s 等待回放结束", PREFIX);
        ResetMinidemoState();
        ClientCommand(client, "sm_m");
        return;
    }
    g_iMinidemoCount = 0;
    g_iMinidemoSide = (1 << 0) | (1 << 1);
    BuildPath(Path_SM, g_sMinidemoDirBase, sizeof(g_sMinidemoDirBase), "data/csgowiki/minidemo");
    if (!DirExists(g_sMinidemoDirBase)) {
        PrintToChat(client, "%s 路径错误", PREFIX);
        ResetMinidemoState();
        ClientCommand(client, "sm_m");
        return;
    }
    ResetMinidemoBots();
    g_bMinidemoPlaying = true;
    // CreateTimer(0.2, BotHoldTimer, _, TIMER_REPEAT);
    int teamFlags[2] = {CS_TEAM_T, CS_TEAM_CT};
    for (int i = 0; i < 2; ++i) {
        if (g_iMinidemoSide & (1 << i)) {
            PlayOneSide(client, teamFlags[i]);          
        }
    }
}

stock void PlayOneSide(int client, int teamFlag) {
    char Path[LENGTH_PATH];
    Format(Path, sizeof(Path), "%s/%s", g_sMinidemoDirBase, teamFlag == CS_TEAM_T ? "t" : "ct");
    if (!DirExists(Path)) {
        PrintToChat(client, "%s 路径错误: %s", PREFIX, Path);
        return;
    }
    DirectoryListing dL = OpenDirectory(Path);
    int startCount = g_iMinidemoCount;
    while (dL.GetNext(g_sMinidemoName[g_iMinidemoCount], sizeof(g_sMinidemoDirBase))) {
        if (StrContains(g_sMinidemoName[g_iMinidemoCount], ".rec", false) != -1) {
            ReplaceString(g_sMinidemoName[g_iMinidemoCount++], sizeof(g_sMinidemoName), ".rec", "", false);
        }
    }
    for (int idx = startCount; idx < g_iMinidemoCount; ++idx) {
        ServerCommand("bot_add");
    }
    CreateTimer(0.1, BotPrepareTimer, (teamFlag << 10) | (startCount << 5) | g_iMinidemoCount);
}

public Action BotPrepareTimer(Handle timer, int vals) {
    // set g_iMinidemoBots
    int teamFlag = vals >> 10;
    int startCount = (vals >> 5) & ((1 << 5) - 1);
    int endCount = vals & ((1 << 5) - 1);

    for (int idx = startCount; idx < endCount; ++idx) {
        if (!IsMinidemoBot(g_iMinidemoBots[idx])) {
            g_iMinidemoBots[idx] = GetPreparedBot(idx, teamFlag);
            g_bMinidemoBotsOn[idx] = true;
        }
    }

    CreateTimer(10.0, BotReplayStartTimer, vals);

    return Plugin_Handled;
}

public Action BotReplayStartTimer(Handle timer, int vals) {
    int teamFlag = vals >> 10;
    int startCount = (vals >> 5) & ((1 << 5) - 1);
    int endCount = vals & ((1 << 5) - 1);
    for (int idx = startCount; idx < endCount; ++idx) {
        if (!IsMinidemoBot(g_iMinidemoBots[idx])) {
            continue;
        }
        CS_RespawnPlayer(g_iMinidemoBots[idx]);

        DataPack dpack = new DataPack();
        dpack.WriteCell(g_iMinidemoBots[idx]);
        char filepath[128];
        Format(filepath, sizeof(filepath), "%s/%s/%s.rec", g_sMinidemoDirBase, teamFlag == CS_TEAM_T ? "t": "ct", g_sMinidemoName[idx]);
        dpack.WriteString(filepath);

        RequestFrame(StartMinidemoReplay, dpack);
    }
    return Plugin_Handled;
}

public void StartMinidemoReplay(DataPack pack) {
    pack.Reset();
    int client = pack.ReadCell();
    char filepath[128];
    pack.ReadString(filepath, sizeof(filepath));

    BMError err = BotMimicFix_PlayRecordFromFile(client, filepath);
    if (err != BM_NoError) {
        char errString[128];
        BotMimicFix_GetErrorString(err, errString, sizeof(errString));
        LogError("Error playing record %s on client %d: %s", filepath, client, errString);
    }

    delete pack;
}