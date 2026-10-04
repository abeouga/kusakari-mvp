package jp.kusakari.catalog;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;

public final class CatalogDtos {

  private CatalogDtos() {}

  public record ProductView(
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
    int stock,
    String source,
    String sourceUpdatedAt
  ) {}

  public record StoreView(long id, String name, String address, String hours, Double distanceKm) {}

  public record MaterialItem(
    @NotBlank @Size(max = 80) String materialCode,
    @Min(1) @Max(99) int quantity,
    @NotBlank @Pattern(regexp = "piece") String unit
  ) {}

  public record MaterialRequest(
    @Positive long storeId,
    @NotEmpty @Size(max = 50) List<@NotNull @Valid MaterialItem> items
  ) {}

  public record Candidate(ProductView product, int purchaseQuantity, int lineTotalYen, boolean available) {}

  public record MaterialMatch(String materialCode, String status, List<Candidate> candidates) {}
}
