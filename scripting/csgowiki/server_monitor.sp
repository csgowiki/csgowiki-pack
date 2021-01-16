// implement server monitor function

public Action:ServerMonitorTimerCallback(Handle timer) {
    updateServerMonitor();
}

void updateServerMonitor(int exclient = MAXPLAYERS + 1) {
    if (!check_function_on(g_hOnServerMonitor, "")) return;
    char str_monitor[LENGTH_SERVER_MONITOR];
    JSON_Array monitor_json = encode_json_server_monitor(exclient);
    monitor_json.Encode(str_monitor, LENGTH_SERVER_MONITOR);

    System2HTTPRequest httpRequest = new System2HTTPRequest(
        ServerMonitorResponseCallback,
        "https://api.csgowiki.top/api/server/server_monitor/"
    )
    httpRequest.SetData("monitor_json=%s", str_monitor);
    httpRequest.POST();
    json_cleanup_and_delete(monitor_json);
    delete httpRequest;
}

JSON_Array encode_json_server_monitor(int exclient) {
    JSON_Array monitor_json = new JSON_Array();
    char token[LENGTH_TOKEN];
    GetConVarString(g_hCSGOWikiToken, token, LENGTH_TOKEN);
    monitor_json.PushString(token);
    if (exclient == -1) {
        monitor_json.PushObject(new JSON_Array());
        return monitor_json;
    }
    for (int client_id = 0; client_id <= MaxClients; client_id++) {
        if(!IsPlayer(client_id) || client_id == exclient) continue;
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

public ServerMonitorResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        char[] status = new char[LENGTH_STATUS];
        response.GetContent(content, response.ContentLength + 1);
        JSON_Object json_obj = json_decode(content);
        json_obj.GetString("status", status, LENGTH_STATUS);
        if (!StrEqual(status, "ok")) {
            char[] message = new char[LENGTH_NAME];
            json_obj.GetString("message", message, LENGTH_NAME);
            PrintToChatAll("%s \x02%s", PREFIX, message);
        }
        json_cleanup_and_delete(json_obj);
    }
    else {
        PrintToChatAll("%s \x02连接至www.csgowiki.top失败", PREFIX);
    }
}