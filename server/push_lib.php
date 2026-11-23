<?php
require_once __DIR__ . '/push_config.php';

function push_b64url($data) {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function push_der_to_raw($der, $len = 32) {
    if (strlen($der) < 8 || ord($der[0]) !== 0x30) return null;
    $offset = 2;
    if (ord($der[1]) & 0x80) $offset = 2 + (ord($der[1]) & 0x7f);
    $out = '';
    for ($i = 0; $i < 2; $i++) {
        if (!isset($der[$offset]) || ord($der[$offset]) !== 0x02) return null;
        $l = ord($der[$offset + 1]);
        $v = substr($der, $offset + 2, $l);
        $offset += 2 + $l;
        $v = ltrim($v, "\x00");
        $v = str_pad($v, $len, "\x00", STR_PAD_LEFT);
        if (strlen($v) > $len) $v = substr($v, -$len);
        $out .= $v;
    }
    return $out;
}

function push_apns_jwt() {
    static $cached = null, $cachedAt = 0;
    if ($cached !== null && (time() - $cachedAt) < 2400) return $cached;
    if (!defined('PUSH_APNS_KEY_ID') || PUSH_APNS_KEY_ID === '' || PUSH_APNS_TEAM_ID === '') return null;
    if (!file_exists(PUSH_APNS_P8)) return null;
    $header = ['alg' => 'ES256', 'kid' => PUSH_APNS_KEY_ID];
    $claims = ['iss' => PUSH_APNS_TEAM_ID, 'iat' => time()];
    $input = push_b64url(json_encode($header)) . '.' . push_b64url(json_encode($claims));
    $pem = @file_get_contents(PUSH_APNS_P8);
    if ($pem === false) return null;
    $key = @openssl_pkey_get_private($pem);
    if (!$key) return null;
    $sig = '';
    if (!@openssl_sign($input, $sig, $key, OPENSSL_ALGO_SHA256)) return null;
    $raw = push_der_to_raw($sig, 32);
    if ($raw === null) return null;
    $cached = $input . '.' . push_b64url($raw);
    $cachedAt = time();
    return $cached;
}

function push_devices() { return load_json('push_devices', []); }
function push_save_devices($list) { return save_json('push_devices', $list); }

function push_register($token, $extra = []) {
    $token = strtolower(trim((string)$token));
    if (!preg_match('/^[a-f0-9]{64,220}$/', $token)) return false;
    $list = push_devices();
    $now = time();
    foreach ($list as $i => $d) {
        if (($d['token'] ?? '') === $token) {
            $list[$i] = array_merge($d, $extra, ['last_seen' => $now]);
            push_save_devices($list);
            return true;
        }
    }
    $list[] = array_merge([
        'token' => $token, 'platform' => 'ios', 'ts' => $now, 'last_seen' => $now, 'seen_ts' => 0
    ], $extra);
    push_save_devices($list);
    return true;
}

function push_messages() { return load_json('push_messages', []); }

function push_enqueue($title, $body, $appId = 0, $url = '') {
    $list = push_messages();
    $item = [
        'id' => date('YmdHis') . '-' . substr(md5(uniqid('', true)), 0, 6),
        'title' => $title,
        'body' => $body,
        'app_id' => (int)$appId,
        'url' => (string)$url,
        'ts' => time()
    ];
    array_unshift($list, $item);
    $list = array_slice($list, 0, 200);
    save_json('push_messages', $list);
    return $item;
}

function push_messages_for($token) {
    $token = strtolower(trim((string)$token));
    $list = push_devices();
    $seen = 0;
    $idx = -1;
    foreach ($list as $i => $d) {
        if (($d['token'] ?? '') === $token) { $seen = (int)($d['seen_ts'] ?? 0); $idx = $i; }
    }
    $out = [];
    $maxTs = $seen;
    foreach (push_messages() as $m) {
        if ((int)$m['ts'] > $seen && (int)$m['ts'] > $maxTs - 1) {
            $out[] = $m;
            if ((int)$m['ts'] > $maxTs) $maxTs = (int)$m['ts'];
        }
    }
    if ($idx >= 0) {
        $list[$idx]['seen_ts'] = $maxTs;
        $list[$idx]['last_seen'] = time();
        push_save_devices($list);
    }
    return array_reverse($out);
}

function push_apns_send($token, $payload) {
    $jwt = push_apns_jwt();
    if (!$jwt) return ['ok' => false, 'status' => 0, 'error' => 'no-key'];
    $host = (PUSH_APNS_ENV === 'development')
        ? 'https://api.sandbox.push.apple.com'
        : 'https://api.push.apple.com';
    $ch = curl_init($host . '/3/device/' . $token);
    curl_setopt_array($ch, [
        CURLOPT_HTTP_VERSION   => CURL_HTTP_VERSION_2_0,
        CURLOPT_POST           => 1,
        CURLOPT_POSTFIELDS     => json_encode($payload, JSON_UNESCAPED_UNICODE),
        CURLOPT_RETURNTRANSFER => 1,
        CURLOPT_TIMEOUT        => 10,
        CURLOPT_HTTPHEADER     => [
            'authorization: bearer ' . $jwt,
            'apns-topic: ' . PUSH_APNS_BUNDLE,
            'apns-push-type: alert',
            'apns-priority: 10',
            'content-type: application/json'
        ],
    ]);
    $resp = curl_exec($ch);
    $code = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return ['ok' => $code === 200, 'status' => $code, 'resp' => (string)$resp];
}

function push_deliver($title, $body, $appId = 0, $url = '') {
    if (!PUSH_APNS_ENABLED) {
        return ['mode' => 'inbox', 'sent' => 0, 'total' => count(push_devices())];
    }
    $payload = ['aps' => ['alert' => ['title' => $title, 'body' => $body], 'sound' => 'default', 'badge' => 1]];
    if ($appId) $payload['app_id'] = (int)$appId;
    if ($url !== '') $payload['url'] = $url;
    $sent = 0; $failed = [];
    foreach (push_devices() as $d) {
        $r = push_apns_send((string)$d['token'], $payload);
        if ($r['ok']) $sent++;
        else $failed[] = ['token' => substr((string)$d['token'], 0, 12), 'status' => $r['status'], 'resp' => $r['resp'] ?? ($r['error'] ?? '')];
    }
    return ['mode' => 'apns', 'sent' => $sent, 'failed' => $failed, 'total' => count(push_devices())];
}
