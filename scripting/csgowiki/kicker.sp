// kick player have no csgowiki account

public Action AutoKickerCallback(Handle timer, int client) {
    if (!IsPlayer(client))
        return Plugin_Handled;
    if (g_aPlayerStateBind[client] == e_bBinded) 
        return Plugin_Handled;
    char client_name[LENGTH_NAME];
    GetClientName(client, client_name, sizeof(client_name));
    KickClient(client, "请前往mycsgolab.com绑定steam账号（防止熊服），欢迎加入交流群：762993431");
    PrintToChatAll("%s 玩家[\x0F%s\x01] 由于未绑定csgolab账户而踢出", PREFIX, client_name);
    return Plugin_Handled;
}