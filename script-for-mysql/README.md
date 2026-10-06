# 既存MySQL用スクリプト

MySQL ServerをPCへインストール済みで、rootパスワードを`password`、ポートを3306にしている場合に使用します。

1. `setup.bat`または`setup-existing-mysql.bat`を実行します。
2. セットアップ完了後、`start.bat`または`start-existing-mysql.bat`を実行します。
3. 停止するときはプロジェクト直下の`stop.bat`を実行します。KusakariのAPI/Webだけを停止し、既存MySQLは停止しません。

ブラウザーとSysOverRayを開かずに起動する場合は、次を実行します。

```bat
start.bat -NoBrowser -NoOverlay
```

このフォルダーはプロジェクト内の任意の階層へ移動できます。プロジェクト全体を別のドライブ・フォルダーへ移動しても動作します。フォルダーだけをプロジェクト外へコピーした場合は、アプリ本体や`backend`がないため動作しません。
