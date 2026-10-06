import { useState } from 'react';
import {
  ArrowDown,
  ArrowRight,
  ArrowUpRight,
  Check,
  ChevronDown,
  Leaf,
  MapPin,
  Search,
  ShoppingBag,
  Sprout,
  X,
  PackageCheck,
  ListTree,
} from 'lucide-react';
import { useShop } from './useShop';
import { ProductCard } from './components/ProductCard';
import { ProductDetail } from './components/ProductDetail';
import { Dialog } from './components/Dialog';
import { Cart, OrderSummary } from './components/Cart';
import { Stores } from './components/Stores';
import { Materials } from './components/Materials';

const categories = ['すべて', '庭木', '草花', 'ハーブ', '観葉植物'];

export default function App() {
  const shop = useShop();
  const [panel, setPanel] = useState('');
  const [detailId, setDetailId] = useState('');
  const [category, setCategory] = useState('すべて');
  const [search, setSearch] = useState('');
  const [sort, setSort] = useState('recommended');
  const [inStockOnly, setInStockOnly] = useState(false);
  const detail = shop.products.find((product) => product.id === detailId);
  const keyword = search.trim().toLowerCase();
  const products = [];
  for (const product of shop.products) {
    if (category !== 'すべて' && product.category !== category) continue;
    if (inStockOnly && product.stock === 0) continue;
    const text = `${product.name} ${product.latinName} ${product.sku}`.toLowerCase();
    if (!text.includes(keyword)) continue;
    products.push(product);
  }
  if (sort === 'price-asc') {
    products.sort((a, b) => a.priceYen - b.priceYen);
  }
  if (sort === 'price-desc') {
    products.sort((a, b) => b.priceYen - a.priceYen);
  }
  let itemCount = 0;
  let storeName = '';
  let storeLabel = '読み込み中…';
  if (shop.cart) {
    itemCount = shop.cart.itemCount;
    storeName = shop.cart.storeName;
    storeLabel = storeName;
  }
  const loading = !shop.cart && shop.busy;

  function close() {
    setPanel('');
    setDetailId('');
    shop.setLastOrder(null);
  }
  /** @param {string} next */
  function open(next) {
    shop.setError('');
    shop.setNotice('');
    setPanel(next);
  }

  return (
    <>
      <a className="skip-link" href="#plants">
        商品一覧へスキップ
      </a>
      <div className="announcement">
        <span>GREEN FOR YOUR EVERYDAY</span>
        <span>ひと鉢からはじまる、緑のある暮らし。</span>
        <span>植物のオンラインストア</span>
      </div>
      <header className="site-header">
        <a className="brand" href="#" aria-label="Kusakari トップへ">
          <Sprout strokeWidth={1.5} />
          <span>
            kusakari<span className="brand-dot">.</span>
          </span>
        </a>
        <nav aria-label="メインナビゲーション">
          <a className="active" href="#plants">
            植物を探す
          </a>
          <button onClick={() => open('stores')}>店舗を探す</button>
          <button onClick={() => open('guide')}>Kusakariについて</button>
        </nav>
        <div className="header-actions">
          <button className="history-button" onClick={() => open('orders')}>
            注文履歴
          </button>
          <button className="bag-button" onClick={() => open('cart')} aria-label={`カートを開く（${itemCount}点）`}>
            <ShoppingBag size={20} />
            <span className="bag-text">バッグ</span>
            <span className="bag-count">{itemCount}</span>
          </button>
        </div>
      </header>

      <main>
        <section className="hero">
          <div className="hero-copy">
            <p className="eyebrow">
              <span className="tiny-line" /> ROOTED IN EVERYDAY LIFE
            </p>
            <h1>
              植物と、
              <br />
              暮らす<span className="soft-dot">。</span>
            </h1>
            <p className="hero-description">
              朝の光に揺れる葉。
              <br />
              ふと目を向けたくなる、小さな緑。
              <br />
              あなたの毎日に、ひと鉢の余白を。
            </p>
            <a className="primary-button hero-button" href="#plants">
              お気に入りの植物を探す
              <ArrowRight size={18} />
            </a>
            <div className="hero-footnote">
              <span>01 — THE GREEN COLLECTION</span>
              <ArrowDown size={16} />
            </div>
          </div>
          <div className="hero-visual">
            <img
              src="/images/olive.png"
              alt="柔らかな光の中のオリーブの鉢植え"
              fetchPriority="high"
              width="1024"
              height="1536"
            />
            <span className="vertical-caption">A LITTLE GREEN, A LITTLE BETTER.</span>
            <button
              className="hero-product-label"
              onClick={() => setDetailId('olive')}
              disabled={!shop.products.length}
            >
              <span>
                <small>MEET YOUR FIRST GREEN</small>
                <strong>オリーブ</strong>
                <em>Olea europaea</em>
              </span>
              <ArrowUpRight size={26} />
            </button>
            <div className="hero-stamp">
              <Leaf size={23} />
              <span>
                GROW
                <br />
                SLOWLY.
              </span>
            </div>
          </div>
        </section>

        <div className="benefits">
          <span>
            <Sprout size={20} />
            暮らしに合う植物を
          </span>
          <span>
            <MapPin size={19} />
            お近くの店舗で受け取り
          </span>
          <span>
            <PackageCheck size={20} />
            店舗ごとの在庫を確認
          </span>
        </div>

        <section className="catalog section-container" id="plants">
          <div className="section-heading">
            <div>
              <p className="eyebrow">FIND YOUR GREEN</p>
              <h2>わたしに合う、ひと鉢。</h2>
            </div>
            <p>
              庭にも、ベランダにも、お部屋にも。
              <br />
              植物との暮らしを、ここから。
            </p>
          </div>
          <div className="store-strip">
            <span>
              <MapPin size={17} />
              <small>受取店舗</small>
              <strong>{storeLabel}</strong>
            </span>
            <button onClick={() => open('stores')} disabled={!shop.cart}>
              店舗を変更
              <ChevronDown size={15} />
            </button>
          </div>
          <div className="catalog-controls">
            <div className="categories" aria-label="商品カテゴリー">
              {categories.map((item) => (
                <button key={item} aria-pressed={category === item} onClick={() => setCategory(item)}>
                  {item}
                </button>
              ))}
            </div>
            <label className="search-input">
              <Search size={17} />
              <input
                aria-label="植物を検索"
                placeholder="名前・品番で検索"
                value={search}
                onChange={(event) => setSearch(event.target.value)}
              />
              {search && (
                <button aria-label="検索をクリア" onClick={() => setSearch('')}>
                  <X size={14} />
                </button>
              )}
            </label>
          </div>
          <div className="catalog-meta">
            <span>
              {products.length} ITEMS <small>/ すべて税込価格</small>
            </span>
            <div>
              <label className="stock-filter">
                <input
                  type="checkbox"
                  checked={inStockOnly}
                  onChange={(event) => setInStockOnly(event.target.checked)}
                />
                在庫ありのみ
              </label>
              <select aria-label="商品の並び順" value={sort} onChange={(event) => setSort(event.target.value)}>
                <option value="recommended">おすすめ順</option>
                <option value="price-asc">価格が安い順</option>
                <option value="price-desc">価格が高い順</option>
              </select>
            </div>
          </div>
          {shop.error && !panel && !detail && (
            <div className="error" role="alert">
              {shop.error}
              <button className="text-button" onClick={shop.initialize} disabled={shop.busy}>
                再読み込み
              </button>
            </div>
          )}
          {loading && (
            <div className="loading" role="status">
              植物を読み込んでいます…
            </div>
          )}
          {!loading && (
            <div className="product-grid">
              {products.map((product) => (
                <ProductCard
                  key={product.id}
                  product={product}
                  onOpen={() => {
                    shop.setError('');
                    shop.setNotice('');
                    setDetailId(product.id);
                  }}
                  onAdd={() => shop.add(product.id)}
                  disabled={shop.busy || !shop.cart}
                />
              ))}
            </div>
          )}
          {shop.cart && !products.length && (
            <div className="empty">
              <Leaf size={30} />
              <h3>条件に合う植物が見つかりません。</h3>
              <button
                className="secondary-button"
                onClick={() => {
                  setCategory('すべて');
                  setSearch('');
                  setInStockOnly(false);
                }}
              >
                条件をリセット
              </button>
            </div>
          )}
          <p className="catalog-note">画像はAI生成です。掲載商品・価格・在庫・店舗は、このサイトのデモ用データです。</p>
        </section>

        <section className="material-banner section-container">
          <div className="material-illustration">
            <ListTree size={44} strokeWidth={1} />
            <span>PLAN → PLANT</span>
          </div>
          <div>
            <p className="eyebrow">FROM YOUR GARDEN PLAN</p>
            <h2>庭の計画を、ひと鉢ずつ。</h2>
            <p>
              材料リストから、必要な植物と購入個数を確認。
              <br />
              理想の庭へ、次の一歩を。
            </p>
          </div>
          <button className="outline-button" onClick={() => open('materials')} disabled={!shop.cart}>
            材料リストから探す
            <ArrowUpRight size={19} />
          </button>
        </section>

        <section className="editorial section-container">
          <div>
            <p className="eyebrow">OUR PHILOSOPHY</p>
            <h2>
              育てる時間も、
              <br />
              暮らしの一部に。
            </h2>
          </div>
          <div>
            <p>
              葉が一枚増えたこと。いつもより花が開いたこと。
              <br />
              小さな変化を見つける時間が、毎日に余白をつくります。
            </p>
            <button className="text-link" onClick={() => open('guide')}>
              Kusakariについて
              <ArrowRight size={18} />
            </button>
          </div>
        </section>
      </main>

      <footer className="site-footer">
        <div>
          <span className="brand footer-brand">
            <Sprout strokeWidth={1.5} />
            <span>kusakari.</span>
          </span>
          <p>植物と、暮らす。</p>
        </div>
        <div className="footer-links">
          <button onClick={() => open('guide')}>ご利用ガイド</button>
          <button onClick={() => open('stores')}>店舗一覧</button>
          <button onClick={() => open('orders')}>注文履歴</button>
        </div>
        <div className="footer-bottom">
          <span>© {new Date().getFullYear()} Kusakari</span>
          <span>LOCAL DEMO STORE · NO PAYMENT</span>
        </div>
      </footer>

      {shop.notice && !panel && !detail && (
        <div className="toast" role="status">
          <Check size={17} />
          {shop.notice}
          <button onClick={() => open('cart')}>
            バッグを見る
            <ArrowRight size={15} />
          </button>
          <button aria-label="通知を閉じる" onClick={() => shop.setNotice('')}>
            <X size={16} />
          </button>
        </div>
      )}
      {detail && (
        <ProductDetail
          product={detail}
          storeName={storeName}
          onClose={close}
          onAdd={() => shop.add(detail.id)}
          busy={shop.busy}
          notice={shop.notice}
          error={shop.error}
        />
      )}
      {panel === 'cart' && <Cart shop={shop} onClose={close} onStores={() => open('stores')} />}
      {panel === 'stores' && <Stores shop={shop} onClose={close} />}
      {panel === 'materials' && <Materials shop={shop} onClose={close} />}
      {panel === 'orders' && (
        <Dialog title="注文履歴" onClose={close}>
          {shop.orders.map((order) => (
            <OrderSummary order={order} key={order.id} />
          ))}
          {shop.orders.length === 0 && (
            <div className="empty">
              <PackageCheck size={36} />
              <h3>注文履歴はまだありません。</h3>
              <p>このブラウザーで確定したデモ注文が表示されます。</p>
            </div>
          )}
        </Dialog>
      )}
      {panel === 'guide' && (
        <Dialog title="Kusakariについて" onClose={close}>
          <div className="guide">
            <p className="eyebrow">PLANTS FOR EVERYDAY LIVING</p>
            <h3>植物と暮らす、はじめの一歩。</h3>
            <p>Kusakariは、庭木・草花・ハーブ・観葉植物を探し、店舗ごとの価格と在庫を確認できるECサイトのデモです。</p>
            <h4>お買い物の流れ</h4>
            <ol>
              <li>受取店舗を選び、植物をカートに追加します。</li>
              <li>カートで購入個数と合計金額を確認します。</li>
              <li>確認画面からデモ注文を確定します。</li>
            </ol>
            <h4>このデモでの取り扱い</h4>
            <p>
              すべて税込価格、店舗受け取りは無料です。実決済・配送・実店舗への予約は発生しません。商品画像はAI生成、店舗は架空です。
            </p>
            <p>
              カートと注文履歴はブラウザーのCookieに紐づいて保存されます。Cookieを削除すると、同じ履歴を開けなくなります。個人情報やカード情報は入力しません。
            </p>
            <h4>材料リストについて</h4>
            <p>材料コードから商品候補を検索できます。現在はGreenlyとの自動接続はありません。</p>
          </div>
        </Dialog>
      )}
    </>
  );
}
