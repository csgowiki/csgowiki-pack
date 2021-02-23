// 

public Action:Command_QQchat(client, args) {
    if (!GetConVarBool(g_hChannelEnable)) {
        PrintToChat(client, "%s \x02qq聊天已关闭，请联系服务器管理员", PREFIX);
        return;
    }
    char words[LENGTH_MESSAGE];
    char name[LENGTH_NAME];
    GetClientName(client, name, sizeof(name));
    GetCmdArgString(words, sizeof(words));
    TrimString(words);
    ChannelPush(name, words);
}

public Action:ChannelPullTimerCallback(Handle timer) {
    ChannelPull();
}

void ChannelPull() {
    char remark[LENGTH_NAME];
    char qqgroup[LENGTH_NAME];
    GetConVarString(g_hChannelServerRemark, remark, sizeof(remark));
    GetConVarString(g_hChannelQQgroup, qqgroup, sizeof(qqgroup));

    System2HTTPRequest httpRequest = new System2HTTPRequest(
        ChannelPullCallback,
        "http://channel.csgowiki.top:8000/channel/csgo/?server_remark=%s&qqgroup_id=%s",
        remark, qqgroup
    );
    httpRequest.GET();
    delete httpRequest;
}

public ChannelPullCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    if (success) {
        char[] status = new char[LENGTH_STATUS];
        char[] content = new char[response.ContentLength + 1];
        response.GetContent(content, response.ContentLength + 1);
        JSON_Object json_obj = json_decode(content);
        json_obj.GetString("status", status, LENGTH_STATUS);
        if (StrEqual(status, "ok")) {
            char name[LENGTH_NAME], words[LENGTH_MESSAGE];
            json_obj.GetString("name", name, sizeof(name));
            json_obj.GetString("words", words, sizeof(words));
            if (StrEqual(words, "状态")) {
                char str_monitor[LENGTH_SERVER_MONITOR];
                JSON_Array monitor_json = encode_json_server_monitor(-2, false, false);
                monitor_json.Encode(str_monitor, LENGTH_SERVER_MONITOR);
                ChannelPush("CSGOWiki-Bot", str_monitor);
            } else {
                PrintToChatAll("[\x09QQ\x01] \x04%s\x01：%s", name, words);
            }
        }
        json_cleanup_and_delete(json_obj);
    }
}

void ChannelPush(char[] name, char[] words) {
    char remark[LENGTH_NAME];
    char qqgroup[LENGTH_NAME];
    GetConVarString(g_hChannelServerRemark, remark, sizeof(remark));
    GetConVarString(g_hChannelQQgroup, qqgroup, sizeof(qqgroup));

    System2HTTPRequest httpRequest = new System2HTTPRequest(
        ChannelPushCallback,
        "http://channel.csgowiki.top:8000/channel/csgo/"
    );

    httpRequest.SetData(
        "server_remark=%s&qqgroup_id=%s&name=%s&words=%s",
        remark, qqgroup, name, words
    );
    httpRequest.POST();
    delete httpRequest;
}

public ChannelPushCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    if (success) {
        char[] status = new char[LENGTH_STATUS];
        char[] content = new char[response.ContentLength + 1];
        response.GetContent(content, response.ContentLength + 1);
        JSON_Object json_obj = json_decode(content);
        json_obj.GetString("status", status, LENGTH_STATUS);
        if (!StrEqual(status, "ok")) {
            PrintToChatAll("%s \x02未能成功发送消息", PREFIX);
        }
        json_cleanup_and_delete(json_obj);
    }
}