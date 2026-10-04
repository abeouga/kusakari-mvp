package jp.kusakari.commerce;

import static jp.kusakari.commerce.CommerceDtos.*;

import java.util.List;
import java.util.UUID;
import jp.kusakari.catalog.CatalogRepository;
import jp.kusakari.catalog.CatalogService;
import jp.kusakari.common.ApiException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(isolation = Isolation.READ_COMMITTED)
public class CartService {

  private final CartRepository carts;
  private final OrderRepository orders;
  private final CatalogService catalog;
  private final CatalogRepository stock;

  public CartService(CartRepository carts, OrderRepository orders, CatalogService catalog, CatalogRepository stock) {
    this.carts = carts;
    this.orders = orders;
    this.catalog = catalog;
    this.stock = stock;
  }

  public CartView read(String id) {
    return view(carts.lock(id));
  }

  public CartView updateItem(String id, String productId, ItemRequest request) {
    var cart = carts.lock(id);
    checkRevision(cart, request.revision());
    var product = catalog
      .products(cart.storeId())
      .stream()
      .filter(p -> p.id().equals(productId))
      .findFirst()
      .orElseThrow(() -> new ApiException(404, "PRODUCT_NOT_FOUND", "商品が見つかりません。"));
    if (request.quantity() > product.stock()) throw new ApiException(
      409,
      "OUT_OF_STOCK",
      "選択した店舗の在庫が不足しています。"
    );
    carts.setQuantity(id, productId, request.quantity());
    return view(carts.lock(id));
  }

  public CartView updateStore(String id, StoreRequest request) {
    var cart = carts.lock(id);
    checkRevision(cart, request.revision());
    catalog.requireStore(request.storeId());
    carts.setStore(id, request.storeId());
    return view(carts.lock(id));
  }

  public OrderView checkout(String id, CheckoutRequest request) {
    var cart = carts.lock(id);
    // A lost HTTP response can be retried with the same key, even after the cart was cleared.
    var existing = orders.byRequest(id, request.requestId().toString());
    if (existing.isPresent()) {
      var order = existing.get();
      if (
        order.requestRevision() != request.revision() || order.totalYen() != request.expectedTotalYen()
      ) throw new ApiException(409, "REQUEST_REUSED", "同じ注文キーに異なる内容は指定できません。");
      return orderView(order);
    }
    checkRevision(cart, request.revision());
    stock.lockInventory(cart.storeId(), carts.items(id).stream().map(CartRepository.ItemRow::productId).toList());
    var current = view(cart);
    if (current.items().isEmpty()) throw new ApiException(409, "EMPTY_CART", "カートが空です。");
    if (!current.canCheckout()) throw new ApiException(
      409,
      "OUT_OF_STOCK",
      "在庫が変更されました。数量または受取店舗を変更してください。"
    );
    if (current.totalYen() != request.expectedTotalYen()) throw new ApiException(
      409,
      "PRICE_CHANGED",
      "価格が変更されました。合計金額を確認してください。"
    );
    String orderId = UUID.randomUUID().toString();
    orders.insert(
      orderId,
      id,
      request.requestId().toString(),
      request.revision(),
      current.storeName(),
      current.totalYen()
    );
    for (var line : current.items()) {
      var product = line.product();
      if (!stock.reduceStock(cart.storeId(), product.id(), line.quantity())) throw new ApiException(
        409,
        "OUT_OF_STOCK",
        "在庫が変更されました。もう一度確認してください。"
      );
      orders.insertLine(orderId, product.id(), product.sku(), product.name(), line.quantity(), product.priceYen());
    }
    carts.clear(id);
    return orderView(orders.byRequest(id, request.requestId().toString()).orElseThrow());
  }

  public List<OrderView> orders(String id) {
    return orders.list(id).stream().map(this::orderView).toList();
  }

  private CartView view(CartRepository.CartRow cart) {
    var products = catalog.products(cart.storeId());
    var lines = carts
      .items(cart.id())
      .stream()
      .map(item -> {
        var product = products
          .stream()
          .filter(p -> p.id().equals(item.productId()))
          .findFirst()
          .orElseThrow();
        return new CartLine(
          product,
          item.quantity(),
          Math.multiplyExact(product.priceYen(), item.quantity()),
          product.stock() >= item.quantity()
        );
      })
      .toList();
    return new CartView(
      cart.revision(),
      cart.storeId(),
      catalog.requireStore(cart.storeId()).name(),
      lines,
      lines.stream().mapToInt(CartLine::lineTotalYen).sum(),
      lines.stream().mapToInt(CartLine::quantity).sum(),
      !lines.isEmpty() && lines.stream().allMatch(CartLine::available)
    );
  }

  private OrderView orderView(OrderRepository.OrderRow order) {
    var items = orders
      .lines(order.id())
      .stream()
      .map(i ->
        new OrderLine(
          i.productId(),
          i.sku(),
          i.name(),
          i.quantity(),
          i.unitPriceYen(),
          Math.multiplyExact(i.quantity(), i.unitPriceYen())
        )
      )
      .toList();
    return new OrderView(order.id(), order.status(), order.createdAt(), order.storeName(), order.totalYen(), items);
  }

  private void checkRevision(CartRepository.CartRow cart, long expected) {
    if (cart.revision() != expected) throw new ApiException(
      409,
      "CART_CHANGED",
      "別の操作でカートが更新されました。最新の内容を確認してください。"
    );
  }
}
