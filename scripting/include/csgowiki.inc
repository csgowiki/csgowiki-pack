#include <sourcemod>
#include <csutils>
#include <sdktools>
#include <cstrike>
#include <ripext>
#include <botmimic_fix>

#define PREFIX "\x01[\x05CSGOWiki\x01]"
#pragma dynamic 1310720

#define LENGTH_VERSION 20
#define LENGTH_TOKEN 40
#define LENGTH_STEAMID64 20 // 17 for usuall
#define LENGTH_STATUS 16
#define LENGTH_NAME 33
#define LENGTH_IP 27
#define LENGTH_SERVER_MONITOR 2048
#define LENGTH_MAPNAME 12
#define LENGTH_UTILITY_FULL 13
#define LENGTH_UTILITY_TINY 8
#define LENGTH_UTILITY_ZH 24
#define LENGTH_UTILITY_ID 12
#define LENGTH_UTILITY_BRIEF 41
#define LENGTH_MESSAGE 128
#define DATA_DIM 3
#define LENGTH_URL 256
#define LENGTH_PATH 128
#define MAX_REPLAY_CLIENTS 12

#define CSGO_ACTION_NUM 9
#define CSGOWIKI_ACTION_NUM 7

// 功能开关  steambind 不能关闭
Handle g_hCSGOWikiEnable = INVALID_HANDLE;
Handle g_hOnUtilitySubmit = INVALID_HANDLE;
Handle g_hOnUtilityWiki = INVALID_HANDLE;
Handle g_hWikiReqLimit = INVALID_HANDLE;
Handle g_hWikiAutoKicker = INVALID_HANDLE;
// wiki token
Handle g_hCSGOWikiToken;
// api host
Handle g_hApiHost = INVALID_HANDLE;

// 地图 tick信息
char g_sCurrentMap[LENGTH_MAPNAME];
int g_iServerTickrate;

// 插件版本信息
char g_sCurrentVersion[LENGTH_VERSION];
char g_sLatestVersion[LENGTH_VERSION];
char g_sLatestInfo[LENGTH_MESSAGE];

// 道具路径
const int g_iUtilityPathInterval = 2; // 间隔Frame采样
int g_iPlayerUtilityPathFrameCount[MAXPLAYERS + 1];
ArrayList g_aPlayerUtilityPath[MAXPLAYERS + 1];

// --------- steam_bind.sp define -----------
enum StateBind {
    e_bUnknown = 0,
    e_bUnbind = 1,
    e_bBinded = 2
};

StateBind g_aPlayerStateBind[MAXPLAYERS + 1];

// --------- utility_submit.sp define -----------
enum StateClient {
    e_cDefault = 0,
    e_cThrowReady = 1,
    e_cThrowEnd = 2,
    e_cAlreadyThrown = 3,
    e_cM_ThrowReady = 4,
    e_cM_ThrowEnd = 5,
    e_cM_AlreadyThrown = 6,
    e_cV_ThrowReady = 7
}


enum WikiAction {
    e_wJump = 0,
    e_wDuck = 1,
    e_wRun = 2,
    e_wWalk = 3,
    e_wStand = 4,
    e_wLeftclick = 5,
    e_wRightclick = 6
}


int g_aCsgoActionMap[CSGO_ACTION_NUM] = {
    IN_JUMP, IN_DUCK, IN_ATTACK, IN_ATTACK2, 
    IN_MOVELEFT, IN_MOVERIGHT, IN_FORWARD, IN_BACK, IN_SPEED
};

StateClient g_aPlayerStatus[MAXPLAYERS + 1];
// data for utility record
GrenadeType g_aUtilityType[MAXPLAYERS + 1];
float g_aStartPositions[MAXPLAYERS + 1][DATA_DIM];
float g_aStartAngles[MAXPLAYERS + 1][DATA_DIM];
float g_aThrowPositions[MAXPLAYERS + 1][DATA_DIM];
float g_aEndspotPositions[MAXPLAYERS + 1][DATA_DIM];
float g_aUtilityVelocity[MAXPLAYERS + 1][DATA_DIM];
int g_iUtilityEntityId[MAXPLAYERS + 1];

float g_aUtilityAirtime[MAXPLAYERS + 1];
int g_aActionRecord[MAXPLAYERS + 1];    // encoded


// ------------- wikipro.sp define ----------------
JSONArray g_aProMatchInfo;
JSONArray g_aProMatchDetail[MAXPLAYERS + 1];
int g_aProMatchIndex[MAXPLAYERS + 1];

// ------------- utility_wiki.sp define -----------
JSONArray g_jaUtilityCollection;

char g_aLastArticleId[MAXPLAYERS + 1][LENGTH_UTILITY_ID];
char g_aLastUtilityId[MAXPLAYERS + 1][LENGTH_UTILITY_ID];

JSONArray g_aUtFilterCollection[MAXPLAYERS + 1];
bool g_aReqLock[MAXPLAYERS + 1];

// ------------- utility_modify.sp define ------------
char g_aPlayerToken[MAXPLAYERS + 1][LENGTH_TOKEN];

// ------------- option.sp define ------------------
bool g_bAutoThrow[MAXPLAYERS + 1];

bool g_bBotMimicLoaded = false;

// ------------- minidemo define --------------------
char g_sMinidemoDirBase[LENGTH_PATH];
char g_sMinidemoName[MAX_REPLAY_CLIENTS][LENGTH_PATH];
int g_iMinidemoBots[MAX_REPLAY_CLIENTS];
int g_iMinidemoCount = 0;
bool g_bMinidemoOn = false;
int g_iMinidemoStatus = -1; // (1 << 0) T, (1 << 1) CT, (1 << 0 | 1 << 1) Both
bool g_bMinidemoBotsOn[MAX_REPLAY_CLIENTS];
