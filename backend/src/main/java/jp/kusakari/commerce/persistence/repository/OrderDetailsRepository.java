package jp.kusakari.commerce.persistence.repository;

import jp.kusakari.commerce.persistence.entity.OrderDetailsEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderDetailsRepository extends JpaRepository<OrderDetailsEntity, String> {}
