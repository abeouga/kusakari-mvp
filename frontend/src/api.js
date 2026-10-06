export class ApiError extends Error {
  /** @param {string} message @param {number} status */
  constructor(message, status) {
    super(message);
    this.status = status;
  }
}

/** @param {string} path @param {string} [method] @param {string} [body] */
async function request(path, method = 'GET', body) {
  let response;
  try {
    response = await fetch(`/api${path}`, {
      method,
      body,
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
    });
  } catch {
    throw new ApiError('サーバーに接続できません。接続を確認して再試行してください。', 0);
  }
  const data = await response.json();
  if (!response.ok) {
    let message = '処理を完了できませんでした。';
    if (data.message) message = data.message;
    throw new ApiError(message, response.status);
  }
  return data;
}

export const api = {
  /** @returns {Promise<import('./types').Cart>} */
  cart: () => request('/cart'),
  /** @param {number} storeId @returns {Promise<import('./types').Product[]>} */
  products: (storeId) => request(`/products?storeId=${storeId}`),
  /** @param {number} latitude @param {number} longitude @returns {Promise<import('./types').Store[]>} */
  stores: (latitude, longitude) => request(`/stores?latitude=${latitude}&longitude=${longitude}`),
  /** @param {string} id @param {number} quantity @param {number} revision @returns {Promise<import('./types').Cart>} */
  setItem: (id, quantity, revision) =>
    request(`/cart/items/${encodeURIComponent(id)}`, 'PUT', JSON.stringify({ quantity, revision })),
  /** @param {number} storeId @param {number} revision @returns {Promise<import('./types').Cart>} */
  setStore: (storeId, revision) => request('/cart/store', 'PUT', JSON.stringify({ storeId, revision })),
  /** @param {import('./types').Checkout} payload @returns {Promise<import('./types').Order>} */
  checkout: (payload) => request('/orders', 'POST', JSON.stringify(payload)),
  /** @returns {Promise<import('./types').Order[]>} */
  orders: () => request('/orders'),
  /** @param {number} storeId @param {import('./types').MaterialItem[]} items @returns {Promise<import('./types').MaterialMatch[]>} */
  materials: (storeId, items) => request('/materials/quote', 'POST', JSON.stringify({ storeId, items })),
};

/** @param {number} value */
export const yen = (value) => new Intl.NumberFormat('ja-JP', { style: 'currency', currency: 'JPY' }).format(value);
