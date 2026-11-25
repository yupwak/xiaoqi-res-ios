<?php
require_once __DIR__ . '/../config.php';
security_headers();
if (empty($_SESSION['admin_logged'])) {
    header('Location: ' . ADMIN_PATH . '/');
    exit;
}
if (empty($_SESSION['csrf'])) $_SESSION['csrf'] = bin2hex(random_bytes(16));
$csrf = $_SESSION['csrf'];

$msg = '';
$err = '';

function sponsors_list_raw() {
    $list = load_json('sponsors', []);
    if (!is_array($list)) $list = [];
    usort($list, function ($a, $b) {
        $am = (float)($a['amount'] ?? 0);
        $bm = (float)($b['amount'] ?? 0);
        if ($am == $bm) return (int)($b['ts'] ?? 0) <=> (int)($a['ts'] ?? 0);
        return $bm <=> $am;
    });
    return $list;
}

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'POST') {
    $token = (string)($_POST['csrf'] ?? '');
    if (!hash_equals($csrf, $token)) {
        $err = '会话失效，请刷新';
    } else {
        $op = $_POST['op'] ?? 'save';
        $list = load_json('sponsors', []);
        if (!is_array($list)) $list = [];

        if ($op === 'delete') {
            $id = (string)($_POST['id'] ?? '');
            $list = array_values(array_filter($list, function ($s) use ($id) {
                return (string)($s['id'] ?? '') !== $id;
            }));
            save_json('sponsors', $list);
            $msg = '已删除';
        } else {
            $name = trim((string)($_POST['name'] ?? ''));
            $amount = (float)($_POST['amount'] ?? 0);
            $note = trim((string)($_POST['note'] ?? ''));
            $avatar = trim((string)($_POST['avatar'] ?? ''));
            $id = trim((string)($_POST['id'] ?? ''));
            $qq = preg_replace('/\D/', '', (string)($_POST['qq'] ?? ''));
            if (strlen($qq) < 5 || strlen($qq) > 12) $qq = '';

            // 头像上传
            if (!empty($_FILES['avatar_file']['tmp_name']) && is_uploaded_file($_FILES['avatar_file']['tmp_name'])) {
                $f = $_FILES['avatar_file'];
                if ($f['size'] > 3 * 1024 * 1024) {
                    $err = '头像超过 3MB';
                } else {
                    $info = @getimagesize($f['tmp_name']);
                    $ext = 'jpg';
                    if ($info && isset($info[2])) {
                        $map = [IMAGETYPE_JPEG => 'jpg', IMAGETYPE_PNG => 'png', IMAGETYPE_GIF => 'gif', IMAGETYPE_WEBP => 'webp'];
                        if (isset($map[$info[2]])) $ext = $map[$info[2]];
                    }
                    if (!$info) {
                        $err = '头像不是有效图片';
                    } else {
                        @mkdir(IMG_DIR . 'sponsors', 0755, true);
                        $fname = date('YmdHis') . '_' . substr(md5(uniqid('', true)), 0, 8) . '.' . $ext;
                        if (move_uploaded_file($f['tmp_name'], IMG_DIR . 'sponsors/' . $fname)) {
                            $avatar = 'imgdata/sponsors/' . $fname;
                        } else {
                            $err = '头像保存失败';
                        }
                    }
                }
            }

            if ($err === '' && $avatar === '' && $qq !== '') {
                $avatar = 'https://q1.qlogo.cn/g?b=qq&nk=' . $qq . '&s=640';
            }

            if ($err === '') {
                if ($name === '') {
                    $err = '名字不能为空';
                } else {
                    if ($amount < 0) $amount = 0;
                    $updated = false;
                    if ($id !== '') {
                        foreach ($list as $i => $s) {
                            if ((string)($s['id'] ?? '') === $id) {
                                $list[$i] = array_merge($s, [
                                    'name' => $name, 'amount' => $amount,
                                    'avatar' => $avatar !== '' ? $avatar : ($s['avatar'] ?? ''),
                                    'note' => $note,
                                    'qq' => $qq !== '' ? $qq : ($s['qq'] ?? '')
                                ]);
                                $updated = true;
                                break;
                            }
                        }
                    }
                    if (!$updated) {
                        $list[] = [
                            'id' => date('YmdHis') . substr(md5(uniqid('', true)), 0, 4),
                            'name' => $name,
                            'amount' => $amount,
                            'avatar' => $avatar,
                            'note' => $note,
                            'qq' => $qq,
                            'ts' => time()
                        ];
                    }
                    save_json('sponsors', $list);
                    $msg = $updated ? '已更新' : '已添加';
                }
            }
        }
    }
}

$sponsors = sponsors_list_raw();
$total = 0.0;
foreach ($sponsors as $s) $total += (float)($s['amount'] ?? 0);
$edit = null;
if (!empty($_GET['edit'])) {
    foreach ($sponsors as $s) if ((string)$s['id'] === (string)$_GET['edit']) { $edit = $s; break; }
}
?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<title>赞助名单 · 小七资源库</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,"PingFang SC",sans-serif;background:#0b0b0d;color:#e8e8ea;padding:18px;padding-top:max(18px,env(safe-area-inset-top))}
h1{font-size:20px;margin-bottom:4px}
.sub{font-size:12px;color:#8a8a90;margin-bottom:16px}
.card{background:#151518;border:1px solid #232327;border-radius:14px;padding:14px;margin-bottom:14px}
label{display:block;font-size:12px;color:#9a9aa1;margin:10px 0 6px}
input,textarea{width:100%;background:#0e0e11;border:1px solid #2a2a30;color:#e8e8ea;border-radius:9px;padding:10px 12px;font-size:14px;font-family:inherit;outline:none}
input:focus,textarea:focus{border-color:#3b7bff}
button{background:#0a8ffd;color:#fff;border:0;border-radius:10px;padding:12px 16px;font-size:14px;font-weight:600;font-family:inherit}
button:active{opacity:.8}
button.wide{width:100%;margin-top:14px;padding:13px}
button.del{background:#2a1a1a;color:#ff8f8f;padding:6px 10px;font-size:12px;border-radius:8px}
button.edit{background:#1c2431;color:#8fb8ff;padding:6px 10px;font-size:12px;border-radius:8px;margin-right:6px}
.ok{color:#6ee7a8;font-size:13px;margin-bottom:10px}
.bad{color:#ff8f8f;font-size:13px;margin-bottom:10px}
.rank{display:flex;align-items:center;gap:12px;padding:11px 0;border-bottom:1px solid #1e1e22}
.rank:last-child{border-bottom:0}
.rank img,.rank .ph{width:42px;height:42px;border-radius:50%;object-fit:cover;background:#232327;display:flex;align-items:center;justify-content:center;font-size:15px;color:#7c7c84;flex:0 0 42px}
.rank .info{flex:1;min-width:0}
.rank .nm{font-size:14px}
.rank .nt{font-size:11px;color:#7a7a82;margin-top:2px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.amt{font-size:15px;font-weight:700;color:#ffd166;white-space:nowrap}
.no{font-size:12px;color:#7a7a82}
a{color:#0a8ffd;text-decoration:none;font-size:12px}
</style>
</head>
<body>
<h1>赞助名单</h1>
<div class="sub">共 <?= count($sponsors) ?> 人 · 累计 ¥<?= number_format($total, 2) ?> · 金额高的排在最上面</div>

<?php if ($msg): ?><div class="ok"><?= htmlspecialchars($msg) ?></div><?php endif; ?>
<?php if ($err): ?><div class="bad"><?= htmlspecialchars($err) ?></div><?php endif; ?>

<div class="card">
  <div style="font-size:13px;color:#9a9aa1;margin-bottom:4px"><?= $edit ? '编辑赞助者' : '添加赞助者' ?></div>
  <form method="post" enctype="multipart/form-data">
    <input type="hidden" name="csrf" value="<?= htmlspecialchars($csrf) ?>">
    <input type="hidden" name="op" value="save">
    <input type="hidden" name="id" value="<?= htmlspecialchars($edit['id'] ?? '') ?>">
    <label>名字</label>
    <input name="name" maxlength="40" value="<?= htmlspecialchars($edit['name'] ?? '') ?>" placeholder="例如：张三">
    <label>赞助金额（元）</label>
    <input name="amount" type="number" step="0.01" min="0" value="<?= htmlspecialchars((string)($edit['amount'] ?? '')) ?>" placeholder="100">
    <label>QQ 号（填了自动采集头像，后台记录、前端不显示）</label>
    <input name="qq" inputmode="numeric" maxlength="12" value="<?= htmlspecialchars((string)($edit['qq'] ?? '')) ?>" placeholder="例如：123456789">
    <label>头像（上传图片，或填图片地址；留空则用 QQ 头像）</label>
    <input type="file" name="avatar_file" accept="image/*">
    <input name="avatar" style="margin-top:8px" value="<?= htmlspecialchars($edit['avatar'] ?? '') ?>" placeholder="https://... 或 imgdata/sponsors/xxx.jpg">
    <label>备注（可选）</label>
    <input name="note" maxlength="120" value="<?= htmlspecialchars($edit['note'] ?? '') ?>" placeholder="留言">
    <button class="wide" type="submit"><?= $edit ? '保存修改' : '添加' ?></button>
    <?php if ($edit): ?>
      <div style="text-align:center;margin-top:10px"><a href="sponsors.php">取消编辑</a></div>
    <?php endif; ?>
  </form>
</div>

<div class="card">
  <div style="font-size:13px;color:#9a9aa1;margin-bottom:6px">名单（按金额降序）</div>
  <?php if (!$sponsors): ?>
    <div class="no">还没有赞助者</div>
  <?php else: ?>
    <?php foreach ($sponsors as $i => $s): ?>
      <div class="rank">
        <?php $av = (string)($s['avatar'] ?? ''); ?>
        <?php if ($av !== ''): ?>
          <img src="../<?= htmlspecialchars(ltrim($av, '/')) ?>" alt="">
        <?php else: ?>
          <div class="ph"><?= htmlspecialchars(mb_substr((string)$s['name'], 0, 1)) ?></div>
        <?php endif; ?>
        <div class="info">
          <div class="nm"><?= htmlspecialchars((string)$s['name']) ?></div>
          <div class="nt"><?= htmlspecialchars((string)($s['note'] ?? '')) ?><?= !empty($s['qq']) ? ' · QQ ' . htmlspecialchars((string)$s['qq']) : '' ?></div>
        </div>
        <div class="amt">¥<?= number_format((float)$s['amount'], 2) ?></div>
        <div>
          <a class="edit" href="?edit=<?= urlencode((string)$s['id']) ?>" style="padding:6px 10px;border-radius:8px;display:inline-block">改</a>
          <form method="post" style="display:inline">
            <input type="hidden" name="csrf" value="<?= htmlspecialchars($csrf) ?>">
            <input type="hidden" name="op" value="delete">
            <input type="hidden" name="id" value="<?= htmlspecialchars((string)$s['id']) ?>">
            <button class="del" type="submit" onclick="return confirm('确定删除？')">删</button>
          </form>
        </div>
      </div>
    <?php endforeach; ?>
  <?php endif; ?>
</div>
</body>
</html>
