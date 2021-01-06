// implement server monitor function


public Action:Command_Test(client, args) {
    // playername  steamid  ping
    char output[1024];
    JSON_Array monitor_json = encode_json_server_monitor();
    monitor_json.Encode(output, sizeof(output));
    PrintToChat(client, output);
}

void updateServerMonitor() {
    char str_monitor[LENGTH_SERVER_MONITOR];
    JSON_Array monitor_json = encode_json_server_monitor();
    monitor_json.Encode(str_monitor, LENGTH_SERVER_MONITOR);

    System2HTTPRequest httpRequest = new System2HTTPRequest(
        ServerMonitorResponseCallback,
        "https://api.csgowiki.top/api/server/server_monitor/"
    )
    httpRequest.SetData("monitor_json=%s", str_monitor);
    httpRequest.POST();
}

JSON_Array encode_json_server_monitor() {
    JSON_Array monitor_json = new JSON_Array();
    char token[LENGTH_TOKEN];
    GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);
    monitor_json.PushString(token);
    for (int client_id = 0; client_id <= MaxClients; client_id++) {
        if(!IsPlayer(client_id)) continue;
        char client_name[LENGTH_NAME], steamid[LENGTH_STEAMID64], str_ping[4];
        GetClientName(client_id, client_name, LENGTH_NAME);
        GetClientAuthId(client_id, AuthId_SteamID64, steamid, LENGTH_STEAMID64)
        float latency = GetClientAvgLatency(client_id, NetFlow_Both);
        IntToString(RoundToNearest(latency * 500), str_ping, sizeof(str_ping));
        // json encode
        JSON_Array client_arr = new JSON_Array();
        client_arr.PushString(client_name);
        client_arr.PushString(steamid);
        client_arr.PushString(str_ping);
        monitor_json.PushObject(client_arr);
    }
    return monitor_json;
}