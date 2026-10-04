package jp.kusakari.commerce;

import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class CartRepository {

  private final JdbcTemplate jdbc;

  public CartRepository(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  public record CartRow(String id, long storeId, long revision) {}

  public record ItemRow(String productId, int quantity) {}

  public boolean exists(String id) {
    return Boolean.TRUE.equals(jdbc.queryForObject("SELECT EXISTS(SELECT 1 FROM carts WHERE id=?)", Boolean.class, id));
  }

  public void create(String id) {
    jdbc.update("INSERT INTO carts(id) VALUES (?)", id);
  }

  public CartRow lock(String id) {
    return jdbc.queryForObject(
      "SELECT * FROM carts WHERE id=? FOR UPDATE",
      (rs, n) -> new CartRow(rs.getString("id"), rs.getLong("store_id"), rs.getLong("revision")),
      id
    );
  }

  public List<ItemRow> items(String id) {
    return jdbc.query(
      "SELECT product_id,quantity FROM cart_items WHERE cart_id=? ORDER BY product_id",
      (rs, n) -> new ItemRow(rs.getString("product_id"), rs.getInt("quantity")),
      id
    );
  }

  public void setQuantity(String id, String productId, int quantity) {
    if (quantity == 0) jdbc.update("DELETE FROM cart_items WHERE cart_id=? AND product_id=?", id, productId);
    else jdbc.update(
      "INSERT INTO cart_items(cart_id,product_id,quantity) VALUES (?,?,?) ON DUPLICATE KEY UPDATE quantity=?",
      id,
      productId,
      quantity,
      quantity
    );
    increment(id);
  }

  public void setStore(String id, long storeId) {
    jdbc.update("UPDATE carts SET store_id=?,revision=revision+1 WHERE id=?", storeId, id);
  }

  public void clear(String id) {
    jdbc.update("DELETE FROM cart_items WHERE cart_id=?", id);
    increment(id);
  }

  private void increment(String id) {
    jdbc.update("UPDATE carts SET revision=revision+1 WHERE id=?", id);
  }
}
