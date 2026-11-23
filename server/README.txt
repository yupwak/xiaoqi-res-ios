小七资源库 · 消息推送补丁

放置位置（覆盖前先备份原 api.php）：
  api.php           -> 网站根目录/api.php          （已改好，直接覆盖）
  push_config.php   -> 网站根目录/push_config.php  （新文件）
  push_lib.php      -> 网站根目录/push_lib.php     （新文件）
  Admins/push.php   -> 网站根目录/Admins/push.php  （新文件，后台推送页）

后台入口：https://6778.top/Admins/push.php（登录后访问）

必做：nginx 的 action 白名单要放行新接口，否则会被 404 拦掉
  front: register_device, pull_messages
  admin: push_send, push_devices, push_delete_device, push_clear, push_preview

想要 App 完全关闭也能收到：编辑 push_config.php，填 Key ID / Team ID，
把 AuthKey_xxx.p8 放到 Adminsdata/AuthKey.p8，PUSH_APNS_ENABLED 改 true。
不配也能用：后台发的消息进收件箱，App 打开时拉取并本地弹通知。
