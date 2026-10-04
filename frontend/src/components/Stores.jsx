import { MapPin, Navigation, Check, Clock } from 'lucide-react';
import { Dialog } from './Dialog';

/** @param {{shop:ReturnType<import('../useShop').useShop>, onClose:()=>void}} props */
export function Stores({ shop, onClose }) {
  return (
    <Dialog title="受取店舗を選ぶ" onClose={onClose} wide>
      {shop.error && (
        <p className="error" role="alert">
          {shop.error}
        </p>
      )}
      <p className="muted">{shop.locationLabel}から近い順に表示しています。距離は直線距離です。</p>
      <div className="location-controls">
        <label>
          距離の基準
          <select
            aria-label="距離の基準"
            disabled={shop.busy}
            value={shop.locationLabel}
            onChange={(event) => {
              const points = /** @type {Record<string, [number, number]>} */ ({
                東京駅: [35.6812, 139.7671],
                横浜駅: [35.466, 139.622],
                大宮駅: [35.906, 139.624],
              });
              const point = points[event.target.value];
              if (point) void shop.locate(...point, event.target.value);
            }}
          >
            <option>東京駅</option>
            <option>横浜駅</option>
            <option>大宮駅</option>
            {shop.locationLabel === '現在地' && <option>現在地</option>}
          </select>
        </label>
        <button className="secondary-button" onClick={shop.geolocate} disabled={shop.busy}>
          <Navigation size={16} />
          現在地を使う
        </button>
      </div>
      <div className="store-list">
        {shop.stores.map((store, index) => (
          <article className={`store-card ${store.id === shop.cart?.storeId ? 'selected' : ''}`} key={store.id}>
            <div className="store-title">
              <MapPin size={22} />
              <h3>{store.name}</h3>
              {index === 0 && <span className="pill">最寄り</span>}
              <strong>{store.distanceKm} km</strong>
            </div>
            <p>{store.address}</p>
            <p>
              <Clock size={14} />
              {store.hours}
            </p>
            <button
              className={store.id === shop.cart?.storeId ? 'secondary-button' : 'primary-button'}
              disabled={shop.busy || store.id === shop.cart?.storeId}
              onClick={() => void shop.selectStore(store.id)}
            >
              {store.id === shop.cart?.storeId ? (
                <>
                  <Check size={16} />
                  選択中
                </>
              ) : (
                'この店舗で受け取る'
              )}
            </button>
          </article>
        ))}
      </div>
      <p className="fine-print">店舗はすべて架空です。実店舗の営業時間・在庫とは連動していません。</p>
    </Dialog>
  );
}
