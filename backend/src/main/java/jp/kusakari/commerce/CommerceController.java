package jp.kusakari.commerce;

import static jp.kusakari.commerce.CommerceDtos.*;

import jakarta.servlet.http.*;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import jp.kusakari.common.SessionResolver;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class CommerceController {

  private final CartService service;
  private final SessionResolver sessions;

  public CommerceController(CartService service, SessionResolver sessions) {
    this.service = service;
    this.sessions = sessions;
  }

  @GetMapping("/health")
  public Map<String, String> health() {
    return Map.of("status", "ok", "application", "kusakari", "backend", "spring-boot");
  }

  @GetMapping("/cart")
  public CartView cart(HttpServletRequest req, HttpServletResponse res) {
    return service.read(sessions.resolve(req, res));
  }

  @PutMapping("/cart/items/{productId}")
  public CartView item(
    @PathVariable String productId,
    @Valid @RequestBody ItemRequest input,
    HttpServletRequest req,
    HttpServletResponse res
  ) {
    return service.updateItem(sessions.resolve(req, res), productId, input);
  }

  @PutMapping("/cart/store")
  public CartView store(@Valid @RequestBody StoreRequest input, HttpServletRequest req, HttpServletResponse res) {
    return service.updateStore(sessions.resolve(req, res), input);
  }

  @PostMapping("/orders")
  public OrderView checkout(
    @Valid @RequestBody CheckoutRequest input,
    HttpServletRequest req,
    HttpServletResponse res
  ) {
    return service.checkout(sessions.resolve(req, res), input);
  }

  @GetMapping("/orders")
  public List<OrderView> orders(HttpServletRequest req, HttpServletResponse res) {
    return service.orders(sessions.resolve(req, res));
  }
}
