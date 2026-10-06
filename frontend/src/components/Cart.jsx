import { useState } from 'react';
import { ShoppingBag, MapPin, Minus, Plus, Trash2, ArrowRight, CheckCircle2 } from 'lucide-react';
import { Dialog } from './Dialog';
import { yen } from '../api';

/** @param {{shop:ReturnType<import('../useShop').useShop>, onClose:()=>void, onStores:()=>void}} props */
export function Cart({ shop, onClose, onStores }) {
  const [confirming, setConfirming] = useState(false);
  const cart = shop.cart;
  if (shop.lastOrder) {
    return (
      <Dialog title="注文を保存しました" onClose={onClose}>
        <div className="order-success">
          <CheckCircle2 size={42} />
          <h3>植物を迎える準備ができました。</h3>
          <p>デモ注文のため、お支払い・実際の取り置きは発生しません。</p>
        </div>
        <OrderSummary order={shop.lastOrder} />
        <button className="primary-button full" onClick={onClose}>
          お買い物を続ける
        </button>
      </Dialog>
    );
  }
  if (!cart || cart.items.length === 0) {
    return (
      <Dialog title="ショッピングバッグ (0)" onClose={onClose}>
        {shop.error && (
          <p className="error" role="alert">
            {shop.error}
          </p>
        )}
        <div className="empty">
          <ShoppingBag size={40} />
          <h3>まだ植物が入っていません。</h3>
          <p>お気に入りのひと鉢を見つけてください。</p>
          <button className="primary-button" onClick={onClose}>
            植物を探す
          </button>
        </div>
      </Dialog>
    );
  }
  let title = `ショッピングバッグ (${cart.itemCount})`;
  let checkoutLabel = 'デモ注文を確定する';
  if (confirming) title = '注文内容の確認';
  if (shop.busy) checkoutLabel = '保存中…';
  return (
    <Dialog title={title} onClose={onClose}>
      {shop.error && (
        <p className="error" role="alert">
          {shop.error}
        </p>
      )}
      <div className="cart-store">
        <MapPin size={18} />
        <div>
          <small>店舗受け取り</small>
          <strong>{cart.storeName}</strong>
        </div>
        <button className="text-button" disabled={shop.busy} onClick={onStores}>
          変更
        </button>
      </div>
      <div className="cart-items">
        {cart.items.map((line) => (
          <article className="cart-line" key={line.product.id}>
            <img src={line.product.imageUrl} alt={line.product.name} />
            <div className="cart-line-main">
              <h3>{line.product.name}</h3>
              <p>{yen(line.product.priceYen)} / 1鉢</p>
              {!line.available && <p className="error-text">在庫不足（現在 {line.product.stock} 点）</p>}
              {!confirming && (
                <div className="quantity-control">
                  <button
                    aria-label={`${line.product.name}を1個減らす`}
                    disabled={shop.busy || line.quantity <= 1}
                    onClick={() => shop.setQuantity(line.product.id, line.quantity - 1)}
                  >
                    <Minus size={14} />
                  </button>
                  <span aria-label="数量">{line.quantity}</span>
                  <button
                    aria-label={`${line.product.name}を1個増やす`}
                    disabled={shop.busy || line.quantity >= 99 || line.quantity >= line.product.stock}
                    onClick={() => shop.setQuantity(line.product.id, line.quantity + 1)}
                  >
                    <Plus size={14} />
                  </button>
                </div>
              )}
              {confirming && <p>数量：{line.quantity} 鉢</p>}
            </div>
            <div className="cart-line-end">
              <strong>{yen(line.lineTotalYen)}</strong>
              {!confirming && (
                <button
                  className="icon-button"
                  aria-label={`${line.product.name}を削除`}
                  disabled={shop.busy}
                  onClick={() => shop.setQuantity(line.product.id, 0)}
                >
                  <Trash2 size={17} />
                </button>
              )}
            </div>
          </article>
        ))}
      </div>
      <div className="totals">
        <div>
          <span>商品小計（税込）</span>
          <span>{yen(cart.totalYen)}</span>
        </div>
        <div>
          <span>店舗受け取り</span>
          <span>無料</span>
        </div>
        <div className="grand-total">
          <strong>合計</strong>
          <strong>{yen(cart.totalYen)}</strong>
        </div>
      </div>
      <p className="fine-print">
        すべてデモ商品です。注文はこの端末用に保存されます。実決済・発送・取り置きは行いません。
      </p>
      {confirming && (
        <>
          <button className="primary-button full" disabled={shop.busy || !cart.canCheckout} onClick={shop.checkout}>
            {checkoutLabel}
            <CheckCircle2 size={18} />
          </button>
          <button className="text-button back-button" disabled={shop.busy} onClick={() => setConfirming(false)}>
            カートに戻る
          </button>
        </>
      )}
      {!confirming && (
        <button
          className="primary-button full"
          disabled={shop.busy || !cart.canCheckout}
          onClick={() => setConfirming(true)}
        >
          注文内容を確認する
          <ArrowRight size={18} />
        </button>
      )}
    </Dialog>
  );
}

/** @param {{order:import('../types').Order}} props */
export function OrderSummary({ order }) {
  return (
    <article className="order-summary">
      <div className="order-label">
        DEMO ORDER <span>{new Date(order.createdAt).toLocaleString('ja-JP')}</span>
      </div>
      <p className="order-id">注文番号：{order.id}</p>
      <p>{order.storeName}で受け取り</p>
      {order.items.map((item) => (
        <div className="order-row" key={item.productId}>
          <span>
            {item.name} × {item.quantity}
          </span>
          <strong>{yen(item.lineTotalYen)}</strong>
        </div>
      ))}
      <div className="grand-total">
        <strong>合計（税込）</strong>
        <strong>{yen(order.totalYen)}</strong>
      </div>
    </article>
  );
}
