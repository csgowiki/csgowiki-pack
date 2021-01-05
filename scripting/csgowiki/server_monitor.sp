// implement server monitor function
#include <smlib/general>
void getServerIp(char[] serverIp) {
    new ipVal = GetConVarInt(FindConVar("hostip"));
    LongToIP(ipVal, serverIp, LENGTH_IP);
}


public Action:Command_Test(client, args) {
    char serverIp[LENGTH_IP];
    getServerIp(serverIp);
    PrintToChat(client, "%s ip:%s", PREFIX, serverIp);
}