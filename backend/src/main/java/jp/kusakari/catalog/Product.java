package jp.kusakari.catalog;

/** Internal database projection. HTTP responses are assembled by CatalogService. */
public record Product(
  String id,
  String sku,
  String name,
  String latinName,
  String category,
  String description,
  String sizeLabel,
  String care,
  int priceYen,
  String unit,
  String imageUrl,
  String badge,
  String source,
  String sourceUpdatedAt,
  int stock
) {}
