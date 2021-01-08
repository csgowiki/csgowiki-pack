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

void Utility_TinyName2Zh(char[] utTinyName, char[] format, char[] zh) {
    if (StrEqual(utTinyName, "smoke")) {
        Format(zh, LENGTH_UTILITY_ZH, format, "烟雾弹");
    }
    else if (StrEqual(utTinyName, "grenade")) {
        Format(zh, LENGTH_UTILITY_ZH, format, "手雷");
    }
    else if (StrEqual(utTinyName, "flash")) {
        Format(zh, LENGTH_UTILITY_ZH, format, "闪光弹");
    }
    else if (StrEqual(utTinyName, "molotov")) {
        Format(zh, LENGTH_UTILITY_ZH, format, "燃烧弹");
    }
}

void Utility_TinyName2Weapon(char[] utTinyName, char[] weaponName, client) {
    if (StrEqual(utTinyName, "smoke")) {
        strcopy(weaponName, LENGTH_UTILITY_ZH, "weapon_smokegrenade");
    }
    else if (StrEqual(utTinyName, "grenade")) {
        strcopy(weaponName, LENGTH_UTILITY_ZH, "weapon_hegrenade");
    }
    else if (StrEqual(utTinyName, "flash")) {
        strcopy(weaponName, LENGTH_UTILITY_ZH, "weapon_flashbang");
    }
    else if (StrEqual(utTinyName, "molotov")) {
        new teamFlag = GetClientTeam(client);
        if (CS_TEAM_T == teamFlag) {
            strcopy(weaponName, LENGTH_UTILITY_ZH, "weapon_molotov");
        }
        else if (CS_TEAM_CT == teamFlag){  // [TODO]  spec
            strcopy(weaponName, LENGTH_UTILITY_ZH, "weapon_incgrenade");
        }
    }
}