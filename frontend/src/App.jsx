import { useState } from 'react';
import {
  ArrowDown,
  ArrowRight,
  ArrowUpRight,
  Check,
  Leaf,
  MapPin,
  ShoppingBag,
  PackageCheck,
  Sprout,
  X,
  ListTree,
} from 'lucide-react';
import { useShop } from './useShop';
import { Catalog } from './components/Catalog';
import { ProductManager } from './components/ProductManager';
import { Orders } from './components/Orders';
import { ProductDetail } from './components/ProductDetail';
import { Dialog } from './components/Dialog';
import { CartPage } from './components/CartPage';
import { Stores } from './components/Stores';
import { Materials } from './components/Materials';

export default function App() {
  const shop = useShop();
  const [panel, setPanel] = useState('');
  const [detailId, setDetailId] = useState('');
  const detail = shop.products.find((product) => product.id === detailId);
  let itemCount = 0;
  let storeName = '';
  if (shop.cart) {
    itemCount = shop.cart.itemCount;
    storeName = shop.cart.storeName;
  }
  /** @param {string} id */
  function openDetail(id) {
    shop.setError('');
    shop.setNotice('');
    setDetailId(id);
  }

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

  if (window.location.pathname === '/cart') {
    return (
      <>
        <CartPage shop={shop} onOrders={() => open('orders')} onStores={() => open('stores')} />
        {panel === 'stores' && <Stores shop={shop} onClose={close} />}
        {panel === 'orders' && <Orders shop={shop} onClose={close} />}
      </>
    );
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
          <a className="bag-button" href="/cart" aria-label={`カートを開く（${itemCount}点）`}>
            <ShoppingBag size={20} />
            <span className="bag-text">バッグ</span>
            <span className="bag-count">{itemCount}</span>
          </a>
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
            <button className="hero-product-label" onClick={() => openDetail('olive')} disabled={!shop.products.length}>
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

        <Catalog shop={shop} onStores={() => open('stores')} onDetail={openDetail} />

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
          <button onClick={() => open('manage')}>商品管理</button>
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
          <a href="/cart">
            カートを見る
            <ArrowRight size={15} />
          </a>
          <button aria-label="通知を閉じる" onClick={() => shop.setNotice('')}>
            <X size={16} />
          </button>
        </div>
      )}
      {detail && (
        <ProductDetail
          key={detail.id}
          product={detail}
          storeName={storeName}
          onClose={close}
          onAdd={(quantity) => shop.add(detail.id, quantity)}
          busy={shop.busy}
          notice={shop.notice}
          error={shop.error}
        />
      )}
      {panel === 'stores' && <Stores shop={shop} onClose={close} />}
      {panel === 'materials' && <Materials shop={shop} onClose={close} />}
      {panel === 'orders' && <Orders shop={shop} onClose={close} />}
      {panel === 'manage' && <ProductManager shop={shop} onClose={close} />}
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
              カートと注文履歴はブラウザーのCookieに紐づいて保存されます。Cookieを削除すると、同じ履歴を開けなくなります。連絡先にはデモ情報を入力してください。カード情報は入力しません。
            </p>
            <h4>材料リストについて</h4>
            <p>材料コードから商品候補を検索できます。現在はGreenlyとの自動接続はありません。</p>
          </div>
        </Dialog>
      )}
    </>
  );
}
