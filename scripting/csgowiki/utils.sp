// check handle function on/off
bool check_function_on(Handle: ghandle, char[] errorMsg, client) {
    bool benable = GetConVarBool(ghandle);
    if (!benable) {
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