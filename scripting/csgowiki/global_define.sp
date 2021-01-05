#include <sourcemod>
#include <system2>
#include <json>

#define PREFIX "\x01[\x05CSGO Wiki\x01]"
#define LENGTH_TOKEN 33
#define LENGTH_STEAMID64 20 // 17 for usuall
#define LENGTH_STATUS 5
#define LENGTH_NAME 33


// 功能开关  steambind 不能关闭
new Handle: g_hCSGOWikiEnable;
new Handle: g_hOnUtilitySubmit;
new Handle: g_hOnUtilityWiki;
new Handle: g_hOnServerMonitor;
// wiki token
new Handle: g_hCSGOWikiToken;

// --------- steam_bind.sp define -----------
enum StateBind {
    e_bUnkown = 0,
    e_bUnbind = 1,
    e_bBinded = 2
};

StateBind g_aPlayerStateBind[MAXPLAYERS + 1];
