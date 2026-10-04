import { ArrowUpRight, Plus } from 'lucide-react';
import { yen } from '../api';

/** @param {{product:import('../types').Product, onOpen:()=>void, onAdd:()=>void, disabled:boolean}} props */
export function ProductCard({ product, onOpen, onAdd, disabled }) {
  return (
    <article className="product-card" data-testid={`product-${product.id}`}>
      <button className="product-photo" onClick={onOpen} aria-label={`${product.name}の詳細`}>
        <img src={product.imageUrl} alt={product.name} loading="lazy" width="1024" height="1536" />
        <span className="product-badge">{product.badge}</span>
        <span className="photo-arrow">
          <ArrowUpRight size={20} />
        </span>
      </button>
      <div className="product-meta">
        <span>{product.category}</span>
        <span className={product.stock ? 'stock' : 'sold-out'}>
          {product.stock ? `在庫 ${product.stock} 点` : 'この店舗では在庫なし'}
        </span>
      </div>
      <button className="product-name" onClick={onOpen}>
        {product.name}
      </button>
      <p className="latin">{product.latinName}</p>
      <div className="product-bottom">
        <span className="price">
          {yen(product.priceYen)} <small>税込</small>
        </span>
        <button
          className="add-button"
          onClick={onAdd}
          disabled={disabled || !product.stock}
          aria-label={`${product.name}をカートに追加`}
        >
          <Plus size={20} />
        </button>
      </div>
    </article>
  );
}
