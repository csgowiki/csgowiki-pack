#include <sourcemod>
#include <system2>
#include <json>

#pragma dynamic 50000

#define STRLENGTH 32
#define MATCHID 128
#define RESULTSCACHE 10


JSON_Object g_jResults[RESULTSCACHE];
bool g_bResultsQuery = false;

public Plugin:myinfo = {
    name = "Htlv information",
    author = "CarOL",
    description = "show information grab from htlv",
    url = "https://github.com/Herixth/CSGOWiki-Plugins"
};

public OnPluginStart() {
    RegConsoleCmd("sm_hltv", Command_Hltv);
    queryResults();
    CreateTimer(120.0, TimerCallBack, _, TIMER_REPEAT);
}

public Action:Command_Hltv(client, args) {
    if (!g_bResultsQuery) {
        queryResults();
    }
    setMainMenu(client);
}

void setMainMenu(client) {
    new Handle:menuhandle = CreateMenu(HltvMenuCallBack);
    SetMenuTitle(menuhandle, "Hltv信息面板");
    AddMenuItem(menuhandle, "result", "比赛结果");
    AddMenuItem(menuhandle, "news", "新闻(开发中...)");
    AddMenuItem(menuhandle, "match", "比赛预告(开发中...)");
    SetMenuPagination(menuhandle, 7);
    SetMenuExitButton(menuhandle, true);
    DisplayMenu(menuhandle, client, MENU_TIME_FOREVER);
}

void setSub1Menu(client) {
    new Handle:submenuhandle = CreateMenu(ResultMenuCallBack);
    SetMenuTitle(submenuhandle, "近期10场比赛结果");
    for (int idx = 0; idx < RESULTSCACHE; idx ++) {
        char itemid[2];
        char mapflg[8];
        char teamname[2][STRLENGTH];
        int results[2];
        IntToString(idx, itemid, sizeof(itemid));
        g_jResults[idx].GetString("maps", mapflg, sizeof(mapflg));
        JSON_Object team1 = g_jResults[idx].GetObject("team1");
        JSON_Object team2 = g_jResults[idx].GetObject("team2");
        team1.GetString("name", teamname[0], STRLENGTH);
        team2.GetString("name", teamname[1], STRLENGTH);
        results[0] = team1.GetInt("result");
        results[1] = team2.GetInt("result");
        char showInfo[3 * STRLENGTH];
        Format(showInfo, sizeof(showInfo), "[%d : %d] %s vs %s (%s)", results[0], results[1], teamname[0], teamname[1], mapflg);
        AddMenuItem(submenuhandle, itemid, showInfo);
    }
    SetMenuPagination(submenuhandle, 7);
    SetMenuExitBackButton(submenuhandle, true);
    SetMenuExitButton(submenuhandle, true);
    DisplayMenu(submenuhandle, client, MENU_TIME_FOREVER);
}

public HltvMenuCallBack(Handle:menuhandle, MenuAction:action, client, Position) {
    if (action == MenuAction_Select) {
        decl String:Item[STRLENGTH];
        GetMenuItem(menuhandle, Position, Item, sizeof(Item));
        if (StrEqual(Item, "result")) {
            setSub1Menu(client);
        }
    }
}

public ResultMenuCallBack(Handle:menuhandle, MenuAction:action, client, Position) {
    if (action == MenuAction_Select) {
        decl String:Item[STRLENGTH];
        GetMenuItem(menuhandle, Position, Item, sizeof(Item));
        int idx = StringToInt(Item);
        queryProRecord(client, idx);

        DisplayMenuAtItem(menuhandle, client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
    }
    if (Position == -6) {
        setMainMenu(client);
    }
}

void queryResults() {
    System2HTTPRequest httpRequest = new System2HTTPRequest(
        HltvApiResultCallBack, 
        "https://hltv-api.vercel.app/api/results/"
    )
    httpRequest.GET();
}

void queryProRecord(client, int cachedIdx) {
    char matchId[MATCHID];
    char event[64];
    g_jResults[cachedIdx].GetString("matchId", matchId, sizeof(matchId));
    g_jResults[cachedIdx].GetString("event", event, sizeof(event));
    System2HTTPRequest httpRequest = new System2HTTPRequest(
        HltvApiProRecordCallBack, 
        "https://hltv-api.vercel.app/api/%s/",
        matchId
    )
    httpRequest.Any = client;
    httpRequest.GET();
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x0E赛事\x01：---- \x03%s\x01 ----", event);
}

public HltvApiResultCallBack(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        response.GetContent(content, response.ContentLength + 1);
        JSONArray arr = view_as<JSONArray>(json_decode(content));
        for (int idx = 0; idx < RESULTSCACHE; idx++) {
            g_jResults[idx] = arr.GetObject(idx);
        }
        g_bResultsQuery = true;
    }
    else {
        PrintToChatAll("\x01[\x05CSGO Wiki\x01] \x02hltv-api访问失败，请及时联系服务器管理员");
    }
}

public HltvApiProRecordCallBack(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    int client = request.Any;
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        response.GetContent(content, response.ContentLength + 1);
        JSONArray proRecord = view_as<JSONArray>(json_decode(content));
        printOutProRecord(client, proRecord);
    }
    else {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02hltv-api访问失败，请及时联系服务器管理员");
    }
}

public Action:TimerCallBack(Handle timer) {
    queryResults();
}

void printOutProRecord(client, JSONArray proRecord) {
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x01|\x0E    选手    \x01|\x09 击杀 \x01|\x09 死亡 \x01|\x09 ADR \x01|\x09 KAST \x01|\x10 Rating \x01|")
    for (int idx = 0; idx < 10; idx ++) {  // 默认10人 可能有例外
        JSON_Object pro = proRecord.GetObject(idx);
        char oriName[STRLENGTH];
        char NameBuffer[5][STRLENGTH];
        pro.GetString("playerName", oriName, sizeof(oriName));
        int kills = pro.GetInt("kills");
        int deaths = pro.GetInt("deaths");
        float adr = pro.GetFloat("adr");
        float kast = pro.GetFloat("kast");
        float rating = pro.GetFloat("rating");
        ExplodeString(oriName, " ", NameBuffer, 5, STRLENGTH);
        if (rating >= 1) {
            PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x01|\x06 %8s \x01|\x0B %2d \x01|\x0B %2d \x01|\x08 %.1f \x01|\x08 %.1f \x01|\x04 %.2f \x01|",
                NameBuffer[1], kills, deaths, adr, kast, rating);
        }
        else {
            PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x01|\x06 %8s \x01|\x0B %2d \x01|\x0B %2d \x01|\x08 %.1f \x01|\x08 %.1f \x01|\x02 %.2f \x01|",
                NameBuffer[1], kills, deaths, adr, kast, rating);
        }
    }
    PrintToChat(client, "\x01[\x05CSGO Wiki\x01] ---------------------------------------------------");
}