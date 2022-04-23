// minidemo utils
public void ResetMinidemoBots() {
    g_bMinidemoPlaying = false;
    for (int idx = 0; idx < MAX_REPLAY_CLIENTS; ++idx) {
        g_iMinidemoBots[idx] = -1;
        g_bMinidemoBotsOn[idx] = false;
    }
}

public bool isPossibleMinidemoBot(int client) {
    if (!IsValidClient(client) || !IsFakeClient(client) || IsClientSourceTV(client)) {
        return false;
    }
    return IsFakeClient(client);
}

// if client is minidemo replay bot
public bool IsMinidemoBot(int client) {
    if (!isPossibleMinidemoBot(client)) {
        return false;
    }
    for (int idx = 0; idx < g_iMinidemoCount; ++idx) {
        if (g_iMinidemoBots[idx] == client) {
            return true;
        }
    }
    return false;
}

public int GetLargestBotUserId() {
    int largestUserid = -1;
    for (int i = 0; i <= MaxClients; ++i) {
        if (IsValidClient(i) && IsFakeClient(i) && !IsClientSourceTV(i)) {
            int userid = GetClientUserId(i);
            if (userid > largestUserid && !IsMinidemoBot(i)) {
                largestUserid = userid;
            }
        }
    }
    return largestUserid;
}

public void KillBot(int client) {
    // float botOrigin[3] = {-5000.0, 0.0, 0.0};
    // TeleportEntity(client, botOrigin, NULL_VECTOR, NULL_VECTOR);
    ForcePlayerSuicide(client);
}

public int GetPreparedBot(int idx, int teamFlag) {
    int largestUserid = GetLargestBotUserId();
    if (largestUserid == -1) {
        return -1;
    }

    int bot = GetClientOfUserId(largestUserid);
    if (!IsValidClient(bot)) {
        return -1;
    }

    SetClientName(bot, g_sMinidemoName[idx]);
    CS_SwitchTeam(bot, teamFlag);
    KillBot(bot);
    return bot;
}

public void ResetMinidemoState() {
    g_iDemoLeader = -1;
    g_iDemoDownloadBits = 0;
    g_iDemoDownloadNum = 0;
    g_iMinidemoStatus = e_mDefault;
    ClearMinidemoFiles();
}

public void DeleteFilesInDir(char []Path) {
    if (!DirExists(Path)) {
        return;
    }
    char filebuffer[PLATFORM_MAX_PATH + 1];
    DirectoryListing dL = OpenDirectory(Path);
    while (dL.GetNext(filebuffer, sizeof(filebuffer))) {
        if (StrEqual(filebuffer, ".") || StrEqual(filebuffer, "..")) {
            continue;
        }
        Format(filebuffer, sizeof(filebuffer), "%s/%s", Path, filebuffer);
        DeleteFile(filebuffer);
    }
}

public void ClearMinidemoFiles() {
    char ctdir[PLATFORM_MAX_PATH + 1];
    char tdir[PLATFORM_MAX_PATH + 1];
    BuildPath(Path_SM, ctdir, sizeof(ctdir), "data/csgowiki/minidemo/ct");
    BuildPath(Path_SM, tdir, sizeof(tdir), "data/csgowiki/minidemo/t");
    // remove files in ctdir and tdir
    DeleteFilesInDir(ctdir);
    DeleteFilesInDir(tdir);

    EnforceDirExists("data/csgowiki/minidemo");
    EnforceDirExists("data/csgowiki/minidemo/ct");
    EnforceDirExists("data/csgowiki/minidemo/t");
}