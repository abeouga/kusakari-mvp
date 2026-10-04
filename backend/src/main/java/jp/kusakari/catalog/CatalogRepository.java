package jp.kusakari.catalog;

import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

@Repository
public class CatalogRepository {

  private final JdbcTemplate jdbc;

  public CatalogRepository(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  private static final RowMapper<Product> PRODUCT = (rs, row) ->
    new Product(
      rs.getString("id"),
      rs.getString("sku"),
      rs.getString("name"),
      rs.getString("latin_name"),
      rs.getString("category"),
      rs.getString("description"),
      rs.getString("size_label"),
      rs.getString("care"),
      rs.getInt("price_yen"),
      rs.getString("unit"),
      rs.getString("image_url"),
      rs.getString("badge"),
      rs.getString("source"),
      rs.getTimestamp("source_updated_at").toInstant().toString(),
      rs.getInt("quantity")
    );

  public List<Product> products(long storeId) {
    return jdbc.query(
      """
      SELECT p.*, i.quantity FROM products p JOIN inventory i ON i.product_id=p.id
      WHERE i.store_id=? ORDER BY FIELD(p.id,'olive','lavender','rosemary','monstera'),p.id
      """,
      PRODUCT,
      storeId
    );
  }

  public List<String> mappedProductIds(String materialCode) {
    return jdbc.queryForList(
      "SELECT product_id FROM material_products WHERE material_code=?",
      String.class,
      materialCode
    );
  }

  public List<Store> stores() {
    return jdbc.query("SELECT * FROM stores ORDER BY id", (rs, row) ->
      new Store(
        rs.getLong("id"),
        rs.getString("name"),
        rs.getString("address"),
        rs.getDouble("latitude"),
        rs.getDouble("longitude"),
        rs.getString("hours")
      )
    );
  }

  /** Fixed lock order prevents deadlocks when several carts share inventory. */
  public void lockInventory(long storeId, List<String> productIds) {
    productIds
      .stream()
      .sorted()
      .forEach(id ->
        jdbc.queryForList("SELECT quantity FROM inventory WHERE store_id=? AND product_id=? FOR UPDATE", storeId, id)
      );
  }

  public boolean reduceStock(long storeId, String productId, int quantity) {
    return (
      jdbc.update(
        "UPDATE inventory SET quantity=quantity-? WHERE store_id=? AND product_id=? AND quantity>=?",
        quantity,
        storeId,
        productId,
        quantity
      ) == 1
    );
  }
}
