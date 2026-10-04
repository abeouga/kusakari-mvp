package jp.kusakari.commerce;

import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

@Repository
public class OrderRepository {

  private final JdbcTemplate jdbc;

  public OrderRepository(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  public record OrderRow(
    String id,
    String status,
    String createdAt,
    String storeName,
    int totalYen,
    long requestRevision
  ) {}

  public record LineRow(String productId, String sku, String name, int quantity, int unitPriceYen) {}

  private static final RowMapper<OrderRow> ROW = (rs, n) ->
    new OrderRow(
      rs.getString("id"),
      rs.getString("status"),
      rs.getTimestamp("created_at").toInstant().toString(),
      rs.getString("store_name"),
      rs.getInt("total_yen"),
      rs.getLong("request_revision")
    );

  public Optional<OrderRow> byRequest(String cartId, String requestId) {
    return jdbc
      .query("SELECT * FROM orders WHERE cart_id=? AND request_id=?", ROW, cartId, requestId)
      .stream()
      .findFirst();
  }

  public List<OrderRow> list(String cartId) {
    return jdbc.query("SELECT * FROM orders WHERE cart_id=? ORDER BY created_at DESC,id LIMIT 30", ROW, cartId);
  }

  public List<LineRow> lines(String orderId) {
    return jdbc.query(
      "SELECT * FROM order_items WHERE order_id=? ORDER BY product_id",
      (rs, n) ->
        new LineRow(
          rs.getString("product_id"),
          rs.getString("sku"),
          rs.getString("product_name"),
          rs.getInt("quantity"),
          rs.getInt("unit_price_yen")
        ),
      orderId
    );
  }

  public void insert(String id, String cartId, String requestId, long revision, String storeName, int total) {
    jdbc.update(
      "INSERT INTO orders(id,cart_id,request_id,request_revision,store_name,total_yen) VALUES (?,?,?,?,?,?)",
      id,
      cartId,
      requestId,
      revision,
      storeName,
      total
    );
  }

  public void insertLine(String id, String productId, String sku, String name, int quantity, int price) {
    jdbc.update(
      "INSERT INTO order_items(order_id,product_id,sku,product_name,quantity,unit_price_yen) VALUES (?,?,?,?,?,?)",
      id,
      productId,
      sku,
      name,
      quantity,
      price
    );
  }
}
