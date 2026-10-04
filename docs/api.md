# API契約（v1の実装）

開発URL: `http://127.0.0.1:8086/api`。ブラウザーはViteの `/api` プロキシを使用します。
リクエストと応答はJSON、金額は税込JPYの整数、数量は1〜99の整数です。
未定義フィールド・必須項目の欠落・小数の個数は400です。

| メソッド | パス | 内容 |
|---|---|---|
| GET | `/health` | アプリ名と状態 |
| GET | `/products?storeId=1` | 商品、SKU、単価、単位、画像、選択店舗の在庫、出所/更新日時 |
| GET | `/stores?latitude=35.6812&longitude=139.7671` | 指定地点から直線距離順の店舗。座標は両方省略可能 |
| GET | `/cart` | Cookieのカート。初回はサーバーが作成 |
| PUT | `/cart/items/{productId}` | `{ "quantity": 2, "revision": 0 }`。数量0で削除 |
| PUT | `/cart/store` | `{ "storeId": 2, "revision": 1 }`。在庫不足の商品もカートには残す |
| POST | `/orders` | 下記の確定要求。保存済みの同一要求は同じ注文を返す |
| GET | `/orders` | 同じCookieの最近30件。単価・商品名は注文時の記録 |
| POST | `/materials/quote` | 材料コードごとの商品候補と必要金額 |

## 注文要求

```json
{
  "requestId": "4502d427-883d-4a61-bd56-9f1177fbb81e",
  "revision": 2,
  "expectedTotalYen": 13600
}
```

`requestId` は操作ごとにUUIDを生成し、通信失敗後の再試行では同じ値を使います。
レスポンスは注文ID、`DEMO_CONFIRMED`、保存日時、店舗名、合計金額、商品ID/SKU/商品名/数量/単価/小計の明細です。
住所、氏名、カード情報は受け取りません。

## 材料から商品への対応付け

```json
{
  "storeId": 1,
  "items": [
    { "materialCode": "plant.olive", "quantity": 1, "unit": "piece" },
    { "materialCode": "plant.herb", "quantity": 2, "unit": "piece" }
  ]
}
```

材料ごとに `materialCode / status / candidates` を返します。
候補には `product / purchaseQuantity / lineTotalYen / available` を含めます。
`plant.herb` はラベンダーとローズマリーの2候補を返し、どちらを購入するかを人が選びます。
代替候補の小計を全部足した金額を「材料全体の合計」とは扱いません。選択後のカートが正しい合計です。

| 材料コード | 商品 |
|---|---|
| plant.olive | オリーブ |
| plant.lavender | ラベンダー |
| plant.rosemary | ローズマリー |
| plant.monstera | モンステラ |
| plant.herb | ラベンダー、ローズマリー |

50行まで受け付け、未対応コードは `UNMAPPED` です。単位は `piece`（鉢）のみです。

### 将来のGreenly接続手順

1. Greenly側でGardenDocumentを集計し、材料コード・個数・単位へ変換します。Three.jsの表示オブジェクトは送信しません。
2. Kusakariの候補取得APIへ送り、利用者が商品と受取店舗を選択します。
3. 選択した `productId / quantity` をECのカートへ追加します。
4. ECの最新価格・在庫を確認し、注文確認画面で利用者が確定します。

現在はGreenlyからの通信を許可しておらず、この変換処理も実装していません。
接続時には認証・許可Origin・Cookieの共有方針・改ざんや重複の扱いを別途決定します。
クライアントからの価格やownerIdは採用しません。

## エラー

```json
{ "code": "CART_CHANGED", "message": "別の操作でカートが更新されました。最新の内容を確認してください。" }
```

- 400 `INVALID_INPUT` / `INVALID_LOCATION`: 不正な入力。
- 403 `ORIGIN_REJECTED`: 許可していないブラウザーOriginまたはHost。
- 404 `STORE_NOT_FOUND` / `PRODUCT_NOT_FOUND`: 存在しないID。
- 409 `CART_CHANGED`: 古いrevision。
- 409 `OUT_OF_STOCK`: 選択店舗の在庫不足。
- 409 `PRICE_CHANGED`: 確認した金額と現在の合計が異なる。
- 409 `EMPTY_CART`: 空カートの注文。
- 409 `REQUEST_REUSED`: 同じ注文キーを異なるrevision/金額で再利用。
- 503 `DATABASE_UNAVAILABLE`: DB処理失敗。例外詳細・SQL・認証情報は応答に含めない。

開発Originは `http://127.0.0.1:5186`、E2Eでは `http://127.0.0.1:15186` です。
Cookieはカートの参照権限を持つため、実利用では他人へ共有しません。
