// implement control methods

//! params[in] client - operator
//! params[in] seconds - number of seconds to fast forward or rewind (positive forward, negative rewind)
void DemoForwardOrRewind(int client, float seconds) {
    if (!g_bMinidemoPlaying) {
        PrintToChat(client, "%s 当前没有播放任何回放", PREFIX);
        return;
    }
    int ticks = RoundFloat(FloatAbs(seconds) * g_iServerTickrate);
    
    for (int idx = 0; idx < g_iMinidemoCount; ++idx) {
        if (g_bMinidemoBotsOn[idx]) {
            int error = 0;
            if (seconds > 0.0) {
                BotMimicFix_FastForwardPlayback(g_iMinidemoBots[idx], ticks, 128); // 128 is the preset by minidemo-encoder
            }
            else {
                BotMimicFix_RewindPlayback(g_iMinidemoBots[idx], ticks, 128);
            }
            if (error) {
                PrintToChat(client, "%s 快进/回放失败");
            }
        }
    }
}

void DemoPauseOrResume(int client) {
    if (!g_bMinidemoPlaying) {
        PrintToChat(client, "%s 当前没有播放任何回放", PREFIX);
        return;
    }
    g_bMinidemoPaused = !g_bMinidemoPaused;

    for (int idx = 0; idx < g_iMinidemoCount; ++idx) {
        if (g_bMinidemoBotsOn[idx] && g_bMinidemoPaused) {
            BotMimicFix_PauseMimicing(g_iMinidemoBots[idx]);
        }
        else if (g_bMinidemoBotsOn[idx] && !g_bMinidemoPaused) {
            BotMimicFix_ResumeMimicing(g_iMinidemoBots[idx]);
        }
    }
}