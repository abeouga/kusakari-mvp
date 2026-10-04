/**
 * API contract descriptions for checkJs. Runtime data is owned by the Spring Boot API.
 * @typedef {Object} Product
 * @property {string} id
 * @property {string} sku
 * @property {string} name
 * @property {string} latinName
 * @property {string} category
 * @property {string} description
 * @property {string} sizeLabel
 * @property {string} care
 * @property {number} priceYen
 * @property {string} unit
 * @property {string} imageUrl
 * @property {string} badge
 * @property {number} stock
 * @property {string} source
 * @property {string} sourceUpdatedAt
 *
 * @typedef {{id:number, name:string, address:string, hours:string, distanceKm:number|null}} Store
 * @typedef {{product:Product, quantity:number, lineTotalYen:number, available:boolean}} CartLine
 * @typedef {{revision:number, storeId:number, storeName:string, items:CartLine[], totalYen:number, itemCount:number, canCheckout:boolean}} Cart
 * @typedef {{productId:string, sku:string, name:string, quantity:number, unitPriceYen:number, lineTotalYen:number}} OrderLine
 * @typedef {{id:string, status:string, createdAt:string, storeName:string, totalYen:number, items:OrderLine[]}} Order
 * @typedef {{requestId:string, revision:number, expectedTotalYen:number}} Checkout
 * @typedef {{materialCode:string, quantity:number, unit:string}} MaterialItem
 * @typedef {{materialCode:string, status:string, candidates:{product:Product, purchaseQuantity:number, lineTotalYen:number, available:boolean}[]}} MaterialMatch
 */
export {};
