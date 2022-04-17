// minidemo utils
public void resetMinidemoBots() {
    g_bMinidemoOn = false;
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
public bool isMinidemoBot(int client) {
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
            if (userid > largestUserid && !isMinidemoBot(i)) {
                largestUserid = userid;
            }
        }
    }
    return largestUserid;
}

public void KillBot(int client) {
    float botOrigin[3] = {-7000.0, 0.0, 0.0};
    TeleportEntity(client, botOrigin, NULL_VECTOR, NULL_VECTOR);
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