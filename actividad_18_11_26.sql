CREATE TABLE public.productos_locales (
  id_producto INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  categoria VARCHAR(50) NOT NULL,
  existencia INTEGER NOT NULL CHECK (existencia >= 0),
  precio NUMERIC(10,2) NOT NULL CHECK (precio > 0)
);


INSERT INTO public.productos_locales (nombre, categoria, existencia, precio)
VALUES
  ('Laptop ASUS Vivobook', 'computadoras', 14, 12890),
  ('Webcam Logitech', 'accesorios', 22, 1499),
  ('Impresora multifuncional HP', 'impresoras', 9, 3890),
  ('Monitor Samsung', 'monitores', 11, 5650),
  ('Hub USB-C Anker', 'accesorios', 35, 890);

--crear rol lector_fdw con permisos de lectura en la tabla productos_remotos del servidor remoto
CREATE ROLE lector_fdw
WITH LOGIN PASSWORD 
'12345';

--otorgar permisos de conexión a la base de datos y de uso del esquema público al rol lector_fdw
GRANT CONNECT ON DATABASE postgres TO lector_fdw;

GRANT USAGE ON SCHEMA public TO lector_fdw;

GRANT SELECT ON TABLE public.productos_remotos TO lector_fdw;

--otorgar permisos de actualización en la tabla productos_remotos al rol lector_fdw
GRANT UPDATE ON TABLE public.productos_remotos TO lector_fdw;

--otorgar permisos de inserción en la tabla productos_remotos al rol lector_fdw
GRANT DELETE ON TABLE public.productos_remotos TO lector_fdw;


--crear la extensión postgres_fdw si no existe
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

--consultar si la extensión postgres_fdw está instalada
SELECT extname, extversion FROM pg_extension
WHERE extname = 'postgres_fdw';


--crear el servidor remoto
CREATE SERVER supabase_inventario
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'aws-1-us-west-2.pooler.supabase.com',
          port '5432',
          dbname 'postgres', 
          sslmode 'require');

--consultar los servidores remotos existentes
SELECT
srvname,
srvoptions
FROM pg_foreign_server;

--crear el mapeo de usuario para el servidor remoto
CREATE USER MAPPING FOR postgres
  SERVER supabase_inventario
  OPTIONS (user 'lector_fdw.tmqeapodhgbqqdilwqur', 
          password '12345');

--crear el esquema nube si no existe en local
CREATE SCHEMA IF NOT EXISTS nube;

--importar la tabla productos_remotos del servidor remoto al esquema nube
IMPORT FOREIGN SCHEMA public
LIMIT TO (productos_remotos)
from SERVER supabase_inventario
INTO nube;

--consultar las tablas foráneas importadas
SELECT 
      foreign_table_schema,
      foreign_table_name,
      foreign_server_name
FROM information_schema.foreign_tables;


SELECT * FROM nube.productos_remotos;


INSERT INTO public.productos_remotos (nombre, categoria, existencia, precio)
VALUES
  ('Desktop HP', 'computadoras', 10, 14200),
  ('Audífonos con micrófono HyperX', 'accesorios', 30, 1650),
  ('Impresora láser Brother', 'impresoras', 7, 3490),
  ('Monitor LG UltraGear', 'monitores', 18, 4150),
  ('MacBook Air 13', 'computadoras', 6, 23999);

  select * from public.productos_remotos;

CREATE ROLE lector_fdw
WITH LOGIN password
'12345';

GRANT CONNECT ON DATABASE postgres TO lector_fdw;

GRANT USAGE ON SCHEMA public TO lector_fdw;

GRANT SELECT ON TABLE public.productos_remotos TO lector_fdw;

--Crear la vista con productos loacales y remotos con una columna temporal que indique la sucursal de origen
SELECT 
'CHALCO' AS sucursal,
nombre,
categoria,
existencia,
precio
FROM public.productos_locales
UNION ALL
SELECT
'CENTRO' AS sucursal,
nombre,
categoria,
existencia,
precio
FROM nube.productos_remotos;

--creación de la vista inventario_general que combina los productos locales y remotos con una columna que indica la sucursal de origen
CREATE OR REPLACE VIEW inventario_general AS
SELECT
'CHALCO' :: TEXT AS sucursal,
id_producto,
nombre,
categoria,
existencia,
precio
FROM public.productos_locales
UNION ALL
SELECT
'CENTRO' :: TEXT AS sucursal,
id_producto,
nombre,
categoria,
existencia,
precio
FROM nube.productos_remotos;

--consultar la vista inventario_general
SELECT * FROM inventario_general;


--ACTIVIDAD 20 NOVIEMBRE 2026

--Consulta cuantos productos hay por sucursal (sum)
SELECT
sucursal,
SUM(existencia) AS total_productos
FROM inventario_general
GROUP BY sucursal;

--consutar cual es el valor del inventario por sucursal (sum)
SELECT
sucursal,
SUM(existencia * precio) AS valor_inventario
FROM inventario_general
GROUP BY sucursal;

--consultar cuales son los productos con existencia menor a 10
SELECT * FROM inventario_general
WHERE existencia < 10;

--consultar cual es el producto con el precio más alto por sucursal (max)
SELECT
sucursal,
nombre,
precio
FROM inventario_general
WHERE (sucursal, precio) IN (
  SELECT
  sucursal,
  MAX(precio)
  FROM inventario_general
  GROUP BY sucursal
);

--comparar el precio de productos con el mismo nombre por sucursal
SELECT
  nombre,
  sucursal,
  precio
FROM inventario_general
WHERE nombre IN (
  SELECT nombre
  FROM inventario_general
  GROUP BY nombre
  HAVING COUNT(DISTINCT sucursal) > 1
)


--consultar existencias totlaes por categorias 
SELECT
  categoria,
  SUM(existencia) AS total_existencias
FROM inventario_general
GROUP BY categoria;

--clasificar productos por precio de cada sucursal (RANK, PARTITION BY, ORDER BY)
SELECT
  sucursal,
  nombre,
  precio,
  RANK() OVER (PARTITION BY sucursal ORDER BY precio DESC) AS ranking_precio
FROM inventario_general
ORDER BY sucursal, ranking_precio;

--vista para un dashboard de inventario distribuido (COUNT, SUM, ROUND, AVG, GROUP BY)
CREATE OR REPLACE VIEW dashboard_inventario AS
SELECT
  sucursal,
  COUNT(*) AS total_productos,
  SUM(existencia) AS total_existencias,
  ROUND(AVG(precio), 2) AS precio_promedio,
  SUM(existencia * precio) AS valor_total_inventario
FROM inventario_general
GROUP BY sucursal;