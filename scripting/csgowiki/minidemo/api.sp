// provide api method for minidemo
char BASE_URL[LENGTH_URL] = "https://minidemo-1256946954.cos.ap-chengdu.myqcloud.com";

// Get minidemo index info by map
void GetDemoCollection(int client=-1) {
    char url[LENGTH_URL] = "";
    Format(url, sizeof(url), "%s/%s/index.json", BASE_URL, g_sCurrentMap);
    HTTPRequest DemoCollectionRequest = new HTTPRequest(url);

    DemoCollectionRequest.SetHeader("Content-Type", "application/json");
    DemoCollectionRequest.Get(DemoCollectionResponseCallback, client);

    if (client == -1) {
        g_iDemoLeader = -1;
    }
}

void DemoCollectionResponseCallback(HTTPResponse response, int client) {
    if (response.Status == HTTPStatus_OK) {
        // if (g_MinidemoCollection != null) {
        //     delete g_MinidemoCollection;
        // }
        g_MinidemoCollection = new JSONObject();
        JSONObject resp_json = view_as<JSONObject>(response.Data);
        JSONObjectKeys keys = resp_json.Keys();
        char key[LENGTH_NAME];
        // deep copy
        while (keys.ReadKey(key, sizeof(key))) {
            JSONObject value = view_as<JSONObject>(resp_json.Get(key));
            g_MinidemoCollection.Set(key, value);
        }
        delete keys;
        PrintToServer("%s demo collection init.", PREFIX);
        if (IsPlayer(client)) {
            PrintToChat(client, "%s \x05demo信息获取成功", PREFIX);
            ClientCommand(client, "sm_demo");
        }
    }
    else {
        PrintToChatAll("%s \x02连接至DEMO API失败：%d", PREFIX, response.Status);
        PrintToServer("%s \x02连接至DEMO API失败：%d", PREFIX, response.Status);
    }
}

// called after set `g_iDemoLeader, g_sDemoPickedMatch, g_sDemoPickedRound`
// g_iMinidemoStatus == e_mPicking
void DownloadMinidemoStart(int client) {
    if (g_iMinidemoStatus != e_mPicking) {
        PrintToChat(client, "%s \x02当前状态不能下载minidemo", PREFIX);
        return;
    }
    g_iMinidemoStatus = e_mDownloading;

    JSONObject info = view_as<JSONObject>(g_MinidemoCollection.Get(g_sDemoPickedMatch));
    JSONObject team1 = view_as<JSONObject>(info.Get("team1"));
    JSONObject team2 = view_as<JSONObject>(info.Get("team2"));
    JSONArray team1players = view_as<JSONArray>(team1.Get("players"));
    JSONArray team2players = view_as<JSONArray>(team2.Get("players"));
    // get player names;
    int team1_size = team1players.Length;
    int team2_size = team2players.Length;
    char team1names[6][LENGTH_NAME];
    char team2names[6][LENGTH_NAME];
    for (int i = 0; i < team1_size; ++i) {
        char name[LENGTH_NAME];
        team1players.GetString(i, name, LENGTH_NAME);
        strcopy(team1names[i], sizeof(name), name);
    }
    for (int i = 0; i < team2_size; ++i) {
        char name[LENGTH_NAME];
        team2players.GetString(i, name, LENGTH_NAME);
        strcopy(team2names[i], sizeof(name), name);
    }
    // confirm ct/t
    // ctRounds may be not correct
    JSONArray team1ctRounds = view_as<JSONArray>(team1.Get("ctRounds"));
    int sample = team1ctRounds.GetInt(0);
    char team1flag[3] = "";
    char team2flag[3] = "";
    if ((sample < 15 && g_iDemoPickedRound < 15) || (sample >= 15 && g_iDemoPickedRound >= 15)) {
        strcopy(team1flag, sizeof(team1flag), "ct");
        strcopy(team2flag, sizeof(team2flag), "t");
    }
    else if ((sample < 15 && g_iDemoPickedRound >= 15) || (sample >= 15 && g_iDemoPickedRound < 15)) {
        strcopy(team1flag, sizeof(team1flag), "t");
        strcopy(team2flag, sizeof(team2flag), "ct");
    }
    else {
        PrintToChat(client, "%s \x02队伍信息获取失败", PREFIX);
    }
    // ensure minidemo dir exists and clear ct/t dir
    ClearMinidemoFiles();
    g_iDemoDownloadBits = 0;
    g_iDemoDownloadNum = team1_size + team2_size;
    // download every player's minidemo file
    for (int i = 0; i < team1_size; ++i) {
        if (g_iMinidemoStatus != e_mDownloading) {
            PrintToChatAll("%s \x02minidemo下载被中断", PREFIX);
            break;
        }
        char url[LENGTH_URL] = "";
        Format(url, sizeof(url), "%s/%s.rec", team1flag, team1names[i]);
        DownloadOneMinidemo(client, url, i);
    }
    for (int i = 0; i < team2_size; ++i) {
        if (g_iMinidemoStatus != e_mDownloading) {
            PrintToChatAll("%s \x02minidemo下载被中断", PREFIX);
            break;
        }
        char url[LENGTH_URL] = "";
        Format(url, sizeof(url), "%s/%s.rec", team2flag, team2names[i]);
        DownloadOneMinidemo(client, url, i + team1_size);
    }
}

void DownloadOneMinidemo(int client, char[] url_tail, int index) {
    char url[LENGTH_URL] = "";
    Format(url, sizeof(url), "%s/%s/%s/round%d/%s", BASE_URL, g_sCurrentMap, g_sDemoPickedMatch, g_iDemoPickedRound, url_tail);
    char filepath[PLATFORM_MAX_PATH + 1];
    BuildPath(Path_SM, filepath, sizeof(filepath), "data/csgowiki/minidemo/%s", url_tail);
    if (FileExists(filepath)) {
        PrintToChat(client, "%s \x08%s已存在", PREFIX, url_tail);
        SetOneFileDownloadCompleted(client, index);
        return;
    }
    PrintToServer("%s \x02开始下载minidemo [%s]", PREFIX, url);
    HTTPRequest request = new HTTPRequest(url);
    DataPack pack = new DataPack();
    pack.WriteCell(client);
    pack.WriteCell(index);
    request.DownloadFile(filepath, MinidemoDownloadCallback, pack);
}

void MinidemoDownloadCallback(HTTPStatus status, DataPack pack) {
    pack.Reset();
    int client = pack.ReadCell();
    int index = pack.ReadCell();
    if (!IsPlayer(client)) {
        // client disconnected, quit minidemo, and clear minidemo files
        ResetMinidemoState();
        return;
    }
    // if (status == HTTPStatus_NotFound || status == HTTPStatus_InternalServerError) {
    //     PrintToChat(client, "%s \x02未找到minidemo: 编号%d", PREFIX, index);
    //     PrintToServer("%s \x02未找到minidemo: 编号%d", PREFIX, index);
    //     return;
    // }
    // if (status != HTTPStatus_OK) {
    //     // Download failed
    //     PrintToChat(client, "%s \x02minidemo下载失败: 编号%d", PREFIX, index);
    //     PrintToServer("%s \x02minidemo下载失败: 编号%d", PREFIX, index);
    //     return;
    // }
    SetOneFileDownloadCompleted(client, index);
}

void SetOneFileDownloadCompleted(int client, int index) {
    g_iDemoDownloadBits |= (1 << index); // downloaded

    // check if all minidemo files downloaded
    if (g_iDemoDownloadBits == (1 << g_iDemoDownloadNum) - 1) {
        // all minidemo files downloaded
        PrintToChatAll("%s \x03minidemo下载完成", PREFIX);
        PrintToServer("%s \x03minidemo下载完成", PREFIX);
        // checking minidemo
        // TODO
        g_iMinidemoStatus = e_mChecking;
        // start playing minidemo

        g_iMinidemoStatus = e_mPlaying;

        // ResetMinidemoState();
        PlayerBothSide(client);
    }
}