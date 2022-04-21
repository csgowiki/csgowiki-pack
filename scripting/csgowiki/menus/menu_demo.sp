
public Action Command_Demo(int client, any args) {
    if (g_iMinidemoStatus != e_Default) {
        PrintToChat(client, "%s \x02当前状态不可用", PREFIX);
        return;
    }
}