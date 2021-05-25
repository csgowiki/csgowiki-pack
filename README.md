# CSGOWiki-Pack
`csgowiki-pack`插件服务于[csgowiki](https://csgowiki.top)网站，插件的正常运作需要csgowiki的账号，如果你没有，那么请先前往网站注册。

# Install | 安装

1. 安装环境：[sourcemod](https://www.sourcemod.net/downloads.php?branch=stable) (v1.10以上) 

    > sourcemod 基础环境

2. 安装运行依赖：[system2](https://forums.alliedmods.net/showthread.php?t=146019) (必须) 

    > 实现http/https等网络通信

3. 安装插件依赖：[csgo-practice-mode](https://github.com/splewis/csgo-practice-mode) (必须)
    > 启用练习环境

4. 安装编译依赖：[sm-json](https://github.com/clugg/sm-json) (不必须，编译时需要) 

    > 实现基于sourcemod的json操作

5. 下载 [csgowiki-pack.zip](https://github.com/hx-w/CSGOWiki-Plugins/releases/)，解压，编辑`cfg/sourcemod/csgowiki-pack.cfg`文件

    > 参考[CFG | 配置]，`sm_csgowiki_token`一项必填

6. 将`addons/`与`cfg/`拖拽至`csgo/`目录下即可

### 注意

本插件只有`csgowiki-pack.smx`一项编译文件，如果你以前安装过csgowiki老版本的插件，请手动**卸载**：

- `utility_helper.smx`
- `utility_uploader.smx`
- `server_monitor.smx`
- `steambind.smx`

老版本的插件都归档在[[archive](https://github.com/hx-w/CSGOWiki-Plugins/tree/master/archive)]里，大部分已失效。

# Features | 特性

- [x] 服务器在线玩家信息监视功能(玩家昵称，steamid，ping)
- [x] 网站账号绑定功能
- [x] 捕捉游戏内玩家动作，并上传道具至网站
- [x] 获取网站道具记录，并将玩家传送至投掷点，更好地学习道具
- [x] 搜索玩家附近的网站道具记录
- [x] Lv4玩家在服务器内修改道具数据
- [x] `Hint Text`颜色乱码修复
- [x] 只有一项编译文件，更合理的插件结构
- [x] 实现游戏服务器与qq群之间信息互通
- [x] 自动投掷记录的道具

# Setup | 配置与指令

## CFG | 配置

文件：`cfg/sourcemod/csgowiki-pack.cfg`

| 指令                    | 取值     | 备注                                                         | 等级限制                                                |
| ----------------------- | -------- | ------------------------------------------------------------ | ------------------------------------------------------- |
| `sm_csgowiki_enable`    | 0/1      | 插件功能总开关                                               | 无                                                      |
| `sm_csgowiki_token`     | 字符串   | csgowiki用户token，不要泄露，前往[csgowiki](https://www.csgowiki.top/profile/revise/)获取 | 无                                                      |
| `sm_utility_submit_on`  | 0/1      | 道具上传功能开关                                             | >=Lv3                                                   |
| `sm_utility_wiki_on`    | 0/1      | 道具学习功能开关                                             | 见[请求次数限制](https://www.csgowiki.top/profile/exp/) |
| `sm_wiki_request_limit` | 0.0~10.0 | `!wiki`请求冷却时间(秒)，默认1.0s，设置0为不限制冷却时间     | 无                                                      |
| `sm_qqchat_enable`      | 0/1      | qqchat功能开关                                       | 无                                                      |
| `sm_qqchat_remark`      | 字符串   | 服务器的备注，显示在qq群里消息的前缀 **不要包含空格**                        | 无                                                      |
| `sm_qqchat_qqgroup`     | 字符串   | 指定的qq群号，一个服务器只能指定一个                         | 无                                                      |
| `sm_wiki_auto_kick`     | 0.0~10.0 | 未绑定csgowiki的账号在服务器的时间(分钟)，超出改时间会将玩家踢出服务器。设置为0为不开启(不建议开启) | 无                                                      |

## Command | 命令

- `/bsteam <token>`  绑定csgowiki账号，方法见：[绑定steam](https://www.csgowiki.top/login/steambind/)

    > 注意用`/`开头，可以不在聊天栏中回显指令，防止token泄露。也可以在**控制台**输入`sm_bsteam <token>`，效果相同

- `!submit` 上传道具至csgowiki，方法见：[道具上传方法](https://www.csgowiki.top/utility/contribute/)

    > 上传道具时先**瞄准好瞄点**，再**输入指令**。快速双击`E`同样可以触发该指令

- `!abort` 终止道具上传流程

- `!wiki <id>` 呼出道具合集菜单/传送至指定道具位置

    > 道具id可选，如果输入id则可以直接传送至该道具所在地点(方便管理员审核道具)，如果不输入则呼出道具合集菜单

- `/modify <token>` 修改某一道具的数据

    > 修改通过`!wiki`传送到的上一个道具记录，要求等级>=Lv4，修改流程与上传道具相同
    
- `!qq <内容>` 可以向`sm_qqchat_qqgroup`指定的qq群里发送消息

## qqchat | qq群聊功能

1. 申请添加csgowiki官方的qq机器人：`qq2823195212`，验证消息输入：`8802`
2. 将机器人邀请进入群聊
3. 开启`sm_qqchat_enable 1`，设置qq群号`sm_qqchat_qqgroup xxx`和服务器备注`sm_qqchat_remark xxx`
4. 在服务器内使用`!qq <内容>`向qq群发消息，在qq群内at机器人向服务器发消息

**注意**

1. qq机器人为csgowiki提供，不会在你的群里收集信息，如果出现问题联系csgowiki站长，解释权归csgowiki所有
2. 目前支持的额外功能还有：
    - `@bot 状态` 查看服务器内在线人数
    - 开发中...

# Contributions | 贡献

如果你对本项目有一些想法，欢迎提交`issue`与我讨论。

欢迎提交pr。
