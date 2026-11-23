<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/push_lib.php';
security_headers();
if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') json_not_found();
$source = $_POST['source'] ?? 'front';
$action = $_POST['action'] ?? '';
if ($source === 'admin' && !admin_ip_allowed()) json_not_found();
session_guard();
$is_admin = isset($_SESSION['admin_logged']) && $_SESSION['admin_logged'] === true;
if ($source !== 'front' && $source !== 'admin') json_not_found();
$front_actions = ['get_data', 'track_visit', 'track_download', 'add_download', 'register_device', 'pull_messages'];
$admin_actions = ['login', 'logout', 'change_credentials', 'get_stats', 'reset_stats',
    'save_settings', 'get_carousel', 'save_carousel', 'delete_carousel',
    'get_tags', 'save_tags', 'get_apps', 'save_app', 'delete_app', 'get_data',
    'push_send', 'push_devices', 'push_delete_device', 'push_clear', 'push_preview'];
$allowed = $source === 'admin' ? $admin_actions : $front_actions;
if (!in_array($action, $allowed, true)) json_not_found();
if ($source === 'admin' && !in_array($action, ['login', 'logout'], true) && !$is_admin) {
    json_response(401, null, '请先登录');
}
if ($source === 'admin' && $action !== 'login') {
    $csrf_in = (string)($_POST['csrf'] ?? '');
    $csrf_sess = (string)($_SESSION['csrf'] ?? '');
    if ($csrf_sess === '' || $csrf_in === '' || !hash_equals($csrf_sess, $csrf_in)) {
        json_response(401, null, '会话已失效，请刷新页面');
    }
}
if ($source === 'front') {
    if ($action === 'register_device') {
        $token = strtolower(trim((string)($_POST['token'] ?? '')));
        if ($token === '') json_response(1, null, '缺少 token');
        $ok = push_register($token, [
            'platform' => clean_text($_POST['platform'] ?? 'ios', 16),
            'model'    => clean_text($_POST['model'] ?? '', 64),
            'name'     => clean_text($_POST['name'] ?? '', 64),
            'bundle'   => clean_text($_POST['bundle'] ?? '', 64),
            'version'  => clean_text($_POST['version'] ?? '', 32)
        ]);
        if (!$ok) json_response(1, null, 'token 格式不对');
        json_response(0, ['total' => count(push_devices())], 'ok');
    }
    if ($action === 'pull_messages') {
        $token = strtolower(trim((string)($_POST['token'] ?? '')));
        if ($token === '') json_response(1, null, '缺少 token');
        json_response(0, ['messages' => push_messages_for($token)]);
    }
    if ($action === 'get_data') {
        $apps_out = [];
        foreach ($apps as $app) {
            $apps_out[] = [
                'id' => $app['id'],
                'name' => $app['name'],
                'tag' => $app['tag'],
                'tag_name' => $app['tag_name'] ?? '',
                'desc' => $app['desc'] ?? '',
                'icon' => img_url($app['icon'] ?? ''),
                'screenshots' => array_map('img_url', $app['screenshots'] ?? []),
                'download_url' => $app['download_url'] ?? '',
                'detail' => $app['detail'] ?? '',
                'system_req' => $app['system_req'] ?? 'iOS 16+',
                'is_top' => $app['is_top'] ?? false,
                'no_track' => $app['no_track'] ?? false,
                'sort' => $app['sort'] ?? 0,
                'click_count' => $app['click_count'] ?? 0,
                'download_count' => $app['download_count'] ?? 0
            ];
        }
        usort($apps_out, function($a, $b) {
            if ($a['is_top'] != $b['is_top']) return $b['is_top'] - $a['is_top'];
            return ($a['sort'] ?? 0) - ($b['sort'] ?? 0);
        });
        $carousel_out = [];
        foreach ($carousel as $c) {
            $carousel_out[] = [
                'id' => $c['id'],
                'image' => img_url($c['image'] ?? ''),
                'link_type' => $c['link_type'] ?? 'none',
                'link_value' => $c['link_value'] ?? '',
                'resource_id' => $c['resource_id'] ?? 0
            ];
        }
        usort($carousel_out, function($a, $b) { return ($a['sort'] ?? 0) - ($b['sort'] ?? 0); });
        $tags_out = array_values(array_filter($tags, function($t) { return $t['value'] !== 'all'; }));
        usort($tags_out, function($a, $b) { return ($a['sort'] ?? 0) - ($b['sort'] ?? 0); });
        json_response(0, ['settings' => $settings, 'carousel' => $carousel_out, 'apps' => $apps_out, 'tags' => $tags_out]);
    }
    if ($action === 'track_visit') {
        $ip = get_client_ip();
        $today = date('Y-m-d');
        if (($stats['last_visit_date'] ?? '') !== $today) { $stats['today_visits'] = 0; $stats['last_visit_date'] = $today; }
        if (($stats['last_download_date'] ?? '') !== $today) { $stats['today_downloads'] = 0; $stats['last_download_date'] = $today; }
        $ip_visits = $stats['ip_visits'] ?? [];
        $key = $ip . '_' . $today;
        if (!isset($ip_visits[$key])) { $ip_visits[$key] = true; $stats['today_visits']++; $stats['total_visits']++; }
        $cutoff = date('Y-m-d', strtotime('-3 days'));
        foreach ($ip_visits as $k => $v) {
            if (strpos($k, '_') !== false) { $d = explode('_', $k)[1] ?? ''; if ($d < $cutoff) unset($ip_visits[$k]); }
        }
        $stats['ip_visits'] = $ip_visits;
        save_json('stats', $stats);
        json_response(0, ['total_visits' => $stats['total_visits'], 'today_visits' => $stats['today_visits']]);
    }
    if ($action === 'track_download') {
        $app_id = (int)($_POST['app_id'] ?? 0);
        if ($app_id <= 0) json_not_found();
        $ip = get_client_ip();
        $today = date('Y-m-d');
        if (($stats['last_download_date'] ?? '') !== $today) { $stats['today_downloads'] = 0; $stats['last_download_date'] = $today; }
        $app_no_track = false;
        foreach ($apps as $app) { if ($app['id'] == $app_id && !empty($app['no_track'])) { $app_no_track = true; break; } }
        if ($app_no_track) json_response(0, ['msg' => 'no_track']);
        $ip_downloads = $stats['ip_downloads'] ?? [];
        $key = $ip . '_' . $app_id . '_' . $today;
        if (!isset($ip_downloads[$key])) { $ip_downloads[$key] = true; $stats['today_downloads']++; $stats['total_downloads']++; }
        $cutoff = date('Y-m-d', strtotime('-3 days'));
        foreach ($ip_downloads as $k => $v) {
            $parts = explode('_', $k);
            if (count($parts) >= 3) { $d = $parts[count($parts) - 1]; if ($d < $cutoff) unset($ip_downloads[$k]); }
        }
        $stats['ip_downloads'] = $ip_downloads;
        foreach ($apps as &$app) { if ($app['id'] == $app_id) { $app['click_count'] = ($app['click_count'] ?? 0) + 1; break; } }
        unset($app);
        save_json('apps', $apps);
        save_json('stats', $stats);
        json_response(0, ['total_downloads' => $stats['total_downloads'], 'today_downloads' => $stats['today_downloads']]);
    }
    if ($action === 'add_download') {
        $rid = (int)($_POST['rid'] ?? 0);
        if ($rid <= 0) json_not_found();
        $ip = get_client_ip();
        $exists = false;
        foreach ($download_logs as $log) {
            if (($log['ip'] ?? '') === $ip && (int)($log['resource_id'] ?? 0) === $rid) { $exists = true; break; }
        }
        if (!$exists) {
            $next_id = 1;
            foreach ($download_logs as $log) { if ((int)($log['id'] ?? 0) >= $next_id) $next_id = (int)$log['id'] + 1; }
            $download_logs[] = ['id' => $next_id, 'ip' => $ip, 'resource_id' => $rid, 'create_time' => date('Y-m-d H:i:s')];
            save_json('download_logs', $download_logs);
            foreach ($apps as &$app) {
                if ($app['id'] == $rid) { $app['download_count'] = ($app['download_count'] ?? 0) + 1; break; }
            }
            unset($app);
            save_json('apps', $apps);
        }
        json_response(0, null, 'ok');
    }
}
if ($source === 'admin') {
    if ($action === 'push_send') {
        $title = clean_text($_POST['title'] ?? '', 120);
        $body  = clean_text($_POST['body'] ?? '', 500);
        $appId = (int)($_POST['app_id'] ?? 0);
        $url   = clean_text($_POST['url'] ?? '', 300);
        if ($title === '' || $body === '') json_response(1, null, '标题和内容不能为空');
        $item = push_enqueue($title, $body, $appId, $url);
        $delivery = push_deliver($title, $body, $appId, $url);
        json_response(0, ['item' => $item, 'delivery' => $delivery], 'ok');
    }
    if ($action === 'push_devices') {
        $list = [];
        foreach (push_devices() as $d) {
            $list[] = [
                'token' => $d['token'],
                'short' => substr($d['token'], 0, 10) . '…' . substr($d['token'], -6),
                'model' => $d['model'] ?? '',
                'name' => $d['name'] ?? '',
                'version' => $d['version'] ?? '',
                'last_seen' => $d['last_seen'] ?? 0
            ];
        }
        usort($list, function($a, $b) { return ($b['last_seen'] ?? 0) - ($a['last_seen'] ?? 0); });
        json_response(0, ['devices' => $list, 'total' => count($list), 'apns' => PUSH_APNS_ENABLED]);
    }
    if ($action === 'push_delete_device') {
        $token = strtolower(trim((string)($_POST['token'] ?? '')));
        $list = array_values(array_filter(push_devices(), function($d) use ($token) {
            return ($d['token'] ?? '') !== $token;
        }));
        push_save_devices($list);
        json_response(0, ['total' => count($list)], 'ok');
    }
    if ($action === 'push_clear') {
        save_json('push_messages', []);
        json_response(0, null, 'ok');
    }
    if ($action === 'push_preview') {
        json_response(0, ['messages' => array_slice(push_messages(), 0, 20)]);
    }
    if ($action === 'get_data') {
        $apps_out = [];
        foreach ($apps as $app) {
            $apps_out[] = [
                'id' => $app['id'],
                'name' => $app['name'],
                'tag' => $app['tag'],
                'tag_name' => $app['tag_name'] ?? '',
                'desc' => $app['desc'] ?? '',
                'icon' => img_url($app['icon'] ?? ''),
                'screenshots' => array_map('img_url', $app['screenshots'] ?? []),
                'download_url' => $app['download_url'] ?? '',
                'detail' => $app['detail'] ?? '',
                'system_req' => $app['system_req'] ?? 'iOS 16+',
                'is_top' => $app['is_top'] ?? false,
                'no_track' => $app['no_track'] ?? false,
                'sort' => $app['sort'] ?? 0,
                'click_count' => $app['click_count'] ?? 0,
                'download_count' => $app['download_count'] ?? 0
            ];
        }
        usort($apps_out, function($a, $b) {
            if ($a['is_top'] != $b['is_top']) return $b['is_top'] - $a['is_top'];
            return ($a['sort'] ?? 0) - ($b['sort'] ?? 0);
        });
        $carousel_out = [];
        foreach ($carousel as $c) {
            $carousel_out[] = [
                'id' => $c['id'],
                'image' => img_url($c['image'] ?? ''),
                'link_type' => $c['link_type'] ?? 'none',
                'link_value' => $c['link_value'] ?? '',
                'resource_id' => $c['resource_id'] ?? 0
            ];
        }
        usort($carousel_out, function($a, $b) { return ($a['sort'] ?? 0) - ($b['sort'] ?? 0); });
        $tags_out = array_values(array_filter($tags, function($t) { return $t['value'] !== 'all'; }));
        usort($tags_out, function($a, $b) { return ($a['sort'] ?? 0) - ($b['sort'] ?? 0); });
        json_response(0, ['settings' => $settings, 'carousel' => $carousel_out, 'apps' => $apps_out, 'tags' => $tags_out]);
    }
    if ($action === 'login') {
        $ip = get_client_ip();
        $lock = login_locked_seconds($ip);
        if ($lock > 0) json_response(1, null, '尝试次数过多，请 ' . ceil($lock / 60) . ' 分钟后再试');
        $username = clean_text($_POST['username'] ?? '', 32);
        $password = (string)($_POST['password'] ?? '');
        $captcha = strtoupper(trim($_POST['captcha'] ?? ''));
        $need_captcha = captcha_available();
        if ($username === '' || $password === '' || ($need_captcha && $captcha === '')) json_response(1, null, '请填写完整信息');
        if ($need_captcha) {
            $captcha_stored = $_SESSION['captcha'] ?? '';
            $captcha_time = (int)($_SESSION['captcha_time'] ?? 0);
            unset($_SESSION['captcha'], $_SESSION['captcha_time']);
            if ($captcha_stored === '' || !hash_equals(strtoupper((string)$captcha_stored), $captcha)) {
                record_login_fail($ip);
                audit_log('login_fail', 'captcha');
                json_response(1, null, '验证码错误');
            }
            if (time() - $captcha_time > 300) {
                audit_log('login_fail', 'captcha_expired');
                json_response(1, null, '验证码已过期，请刷新');
            }
        }
        $admin = load_json(ADMIN_CRED_FILE, [], ADMIN_DATA_DIR);
        $hash = (string)($admin['password'] ?? '');
        if ($hash === '') $hash = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi';
        $pass_ok = password_verify($password, $hash);
        if (!hash_equals((string)($admin['username'] ?? ''), $username) || !$pass_ok) {
            record_login_fail($ip);
            audit_log('login_fail', 'credential');
            json_response(1, null, '账号或密码错误');
        }
        session_regenerate_id(true);
        $_SESSION['admin_logged'] = true;
        $_SESSION['admin_username'] = $admin['username'];
        $_SESSION['last_active'] = time();
        $_SESSION['csrf'] = bin2hex(random_bytes(32));
        clear_login_fails($ip);
        audit_log('login_ok', $admin['username']);
        json_response(0, ['username' => $admin['username']], '登录成功');
    }
    if ($action === 'logout') {
        audit_log('logout', (string)($_SESSION['admin_username'] ?? ''));
        $_SESSION = [];
        if (ini_get('session.use_cookies')) {
            $p = session_get_cookie_params();
            setcookie(session_name(), '', time() - 42000, $p['path'], $p['domain'], $p['secure'], $p['httponly']);
        }
        session_destroy();
        json_response(0, null, '已退出');
    }
    if ($action === 'change_credentials') {
        $old_user = clean_text($_POST['old_username'] ?? '', 32);
        $old_pass = (string)($_POST['old_password'] ?? '');
        $new_user = clean_text($_POST['new_username'] ?? '', 32);
        $new_pass = (string)($_POST['new_password'] ?? '');
        $admin = load_json(ADMIN_CRED_FILE, [], ADMIN_DATA_DIR);
        if ($old_user === '' || $old_pass === '') json_response(1, null, '请输入原账号和密码');
        if (!hash_equals((string)($admin['username'] ?? ''), $old_user) || !password_verify($old_pass, (string)($admin['password'] ?? ''))) {
            audit_log('cred_change_fail', 'old_credential');
            json_response(1, null, '原账号或密码错误');
        }
        if ($new_user === '' && $new_pass === '') json_response(1, null, '新账号和新密码至少填写一项');
        if ($new_pass !== '' && (strlen($new_pass) < 8 || strlen($new_pass) > 64)) json_response(1, null, '新密码长度需为8-64位');
        if ($new_user !== '') $admin['username'] = $new_user;
        if ($new_pass !== '') $admin['password'] = password_hash($new_pass, PASSWORD_DEFAULT);
        $admin['updated_at'] = date('Y-m-d H:i:s');
        save_json(ADMIN_CRED_FILE, $admin, ADMIN_DATA_DIR);
        $_SESSION['admin_username'] = $admin['username'];
        session_regenerate_id(true);
        audit_log('cred_changed', 'username=' . $admin['username']);
        json_response(0, null, '账号密码已修改');
    }
    if ($action === 'get_stats') {
        $today = date('Y-m-d');
        $s = $stats;
        if (($s['last_visit_date'] ?? '') !== $today) $s['today_visits'] = 0;
        if (($s['last_download_date'] ?? '') !== $today) $s['today_downloads'] = 0;
        $total_dl = 0;
        $dl_list = [];
        foreach ($apps as $a) {
            $dc = (int)($a['download_count'] ?? 0);
            $total_dl += $dc;
            $dl_list[] = ['name' => $a['name'], 'download_count' => $dc];
        }
        usort($dl_list, function($a, $b) { return $b['download_count'] - $a['download_count']; });
        json_response(0, ['total_visits' => $s['total_visits'] ?? 0, 'today_visits' => $s['today_visits'] ?? 0, 'total_downloads' => $s['total_downloads'] ?? 0, 'today_downloads' => $s['today_downloads'] ?? 0, 'total_resource_downloads' => $total_dl, 'top_downloads' => $dl_list]);
    }
    if ($action === 'reset_stats') {
        save_json('stats', ['total_visits' => 0, 'today_visits' => 0, 'last_visit_date' => date('Y-m-d'), 'total_downloads' => 0, 'today_downloads' => 0, 'last_download_date' => date('Y-m-d'), 'ip_visits' => [], 'ip_downloads' => []]);
        json_response(0, null, '统计已重置');
    }
    if ($action === 'save_settings') {
        $web_title = clean_text($_POST['web_title'] ?? 'Resource', 100);
        $home_title = clean_text($_POST['home_title'] ?? 'Resource', 100);
        $search_placeholder = clean_text($_POST['search_placeholder'] ?? '搜索资源...', 100);
        if ($web_title === '') $web_title = 'Resource';
        if ($home_title === '') $home_title = 'Resource';
        $settings['web_title'] = $web_title;
        $settings['home_title'] = $home_title;
        $settings['search_placeholder'] = $search_placeholder;
        if (!empty($_FILES['apple_icon_file']['tmp_name'])) {
            $path = handle_upload($_FILES['apple_icon_file'], 'icons');
            if ($path) {
                delete_image($settings['apple_icon'] ?? '');
                $settings['apple_icon'] = $path;
            }
        }
        save_json('settings', $settings);
        json_response(0, null, '保存成功');
    }
    if ($action === 'get_carousel') json_response(0, $carousel);
    if ($action === 'save_carousel') {
        $id = (int)($_POST['id'] ?? 0);
        $link_type = $_POST['link_type'] ?? 'none';
        if (!in_array($link_type, ['none', 'app', 'http'], true)) json_not_found();
        $link_value = trim($_POST['link_value'] ?? '');
        if ($link_type === 'app') {
            $link_value = (string)(int)$link_value;
            $exists = false;
            foreach ($apps as $a) if ((string)$a['id'] === $link_value) { $exists = true; break; }
            if (!$exists) json_response(1, null, '跳转应用不存在');
        } elseif ($link_type === 'http') {
            if (!is_http_url($link_value)) json_response(1, null, '跳转链接必须是 http(s) 开头的有效网址');
        } else {
            $link_value = '';
        }
        $item = ['id' => $id ?: time(), 'image' => '', 'link_type' => $link_type, 'link_value' => $link_value, 'resource_id' => (int)($_POST['resource_id'] ?? 0), 'sort' => (int)($_POST['sort'] ?? 0)];
        if (!empty($_FILES['image_file']['tmp_name'])) { $path = handle_upload($_FILES['image_file'], 'carousel'); if ($path) $item['image'] = $path; }
        elseif (!empty($_POST['image_url'])) {
            $url = trim($_POST['image_url']);
            if (!is_http_url($url)) json_response(1, null, '图片地址必须是 http(s) 开头的有效网址');
            $item['image'] = $url;
        }
        if ($id) {
            $found = false;
            foreach ($carousel as &$c) { if ($c['id'] == $id) { if (empty($item['image'])) $item['image'] = $c['image']; $c = $item; $found = true; break; } }
            unset($c);
            if (!$found) json_not_found();
        } else {
            if (empty($item['image'])) json_response(1, null, '请上传图片');
            $carousel[] = $item;
        }
        save_json('carousel', $carousel);
        json_response(0, null, '保存成功');
    }
    if ($action === 'delete_carousel') {
        $id = (int)($_POST['id'] ?? 0);
        if ($id <= 0) json_not_found();
        $done = false;
        foreach ($carousel as $i => $c) { if ($c['id'] == $id) { delete_image($c['image'] ?? ''); array_splice($carousel, $i, 1); $done = true; break; } }
        if (!$done) json_not_found();
        save_json('carousel', $carousel);
        json_response(0, null, '已删除');
    }
    if ($action === 'get_tags') json_response(0, $tags);
    if ($action === 'save_tags') {
        $in = json_decode($_POST['tags'] ?? '[]', true);
        if (!is_array($in)) json_response(1, null, '数据格式错误');
        $out = [];
        foreach ($in as $t) {
            if (!is_array($t)) continue;
            $id = (int)($t['id'] ?? 0);
            $name = clean_text($t['name'] ?? '', 20);
            $value = (string)($t['value'] ?? '');
            $sort = (int)($t['sort'] ?? 0);
            if ($name === '' || !is_ident($value, 30)) json_response(1, null, '标签名称和标识值不合法（标识值只能用字母数字下划线）');
            $out[] = ['id' => $id ?: time(), 'name' => $name, 'value' => $value, 'sort' => $sort];
        }
        $has_all = false;
        foreach ($out as $t) { if ($t['value'] === 'all') { $has_all = true; break; } }
        if (!$has_all) array_unshift($out, ['id' => 1, 'name' => '全部', 'value' => 'all', 'sort' => 0]);
        save_json('tags', $out);
        json_response(0, null, '保存成功');
    }
    if ($action === 'get_apps') json_response(0, $apps);
    if ($action === 'save_app') {
        $id = (int)($_POST['id'] ?? 0);
        $name = clean_text($_POST['name'] ?? '', 80);
        $tag = (string)($_POST['tag'] ?? '');
        $tag_name = clean_text($_POST['tag_name'] ?? '', 30);
        $desc = clean_text($_POST['desc'] ?? '', 200);
        $download_url = trim($_POST['download_url'] ?? '');
        $detail = clean_text($_POST['detail'] ?? '', 10000);
        $system_req = clean_text($_POST['system_req'] ?? 'iOS 16+', 50);
        if (!is_ident($tag, 30)) json_response(1, null, '标签分类不合法');
        if (!is_http_url($download_url)) json_response(1, null, '下载链接必须是 http(s) 开头的有效网址');
        $item = ['id' => $id ?: time(), 'name' => $name, 'tag' => $tag, 'tag_name' => $tag_name, 'desc' => $desc, 'icon' => '', 'screenshots' => [], 'download_url' => $download_url, 'detail' => $detail, 'system_req' => $system_req, 'is_top' => !empty($_POST['is_top']), 'no_track' => !empty($_POST['no_track']), 'sort' => (int)($_POST['sort'] ?? 0), 'click_count' => 0, 'download_count' => 0];
        $old = null;
        if ($id) { foreach ($apps as $a) { if ($a['id'] == $id) { $old = $a; break; } } if (!$old) json_not_found(); $item['click_count'] = $old['click_count'] ?? 0; $item['download_count'] = $old['download_count'] ?? 0; $item['icon'] = $old['icon'] ?? ''; $item['screenshots'] = $old['screenshots'] ?? []; }
        if (!empty($_FILES['icon_file']['tmp_name'])) { $path = handle_upload($_FILES['icon_file'], 'icons'); if ($path) { delete_image($item['icon']); $item['icon'] = $path; } }
        elseif (!empty($_POST['icon_url'])) {
            $url = trim($_POST['icon_url']);
            if (!is_http_url($url)) json_response(1, null, '图标地址必须是 http(s) 开头的有效网址');
            delete_image($item['icon']); $item['icon'] = $url;
        }
        $screenshots = $item['screenshots'];
        if (!empty($_FILES['screenshot_files']['tmp_name'][0])) {
            foreach ($screenshots as $s) delete_image($s);
            $screenshots = [];
            foreach ($_FILES['screenshot_files']['tmp_name'] as $i => $tmp) {
                if ($_FILES['screenshot_files']['error'][$i] !== UPLOAD_ERR_OK) continue;
                $f = ['tmp_name' => $tmp, 'error' => $_FILES['screenshot_files']['error'][$i]];
                $path = handle_upload($f, 'screenshots');
                if ($path) $screenshots[] = $path;
            }
        }
        if (!empty($_POST['screenshot_urls'])) {
            $urls = json_decode($_POST['screenshot_urls'], true);
            if (is_array($urls)) { foreach ($urls as $u) { $u = trim((string)$u); if ($u) { if (!is_http_url($u)) json_response(1, null, '截图地址必须是 http(s) 开头的有效网址'); $screenshots[] = $u; } } }
        }
        $item['screenshots'] = array_values(array_unique($screenshots));
        if ($id) { foreach ($apps as &$a) { if ($a['id'] == $id) { $a = $item; break; } } unset($a); }
        else { if ($name === '') json_response(1, null, '请填写应用名称'); $apps[] = $item; }
        save_json('apps', $apps);
        json_response(0, null, '保存成功');
    }
    if ($action === 'delete_app') {
        $id = (int)($_POST['id'] ?? 0);
        if ($id <= 0) json_not_found();
        $done = false;
        foreach ($apps as $i => $a) { if ($a['id'] == $id) { delete_image($a['icon'] ?? ''); foreach (($a['screenshots'] ?? []) as $s) delete_image($s); array_splice($apps, $i, 1); $done = true; break; } }
        if (!$done) json_not_found();
        save_json('apps', $apps);
        json_response(0, null, '已删除');
    }
}
?>
