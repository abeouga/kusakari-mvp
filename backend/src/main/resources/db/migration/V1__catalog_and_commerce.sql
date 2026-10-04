CREATE TABLE products (
  id VARCHAR(40) PRIMARY KEY, sku VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(120) NOT NULL, latin_name VARCHAR(120) NOT NULL,
  category VARCHAR(30) NOT NULL, description TEXT NOT NULL,
  size_label VARCHAR(80) NOT NULL, care VARCHAR(250) NOT NULL,
  price_yen INT NOT NULL, unit VARCHAR(20) NOT NULL DEFAULT 'piece',
  image_url VARCHAR(250) NOT NULL, badge VARCHAR(30) NOT NULL,
  source VARCHAR(30) NOT NULL DEFAULT 'demo', source_product_id VARCHAR(120),
  source_updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT positive_price CHECK(price_yen > 0)
);
CREATE TABLE stores (
  id BIGINT PRIMARY KEY, name VARCHAR(100) NOT NULL,
  address VARCHAR(200) NOT NULL, latitude DOUBLE NOT NULL, longitude DOUBLE NOT NULL,
  hours VARCHAR(80) NOT NULL
);
CREATE TABLE inventory (
  store_id BIGINT NOT NULL, product_id VARCHAR(40) NOT NULL, quantity INT NOT NULL,
  PRIMARY KEY(store_id, product_id), FOREIGN KEY(store_id) REFERENCES stores(id),
  FOREIGN KEY(product_id) REFERENCES products(id), CONSTRAINT nonnegative_stock CHECK(quantity >= 0)
);
CREATE TABLE material_products (
  material_code VARCHAR(80) NOT NULL, product_id VARCHAR(40) NOT NULL,
  PRIMARY KEY(material_code, product_id), FOREIGN KEY(product_id) REFERENCES products(id)
);
CREATE TABLE carts (
  id CHAR(36) PRIMARY KEY, store_id BIGINT NOT NULL DEFAULT 1, revision BIGINT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(store_id) REFERENCES stores(id)
);
CREATE TABLE cart_items (
  cart_id CHAR(36) NOT NULL, product_id VARCHAR(40) NOT NULL, quantity INT NOT NULL,
  PRIMARY KEY(cart_id, product_id), FOREIGN KEY(cart_id) REFERENCES carts(id),
  FOREIGN KEY(product_id) REFERENCES products(id), CONSTRAINT cart_quantity CHECK(quantity BETWEEN 1 AND 99)
);
CREATE TABLE orders (
  id CHAR(36) PRIMARY KEY, cart_id CHAR(36) NOT NULL, request_id CHAR(36) NOT NULL,
  request_revision BIGINT NOT NULL, store_name VARCHAR(100) NOT NULL,
  total_yen INT NOT NULL, status VARCHAR(30) NOT NULL DEFAULT 'DEMO_CONFIRMED',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(cart_id, request_id), FOREIGN KEY(cart_id) REFERENCES carts(id)
);
CREATE TABLE order_items (
  order_id CHAR(36) NOT NULL, product_id VARCHAR(40) NOT NULL,
  sku VARCHAR(50) NOT NULL, product_name VARCHAR(120) NOT NULL,
  quantity INT NOT NULL, unit_price_yen INT NOT NULL,
  PRIMARY KEY(order_id, product_id), FOREIGN KEY(order_id) REFERENCES orders(id)
);

INSERT INTO products(id,sku,name,latin_name,category,description,size_label,care,price_yen,image_url,badge) VALUES
('olive','KS-OLV-001','オリーブ','Olea europaea','庭木','銀色を帯びた葉と、自然な枝ぶり。庭やベランダに穏やかな表情を添えるひと鉢です。鉢付きのデモ商品です。','高さ 約70–90cm / 7号鉢','日当たりと風通しのよい屋外に。土の表面が乾いてから、たっぷり水を与えます。',6800,'/images/olive.png','おすすめ'),
('lavender','KS-LAV-001','イングリッシュラベンダー','Lavandula angustifolia','草花','やさしい紫とすっきりした香り。花壇のアクセントにも、玄関先の小さな彩りにも。鉢付きのデモ商品です。','高さ 約30–40cm / 5号鉢','日当たりのよい場所で管理し、蒸れを避けます。花後は切り戻して風通しを保ちます。',1980,'/images/lavender.png','花のある暮らし'),
('rosemary','KS-ROS-001','ローズマリー','Salvia rosmarinus','ハーブ','すっと伸びる枝と繊細な葉。暮らしのそばで香りを楽しめる、立性のハーブです。鉢付きのデモ商品です。','高さ 約30–45cm / 5号鉢','日当たりのよい屋外を好みます。過湿を避け、乾き気味に育てます。',1480,'/images/rosemary.png','育てやすい'),
('monstera','KS-MON-001','モンステラ','Monstera deliciosa','観葉植物','大きな切れ込みのある葉が、部屋に柔らかな陰影をつくります。室内の明るい場所に。鉢付きのデモ商品です。','高さ 約50–65cm / 6号鉢','直射日光を避けた明るい室内へ。土が乾いたら水やりし、冬は控えめにします。',4200,'/images/monstera.png','室内におすすめ');
INSERT INTO stores VALUES
(1,'二子玉川ガーデン','東京都世田谷区・二子玉川周辺（架空店舗）',35.612,139.626,'10:00–18:00 / 水曜定休'),
(2,'横浜グリーンハウス','神奈川県横浜市・横浜駅周辺（架空店舗）',35.466,139.622,'10:00–19:00 / 火曜定休'),
(3,'大宮ボタニカル','埼玉県さいたま市・大宮駅周辺（架空店舗）',35.906,139.624,'09:00–18:00 / 木曜定休');
INSERT INTO inventory VALUES
(1,'olive',24),(1,'lavender',48),(1,'rosemary',60),(1,'monstera',18),
(2,'olive',12),(2,'lavender',30),(2,'rosemary',25),(2,'monstera',0),
(3,'olive',8),(3,'lavender',20),(3,'rosemary',35),(3,'monstera',9);
INSERT INTO material_products VALUES
('plant.olive','olive'),('plant.lavender','lavender'),('plant.rosemary','rosemary'),
('plant.monstera','monstera'),('plant.herb','lavender'),('plant.herb','rosemary');
