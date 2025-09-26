-- =====================================================
-- SCRIPT DE BASE DE DATOS ERP - MARIADB
-- Módulos: ABM Clientes, ABM Artículos, ABM Usuarios, Gestión de Ventas y Stock
-- =====================================================

-- Crear la base de datos
CREATE DATABASE IF NOT EXISTS erp_sistema 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE erp_sistema;

-- =====================================================
-- MÓDULO ABM USUARIOS
-- =====================================================

-- Tabla de roles
CREATE TABLE roles (
    id_rol INT AUTO_INCREMENT PRIMARY KEY,
    nombre_rol VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabla de permisos
CREATE TABLE permisos (
    id_permiso INT AUTO_INCREMENT PRIMARY KEY,
    nombre_permiso VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    modulo VARCHAR(50) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de roles y permisos (relación muchos a muchos)
CREATE TABLE roles_permisos (
    id_rol_permiso INT AUTO_INCREMENT PRIMARY KEY,
    id_rol INT NOT NULL,
    id_permiso INT NOT NULL,
    fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_rol) REFERENCES roles(id_rol) ON DELETE CASCADE,
    FOREIGN KEY (id_permiso) REFERENCES permisos(id_permiso) ON DELETE CASCADE,
    UNIQUE KEY unique_rol_permiso (id_rol, id_permiso)
);

-- Tabla de usuarios
CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre_usuario VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    nombre_completo VARCHAR(100) NOT NULL,
    documento VARCHAR(20),
    telefono VARCHAR(20),
    id_rol INT NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    ultimo_acceso TIMESTAMP NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_rol) REFERENCES roles(id_rol)
);

-- Tabla de auditoría de usuarios
CREATE TABLE auditoria_usuarios (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    accion VARCHAR(50) NOT NULL,
    tabla_afectada VARCHAR(50),
    registro_id INT,
    valores_anteriores JSON,
    valores_nuevos JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    fecha_accion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);

-- =====================================================
-- MÓDULO ABM ARTÍCULOS
-- =====================================================

-- Tabla de categorías de artículos
CREATE TABLE categorias_articulos (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    codigo_categoria VARCHAR(20) NOT NULL UNIQUE,
    nombre_categoria VARCHAR(100) NOT NULL,
    descripcion TEXT,
    categoria_padre_id INT NULL,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (categoria_padre_id) REFERENCES categorias_articulos(id_categoria)
);

-- Tabla de unidades de medida
CREATE TABLE unidades_medida (
    id_unidad INT AUTO_INCREMENT PRIMARY KEY,
    codigo_unidad VARCHAR(10) NOT NULL UNIQUE,
    nombre_unidad VARCHAR(50) NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE
);

-- Tabla de artículos
CREATE TABLE articulos (
    id_articulo INT AUTO_INCREMENT PRIMARY KEY,
    codigo_articulo VARCHAR(50) NOT NULL UNIQUE,
    codigo_barras VARCHAR(50) UNIQUE,
    nombre_articulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    id_categoria INT NOT NULL,
    id_unidad INT NOT NULL,
    peso DECIMAL(10,3),
    volumen DECIMAL(10,3),
    requiere_lote BOOLEAN DEFAULT FALSE,
    requiere_serie BOOLEAN DEFAULT FALSE,
    tiene_vencimiento BOOLEAN DEFAULT FALSE,
    stock_minimo DECIMAL(10,2) DEFAULT 0,
    stock_maximo DECIMAL(10,2) DEFAULT 0,
    punto_reorden DECIMAL(10,2) DEFAULT 0,
    costo_estandar DECIMAL(12,2) DEFAULT 0,
    precio_base DECIMAL(12,2) DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_categoria) REFERENCES categorias_articulos(id_categoria),
    FOREIGN KEY (id_unidad) REFERENCES unidades_medida(id_unidad)
);

-- Tabla de listas de precios
CREATE TABLE listas_precios (
    id_lista_precio INT AUTO_INCREMENT PRIMARY KEY,
    nombre_lista VARCHAR(100) NOT NULL,
    descripcion TEXT,
    fecha_vigencia_desde DATE NOT NULL,
    fecha_vigencia_hasta DATE,
    activa BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de precios por artículo y lista
CREATE TABLE precios_articulos (
    id_precio_articulo INT AUTO_INCREMENT PRIMARY KEY,
    id_articulo INT NOT NULL,
    id_lista_precio INT NOT NULL,
    precio DECIMAL(12,2) NOT NULL,
    descuento_porcentaje DECIMAL(5,2) DEFAULT 0,
    precio_final DECIMAL(12,2) GENERATED ALWAYS AS (precio * (1 - descuento_porcentaje/100)) STORED,
    fecha_vigencia_desde DATE NOT NULL,
    fecha_vigencia_hasta DATE,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_articulo) REFERENCES articulos(id_articulo) ON DELETE CASCADE,
    FOREIGN KEY (id_lista_precio) REFERENCES listas_precios(id_lista_precio) ON DELETE CASCADE,
    UNIQUE KEY unique_articulo_lista_fecha (id_articulo, id_lista_precio, fecha_vigencia_desde)
);

-- Tabla de lotes
CREATE TABLE lotes (
    id_lote INT AUTO_INCREMENT PRIMARY KEY,
    id_articulo INT NOT NULL,
    numero_lote VARCHAR(50) NOT NULL,
    fecha_vencimiento DATE,
    fecha_fabricacion DATE,
    cantidad_inicial DECIMAL(10,2) NOT NULL,
    cantidad_disponible DECIMAL(10,2) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_articulo) REFERENCES articulos(id_articulo) ON DELETE CASCADE,
    UNIQUE KEY unique_articulo_lote (id_articulo, numero_lote)
);

-- Tabla de series
CREATE TABLE series (
    id_serie INT AUTO_INCREMENT PRIMARY KEY,
    id_articulo INT NOT NULL,
    numero_serie VARCHAR(100) NOT NULL,
    estado ENUM('disponible', 'vendido', 'garantia', 'defectuoso') DEFAULT 'disponible',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_articulo) REFERENCES articulos(id_articulo) ON DELETE CASCADE,
    UNIQUE KEY unique_articulo_serie (id_articulo, numero_serie)
);

-- =====================================================
-- MÓDULO ABM CLIENTES
-- =====================================================

-- Tabla de tipos de cliente
CREATE TABLE tipos_cliente (
    id_tipo_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre_tipo VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE
);

-- Tabla de clientes
CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    codigo_cliente VARCHAR(20) NOT NULL UNIQUE,
    razon_social VARCHAR(200) NOT NULL,
    nombre_fantasia VARCHAR(200),
    cuit VARCHAR(13) NOT NULL UNIQUE,
    id_tipo_cliente INT NOT NULL,
    id_lista_precio INT,
    limite_credito DECIMAL(15,2) DEFAULT 0,
    saldo_cuenta_corriente DECIMAL(15,2) DEFAULT 0,
    descuento_porcentaje DECIMAL(5,2) DEFAULT 0,
    condicion_pago_id INT,
    observaciones TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_alta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_tipo_cliente) REFERENCES tipos_cliente(id_tipo_cliente),
    FOREIGN KEY (id_lista_precio) REFERENCES listas_precios(id_lista_precio)
);

-- Tabla de condiciones de pago
CREATE TABLE condiciones_pago (
    id_condicion_pago INT AUTO_INCREMENT PRIMARY KEY,
    nombre_condicion VARCHAR(100) NOT NULL,
    dias_vencimiento INT NOT NULL DEFAULT 0,
    descuento_porcentaje DECIMAL(5,2) DEFAULT 0,
    dias_descuento INT DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE
);

-- Agregar la clave foránea después de crear la tabla condiciones_pago
ALTER TABLE clientes 
ADD FOREIGN KEY (condicion_pago_id) REFERENCES condiciones_pago(id_condicion_pago);

-- Tabla de domicilios de clientes
CREATE TABLE domicilios_clientes (
    id_domicilio INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    tipo_domicilio ENUM('fiscal', 'comercial', 'entrega', 'cobranza') NOT NULL,
    calle VARCHAR(200) NOT NULL,
    numero VARCHAR(20),
    piso VARCHAR(10),
    departamento VARCHAR(10),
    localidad VARCHAR(100) NOT NULL,
    codigo_postal VARCHAR(10),
    provincia VARCHAR(100) NOT NULL,
    pais VARCHAR(100) DEFAULT 'Argentina',
    es_principal BOOLEAN DEFAULT FALSE,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) ON DELETE CASCADE
);

-- Tabla de contactos de clientes
CREATE TABLE contactos_clientes (
    id_contacto INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    nombre_contacto VARCHAR(100) NOT NULL,
    apellido_contacto VARCHAR(100) NOT NULL,
    cargo VARCHAR(100),
    email VARCHAR(100),
    telefono VARCHAR(20),
    celular VARCHAR(20),
    es_principal BOOLEAN DEFAULT FALSE,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) ON DELETE CASCADE
);

-- =====================================================
-- MÓDULO GESTIÓN DE VENTAS Y STOCK
-- =====================================================

-- Tabla de tipos de comprobante
CREATE TABLE tipos_comprobante (
    id_tipo_comprobante INT AUTO_INCREMENT PRIMARY KEY,
    codigo_tipo VARCHAR(10) NOT NULL UNIQUE,
    nombre_tipo VARCHAR(100) NOT NULL,
    descripcion TEXT,
    afecta_stock BOOLEAN DEFAULT TRUE,
    requiere_autorizacion BOOLEAN DEFAULT FALSE,
    activo BOOLEAN DEFAULT TRUE
);

-- Tabla de estados de pedidos
CREATE TABLE estados_pedido (
    id_estado INT AUTO_INCREMENT PRIMARY KEY,
    nombre_estado VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    color VARCHAR(7),
    orden INT DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE
);

-- Tabla de pedidos
CREATE TABLE pedidos (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    numero_pedido VARCHAR(20) NOT NULL UNIQUE,
    id_cliente INT NOT NULL,
    id_usuario_creador INT NOT NULL,
    id_usuario_vendedor INT,
    fecha_pedido DATE NOT NULL,
    fecha_entrega_prevista DATE,
    id_estado INT NOT NULL,
    id_tipo_comprobante INT NOT NULL,
    subtotal DECIMAL(15,2) DEFAULT 0,
    descuento_porcentaje DECIMAL(5,2) DEFAULT 0,
    descuento_monto DECIMAL(15,2) DEFAULT 0,
    impuestos DECIMAL(15,2) DEFAULT 0,
    total DECIMAL(15,2) NOT NULL,
    observaciones TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    FOREIGN KEY (id_usuario_creador) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_usuario_vendedor) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_estado) REFERENCES estados_pedido(id_estado),
    FOREIGN KEY (id_tipo_comprobante) REFERENCES tipos_comprobante(id_tipo_comprobante)
);

-- Tabla de detalles de pedidos
CREATE TABLE detalles_pedidos (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_articulo INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(12,2) NOT NULL,
    descuento_porcentaje DECIMAL(5,2) DEFAULT 0,
    descuento_monto DECIMAL(12,2) DEFAULT 0,
    subtotal DECIMAL(15,2) GENERATED ALWAYS AS (cantidad * precio_unitario * (1 - descuento_porcentaje/100) - descuento_monto) STORED,
    observaciones TEXT,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    FOREIGN KEY (id_articulo) REFERENCES articulos(id_articulo)
);

-- Tabla de remitos
CREATE TABLE remitos (
    id_remito INT AUTO_INCREMENT PRIMARY KEY,
    numero_remito VARCHAR(20) NOT NULL UNIQUE,
    id_pedido INT NOT NULL,
    id_cliente INT NOT NULL,
    id_usuario_creador INT NOT NULL,
    fecha_remito DATE NOT NULL,
    fecha_entrega DATE,
    observaciones TEXT,
    estado ENUM('pendiente', 'entregado', 'cancelado') DEFAULT 'pendiente',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    FOREIGN KEY (id_usuario_creador) REFERENCES usuarios(id_usuario)
);

-- Tabla de detalles de remitos
CREATE TABLE detalles_remitos (
    id_detalle_remito INT AUTO_INCREMENT PRIMARY KEY,
    id_remito INT NOT NULL,
    id_articulo INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    id_lote INT NULL,
    id_serie INT NULL,
    observaciones TEXT,
    FOREIGN KEY (id_remito) REFERENCES remitos(id_remito) ON DELETE CASCADE,
    FOREIGN KEY (id_articulo) REFERENCES articulos(id_articulo),
    FOREIGN KEY (id_lote) REFERENCES lotes(id_lote),
    FOREIGN KEY (id_serie) REFERENCES series(id_serie)
);

-- Tabla de facturas
CREATE TABLE facturas (
    id_factura INT AUTO_INCREMENT PRIMARY KEY,
    numero_factura VARCHAR(20) NOT NULL UNIQUE,
    id_pedido INT NOT NULL,
    id_remito INT,
    id_cliente INT NOT NULL,
    id_usuario_creador INT NOT NULL,
    fecha_factura DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    subtotal DECIMAL(15,2) NOT NULL,
    impuestos DECIMAL(15,2) NOT NULL,
    total DECIMAL(15,2) NOT NULL,
    saldo_pendiente DECIMAL(15,2) NOT NULL,
    estado ENUM('emitida', 'cobrada', 'parcial', 'vencida', 'cancelada') DEFAULT 'emitida',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    FOREIGN KEY (id_remito) REFERENCES remitos(id_remito),
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    FOREIGN KEY (id_usuario_creador) REFERENCES usuarios(id_usuario)
);

-- Tabla de detalles de facturas
CREATE TABLE detalles_facturas (
    id_detalle_factura INT AUTO_INCREMENT PRIMARY KEY,
    id_factura INT NOT NULL,
    id_articulo INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(12,2) NOT NULL,
    subtotal DECIMAL(15,2) NOT NULL,
    FOREIGN KEY (id_factura) REFERENCES facturas(id_factura) ON DELETE CASCADE,
    FOREIGN KEY (id_articulo) REFERENCES articulos(id_articulo)
);

-- Tabla de movimientos de stock
CREATE TABLE movimientos_stock (
    id_movimiento INT AUTO_INCREMENT PRIMARY KEY,
    id_articulo INT NOT NULL,
    id_lote INT NULL,
    id_serie INT NULL,
    tipo_movimiento ENUM('entrada', 'salida', 'ajuste', 'transferencia') NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(12,2),
    total DECIMAL(15,2),
    motivo VARCHAR(200),
    id_pedido INT NULL,
    id_remito INT NULL,
    id_factura INT NULL,
    id_usuario INT NOT NULL,
    fecha_movimiento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT,
    FOREIGN KEY (id_articulo) REFERENCES articulos(id_articulo),
    FOREIGN KEY (id_lote) REFERENCES lotes(id_lote),
    FOREIGN KEY (id_serie) REFERENCES series(id_serie),
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    FOREIGN KEY (id_remito) REFERENCES remitos(id_remito),
    FOREIGN KEY (id_factura) REFERENCES facturas(id_factura),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);

-- Tabla de stock actual
CREATE TABLE stock_actual (
    id_stock INT AUTO_INCREMENT PRIMARY KEY,
    id_articulo INT NOT NULL UNIQUE,
    cantidad_disponible DECIMAL(10,2) DEFAULT 0,
    cantidad_reservada DECIMAL(10,2) DEFAULT 0,
    cantidad_total DECIMAL(10,2) GENERATED ALWAYS AS (cantidad_disponible + cantidad_reservada) STORED,
    ultima_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_articulo) REFERENCES articulos(id_articulo) ON DELETE CASCADE
);

-- Tabla de pagos/cobranzas
CREATE TABLE pagos (
    id_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_factura INT NOT NULL,
    id_cliente INT NOT NULL,
    monto DECIMAL(15,2) NOT NULL,
    fecha_pago DATE NOT NULL,
    forma_pago ENUM('efectivo', 'transferencia', 'cheque', 'tarjeta') NOT NULL,
    numero_comprobante VARCHAR(50),
    observaciones TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_factura) REFERENCES facturas(id_factura),
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

-- =====================================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- =====================================================

-- Índices para clientes
CREATE INDEX idx_clientes_cuit ON clientes(cuit);
CREATE INDEX idx_clientes_razon_social ON clientes(razon_social);
CREATE INDEX idx_clientes_activo ON clientes(activo);

-- Índices para artículos
CREATE INDEX idx_articulos_codigo ON articulos(codigo_articulo);
CREATE INDEX idx_articulos_codigo_barras ON articulos(codigo_barras);
CREATE INDEX idx_articulos_categoria ON articulos(id_categoria);
CREATE INDEX idx_articulos_activo ON articulos(activo);

-- Índices para pedidos
CREATE INDEX idx_pedidos_cliente ON pedidos(id_cliente);
CREATE INDEX idx_pedidos_fecha ON pedidos(fecha_pedido);
CREATE INDEX idx_pedidos_estado ON pedidos(id_estado);
CREATE INDEX idx_pedidos_numero ON pedidos(numero_pedido);

-- Índices para movimientos de stock
CREATE INDEX idx_movimientos_articulo ON movimientos_stock(id_articulo);
CREATE INDEX idx_movimientos_fecha ON movimientos_stock(fecha_movimiento);
CREATE INDEX idx_movimientos_tipo ON movimientos_stock(tipo_movimiento);

-- Índices para facturas
CREATE INDEX idx_facturas_cliente ON facturas(id_cliente);
CREATE INDEX idx_facturas_fecha ON facturas(fecha_factura);
CREATE INDEX idx_facturas_estado ON facturas(estado);
CREATE INDEX idx_facturas_vencimiento ON facturas(fecha_vencimiento);

-- =====================================================
-- DATOS INICIALES
-- =====================================================

-- Insertar roles básicos
INSERT INTO roles (nombre_rol, descripcion) VALUES
('Administrador', 'Acceso completo al sistema'),
('Vendedor', 'Acceso a módulos de ventas y clientes'),
('Logística', 'Acceso a gestión de stock y despachos'),
('Contador', 'Acceso a módulos financieros y reportes'),
('Operador', 'Acceso limitado a operaciones básicas');

-- Insertar permisos básicos
INSERT INTO permisos (nombre_permiso, descripcion, modulo) VALUES
('clientes_crear', 'Crear nuevos clientes', 'Clientes'),
('clientes_modificar', 'Modificar clientes existentes', 'Clientes'),
('clientes_eliminar', 'Eliminar clientes', 'Clientes'),
('articulos_crear', 'Crear nuevos artículos', 'Artículos'),
('articulos_modificar', 'Modificar artículos existentes', 'Artículos'),
('articulos_eliminar', 'Eliminar artículos', 'Artículos'),
('ventas_crear_pedido', 'Crear nuevos pedidos', 'Ventas'),
('ventas_modificar_pedido', 'Modificar pedidos', 'Ventas'),
('ventas_autorizar_pedido', 'Autorizar pedidos', 'Ventas'),
('stock_ver', 'Ver información de stock', 'Stock'),
('stock_movimientos', 'Realizar movimientos de stock', 'Stock'),
('facturacion_emitir', 'Emitir facturas', 'Facturación'),
('reportes_ver', 'Ver reportes', 'Reportes');

-- Insertar tipos de cliente
INSERT INTO tipos_cliente (nombre_tipo, descripcion) VALUES
('Consumidor Final', 'Cliente consumidor final'),
('Empresa', 'Cliente empresa'),
('Distribuidor', 'Cliente distribuidor'),
('Franquicia', 'Cliente franquicia');

-- Insertar categorías de artículos
INSERT INTO categorias_articulos (codigo_categoria, nombre_categoria, descripcion) VALUES
('CAT001', 'Productos', 'Categoría principal de productos'),
('CAT002', 'Servicios', 'Categoría de servicios'),
('CAT003', 'Repuestos', 'Categoría de repuestos');

-- Insertar unidades de medida
INSERT INTO unidades_medida (codigo_unidad, nombre_unidad, descripcion) VALUES
('UN', 'Unidad', 'Unidad individual'),
('KG', 'Kilogramo', 'Peso en kilogramos'),
('M', 'Metro', 'Longitud en metros'),
('M2', 'Metro cuadrado', 'Superficie en metros cuadrados'),
('M3', 'Metro cúbico', 'Volumen en metros cúbicos'),
('LT', 'Litro', 'Volumen en litros'),
('HS', 'Hora', 'Tiempo en horas');

-- Insertar condiciones de pago
INSERT INTO condiciones_pago (nombre_condicion, dias_vencimiento, descuento_porcentaje, dias_descuento) VALUES
('Contado', 0, 0, 0),
('30 días', 30, 0, 0),
('60 días', 60, 0, 0),
('90 días', 90, 0, 0),
('2% 10 días', 30, 2, 10);

-- Insertar tipos de comprobante
INSERT INTO tipos_comprobante (codigo_tipo, nombre_tipo, descripcion, afecta_stock) VALUES
('PED', 'Pedido', 'Pedido de venta', FALSE),
('REM', 'Remito', 'Remito de entrega', TRUE),
('FAC', 'Factura', 'Factura A', TRUE),
('FACB', 'Factura B', 'Factura B', TRUE),
('NC', 'Nota de Crédito', 'Nota de crédito', TRUE);

-- Insertar estados de pedido
INSERT INTO estados_pedido (nombre_estado, descripcion, color, orden) VALUES
('Borrador', 'Pedido en borrador', '#6c757d', 1),
('Pendiente', 'Pedido pendiente de autorización', '#ffc107', 2),
('Autorizado', 'Pedido autorizado', '#17a2b8', 3),
('En Preparación', 'Pedido en preparación', '#fd7e14', 4),
('Despachado', 'Pedido despachado', '#28a745', 5),
('Entregado', 'Pedido entregado', '#20c997', 6),
('Cancelado', 'Pedido cancelado', '#dc3545', 7);

-- Insertar listas de precios
INSERT INTO listas_precios (nombre_lista, descripcion, fecha_vigencia_desde) VALUES
('Lista General', 'Lista de precios general', CURDATE()),
('Lista Mayorista', 'Lista de precios para mayoristas', CURDATE()),
('Lista Minorista', 'Lista de precios para minoristas', CURDATE());

-- Crear usuario administrador por defecto
INSERT INTO usuarios (nombre_usuario, email, password_hash, nombre_completo, id_rol) VALUES
('admin', 'admin@empresa.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Administrador del Sistema', 1);

-- Asignar todos los permisos al rol administrador
INSERT INTO roles_permisos (id_rol, id_permiso)
SELECT 1, id_permiso FROM permisos;

-- =====================================================
-- TRIGGERS PARA AUTOMATIZACIÓN
-- =====================================================

-- Trigger para actualizar stock cuando se crea un movimiento
DELIMITER //
CREATE TRIGGER tr_actualizar_stock_despues_movimiento
AFTER INSERT ON movimientos_stock
FOR EACH ROW
BEGIN
    INSERT INTO stock_actual (id_articulo, cantidad_disponible, cantidad_reservada)
    VALUES (NEW.id_articulo, 
            CASE WHEN NEW.tipo_movimiento = 'entrada' THEN NEW.cantidad ELSE -NEW.cantidad END,
            0)
    ON DUPLICATE KEY UPDATE
        cantidad_disponible = cantidad_disponible + 
            CASE WHEN NEW.tipo_movimiento = 'entrada' THEN NEW.cantidad ELSE -NEW.cantidad END;
END//
DELIMITER ;

-- Trigger para generar número de pedido automáticamente
DELIMITER //
CREATE TRIGGER tr_generar_numero_pedido
BEFORE INSERT ON pedidos
FOR EACH ROW
BEGIN
    IF NEW.numero_pedido IS NULL OR NEW.numero_pedido = '' THEN
        SET NEW.numero_pedido = CONCAT('PED-', YEAR(NOW()), '-', LPAD(COALESCE((SELECT MAX(CAST(SUBSTRING(numero_pedido, 9) AS UNSIGNED)) FROM pedidos WHERE numero_pedido LIKE CONCAT('PED-', YEAR(NOW()), '-%')), 0) + 1, 6, '0'));
    END IF;
END//
DELIMITER ;

-- Trigger para generar número de remito automáticamente
DELIMITER //
CREATE TRIGGER tr_generar_numero_remito
BEFORE INSERT ON remitos
FOR EACH ROW
BEGIN
    IF NEW.numero_remito IS NULL OR NEW.numero_remito = '' THEN
        SET NEW.numero_remito = CONCAT('REM-', YEAR(NOW()), '-', LPAD(COALESCE((SELECT MAX(CAST(SUBSTRING(numero_remito, 9) AS UNSIGNED)) FROM remitos WHERE numero_remito LIKE CONCAT('REM-', YEAR(NOW()), '-%')), 0) + 1, 6, '0'));
    END IF;
END//
DELIMITER ;

-- Trigger para generar número de factura automáticamente
DELIMITER //
CREATE TRIGGER tr_generar_numero_factura
BEFORE INSERT ON facturas
FOR EACH ROW
BEGIN
    IF NEW.numero_factura IS NULL OR NEW.numero_factura = '' THEN
        SET NEW.numero_factura = CONCAT('FAC-', YEAR(NOW()), '-', LPAD(COALESCE((SELECT MAX(CAST(SUBSTRING(numero_factura, 9) AS UNSIGNED)) FROM facturas WHERE numero_factura LIKE CONCAT('FAC-', YEAR(NOW()), '-%')), 0) + 1, 6, '0'));
    END IF;
END//
DELIMITER ;

-- =====================================================
-- VISTAS ÚTILES
-- =====================================================

-- Vista de clientes con información completa
CREATE VIEW v_clientes_completos AS
SELECT 
    c.id_cliente,
    c.codigo_cliente,
    c.razon_social,
    c.nombre_fantasia,
    c.cuit,
    tc.nombre_tipo AS tipo_cliente,
    lp.nombre_lista AS lista_precios,
    cp.nombre_condicion AS condicion_pago,
    c.limite_credito,
    c.saldo_cuenta_corriente,
    c.descuento_porcentaje,
    c.activo,
    c.fecha_alta
FROM clientes c
LEFT JOIN tipos_cliente tc ON c.id_tipo_cliente = tc.id_tipo_cliente
LEFT JOIN listas_precios lp ON c.id_lista_precio = lp.id_lista_precio
LEFT JOIN condiciones_pago cp ON c.condicion_pago_id = cp.id_condicion_pago;

-- Vista de artículos con información completa
CREATE VIEW v_articulos_completos AS
SELECT 
    a.id_articulo,
    a.codigo_articulo,
    a.codigo_barras,
    a.nombre_articulo,
    a.descripcion,
    ca.nombre_categoria,
    um.nombre_unidad,
    a.precio_base,
    a.stock_minimo,
    a.stock_maximo,
    sa.cantidad_disponible,
    sa.cantidad_reservada,
    sa.cantidad_total,
    a.activo
FROM articulos a
LEFT JOIN categorias_articulos ca ON a.id_categoria = ca.id_categoria
LEFT JOIN unidades_medida um ON a.id_unidad = um.id_unidad
LEFT JOIN stock_actual sa ON a.id_articulo = sa.id_articulo;

-- Vista de pedidos con información completa
CREATE VIEW v_pedidos_completos AS
SELECT 
    p.id_pedido,
    p.numero_pedido,
    c.razon_social AS cliente,
    u.nombre_completo AS vendedor,
    p.fecha_pedido,
    p.fecha_entrega_prevista,
    ep.nombre_estado AS estado,
    p.total,
    p.observaciones
FROM pedidos p
LEFT JOIN clientes c ON p.id_cliente = c.id_cliente
LEFT JOIN usuarios u ON p.id_usuario_vendedor = u.id_usuario
LEFT JOIN estados_pedido ep ON p.id_estado = ep.id_estado;

-- =====================================================
-- PROCEDIMIENTOS ALMACENADOS
-- =====================================================

-- Procedimiento para actualizar saldo de cuenta corriente
DELIMITER //
CREATE PROCEDURE sp_actualizar_saldo_cliente(IN p_id_cliente INT, IN p_monto DECIMAL(15,2), IN p_tipo_movimiento VARCHAR(20))
BEGIN
    DECLARE v_saldo_actual DECIMAL(15,2);
    
    SELECT saldo_cuenta_corriente INTO v_saldo_actual 
    FROM clientes 
    WHERE id_cliente = p_id_cliente;
    
    IF p_tipo_movimiento = 'factura' THEN
        UPDATE clientes 
        SET saldo_cuenta_corriente = saldo_cuenta_corriente + p_monto 
        WHERE id_cliente = p_id_cliente;
    ELSEIF p_tipo_movimiento = 'pago' THEN
        UPDATE clientes 
        SET saldo_cuenta_corriente = saldo_cuenta_corriente - p_monto 
        WHERE id_cliente = p_id_cliente;
    END IF;
END//
DELIMITER ;

-- Procedimiento para reservar stock
DELIMITER //
CREATE PROCEDURE sp_reservar_stock(IN p_id_articulo INT, IN p_cantidad DECIMAL(10,2))
BEGIN
    DECLARE v_stock_disponible DECIMAL(10,2);
    
    SELECT cantidad_disponible INTO v_stock_disponible
    FROM stock_actual
    WHERE id_articulo = p_id_articulo;
    
    IF v_stock_disponible >= p_cantidad THEN
        UPDATE stock_actual 
        SET cantidad_disponible = cantidad_disponible - p_cantidad,
            cantidad_reservada = cantidad_reservada + p_cantidad
        WHERE id_articulo = p_id_articulo;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente';
    END IF;
END//
DELIMITER ;

-- =====================================================
-- FIN DEL SCRIPT
-- =====================================================

-- Mostrar mensaje de finalización
SELECT 'Base de datos ERP creada exitosamente' AS mensaje,
       NOW() AS fecha_creacion;
