# 🔐 claude-ssh-mcp-safety

> SSH MCP経由でリモートサーバーに実行される危険なコマンドを自動ブロックする、Claude Code用のフック。

Claude CodeでSSH MCPを使うと、リモートサーバーへのコマンド実行がローカルのBashツールと異なり**確認プロンプトなしで動作**します。
このフックは `ssh_exec` の実行直前に割り込み、破壊的なコマンドを検出してブロックします。

![Claude Code](https://img.shields.io/badge/Claude_Code-hook-blueviolet?style=flat-square)
![Shell Script](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnubash)
![SSH MCP](https://img.shields.io/badge/SSH--MCP-compatible-0078D7?style=flat-square)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)

---

## ✨ 特徴

- **コマンド実行前に検出** — `ssh_exec` が呼ばれた瞬間に正規表現でチェック
- **11カテゴリをカバー** — ファイル削除・プロセス終了・ディスク操作・DB破壊など
- **安全なコマンドは素通り** — `ls`・`cat`・`grep` 等の読み取り系は一切ブロックしない
- **意図的な実行は可能** — ブロック後に「確認します」と明示すれば実行できる

---

## 🛡️ ブロック対象コマンド

| カテゴリ | 対象コマンド |
|---|---|
| ファイル削除 | `rm`, `shred` |
| プロセス終了 | `kill`, `killall`, `pkill` |
| システム制御 | `shutdown`, `reboot`, `halt`, `poweroff` |
| ディスク操作 | `mkfs.*`, `fdisk`, `parted`, `wipefs` |
| デバイス上書き | `dd of=/dev/...` |
| ファイアウォール | `ufw disable`, `iptables -F/-X`, `nft flush` |
| アカウント操作 | `passwd`, `userdel`, `usermod` |
| サービス制御 | `systemctl stop/disable/mask` |
| cron全削除 | `crontab -r` |
| DB破壊 | `mysql`/`psql`/`mongo` 経由の `DROP TABLE/DATABASE/SCHEMA` |
| システムファイル上書き | `>` による `/etc/`, `/boot/`, `/usr/`, `/bin/` 等への書き込み |

---

## 🚀 セットアップ

### 1. SSH-MCP をインストール

```bash
git clone https://github.com/mixelpixx/SSH-MCP.git ~/.claude/SSH-MCP
cd ~/.claude/SSH-MCP
npm install
npm run build
```

> **Note:** `dotenv` が見つからない場合は `npm install dotenv` を実行してください。

MCPサーバーとして登録します。

```bash
claude mcp add ssh-server node ~/.claude/SSH-MCP/build/index.js \
  -e NODE_NO_WARNINGS=1 --scope user
```

### 2. フックスクリプトを配置

```bash
mkdir -p ~/.claude/hooks
cp check-ssh-dangerous.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/check-ssh-dangerous.sh
```

### 3. settings.json にフックを追加

`~/.claude/settings.json` に以下をマージしてください。

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__ssh-server__ssh_exec",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/check-ssh-dangerous.sh",
            "statusMessage": "危険なコマンドをチェック中..."
          }
        ]
      }
    ]
  }
}
```

設定例は [settings-example.json](./settings-example.json) を参照してください。

### 4. Claude Code を再起動

フックはセッション開始時に読み込まれるため、再起動が必要です。

---

## 💬 ブロックされたコマンドを実行するには

ブロックされた場合、Claude はその旨を通知します。
意図的に実行したい場合は、メッセージに明示的な確認を含めてください。

```
「削除を確認します。rm -rf /var/log/old を実行してください」
```

---

## ⚠️ 制限事項

このフックはコマンド文字列に対する**正規表現マッチング**で動作します。
変数展開・base64エンコードなどで難読化されたコマンドはすり抜ける場合があります。
**意図しない誤操作の防止**を目的としており、悪意ある回避への対策ではありません。

---

## ライセンス

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)

このプロジェクトは **MIT ライセンス** のもとで公開しています。

© 2026 masafykun (https://github.com/masafykun)
