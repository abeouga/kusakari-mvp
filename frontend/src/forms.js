/** @param {FormData} data @param {string} name */
export function formText(data, name) {
  const value = data.get(name);
  if (typeof value === 'string') return value.trim();
  return '';
}

/** @param {FormData} data @param {string} name */
export function formNumber(data, name) {
  const value = formText(data, name);
  if (value === '') return null;
  return Number(value);
}

/** @param {number|null} value */
export function numberValue(value) {
  if (value === null) return '';
  return value;
}
