/** @param {{details:import('../types').DeliveryDetails}} props */
export function DeliverySummary({ details }) {
  let method = '店舗受取';
  let payment = 'カード決済（デモ）';
  let time = '指定なし';
  if (details.timeSlot !== 'ANY') time = details.timeSlot + '時';
  if (details.fulfillmentMethod === 'DELIVERY') method = '自宅配送';
  if (details.paymentMethod === 'STORE') payment = '店頭払い（デモ）';
  if (details.paymentMethod === 'DEMO_WALLET') payment = 'ウォレット決済（デモ）';
  return (
    <div className="delivery-summary">
      <p>
        <strong>{method}</strong> / {payment}
      </p>
      {details.recipientName && (
        <p>
          {details.recipientName} / {details.recipientPhone}
        </p>
      )}
      {details.contactEmail && <p>{details.contactEmail}</p>}
      {details.fulfillmentMethod === 'DELIVERY' && (
        <p>
          〒{details.postalCode} {details.addressLine1} {details.addressLine2}
        </p>
      )}
      {details.requestedDate && (
        <p>
          希望日：{details.requestedDate} / {time}
        </p>
      )}
    </div>
  );
}
