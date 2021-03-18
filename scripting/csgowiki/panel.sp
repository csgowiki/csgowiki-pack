// menu collect

#include "csgowiki/menus/menu_wiki.sp"


public Action:Command_Panel(client, args) {
    Panel panel = new Panel();

    panel.SetTitle("CSGOWiki操作面板")

    panel.DrawItem("社区道具合集[!wiki]");
    panel.DrawItem("职业道具合集[!wikipro]");
    panel.DrawItem("道具能力测试[!wikitest]", ITEMDRAW_DISABLED);
    panel.DrawText("   ");
    panel.DrawItem("道具上传[!submit]");
    panel.DrawItem("道具反馈[!feedback]", ITEMDRAW_DISABLED);
    panel.DrawText("   ");
    panel.DrawItem("第三方插件面板", ITEMDRAW_DISABLED);
    panel.DrawItem("个人偏好设置[!option]", ITEMDRAW_DISABLED);
    panel.DrawItem("管理员工具[!wikiop]", ITEMDRAW_DISABLED);
    panel.Send(client, PanelHandler, MENU_TIME_FOREVER);

    delete panel;
    return Plugin_Handled;
}

public PanelHandler(Menu menu, MenuAction action, client, Position) {
    if (action == MenuAction_Select) {
        PrintToChat(client, "select pos: %d", Position);
    }
    else if (action == MenuAction_Cancel) {

    }
}