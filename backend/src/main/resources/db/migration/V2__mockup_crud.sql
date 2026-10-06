ALTER TABLE products
  MODIFY care TEXT NOT NULL,
  ADD nursery_name VARCHAR(100) NOT NULL DEFAULT '',
  ADD nursery_address VARCHAR(200) NOT NULL DEFAULT '',
  ADD sunlight VARCHAR(30) NOT NULL DEFAULT '未設定',
  ADD use_case VARCHAR(80) NOT NULL DEFAULT '',
  ADD care_level INT NOT NULL DEFAULT 1,
  ADD min_temperature_c INT NULL,
  ADD heat_tolerant BOOLEAN NOT NULL DEFAULT FALSE,
  ADD drought_tolerant BOOLEAN NOT NULL DEFAULT FALSE,
  ADD age_years INT NULL,
  ADD height_cm INT NULL,
  ADD pot_diameter_cm INT NULL,
  ADD family_name VARCHAR(100) NOT NULL DEFAULT '',
  ADD flowering_description TEXT NULL,
  ADD seasonal_care TEXT NULL,
  ADD style_description TEXT NULL,
  ADD published_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ADD active BOOLEAN NOT NULL DEFAULT TRUE,
  ADD CONSTRAINT care_level_range CHECK(care_level BETWEEN 1 AND 3);

CREATE TABLE product_images (
  product_id VARCHAR(40) NOT NULL,
  sort_order INT NOT NULL,
  image_url VARCHAR(2048) NOT NULL,
  PRIMARY KEY(product_id, sort_order),
  FOREIGN KEY(product_id) REFERENCES products(id)
);

CREATE TABLE cart_details (
  cart_id CHAR(36) PRIMARY KEY,
  fulfillment_method VARCHAR(20) NOT NULL DEFAULT 'PICKUP',
  payment_method VARCHAR(20) NOT NULL DEFAULT 'DEMO_CARD',
  recipient_name VARCHAR(100) NOT NULL DEFAULT '',
  recipient_phone VARCHAR(30) NOT NULL DEFAULT '',
  contact_email VARCHAR(200) NOT NULL DEFAULT '',
  postal_code VARCHAR(8) NOT NULL DEFAULT '',
  address_line1 VARCHAR(200) NOT NULL DEFAULT '',
  address_line2 VARCHAR(200) NOT NULL DEFAULT '',
  requested_date VARCHAR(10) NOT NULL DEFAULT '',
  time_slot VARCHAR(20) NOT NULL DEFAULT 'ANY',
  FOREIGN KEY(cart_id) REFERENCES carts(id)
);

CREATE TABLE order_details LIKE cart_details;
ALTER TABLE order_details CHANGE cart_id order_id CHAR(36) NOT NULL,
  ADD FOREIGN KEY(order_id) REFERENCES orders(id);
ALTER TABLE orders
  ADD subtotal_yen INT NOT NULL DEFAULT 0,
  ADD shipping_fee_yen INT NOT NULL DEFAULT 0,
  ADD deleted_at TIMESTAMP NULL;
UPDATE orders SET subtotal_yen=total_yen;

UPDATE products SET nursery_name='湘南オリーブ園',nursery_address='神奈川県平塚市（デモ）',
  sunlight='日なた',use_case='シンボルツリー',care_level=1,min_temperature_c=-5,
  heat_tolerant=TRUE,drought_tolerant=TRUE,age_years=4,height_cm=85,pot_diameter_cm=24,
  family_name='モクセイ科オリーブ属',flowering_description='初夏に開花します。実の収穫には異なる品種の混植を推奨します。',
  seasonal_care='春：剪定と施肥。夏：朝夕に水やり。秋：過湿を避ける。冬：水やりを控える。',
  style_description='地中海風のテラスや、ベランダのコンテナガーデンに。'
  WHERE id='olive';
UPDATE products SET nursery_name='八ヶ岳ボタニカルファーム',nursery_address='長野県（デモ）',
  sunlight='日なた',use_case='花壇・ベランダ',care_level=2,min_temperature_c=-10,
  drought_tolerant=TRUE,height_cm=35,pot_diameter_cm=15,family_name='シソ科',
  seasonal_care='春：植え付け。夏：蒸れを避ける。秋：花後の切り戻し。冬：過湿に注意。'
  WHERE id='lavender';
UPDATE products SET nursery_name='練馬グリーンプランツ',nursery_address='東京都練馬区（デモ）',
  sunlight='日なた',use_case='ハーブ・ベランダ',care_level=1,min_temperature_c=-5,
  heat_tolerant=TRUE,drought_tolerant=TRUE,height_cm=40,pot_diameter_cm=15,family_name='シソ科',
  seasonal_care='春：剪定。夏：風通しを確保。秋：収穫。冬：乾燥気味に管理。'
  WHERE id='rosemary';
UPDATE products SET nursery_name='練馬グリーンプランツ',nursery_address='東京都練馬区（デモ）',
  sunlight='半日陰',use_case='室内インテリア',care_level=1,min_temperature_c=10,
  height_cm=60,pot_diameter_cm=18,family_name='サトイモ科',
  seasonal_care='春夏：土の乾燥後に水やり。秋冬：水やりを減らして室内で管理。'
  WHERE id='monstera';
