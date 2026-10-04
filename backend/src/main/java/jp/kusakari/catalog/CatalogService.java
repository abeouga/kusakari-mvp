package jp.kusakari.catalog;

import static jp.kusakari.catalog.CatalogDtos.*;

import java.util.Comparator;
import java.util.List;
import jp.kusakari.common.ApiException;
import org.springframework.stereotype.Service;

@Service
public class CatalogService {

  private final CatalogRepository repository;

  public CatalogService(CatalogRepository repository) {
    this.repository = repository;
  }

  public Store requireStore(long id) {
    return repository
      .stores()
      .stream()
      .filter(s -> s.id() == id)
      .findFirst()
      .orElseThrow(() -> new ApiException(404, "STORE_NOT_FOUND", "店舗が見つかりません。"));
  }

  public List<ProductView> products(long storeId) {
    requireStore(storeId);
    return repository.products(storeId).stream().map(CatalogService::view).toList();
  }

  public List<StoreView> stores(Double latitude, Double longitude) {
    if (
      (latitude == null) != (longitude == null) ||
      (latitude != null &&
        (!Double.isFinite(latitude) ||
          !Double.isFinite(longitude) ||
          Math.abs(latitude) > 90 ||
          Math.abs(longitude) > 180))
    ) {
      throw new ApiException(400, "INVALID_LOCATION", "緯度・経度を正しく指定してください。");
    }
    return repository
      .stores()
      .stream()
      .map(s ->
        new StoreView(
          s.id(),
          s.name(),
          s.address(),
          s.hours(),
          latitude == null ? null : distance(latitude, longitude, s.latitude(), s.longitude())
        )
      )
      .sorted(Comparator.comparing(StoreView::distanceKm, Comparator.nullsLast(Double::compareTo)))
      .toList();
  }

  public List<MaterialMatch> match(MaterialRequest request) {
    var products = products(request.storeId());
    return request
      .items()
      .stream()
      .map(item -> {
        var ids = repository.mappedProductIds(item.materialCode());
        var candidates = products
          .stream()
          .filter(p -> ids.contains(p.id()))
          .map(p ->
            new Candidate(
              p,
              item.quantity(),
              Math.multiplyExact(p.priceYen(), item.quantity()),
              p.stock() >= item.quantity()
            )
          )
          .toList();
        return new MaterialMatch(item.materialCode(), candidates.isEmpty() ? "UNMAPPED" : "MATCHED", candidates);
      })
      .toList();
  }

  public static ProductView view(Product p) {
    return new ProductView(
      p.id(),
      p.sku(),
      p.name(),
      p.latinName(),
      p.category(),
      p.description(),
      p.sizeLabel(),
      p.care(),
      p.priceYen(),
      p.unit(),
      p.imageUrl(),
      p.badge(),
      p.stock(),
      p.source(),
      p.sourceUpdatedAt()
    );
  }

  private static double distance(double lat1, double lon1, double lat2, double lon2) {
    double a =
      Math.pow(Math.sin(Math.toRadians(lat2 - lat1) / 2), 2) +
      Math.cos(Math.toRadians(lat1)) *
        Math.cos(Math.toRadians(lat2)) *
        Math.pow(Math.sin(Math.toRadians(lon2 - lon1) / 2), 2);
    return Math.round(6371 * 2 * Math.asin(Math.sqrt(Math.min(1, a))) * 10.0) / 10.0;
  }
}
