<?php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../push_lib.php';
security_headers();
if (empty($_SESSION['admin_logged'])) {
    header('Location: ' . ADMIN_PATH . '/');
    exit;
}
if (empty($_SESSION['csrf'])) $_SESSION['csrf'] = bin2hex(random_bytes(16));
$csrf = $_SESSION['csrf'];
$apps = load_json('apps', []);
$devices = push_devices();
$messages = array_slice(push_messages(), 0, 10);
$apns = PUSH_APNS_ENABLED && push_apns_jwt() !== null;
?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<title>消息推送 · 小七资源库</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,"PingFang SC",sans-serif;background:#0b0b0d;color:#e8e8ea;padding:18px;padding-top:max(18px,env(safe-area-inset-top))}
h1{font-size:20px;margin-bottom:4px}
.sub{font-size:12px;color:#8a8a90;margin-bottom:16px}
.card{background:#151518;border:1px solid #232327;border-radius:14px;padding:14px;margin-bottom:14px}
label{display:block;font-size:12px;color:#9a9aa1;margin:10px 0 6px}
input,textarea,select{width:100%;background:#0e0e11;border:1px solid #2a2a30;color:#e8e8ea;border-radius:9px;padding:10px 12px;font-size:14px;font-family:inherit;outline:none}
input:focus,textarea:focus,select:focus{border-color:#3b7bff}
textarea{min-height:74px;resize:vertical}
button{width:100%;margin-top:14px;background:#0a8ffd;color:#fff;border:0;border-radius:11px;padding:13px;font-size:15px;font-weight:600;font-family:inherit}
button:active{opacity:.8}
button.ghost{background:#232327;color:#c9c9cf}
.row{display:flex;justify-content:space-between;align-items:center;padding:9px 0;border-bottom:1px solid #1e1e22;font-size:13px}
.row:last-child{border-bottom:0}
.muted{color:#7a7a82;font-size:12px}
.tag{display:inline-block;padding:2px 8px;border-radius:7px;font-size:11px;background:#1d2a3d;color:#7fb2ff}
.tag.off{background:#3a1d1d;color:#ff9a9a}
pre{white-space:pre-wrap;word-break:break-all;font-size:11px;color:#8a8a90;background:#0e0e11;padding:8px;border-radius:8px;margin-top:8px}
</style>
</head>
<body>
<h1>消息推送</h1>
<div class="sub">发一条通知，装了小七资源库的设备会收到横幅</div>

<div class="card">
  <div class="row"><span>APNs 通道</span><span class="tag <?= $apns ? '' : 'off' ?>" id="apnsTag"><?= $apns ? '已连通' : '未配置（走收件箱）' ?></span></div>
  <div class="row"><span>已登记设备</span><span id="devTotal"><?= count($devices) ?></span></div>
</div>

<div class="card">
  <label>标题</label>
  <input id="title" value="小七资源库" maxlength="120">
  <label>内容</label>
  <textarea id="body" maxlength="500" placeholder="有新资源上架了，快来看看"></textarea>
  <label>点击后跳到资源卡片（可选）</label>
  <select id="appId">
    <option value="0">不跳转资源</option>
    <?php foreach ($apps as $a): ?>
      <option value="<?= (int)$a['id'] ?>"><?= htmlspecialchars($a['name']) ?></option>
    <?php endforeach; ?>
  </select>
  <label>点击后打开链接（可选，填了就优先于资源卡片）</label>
  <input id="url" placeholder="https://6778.top">
  <button id="sendBtn">发送推送</button>
  <button class="ghost" id="refreshBtn" style="margin-top:8px">刷新设备与记录</button>
  <pre id="out" hidden></pre>
</div>

<div class="card">
  <div style="font-size:13px;color:#9a9aa1;margin-bottom:8px">设备</div>
  <div id="devices" class="muted">加载中…</div>
</div>

<div class="card">
  <div style="font-size:13px;color:#9a9aa1;margin-bottom:8px">最近发送</div>
  <div id="history" class="muted">—</div>
</div>

<script>
var CSRF = <?= json_encode($csrf) ?>;

function post(action, data) {
  var fd = new FormData();
  fd.append('source', 'admin');
  fd.append('action', action);
  fd.append('csrf', CSRF);
  for (var k in data) if (data[k] !== undefined && data[k] !== '') fd.append(k, data[k]);
  return fetch('../api.php', { method: 'POST', body: fd })
    .then(function (r) { return r.json(); });
}

function loadDevices() {
  post('push_devices').then(function (res) {
    if (res.code !== 0) { document.getElementById('devices').textContent = res.msg || '失败'; return; }
    var d = res.data.devices || [];
    document.getElementById('devTotal').textContent = res.data.total;
    if (!d.length) { document.getElementById('devices').textContent = '还没有设备登记。打开 App 并允许通知后会自动登记。'; return; }
    var html = '';
    d.forEach(function (x) {
      html += '<div class="row"><div><div>' + (x.model || 'iPhone') + ' · ' + (x.name || '未命名') + '</div>' +
              '<div class="muted">' + x.short + ' · v' + (x.version || '?') + '</div></div>' +
              '<div class="muted">' + (x.last_seen ? new Date(x.last_seen * 1000).toLocaleString() : '') + '</div></div>';
    });
    document.getElementById('devices').innerHTML = html;
  });
}

function loadHistory() {
  post('push_preview').then(function (res) {
    if (res.code !== 0) return;
    var m = (res.data && res.data.messages) || [];
    if (!m.length) { document.getElementById('history').textContent = '还没有发过'; return; }
    var html = '';
    m.forEach(function (x) {
      html += '<div class="row"><div><div>' + x.title + '</div><div class="muted">' + x.body + '</div></div>' +
              '<div class="muted">' + (x.app_id ? '资源 ' + x.app_id : '') + '</div></div>';
    });
    document.getElementById('history').innerHTML = html;
  });
}

document.getElementById('sendBtn').addEventListener('click', function () {
  var body = document.getElementById('body').value.trim();
  if (!body) { alert('内容不能为空'); return; }
  var btn = this; btn.textContent = '发送中…'; btn.disabled = true;
  post('push_send', {
    title: document.getElementById('title').value.trim(),
    body: body,
    app_id: document.getElementById('appId').value,
    url: document.getElementById('url').value.trim()
  }).then(function (res) {
    var out = document.getElementById('out');
    out.hidden = false;
    out.textContent = JSON.stringify(res, null, 2);
    if (res.code === 0) {
      var dv = res.data.delivery || {};
      if (dv.mode === 'inbox') out.textContent = '已存入收件箱。未配置 APNs，App 打开时会拉取并弹出通知。\n' + out.textContent;
      else out.textContent = 'APNs 已送达 ' + dv.sent + '/' + dv.total + '\n' + out.textContent;
    }
    loadHistory();
  }).catch(function (e) {
    alert('请求失败: ' + e);
  }).finally(function () {
    btn.textContent = '发送推送'; btn.disabled = false;
  });
});

document.getElementById('refreshBtn').addEventListener('click', function () {
  loadDevices(); loadHistory();
});

loadDevices(); loadHistory();
</script>
</body>
</html>
