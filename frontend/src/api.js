export class ApiError extends Error {
  /** @param {string} message @param {number} status */
  constructor(message, status) {
    super(message);
    this.status = status;
  }
}

/** @param {string} path @param {RequestInit} [options] */
async function request(path, options = {}) {
  let response;
  try {
    response = await fetch(`/api${path}`, {
      ...options,
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json', ...options.headers },
    });
  } catch {
    throw new ApiError('サーバーに接続できません。接続を確認して再試行してください。', 0);
  }
  const data = await response.json();
  if (!response.ok) throw new ApiError(data.message || '処理を完了できませんでした。', response.status);
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
    request(`/cart/items/${encodeURIComponent(id)}`, { method: 'PUT', body: JSON.stringify({ quantity, revision }) }),
  /** @param {number} storeId @param {number} revision @returns {Promise<import('./types').Cart>} */
  setStore: (storeId, revision) =>
    request('/cart/store', { method: 'PUT', body: JSON.stringify({ storeId, revision }) }),
  /** @param {import('./types').Checkout} payload @returns {Promise<import('./types').Order>} */
  checkout: (payload) => request('/orders', { method: 'POST', body: JSON.stringify(payload) }),
  /** @returns {Promise<import('./types').Order[]>} */
  orders: () => request('/orders'),
  /** @param {number} storeId @param {import('./types').MaterialItem[]} items @returns {Promise<import('./types').MaterialMatch[]>} */
  materials: (storeId, items) =>
    request('/materials/quote', { method: 'POST', body: JSON.stringify({ storeId, items }) }),
};

/** @param {number} value */
export const yen = (value) => new Intl.NumberFormat('ja-JP', { style: 'currency', currency: 'JPY' }).format(value);
