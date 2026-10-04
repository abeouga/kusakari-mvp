import { ShoppingBag, Sun, Ruler } from 'lucide-react';
import { Dialog } from './Dialog';
import { yen } from '../api';

/** @param {{product:import('../types').Product, storeName:string, onClose:()=>void, onAdd:()=>void, busy:boolean, notice:string, error:string}} props */
export function ProductDetail({ product, storeName, onClose, onAdd, busy, notice, error }) {
  return (
    <Dialog title="植物について" onClose={onClose} wide>
      <div className="product-detail">
        <img src={product.imageUrl} alt={product.name} />
        <div>
          <p className="eyebrow">
            {product.category} / {product.sku}
          </p>
          <h3>{product.name}</h3>
          <p className="latin">{product.latinName}</p>
          <p className="detail-description">{product.description}</p>
          <p className="detail-fact">
            <Ruler size={18} />
            {product.sizeLabel}
          </p>
          <p className="detail-fact">
            <Sun size={18} />
            {product.care}
          </p>
          <p className="detail-price">
            {yen(product.priceYen)} <small>税込 / 1鉢</small>
          </p>
          <p className="muted">
            {storeName}：在庫 {product.stock} 点
          </p>
          <button className="primary-button" disabled={busy || !product.stock} onClick={onAdd}>
            <ShoppingBag size={18} />
            カートに追加
          </button>
          {notice && (
            <p className="success-text" role="status">
              {notice}
            </p>
          )}
          {error && (
            <p className="error" role="alert">
              {error}
            </p>
          )}
          <p className="fine-print">画像はAI生成イメージです。価格・在庫はデモ用です。</p>
        </div>
      </div>
    </Dialog>
  );
}
