import { useState } from 'react';
import { ArrowRight, FileJson } from 'lucide-react';
import { Dialog } from './Dialog';
import { api, yen } from '../api';

const example = JSON.stringify(
  [
    { materialCode: 'plant.olive', quantity: 1, unit: 'piece' },
    { materialCode: 'plant.herb', quantity: 2, unit: 'piece' },
  ],
  null,
  2,
);

/** @param {{shop:ReturnType<import('../useShop').useShop>, onClose:()=>void}} props */
export function Materials({ shop, onClose }) {
  const [source, setSource] = useState(example);
  const [matches, setMatches] = useState(/** @type {import('../types').MaterialMatch[]} */ ([]));
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  async function search() {
    setError('');
    setBusy(true);
    setMatches([]);
    try {
      const items = JSON.parse(source);
      if (!Array.isArray(items)) throw new Error('材料リストはJSON配列で入力してください。');
      setMatches(await api.materials(shop.cart?.storeId || 1, items));
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : '材料リストを確認してください。');
    } finally {
      setBusy(false);
    }
  }
  return (
    <Dialog title="材料リストから商品を探す" onClose={onClose} wide>
      <p className="muted">
        材料コードと必要個数から、選択中の店舗で扱う商品候補を表示します。候補は個別に選んでカートへ追加できます。
      </p>
      <label className="field-label" htmlFor="material-json">
        <FileJson size={17} />
        材料リスト（JSON）
      </label>
      <textarea
        id="material-json"
        spellCheck={false}
        value={source}
        onChange={(event) => {
          setSource(event.target.value);
          setMatches([]);
        }}
        rows={10}
      />
      <p className="fine-print">
        対応コード：plant.olive / plant.lavender / plant.rosemary / plant.monstera / plant.herb。単位は
        piece（鉢）です。Greenlyとはまだ接続していません。
      </p>
      <button className="primary-button" disabled={busy || shop.busy} onClick={() => void search()}>
        {busy ? '検索中…' : '商品候補を検索'}
        <ArrowRight size={17} />
      </button>
      {(error || shop.error) && (
        <p className="error" role="alert">
          {error || shop.error}
        </p>
      )}
      {shop.notice && (
        <p className="success-text" role="status">
          {shop.notice}
        </p>
      )}
      <div className="material-results">
        {matches.map((match, index) => (
          <section key={`${match.materialCode}-${index}`}>
            <h3>{match.materialCode}</h3>
            {!match.candidates.length && (
              <p className="muted">対応する商品はありません。材料コードを確認してください。</p>
            )}
            {match.candidates.map((candidate) => (
              <div className="material-candidate" key={candidate.product.id}>
                <img src={candidate.product.imageUrl} alt="" />
                <div>
                  <strong>{candidate.product.name}</strong>
                  <p>
                    {candidate.purchaseQuantity} 鉢 / {yen(candidate.lineTotalYen)}
                  </p>
                  <small>店舗在庫 {candidate.product.stock} 点</small>
                </div>
                <button
                  className="secondary-button"
                  disabled={shop.busy || !candidate.available}
                  onClick={() => void shop.add(candidate.product.id, candidate.purchaseQuantity)}
                >
                  {candidate.available ? 'カートに追加' : '在庫不足'}
                </button>
              </div>
            ))}
          </section>
        ))}
      </div>
    </Dialog>
  );
}
