CREATE DATABASE IF NOT EXISTS plant_sales CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE plant_sales;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  hashed_password VARCHAR(255) NOT NULL,
  role ENUM('employee','executive','admin') NOT NULL DEFAULT 'employee',
  is_active BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE plants (
  id INT AUTO_INCREMENT PRIMARY KEY,
  plant_code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  scientific_name VARCHAR(150),
  category VARCHAR(50),
  sale_price INT NOT NULL DEFAULT 0,
  purchase_price INT DEFAULT 0,
  unit VARCHAR(20) DEFAULT 'ポット',
  notes TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE inventory_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  plant_id INT NOT NULL,
  type ENUM('purchase','sale','discard','adjust') NOT NULL,
  quantity INT NOT NULL,
  unit_price INT DEFAULT 0,
  note VARCHAR(255),
  created_by INT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (plant_id) REFERENCES plants(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE VIEW plant_stock AS
  SELECT p.id, p.plant_code, p.name, p.category,
         p.sale_price, p.purchase_price, p.unit,
         COALESCE(SUM(l.quantity), 0) AS stock
  FROM plants p
  LEFT JOIN inventory_logs l ON p.id = l.plant_id
  WHERE p.is_active = TRUE
  GROUP BY p.id;
