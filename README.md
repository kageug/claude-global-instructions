# claude-global-instructions

Claude Code の**グローバル指示ファイル**（全プロジェクト共通の作業ルール）を、URLで参照できるように置いてあるリポジトリです。

- 本体: [CLAUDE.md](CLAUDE.md)
- 原本の置き場所（ローカル）: `C:\Users\<ユーザー名>\.claude\CLAUDE.md`

## 参照用URL

| 用途 | URL |
| --- | --- |
| ブラウザで読む | https://github.com/kageug/claude-global-instructions/blob/main/CLAUDE.md |
| 中身だけを取得する（整形なしの生テキスト） | https://raw.githubusercontent.com/kageug/claude-global-instructions/main/CLAUDE.md |

生テキストは認証なしで取得できます。

```bash
curl -s https://raw.githubusercontent.com/kageug/claude-global-instructions/main/CLAUDE.md
```

## 中身について

Claude Code が全プロジェクトで参照する作業ルールです。おおむね次の内容が入っています。

- 立場と進め方（依頼者と作業者の役割、自走の範囲）
- 訊かれる前に報告に含める項目
- 回答フォーマット
- 複数セッションでの並行編集と git の扱い
- 取り返しのつかない操作の手順
- 機密情報の扱い
- 使った分だけ課金されるクラウドのコスト管理
- 説明・用語のルール
- Windows の文字コード
- 不具合調査の進め方
- UI/UX 実装方針
- 多言語対応の進め方

**機密情報は含みません**（パスワード・APIキー・トークン・接続文字列は0件であることを確認済み）。

## 同期のしかた

ローカルの原本とこのリポジトリを行き来させるスクリプトを同梱しています。PowerShell から実行します。

### このPCの原本 → リポジトリ（変更を公開する）

```powershell
powershell -ExecutionPolicy Bypass -File .\sync.ps1 -Push
```

`C:\Users\<ユーザー名>\.claude\CLAUDE.md` をリポジトリへコピーし、差分があればコミットして GitHub へ反映します。差分が無ければ何もしません。

### リポジトリ → このPCの原本（別のPCへ配る）

```powershell
powershell -ExecutionPolicy Bypass -File .\sync.ps1 -Pull
```

GitHub の最新を取得して `C:\Users\<ユーザー名>\.claude\CLAUDE.md` を上書きします。上書き前に、同じフォルダへ `CLAUDE.md.bak-<日時>` という名前で控えを取ります。

### 差分だけ見る

```powershell
powershell -ExecutionPolicy Bypass -File .\sync.ps1 -Check
```

原本とリポジトリの中身が一致しているかだけを表示します。ファイルは一切書き換えません。

> 認証は GitHub CLI（`gh`）のログイン情報をそのまま使います。事前に `gh auth login` が済んでいる必要があります。
