package jp.kusakari.common;

import jakarta.servlet.http.*;
import java.time.Duration;
import java.util.UUID;
import jp.kusakari.commerce.CartRepository;
import org.springframework.http.ResponseCookie;
import org.springframework.stereotype.Component;

@Component
public class SessionResolver {

  private static final String COOKIE = "kusakari_cart";
  private final CartRepository carts;

  public SessionResolver(CartRepository carts) {
    this.carts = carts;
  }

  public String resolve(HttpServletRequest request, HttpServletResponse response) {
    if (request.getCookies() != null) for (var cookie : request.getCookies()) {
      if (
        COOKIE.equals(cookie.getName()) && cookie.getValue().matches("[a-f0-9-]{36}") && carts.exists(cookie.getValue())
      ) return cookie.getValue();
    }
    String id = UUID.randomUUID().toString();
    carts.create(id);
    response.addHeader(
      "Set-Cookie",
      ResponseCookie.from(COOKIE, id)
        .httpOnly(true)
        .sameSite("Strict")
        .path("/api")
        .maxAge(Duration.ofDays(30))
        .build()
        .toString()
    );
    return id;
  }
}
