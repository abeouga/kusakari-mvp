# 検証記録

## 2026-10-04: 作業フォルダの改名

作業フォルダを `C:\Users\hanam\Desktop\kusakari` から `C:\Users\hanam\Desktop\kusakari-mvp` に変更しました。SysOverRayのプロジェクト検出は固定フォルダ名ではなく、`package.json`、`backend/pom.xml`、`scripts/start.ps1`を確認する方式に変更しました。下記の2026-10-02記録は当時の実行場所を示すため旧パスを維持しています。

## 2026-10-04: SysOverRayと固定ポートの起動処理

| 検証 | 結果 |
|---|---|
| `dotnet build` (Release) | 成功。警告0、エラー0 |
| JavaScript型確認、lint、Viteビルド | すべて成功 |
| Windows PowerShell 5.1 | `sysover-ray2/start.ps1`が終了コード0。日本語を含むPowerShellファイル6本のUTF-8 BOMを確認 |
| `start.bat` | 作業フォルダ外から実行し、終了コード0。ブラウザーと専用WPF操作画面を起動 |
| `sysover-ray2/start.bat` | 作業フォルダ外から単独実行し、終了コード0。既存の専用画面を置き換え、可視画面と3操作ボタンを確認 |
| WPFの実画面 | `Kusakari 起動オーバーレイ`を直接表示して確認。API 8086・Web 5186が稼働中で、起動・再起動・停止ボタンを確認 |
| `stop.bat` | 終了コード0。固定ポートの待受0件、Kusakari専用Java/Nodeプロセス0件。WPFは停止中を表示 |
| WPFの起動ボタン | 停止状態から操作し、8086と5186へ再接続。Web経由のAPIが`application=kusakari`、`backend=spring-boot`、`status=ok`を返した |
| 再実行時のポート | `start.bat`を再実行しても5186/8086を使用。Web/APIのPIDが入れ替わったことを確認 |
| ブラウザー実画面 | 再読み込み後、4商品、在庫、商品画像を確認 |

確認したPIDの一例: 再実行前はWeb 37832/API 29972、再実行後はWeb 11460/API 33416。停止後に操作画面から再起動した際はWeb 28936/API 40216でした。PIDは実行ごとに変わります。
既存のブラウザータブがサービス再起動中の通信エラーを表示した場合、再読み込みで商品一覧に復帰することを確認しました。外部プロセスが固定ポートを占有する障害注入は実施していません。競合時に別ポートへ移らないことはスクリプトの分岐を確認しました。
この変更は起動・停止とWPF画面のみです。実MySQL/Chromiumの購入E2Eは再実行していません。以下の購入フロー結果は2026-10-02の記録です。

実施日: 2026-10-02。実行先: `C:\Users\hanam\Desktop\kusakari`。

## 結果

| 検証 | 結果 |
|---|---|
| JavaScript checkJs | 成功 |
| ESLint | 成功 |
| Vite production build | 成功。JS 251.79 kB / gzip 78.67 kB |
| Spring Boot Maven package | 成功。Java 21 target、実行JDK 25.0.1 |
| Java / JavaScript / CSS のPrettier確認 | 成功 |
| 実API・実MySQL・Chromium E2E | 最終実行 7 passed (13.6s) |
| PC / 390pxスマートフォンの画面 | スクリーンショットで目視確認。横方向のはみ出しなし |
| 起動済み状態でstart.bat再実行 | 同じWeb/APIプロセスを再利用 |
| stop.bat | 5186 / 8086の待受0件、専用Java/Nodeプロセス0件 |
| 再起動 | 5186経由のAPIプロキシと8086のAPI応答を確認 |
| setup.bat -SkipInstallの再実行 | 成功。既存テーブル・商品・注文を維持 |
| Greenlyとの分離 | 最新の停止・再起動区間で5173 / 8080のPIDが変わらないことを確認 |
| 開発DB保護 | 開発DB `kusakari` の注文0件。注文試験は `kusakari_e2e` のみ |

Javaのユニットテストは追加していません。Mavenの「Tests are skipped」はその構成に対応しており、業務フローの証拠は実API/MySQL E2Eです。
Maven実行時にJDK 25とJansiのnative-access警告が出ますが、コンパイル・JAR生成・実行は成功しています。

## E2Eの7シナリオ

1. API入力検証、カートrevision競合、確認金額と異なる注文の拒否、別セッションの分離、不許可Originの拒否。
2. 同じ確定要求の同時再送から注文1件のみを保存し、在庫が一度だけ減ること。
3. 2人が在庫1点の商品を同時購入した場合、200 / 409、在庫0、注文明細1件となること。
4. 検索・カテゴリー・価格順・商品詳細・数量変更・カート再読み込み・注文確定・履歴再読み込み。
5. 最寄り店舗の並べ替え、店舗変更後の在庫不足と購入制止、材料候補の選択、カートから削除。
6. モバイル表示、画像の正常表示、空検索の復帰、Escapeによるダイアログ終了。
7. 接続遮断を明示した障害注入と再試行による復帰。

正常系のAPIをモックしていません。テストはブラウザーとSpring Bootを専用ポート15186 / 18086で起動します。
同時注文は実APIを並列で呼び、MySQLの在庫と注文明細の件数も照合しています。

## 成果物

- `artifacts/e2e/catalog-desktop.png`
- `artifacts/e2e/catalog-mobile.png`
- `artifacts/e2e/order-after-reload.png`
- `artifacts/e2e/order-after-reload.json`
- `artifacts/e2e/concurrent-checkout.json`
- `artifacts/e2e/lifecycle.json`
- `artifacts/playwright-report/index.html`

注文試験ではオリーブ2鉢・税込13,600円がMySQLへ保存され、再読み込み後も同じ注文IDと明細を取得しました。
E2E購入で減った数量は専用DBにだけ補充します。

## 修正して再確認した点

- WindowsのPATH上のJavaランチャーが子JVMを作るため、初期の停止処理では子JVMが残りました。`java.home` の実行ファイルを直接起動するよう変更し、残留0件を確認しました。
- スマートフォンの見出しの折り返しを調整しました。
- 撮影用E2Eの見出し指定が改行を含むアクセシブル名に一致しなかったため、ページ内のlevel 1見出しを指定する形へ修正しました。失敗時traceは `artifacts/diagnostics/mobile-locator-failure/` に保存しています。
- 作業途中の古いGreenly PIDと最終時点のPIDは一致しませんでした。原因はこの検証では特定していません。直前・直後を採取し直した停止・再起動区間ではGreenly PIDが一致しており、両方の結果をlifecycle.jsonへ残しています。

## 範囲外

外部の実商品フィード、実店舗、決済、公開環境の認証、Greenlyからの呼び出しは検証していません。現在は接続を実装していないためです。
