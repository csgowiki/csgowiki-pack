// check handle function on/off
bool check_function_on(Handle: ghandle, char[] errorMsg, client = -1) {
    bool benable = GetConVarBool(ghandle) && GetConVarBool(g_hCSGOWikiEnable);
    if (!benable && client != -1) {
        PrintToChat(client, "%s %s", PREFIX, errorMsg);
    }
    return benable;
}

// check player valid
stock bool IsPlayer(int client) {
    return IsValidClient(client) && !IsFakeClient(client) && !IsClientSourceTV(client);
}

stock bool IsValidClient(int client) {
    return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}


int GetServerTickrate() {
    return RoundToZero(1.0 / GetTickInterval());
}

// convar handle function
Handle FindOrCreateConvar(char[] cvName, char[] cvDefault, char[] cvDescription) {
    Handle cvHandle = FindConVar(cvName);
    if (cvHandle == INVALID_HANDLE) {
        cvHandle = CreateConVar(cvName, cvDefault, cvDescription);
    }
    return cvHandle;
}

// utils for utility submit
UtilityCode Utility_FullName2Code(const char[] utilityName) {
    if (StrEqual(utilityName, "hegrenade")) return e_uHegrenade;
    else if (StrEqual(utilityName, "flashbang")) return e_uFlasbang;
    else if (StrEqual(utilityName, "smokegrenade")) return e_uSomkegrenade;
    else return e_uMolotov;
}

void Utility_Code2TinyName(UtilityCode utCode, char[] utTinyName) {
    switch (utCode) {
    case e_uHegrenade:
        strcopy(utTinyName, LENGTH_UTILITY_TINY, "grenade");
    case e_uFlasbang:
        strcopy(utTinyName, LENGTH_UTILITY_TINY, "flash");
    case e_uSomkegrenade:
        strcopy(utTinyName, LENGTH_UTILITY_TINY, "smoke");
    case e_uMolotov:
        strcopy(utTinyName, LENGTH_UTILITY_TINY, "molotov");
    }
}

void Action_Int2Array(client, bool[] wikiAction) {
    for (new idx = 0; idx < CSGO_ACTION_NUM; idx++) {
        if (g_aActionRecord[client] & (1 << idx)) {
            switch(g_aCsgoActionMap[idx]) {
            case IN_JUMP:   wikiAction[e_wJump] = true;
            case IN_DUCK:   wikiAction[e_wDuck] = true;
            case IN_ATTACK: wikiAction[e_wLeftclick] = true;
            case IN_ATTACK2:    wikiAction[e_wRightclick] = true;
            case IN_MOVELEFT:   wikiAction[e_wRun] = true;
            case IN_MOVERIGHT:  wikiAction[e_wRun] = true;
            case IN_BACK:       wikiAction[e_wRun] = true;   
            case IN_FORWARD:    wikiAction[e_wRun] = true;
            case IN_SPEED:  wikiAction[e_wWalk] = true;
            }
        }
    }
    // post fix
    if (!wikiAction[e_wRun] && wikiAction[e_wWalk]) {
        wikiAction[e_wWalk] = false; // 没有移动只按shift
    }
    if (wikiAction[e_wRun] && wikiAction[e_wWalk]) {
        wikiAction[e_wRun] = false; // just shift
    }
    if (wikiAction[e_wRun] && wikiAction[e_wDuck]) {
        wikiAction[e_wWalk] = true;
        wikiAction[e_wRun] = false;
    }
    if (!(wikiAction[e_wRun] || wikiAction[e_wWalk] 
        || wikiAction[e_wJump] || wikiAction[e_wDuck])) {
        wikiAction[e_wStand] = true;
    }
}

void Action_Int2Str(client, char[] strAction) {
    bool wikiAction[CSGOWIKI_ACTION_NUM] = {};
    Action_Int2Array(client, wikiAction);
    char StrTemp[CSGOWIKI_ACTION_NUM][6] = {
        "跳 ", "蹲 ", "跑 ", "走 ", "站 ", "左键 ", "右键 "
    };
    for (new idx = 0; idx < CSGOWIKI_ACTION_NUM; idx ++) {
        if (!wikiAction[idx]) continue;
        StrCat(strAction, LENGTH_MESSAGE, StrTemp[idx]);
    }
}

void TicktagGenerate(char[] tickTag, const bool[] wikiAction) {
    strcopy(tickTag, LENGTH_STATUS, "64/128");
    if (wikiAction[e_wJump]) {
        IntToString(g_iServerTickrate, tickTag, LENGTH_STATUS);
    }
}