<?php
/**
 * 推送配置
 * 1) 先填 PUSH_APNS_BUNDLE = 签名后 Info.plist 里的 CFBundleIdentifier
 * 2) 想要「App 完全关闭也能收到」，必须配 p8：
 *    Apple Developer → Certificates, Identifiers & Profiles → Keys → 新建 Key
 *    勾选 Apple Push Notifications service (APNs) → 下载 AuthKey_XXXX.p8
 *    放到 Adminsdata/AuthKey.p8（目录已被 .htaccess 保护）
 * 3) 填好 Key ID、Team ID，把 PUSH_APNS_ENABLED 改 true
 * 不配 p8 也能用：走「收件箱轮询」，App 打开前台时拉取并本地弹通知。
 */
define('PUSH_APNS_ENABLED', false);
define('PUSH_APNS_KEY_ID', '');
define('PUSH_APNS_TEAM_ID', '');
define('PUSH_APNS_BUNDLE', 'com.xiao7.6778');
define('PUSH_APNS_P8', __DIR__ . '/Adminsdata/AuthKey.p8');
define('PUSH_APNS_ENV', 'production'); // production | development
