# CSGOWiki-Plugins
该仓库包含了一些依赖于www.csgowiki.top的插件，后续可能会添加进更多的插件，现有的插件也会提供更新。
# Requirements

- [sourcemod](https://www.sourcemod.net/downloads.php?branch=stable)1.9及以上

- [system2](https://github.com/dordnung/System2): 实现http和ftp等网络协议
- [sm-json](https://github.com/clugg/sm-json): 提供基于sourcemod的json操作

> 当前库中已整合以上两个插件api，若编译或运行失败可根据提供的插件api链接重新下载或更新环境。sourcemod环境需自行部署

# Download
[TODO]
## Installation
[TODO]
# Features

- 依赖于[csgowiki](www.csgowiki.top)网站，为该网站的附属功能
- 定时同步网站内所有当前地图和tick的道具
- 服务器内实时上传道具
- 指令控制功能开关
- 可以传送和被传送，更方便与朋友一起学习道具
- 服务器内实时对不合理道具进行举报
- 汉化practicemode插件

# Commands

## plugin: utility_helper

### Custom command

- `!wiki` 请求www.csgowiki.top相关api，获取网站内的道具合集并调出用户道具菜单
- `!last` 将用户传送至上一次`!wiki`选择的道具投掷点上
- `!report <description>` 举报上一次`!wiki`选择的道具，需要说明举报内容

### Admin command ('b' flag required)

- `!enable [wiki]` 不加参数为开启`utility_helper`和`utility_uploader`两个插件，加参数`wiki`为只开启`utility_helper`插件
- `!disable [wiki]`不加参数为关闭上述两个插件，加参数`wiki`为只关闭`utility_helper`插件

## plugin: utility_uploader

### Custom command

- `!submit [brief]` 开启道具上传模式，可选参数brief道具简介，可以通过`!list`查看历史上传记录
- `!list` 查看本次登录服务器后的所有道具上传记录，没有指定的brief显示为`空`
- `!tp <name>` 将自己传送到名为name的玩家(坐标和视角相同)，name支持正则匹配
- `!tphere <name>` 将名为name的玩家传送到自己位置(坐标和视角相同)，name支持正则匹配

### Admin command ('b' flag required)

- `!enable [upload]` 不加参数为开启`utility_helper`和`utility_uploader`两个插件，加参数`upload`为只开启`utility_upload`插件
- `!disable [upload]`不加参数为关闭上述两个插件，加参数`upload`为只关闭`utility_upload`插件

# Contributions

