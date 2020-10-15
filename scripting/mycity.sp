#include <sourcemod>
#include <clientprefs>
#include <system2>
#include <json>

#define CLASSLENGTH 64
#define RGBA 0, 255, 0, 255
// https://www.nowapi.com/api/weather.today 在这里拿APPKEY和SIGN
#define APPKEY "NEED ADD"
#define SIGN "NEED ADD"

Handle g_HTM;
Handle g_hCookie_TabHud;
bool g_bEnableTabHud[MAXPLAYERS + 1];
char g_sCity[MAXPLAYERS + 1][32];
char g_sWeek[MAXPLAYERS + 1][16];
char g_sWeather[MAXPLAYERS + 1][32];
char g_sTemp[MAXPLAYERS + 1][32];
char g_sTempNow[MAXPLAYERS + 1][16];
bool g_bChecked[MAXPLAYERS + 1];

public Plugin:myinfo = {
    name = "My city",
    author = "CarOL",
    description = "show something fun about my city(auto located)",
    url = "https://github.com/Herixth/CSGOWiki-Plugins"
};

public OnPluginStart() {
    for (int idx = 0; idx <= MAXPLAYERS; idx++) {
        g_bChecked[idx] = false;
    }
    g_hCookie_TabHud = RegClientCookie("toggle_tabhud", "TabHud", CookieAccess_Protected);
    RegConsoleCmd("sm_tabhud", Command_ToggleTabHud);
}

public void OnClientPutInServer(int client){
	g_bEnableTabHud[client] = true;
	char buffer[CLASSLENGTH];
	GetClientCookie(client, g_hCookie_TabHud, buffer, sizeof(buffer));
	if(StrEqual(buffer, "0")){
		g_bEnableTabHud[client] = false;
	}
    if (!g_bChecked[client] && IsValidClient(client)) {
        queryWeatherApi(client);
        g_bChecked[client] = true;
    }
}

public Action:Command_ToggleTabHud(client, args) {
    if (g_bEnableTabHud[client]) {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x04已关闭Tab页面显示天气等信息");
        g_bEnableTabHud[client] = false;
        SetClientCookie(client, g_hCookie_TabHud, "0");
    }
    else {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x04已开启Tab页面显示天气等信息");
        g_bEnableTabHud[client] = true;
        SetClientCookie(client, g_hCookie_TabHud, "1");
    }  
    return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]) {
    if (g_bEnableTabHud[client] && g_bChecked[client]) {
        if (buttons & IN_SCORE) {
            g_HTM = CreateHudSynchronizer();
            char timeNow[CLASSLENGTH];
            char showInfo[4 * CLASSLENGTH];
            FormatTime(timeNow, sizeof(timeNow), "%H:%M:%S", GetTime());
            Format(showInfo, sizeof(showInfo), "城市：%s\n天气：%s\n气温：%s(实时%s)\n时间：%s(%s)", 
                g_sCity[client], g_sWeather[client], g_sTemp[client], g_sTempNow[client], timeNow, g_sWeek[client]);
            SetHudTextParams(0.9, 0, 0.1, RGBA, 0, 0.1, 0.0, 10);
            ShowSyncHudText(client, g_HTM, showInfo);
        }
    }
}

void queryWeatherApi(client) {
    char c_IP[CLASSLENGTH];
    GetClientIP(client, c_IP, sizeof(c_IP));
    PrintToChat(client, "your ip %s", c_IP);
    System2HTTPRequest httpRequest = new System2HTTPRequest(
        WeatherApiCallBack, 
        "http://api.k780.com/?app=weather.today&weaid=%s&appkey=%s&sign=%s&format=json",
        c_IP, APPKEY, SIGN
    )
    httpRequest.Any = client;
    httpRequest.GET();
}

public void WeatherApiCallBack(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    int client = request.Any;
    if (success) {
        char[] content = new char[response.ContentLength + 1];
        char status[2];
        response.GetContent(content, response.ContentLength + 1);
        JSON_Object json_obj = json_decode(content);
        json_obj.GetString("success", status, sizeof(status));
        if (StrEqual(status, "1")) {
            JSON_Object res_obj = json_obj.GetObject("result");
            res_obj.GetString("citynm", g_sCity[client], 32);
            res_obj.GetString("temperature", g_sTemp[client], 32);
            res_obj.GetString("temperature_curr", g_sTempNow[client], 16);
            res_obj.GetString("weather", g_sWeather[client], 32);
            res_obj.GetString("week", g_sWeek[client], 16);
            PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x04天气API请求成功");
        }
        else {
            char errmsg[32];
            json_obj.GetString("msg", errmsg, sizeof(errmsg));
            PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02天气API请求失败: %s", errmsg);
        }
    }
    else {
        PrintToChat(client, "\x01[\x05CSGO Wiki\x01] \x02api访问失败，请及时联系服务器管理员");
    }
}

stock bool IsValidClient(int client) {
	  return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}