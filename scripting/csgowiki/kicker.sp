// kick player have no csgowiki account

public Action:AutoKickerCallback(Handle timer, client) {
    if (g_aPlayerStateBind[client] == e_bBinded) 
        return Plugin_Handled;
    char client_name[LENGTH_NAME];
    GetClientName(client, client_name, sizeof(client_name));
    KickClient(client, "你没有绑定csgowiki账号，根据设置被踢出服务器");
    PrintToChatAll("%s 玩家[\x0F%s\x01] 由于未绑定csgowiki账户而踢出", PREFIX, client_name);
    return Plugin_Handled;
}