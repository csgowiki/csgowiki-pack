// menu collect

#include "csgowiki/menus/menu_wiki.sp"
#include "csgowiki/menus/menu_wikiop.sp"
#include "csgowiki/menus/menu_option.sp"
#include "csgowiki/menus/menu_wikipro.sp"

public Action:Command_Panel(client, args) {
    Panel panel = new Panel();

    panel.SetTitle("CSGOWiki操作面板")

    panel.DrawItem("社区道具合集[!wiki]");
    panel.DrawItem("职业道具合集[!wikipro]");
    panel.DrawItem("道具能力测试[!wikiquiz]", ITEMDRAW_DISABLED);
    panel.DrawText("   ");
    panel.DrawItem("道具上传[!submit]");
    panel.DrawItem("道具反馈[!feedback]", ITEMDRAW_DISABLED);
    panel.DrawText("   ");
    panel.DrawItem("第三方插件面板[!wikidiy]", ITEMDRAW_DISABLED);
    panel.DrawItem("个人偏好设置[!option]");
    panel.DrawItem("管理员工具[!wikiop]");
    panel.DrawText("   ");
    panel.DrawItem("退出", ITEMDRAW_CONTROL);
    
    panel.Send(client, PanelHandler, MENU_TIME_FOREVER);

    delete panel;
    return Plugin_Handled;
}

public PanelHandler(Handle:menu, MenuAction:action, client, Position) {
    if (action == MenuAction_Select) {
        switch(Position) {
            case 1: ClientCommand(client, "sm_wiki");
            case 2: ClientCommand(client, "sm_wikipro");
            case 3: ClientCommand(client, "sm_wikitest");
            case 4: ClientCommand(client, "sm_submit"), ClientCommand(client, "sm_m");
            case 5: ClientCommand(client, "sm_feedback");
            case 6: ClientCommand(client, "sm_wikidiy");
            case 7: ClientCommand(client, "sm_option");
            case 8: ClientCommand(client, "sm_wikiop");
            case 9: CloseHandle(menu);
        }
    }
}