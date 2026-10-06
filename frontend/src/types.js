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
 * @property {string} nurseryName
 * @property {string} nurseryAddress
 * @property {string} sunlight
 * @property {string} useCase
 * @property {number} careLevel
 * @property {number|null} minTemperatureC
 * @property {boolean} heatTolerant
 * @property {boolean} droughtTolerant
 * @property {number|null} ageYears
 * @property {number|null} heightCm
 * @property {number|null} potDiameterCm
 * @property {string} familyName
 * @property {string|null} floweringDescription
 * @property {string|null} seasonalCare
 * @property {string|null} styleDescription
 * @property {string} publishedAt
 * @property {boolean} active
 * @property {string[]} images
 *
 * @typedef {{id:number, name:string, address:string, hours:string, distanceKm:number|null}} Store
 * @typedef {{product:Product, quantity:number, lineTotalYen:number, available:boolean}} CartLine
 * @typedef {{revision:number, storeId:number, storeName:string, items:CartLine[], totalYen:number, itemCount:number, canCheckout:boolean, subtotalYen:number, shippingFeeYen:number, details:DeliveryDetails}} Cart
 * @typedef {{productId:string, sku:string, name:string, quantity:number, unitPriceYen:number, lineTotalYen:number}} OrderLine
 * @typedef {{id:string, status:string, createdAt:string, storeName:string, totalYen:number, items:OrderLine[], subtotalYen:number, shippingFeeYen:number, details:DeliveryDetails}} Order
 * @typedef {{fulfillmentMethod:string, paymentMethod:string, recipientName:string, recipientPhone:string, contactEmail:string, postalCode:string, addressLine1:string, addressLine2:string, requestedDate:string, timeSlot:string}} DeliveryDetails
 * @typedef {Omit<Product,'id'|'unit'|'source'|'sourceUpdatedAt'|'publishedAt'|'active'|'floweringDescription'|'seasonalCare'|'styleDescription'> & {storeId:number,floweringDescription:string,seasonalCare:string,styleDescription:string}} ProductInput
 * @typedef {{requestId:string, revision:number, expectedTotalYen:number}} Checkout
 * @typedef {{materialCode:string, quantity:number, unit:string}} MaterialItem
 * @typedef {{materialCode:string, status:string, candidates:{product:Product, purchaseQuantity:number, lineTotalYen:number, available:boolean}[]}} MaterialMatch
 */
export {};
