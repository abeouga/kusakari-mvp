package jp.kusakari.commerce.persistence.repository;

import jp.kusakari.commerce.persistence.entity.CartDetailsEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CartDetailsRepository extends JpaRepository<CartDetailsEntity, String> {}
