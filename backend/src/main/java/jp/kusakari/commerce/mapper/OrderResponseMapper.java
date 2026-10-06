package jp.kusakari.commerce.mapper;

import java.time.format.DateTimeFormatter;
import java.util.List;
import jp.kusakari.commerce.dto.CommerceDtos.OrderLine;
import jp.kusakari.commerce.dto.CommerceDtos.OrderView;
import jp.kusakari.commerce.persistence.entity.DeliveryFields;
import jp.kusakari.commerce.persistence.entity.OrderEntity;
import jp.kusakari.commerce.persistence.entity.OrderItemEntity;
import jp.kusakari.commerce.service.DeliveryService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class OrderResponseMapper {

  private final DeliveryService delivery;

  public OrderView toView(OrderEntity order, List<OrderItemEntity> items, DeliveryFields details) {
    List<OrderLine> lines = items
      .stream()
      .map(item ->
        new OrderLine(
          item.getId().getProductId(),
          item.getSku(),
          item.getProductName(),
          item.getQuantity(),
          item.getUnitPriceYen(),
          Math.multiplyExact(item.getQuantity(), item.getUnitPriceYen())
        )
      )
      .toList();

    return new OrderView(
      order.getId(),
      order.getStatus(),
      DateTimeFormatter.ISO_INSTANT.format(order.getCreatedAt()),
      order.getStoreName(),
      order.getTotalYen(),
      lines,
      order.getSubtotalYen(),
      order.getShippingFeeYen(),
      delivery.view(details)
    );
  }
}
