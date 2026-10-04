# Kusakari — 植物と、暮らす。

Java / Spring Boot + JavaScript / React / Vite + MySQL で動く、植物ECサイトのローカルデモです。
Greenlyとは別プロジェクトで、コード・ポート・DBを分離しています。

## 開く

- **画面:** http://127.0.0.1:5186
- **API:** http://127.0.0.1:8086/api/health
- **作業先:** `C:\Users\hanam\Desktop\kusakari-mvp`
- **起動:** `start.bat` をダブルクリック
- **停止:** `stop.bat` をダブルクリック

現在の環境ではセットアップ済みです。`start.bat` はブラウザーとKusakari専用のSysOverRay操作画面を開き、画面の表示と操作ボタンまで確認します。ブラウザーを自動で開かない場合は `start.bat -NoBrowser` を実行します。
再実行時は、この作業フォルダから起動したWeb/APIを停止してから同じ5186/8086で作り直します。別のプロセスが固定ポートを使っている場合は停止せず、エラーにします。代替ポートへ移動しません。
Javaや依存を更新した場合は、停止 → ビルド → 起動の順に実行します。

## できること

- オリーブ、ラベンダー、ローズマリー、モンステラの4商品。AI生成画像、サイズ、育て方、SKUを掲載。
- カテゴリー・商品名・品番検索、価格順ソート、在庫あり絞り込み。
- 3つの架空店舗の在庫確認、受取店舗変更。東京駅・横浜駅・大宮駅または許可された現在地から距離順に表示。
- カートへの追加、数量変更、削除、税込合計。カートはMySQLへ保存され、再読み込みで復元。
- 注文確認 → デモ注文確定 → 注文履歴。金額・在庫をサーバーで再確認。
- 材料コードのJSONから商品候補・購入個数・必要金額を取得し、選んだ候補をカートへ追加。
- PC・スマートフォン対応、キーボードでのダイアログ操作、通信失敗時の再試行。

**デモの範囲:** 商品・価格・店舗・在庫はデモ用です。実決済・配送・実店舗での取り置きは行いません。
注文によるデモ在庫の減算と注文履歴の永続化は実装しています。外部EC APIは未接続です。
Greenlyとの自動接続もありません。将来の接続仕様は [docs/api.md](docs/api.md) に記載しています。

## 構成

| 対象 | 技術 / 役割 | 開発ポート |
|---|---|---|
| frontend | JavaScript / React 19 / Vite 8 | 5186 |
| backend | Spring Boot 3.5.16 / Java 21 target / JDBC / Flyway | 8086 |
| database | MySQL 8、開発DB `kusakari` | 3306（既存サーバーを共用） |
| E2E | Playwright Chromium / DB `kusakari_e2e` | 15186 / 18086 |

フロントの実装は `.js` / `.jsx` です。JSDoc + TypeScriptの `checkJs` で型を確認します。
MySQLサーバーそのものは既存のものを使い、DBと権限を分離しています。GreenlyのDBへはアクセスしません。

```text
frontend/src/
  components/       商品・カート・店舗・材料リストの画面
  css/              部位別・画面幅別のスタイル
  api.js            HTTP通信
  types.js          APIの型説明（JSDoc）
  useShop.js         状態更新と処理の順序
backend/src/main/
  java/jp/kusakari/
    catalog/        商品・店舗・材料コード
    commerce/       カート・注文・在庫トランザクション
    common/         Cookie、接続元確認、エラー応答
  resources/db/migration/  Flywayスキーマと初期商品
e2e/                実画面・実API・MySQL検証
scripts/            起動、停止、セットアップ
sysover-ray2/       専用のWPF操作画面と起動スクリプト
docs/               設計判断、API、画像プロンプト、検証記録
```

## 別環境でのセットアップ

前提は Windows、Node.js 24、JDK 21または25、MySQL 8、MySQL CLI、.NET 10 SDKとDesktop Runtimeです。
この環境では Node 24.14.1 / JDK 25.0.1 / MySQL 8.0.45 で検証しました。
Mavenは同梱Wrapperから3.9.12を取得します。

1. `.env.example` を `.env` にコピーし、専用DBユーザーのパスワードを設定します。
2. MySQLを起動します。
3. `setup.bat` を実行し、MySQL rootのパスワードを入力します。
4. `start.bat` を実行します。

セットアップは `kusakari` / `kusakari_e2e` と専用ユーザー `kusakari` を作成します。
既存ユーザーのパスワード、既存の表・商品・注文は上書きしません。アプリ起動時にFlywayを実行し、初回だけ商品と在庫を登録します。
認証情報を持つ `.env`、実行ログ、テスト成果物はGit対象外です。

MySQL CLIの場所が標準インストール先と異なる場合、セットアップ時は `mysql.exe` をPATHへ追加してください。
E2Eでは `MYSQL_CLIENT` 環境変数にCLIのフルパスを指定できます。

## 開発と検証

```powershell
npm ci
npm run check          # JavaScript型確認・lint・Viteビルド・Javaビルド
npm run format:check   # JavaScript / CSS / Java の整形確認
npm run test:e2e       # 専用API・専用Web・専用DBで7シナリオ
```

API変更時は `stop.bat` 後に `npm run build:api`、続いて `start.bat` を実行します。
フロント変更はViteで即時反映されます。

操作画面だけを再表示する場合は `sysover-ray2/start.bat` を実行します。画面には起動、停止、再起動、ブラウザーを開くボタンがあります。
手動のターミナル起動は `npm run dev:api` と `npm run dev:web` です。`stop.bat` はこの作業フォルダのJAR/Viteスクリプトを実行するJava/Nodeプロセスを、コマンドと作成時刻を再確認して停止します。固定ポートを使う別プロジェクトのプロセスは終了しません。
日本語を含むPowerShellスクリプトはWindows PowerShell 5.1で読めるようUTF-8 BOM付きで保存します。

テストのスクリーンショットとAPI JSONは `artifacts/e2e/`、失敗時traceとレポートは `artifacts/playwright-results/` / `artifacts/playwright-report/` です。
開発サーバーのログは `.runtime/` にあります。

## 設計上の制約

- ローカル専用です。127.0.0.1へのbindと接続元チェックを使用し、公開用認証は実装していません。
- CookieはHttpOnly / SameSite=Strict、有効期間30日です。Cookie削除後は以前のカート・注文履歴へアクセスできません。
- 在庫は追加時には予約しません。注文確定時にロック・再確認・減算します。
- 金額は税込JPYの整数です。店舗受け取りのみで、送料は0円です。
- 位置情報はリクエスト内の距離計算に使い、DBに保存しません。距離は道路距離ではなく直線距離です。
- 外部フォント取得に失敗してもOSのフォントで表示されます。商品画像はプロジェクト内にあります。
- 公開時の会員認証、決済、実商品フィード、税・送料規則、注文取消・返金、運用管理は別途実装が必要です。

設計判断: [docs/architecture.md](docs/architecture.md) / API: [docs/api.md](docs/api.md) / 画像: [docs/images.md](docs/images.md)

技術要件の確認元: [Spring Boot 3.5](https://docs.spring.io/spring-boot/3.5/system-requirements.html)、[Vite](https://vite.dev/guide/)。
