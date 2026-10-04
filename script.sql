-- Enunciado 12 MÉDIO
-- Crie dw.fact_sales conforme a Figura 4: transaction_nk como chave primária (dimensão
-- degenerada), chaves estrangeiras NOT NULL para as quatro dimensões, métricas NOT NULL e
-- um índice por chave estrangeira. Carregue-a a partir de staging.cafe_sales, precedida de
-- TRUNCATE: date_sk por formatação da data, sem JOIN; as outras três surrogate keys por JOIN
-- com as dimensões. Por fim, escreva uma consulta que compare, lado a lado, a quantidade de
-- linhas e a soma de total_spent da staging e da fato. Os dois pares devem ser iguais.

-- Criando, adc. índice e carregando dw.fact_sales
DROP TABLE IF EXISTS dw.fact_sales CASCADE;
CREATE TABLE dw.fact_sales(
  transaction_nk VARCHAR(20) PRIMARY KEY,
  date_sk INTEGER NOT NULL,
  item_sk INTEGER NOT NULL REFERENCES dw.dim_item(item_sk),
  payment_sk INTEGER NOT NULL REFERENCES dw.dim_payment(payment_sk),
  location_sk INTEGER NOT NULL REFERENCES dw.dim_location(location_sk),
  quantity INTEGER NOT NULL,
  price_per_unit NUMERIC(6,2) NOT NULL,
  total_spent NUMERIC(8,2) NOT NULL
);

CREATE INDEX ix_fs_date ON dw.fact_sales(date_sk);
CREATE INDEX ix_fs_item ON dw.fact_sales(item_sk);
CREATE INDEX ix_fs_payment ON dw.fact_sales(payment_sk);
CREATE INDEX ix_fs_location ON dw.fact_sales(location_sk);

TRUNCATE dw.fact_sales;
INSERT INTO dw.fact_sales(
  transaction_nk, date_sk, item_sk, payment_sk, location_sk, quantity, price_per_unit, total_spent
)
SELECT
  s.transaction_id, CAST(TO_CHAR(s.transaction_date, 'YYYMMDD') AS INTEGER), di.item_sk, dp.payment_sk,
  dl.location_sk, s.quantity, s.price_per_unit, s.total_spent
FROM staging.cafe_sales s
INNER JOIN dw.dim_item di ON (s.item = di.item)
INNER JOIN dw.dim_payment dp ON (s.payment_method = dp.payment)
INNER JOIN dw.dim_location dl ON (s.location = dl.location);

-- Consulta
SELECT COUNT(total_spent) AS qtd_linhas, SUM(total_spent) AS soma
FROM staging.cafe_sales
UNION ALL
SELECT COUNT(total_spent) AS qtd_linhas, SUM(total_spent) AS soma
FROM dw.fact_sales;
-- Pares iguais


-- Enunciado 11 FÁCIL
-- Crie e carregue dw.dim_item, dw.dim_payment e dw.dim_location, com chaves SERIAL e
-- atributos descritivos UNIQUE. A carga usa DISTINCT sobre staging.cafe_sales; a category
-- de dim_item vem de staging.cardapio. Confira as três dimensões em uma única consulta
-- com UNION ALL: esperam-se 8 itens, 4 formas de pagamento e 3 locais, já incluído o valor
-- 'Unknown'.

-- Criando e carregando dimensões
DROP TABLE IF EXISTS dw.dim_item CASCADE;
CREATE TABLE dw.dim_item(
  item_sk SERIAL PRIMARY KEY,
  item VARCHAR(40) NOT NULL UNIQUE,
  category VARCHAR(40) NOT NULL
);
DROP TABLE IF EXISTS dw.dim_payment CASCADE;
CREATE TABLE dw.dim_payment(
  payment_sk SERIAL PRIMARY KEY,
  payment VARCHAR(20) NOT NULL UNIQUE
);
DROP TABLE IF EXISTS dw.dim_location CASCADE;
CREATE TABLE dw.dim_location(
  location_sk SERIAL PRIMARY KEY,
  location VARCHAR(40) NOT NULL
);

SELECT * FROM staging.cafe_sales;
SELECT * FROM staging.cardapio;

INSERT INTO dw.dim_item(item, category)
SELECT DISTINCT ss.item, sc.category
FROM staging.cafe_sales ss
INNER JOIN staging.cardapio sc ON (ss.item = sc.item);

INSERT INTO dw.dim_payment(payment)
SELECT DISTINCT payment_method FROM staging.cafe_sales;

INSERT INTO dw.dim_location(location)
SELECT DISTINCT location FROM staging.cafe_sales;

-- Consulta
SELECT item FROM dw.dim_item
UNION ALL
SELECT location FROM dw.dim_location
UNION ALL
SELECT payment FROM dw.dim_payment;

-- Enunciado 10 FÁCIL
-- Consulte a menor e a maior data de venda registradas em staging.cafe_sales. Em seguida,
-- crie dw.dim_date com as colunas da Figura 4 (date_sk inteiro no formato YYYYMMDD) e
-- carregue-a com generate_series, gerando todos os dias dos anos completos que cobrem
-- esse intervalo. Confira a quantidade de linhas geradas.

-- Criando e carregando dw.dim_date
DROP TABLE IF EXISTS dw.dim_date CASCADE;
CREATE TABLE dw.dim_date(
  date_sk INTEGER PRIMARY KEY,
  full_date DATE NOT NULL UNIQUE,
  day SMALLINT NOT NULL,
  month SMALLINT NOT NULL,
  month_name VARCHAR(15)NOT NULL,
  quarter SMALLINT NOT NULL,
  year SMALLINT NOT NULL,
  day_of_week VARCHAR(15)NOT NULL,
  is_weekend BOOLEAN NOT NULL
);

INSERT INTO dw.dim_date
SELECT
  CAST(TO_CHAR(d,'YYYYMMDD') AS INTEGER),
  d::DATE,
  EXTRACT(DAY FROM d)::SMALLINT,
  EXTRACT(MONTH FROM d)::SMALLINT,
  TO_CHAR(d, 'TMMonth'),
  EXTRACT(QUARTER FROM d)::SMALLINT,
  EXTRACT(YEAR FROM d)::SMALLINT,
  TO_CHAR(d, 'TMDay'),
  EXTRACT(DOW FROM d) IN (0,6)
  FROM generate_series(DATE '2023-01-01', DATE '2023-12-31', INTERVAL '1day') g(d);

  SELECT COUNT(*) FROM dw.dim_date;

-- Consulta
SELECT 
  MIN(transaction_date) AS menor_data,
  MAX(transaction_date) AS maior_data
FROM staging.cafe_sales;

-- Enunciado 9 MÉDIO
-- Crie staging.cafe_sales com as mesmas colunas e tipos da Tabela 6, agora com NOT NULL
-- em todas elas e com as restrições CHECK (quantity > 0) e CHECK (price_per_unit > 0).
-- Carregue-a, precedida de TRUNCATE, apenas com as linhas de staging.cafe_tipada que
-- não têm nenhum valor nulo. Escreva então uma consulta que devolva, em uma única linha,
-- três colunas: linhas_tipada, linhas_limpas e descartadas. Registre os três números em
-- comentário.

-- Consulta
SELECT 
  COUNT(st.*) AS linhas_tipada,
  COUNT(SS.*) AS linhas_limpas,
  (COUNT(st.*) - COUNT(SS.*)) AS linhas_descartadas
FROM staging.cafe_tipada st
LEFT OUTER JOIN staging.cafe_sales ss ON ss.transaction_id = st.transaction_id;
-- 10000, 9064, 936


-- Carregando
TRUNCATE staging.cafe_sales;
INSERT INTO staging.cafe_sales(
  transaction_id, item, quantity, price_per_unit, total_spent, payment_method,
  location, transaction_date
)
SELECT
  transaction_id, item, quantity, price_per_unit, total_spent, payment_method,
  location, transaction_date
FROM staging.cafe_tipada
WHERE (transaction_id, item, quantity, price_per_unit, total_spent, payment_method,
location, transaction_date) IS NOT NULL;

-- Criando staging.cafe_sales com NOT NULL
DROP TABLE IF EXISTS staging.cafe_sales;
CREATE TABLE staging.cafe_sales(
	transaction_id VARCHAR(20) PRIMARY KEY,
	item VARCHAR(20) NOT NULL,
	quantity INTEGER NOT NULL CHECK(quantity > 0),
	price_per_unit NUMERIC(6,2) NOT NULL CHECK(price_per_unit > 0),
	total_spent NUMERIC(8,2) NOT NULL,
	payment_method VARCHAR(20) NOT NULL,
	location VARCHAR(20) NOT NULL,
	transaction_date DATE NOT NULL
	);

-- Enunciado 8 MÉDIO
-- Aplique à tabela staging.cafe_tipada as regras da Tabela 7, na ordem indicada, com
-- um UPDATE por regra (a R6 pode usar dois). Use subconsultas sobre staging.cardapio
-- nas regras R1 e R5. Abaixo de cada UPDATE, registre em comentário a quantidade de linhas
-- afetadas informada pelo pgAdmin.

-- R6 - forma de pagamento ou local nulos
UPDATE staging.cafe_tipada
SET payment_method = 'Unknown'
WHERE payment_method IS NULL;
-- UPDATE 3178 linhas afetadas
UPDATE staging.cafe_tipada
SET location = 'Unknown'
WHERE location IS NULL;
-- UPDATE 3961 linhas afetadas

-- R5 - item nulo e preço conhecido, pertencente a um único item do cardápio
UPDATE staging.cafe_tipada AS cafe
SET item = (
    SELECT MIN(cardapio.item)
    FROM staging.cardapio AS cardapio
    WHERE cardapio.price = cafe.price_per_unit
    GROUP BY cardapio.price
    HAVING COUNT(DISTINCT cardapio.item) = 1
)
WHERE cafe.item IS NULL
  AND cafe.price_per_unit IS NOT NULL;
-- UPDATE 963 linhas afetadas

-- R4 - total nulo, quantidade e preço conhecidos
UPDATE staging.cafe_tipada
SET total_spent = (quantity * price_per_unit)
WHERE total_spent IS NULL
  AND price_per_unit IS NOT NULL
  AND quantity IS NOT NULL;
-- UPDATE 479 linhas afetadas

-- R3 - quantidade nula, preço e total conhecidos
UPDATE staging.cafe_tipada
SET quantity = ROUND((total_spent / price_per_unit), 0)
WHERE quantity IS NULL
  AND price_per_unit IS NOT NULL
  AND total_spent IS NOT NULL;
-- UPDATE 456 linhas afetadas

-- R2 - preço nulo, quantidade e total conhecidos
UPDATE staging.cafe_tipada
SET price_per_unit = (total_spent / quantity)
WHERE price_per_unit IS NULL
	AND quantity IS NOT NULL
	AND total_spent IS NOT NULL;
-- UPDATE 48 linhas afetadas

-- R1 - preço nulo e item conhecido
UPDATE staging.cafe_tipada AS cafe
SET price_per_unit = (
    SELECT cardapio.price
    FROM staging.cardapio AS cardapio
    WHERE cardapio.item = cafe.item
)
WHERE cafe.price_per_unit IS NULL
  AND cafe.item IS NOT NULL;
-- UPDATE 479 linhas afetadas

-- Enunciado 7 FÁCIL
-- Crie a tabela staging.cardapio com as colunas item (VARCHAR(20), chave primária), price
-- (NUMERIC(6,2) NOT NULL) e category (VARCHAR(10) NOT NULL) e insira nela as oito linhas
-- da Tabela 3.
SELECT * FROM staging.cardapio;

INSERT INTO staging.cardapio (item, price, category) VALUES ('Cookie', 1.00, 'Comida');
INSERT INTO staging.cardapio (item, price, category) VALUES ('Tea', 1.50, 'Bebida');
INSERT INTO staging.cardapio (item, price, category) VALUES ('Coffee', 2.00, 'Bebida');
INSERT INTO staging.cardapio (item, price, category) VALUES ('Cake', 3.00, 'Comida');
INSERT INTO staging.cardapio (item, price, category) VALUES ('Juice', 3.00, 'Bebida');
INSERT INTO staging.cardapio (item, price, category) VALUES ('Sandwich', 4.00, 'Comida');
INSERT INTO staging.cardapio (item, price, category) VALUES ('Smoothie', 4.00, 'Bebida');
INSERT INTO staging.cardapio (item, price, category) VALUES ('Salad', 5.00, 'Comida');

DROP TABLE IF EXISTS staging.cardapio;
CREATE TABLE staging.cardapio(
	item VARCHAR(20) PRIMARY KEY,
	price NUMERIC(6,2) NOT NULL,
	category VARCHAR(10) NOT NULL
	);

-- Enunciado 6 MÉDIO
-- Crie staging.cafe_tipada conforme a Tabela 6 e carregue-a a partir de raw.cafe_sales
-- com um único INSERT ... SELECT, precedido de TRUNCATE. Em todas as colunas, aplique
-- TRIM e transforme '', 'ERROR' e 'UNKNOWN' em NULL antes de qualquer conversão; converta
-- as colunas numéricas com CAST e a data com TO_DATE no formato 'YYYY-MM-DD'. Em seguida,
-- escreva uma consulta que conte os NULL de cada coluna da tabela tipada. Para cada coluna,
-- o total deve ser igual à soma qtd_error + qtd_unknown + qtd_vazio obtida no Enunciado 5.

SELECT 'item' AS coluna,
COUNT(*) FILTER (WHERE item IS NULL) AS qtd_vazio
FROM staging.cafe_tipada
-- UNION ALL
-- SELECT 'quantity', 
-- COUNT(*) FILTER (WHERE quantity IS NULL)
-- FROM staging.cafe_tipada
-- UNION ALL
-- SELECT 'price_per_unit',
-- COUNT(*) FILTER (WHERE price_per_unit IS NULL)
-- FROM staging.cafe_tipada
-- UNION ALL
-- SELECT 'total_spent',
-- COUNT(*) FILTER (WHERE total_spent IS NULL)
-- FROM staging.cafe_tipada
-- UNION ALL
-- SELECT 'payment_method',
-- COUNT(*) FILTER (WHERE payment_method IS NULL)
-- FROM staging.cafe_tipada
-- UNION ALL
-- SELECT 'location', 
-- COUNT(*) FILTER (WHERE location IS NULL)
-- FROM staging.cafe_tipada
-- UNION ALL
-- SELECT 'transaction_date', 
-- COUNT(*) FILTER (WHERE transaction_date IS NULL)
-- FROM staging.cafe_tipada;

-- SELECT * FROM staging.cafe_tipada;

-- TRUNCATE TABLE staging.cafe_tipada;
-- INSERT INTO staging.cafe_tipada(
-- 	transaction_id, item, quantity, price_per_unit,
-- 	total_spent, payment_method, location,
-- 	transaction_date
-- )
-- SELECT
-- 	UPPER(TRIM(transaction_id)),
-- 	INITCAP(TRIM(item)),
-- 	CAST(TRIM(quantity) AS INTEGER),
-- 	CAST(TRIM(price_per_unit) AS NUMERIC(6, 2)),
-- 	CAST(TRIM(total_spent) AS NUMERIC(8, 2)),
-- 	INITCAP(TRIM(payment_method)),	
-- 	INITCAP(TRIM(location)),
-- 	TO_DATE(
-- 		TRIM(transaction_date),
-- 		'YYYY-MM-DD'
-- 	)
-- FROM raw.cafe_sales
-- WHERE TRIM(transaction_id) <> '';

-- UPDATE raw.cafe_sales
-- SET
--     transaction_id = NULLIF(transaction_id, 'ERROR'),
--     item = NULLIF(item, 'ERROR'),
--     quantity = NULLIF(quantity, 'ERROR'),
--     price_per_unit = NULLIF(price_per_unit, 'ERROR'),
--     total_spent = NULLIF(total_spent, 'ERROR'),
--     payment_method = NULLIF(payment_method, 'ERROR'),
--     location = NULLIF(location, 'ERROR'),
--     transaction_date = NULLIF(transaction_date, 'ERROR')
-- WHERE transaction_id LIKE '%ERROR%'
--     OR item LIKE '%ERROR%'
--     OR quantity LIKE '%ERROR%'
--     OR price_per_unit LIKE '%ERROR%'
--     OR total_spent LIKE '%ERROR%'
--     OR payment_method LIKE '%ERROR%'
--     OR location LIKE '%ERROR%'
--     OR transaction_date LIKE '%ERROR%';

-- UPDATE raw.cafe_sales
-- SET
--     transaction_id = NULLIF(transaction_id, 'UNKNOWN'),
--     item = NULLIF(item, 'UNKNOWN'),
--     quantity = NULLIF(quantity, 'UNKNOWN'),
--     price_per_unit = NULLIF(price_per_unit, 'UNKNOWN'),
--     total_spent = NULLIF(total_spent, 'UNKNOWN'),
--     payment_method = NULLIF(payment_method, 'UNKNOWN'),
--     location = NULLIF(location, 'UNKNOWN'),
--     transaction_date = NULLIF(transaction_date, 'UNKNOWN')
-- WHERE transaction_id LIKE '%UNKNOWN%'
--     OR item LIKE '%UNKNOWN%'
--     OR quantity LIKE '%UNKNOWN%'
--     OR price_per_unit LIKE '%UNKNOWN%'
--     OR total_spent LIKE '%UNKNOWN%'
--     OR payment_method LIKE '%UNKNOWN%'
--     OR location LIKE '%UNKNOWN%'
--     OR transaction_date LIKE '%UNKNOWN%';

-- UPDATE raw.cafe_sales
-- SET
--     transaction_id = NULLIF(transaction_id, ''),
--     item = NULLIF(item, ''),
--     quantity = NULLIF(quantity, ''),
--     price_per_unit = NULLIF(price_per_unit, ''),
--     total_spent = NULLIF(total_spent, ''),
--     payment_method = NULLIF(payment_method, ''),
--     location = NULLIF(location, ''),
--     transaction_date = NULLIF(transaction_date, '')
-- WHERE transaction_id LIKE '%%'
--     OR item LIKE ''
--     OR quantity LIKE ''
--     OR price_per_unit LIKE ''
--     OR total_spent LIKE ''
--     OR payment_method LIKE ''
--     OR location LIKE ''
--     OR transaction_date LIKE '';

-- INSERT INTO staging.cafe_tipada (transaction_id)
-- SELECT TRIM(transaction_id)
-- FROM raw.cafe_sales;

-- DROP TABLE IF EXISTS staging.cafe_tipada;
-- CREATE TABLE staging.cafe_tipada(
-- 	transaction_id VARCHAR(20) PRIMARY KEY,
-- 	item VARCHAR(20),
-- 	quantity INTEGER,
-- 	price_per_unit NUMERIC(6,2),
-- 	total_spent NUMERIC(8,2),
-- 	payment_method VARCHAR(20),
-- 	location VARCHAR(20),
-- 	transaction_date DATE
-- 	);

-- Enunciado 5 MÉDIO
-- Escreva uma única consulta, usando UNION ALL, que devolva uma linha para cada coluna
-- da camada raw, exceto transaction_id, com quatro colunas: coluna (o nome da coluna,
-- como texto), qtd_error, qtd_unknown e qtd_vazio (valor NULL ou texto vazio após TRIM).
-- O resultado terá sete linhas.

-- SELECT 
--     'item' AS coluna,
--     COUNT(*) FILTER (WHERE item = 'ERROR') AS qtd_error,
--     COUNT(*) FILTER (WHERE item = 'UNKNOWN') AS qtd_unknown,
--     COUNT(*) FILTER (WHERE item IS NULL OR TRIM(item) = '') AS qtd_vazio,
-- FROM raw.cafe_sales
-- UNION ALL
-- SELECT 'quantity', COUNT(*) FILTER (WHERE quantity = 'ERROR'), COUNT(*) FILTER (WHERE quantity = 'UNKNOWN'), 
-- COUNT(*) FILTER (WHERE quantity IS NULL OR TRIM(quantity) = '')
-- FROM raw.cafe_sales
-- UNION ALL
-- SELECT 'price_per_unit', COUNT(*) FILTER (WHERE price_per_unit = 'ERROR'), COUNT(*) FILTER (WHERE price_per_unit = 'UNKNOWN'), 
-- COUNT(*) FILTER (WHERE price_per_unit IS NULL OR TRIM(price_per_unit) = '')
-- FROM raw.cafe_sales
-- UNION ALL
-- SELECT 'total_spent', COUNT(*) FILTER (WHERE total_spent = 'ERROR'), COUNT(*) FILTER (WHERE total_spent = 'UNKNOWN'), 
-- COUNT(*) FILTER (WHERE total_spent IS NULL OR TRIM(total_spent) = '')
-- FROM raw.cafe_sales
-- UNION ALL
-- SELECT 'payment_method', COUNT(*) FILTER (WHERE payment_method = 'ERROR'), COUNT(*) FILTER (WHERE payment_method = 'UNKNOWN'), 
-- COUNT(*) FILTER (WHERE payment_method IS NULL OR TRIM(payment_method) = '')
-- FROM raw.cafe_sales
-- UNION ALL
-- SELECT 'location', COUNT(*) FILTER (WHERE location = 'ERROR'), COUNT(*) FILTER (WHERE location = 'UNKNOWN'), 
-- COUNT(*) FILTER (WHERE location IS NULL OR TRIM(location) = '')
-- FROM raw.cafe_sales
-- UNION ALL
-- SELECT 'transaction_date', COUNT(*) FILTER (WHERE transaction_date = 'ERROR'), COUNT(*) FILTER (WHERE transaction_date = 'UNKNOWN'), 
-- COUNT(*) FILTER (WHERE transaction_date IS NULL OR TRIM(transaction_date) = '')
-- FROM raw.cafe_sales;

-- Enunciado 4 FÁCIL
-- Para cada uma das colunas item, payment_method e location da camada raw, escreva uma
-- consulta que liste cada valor distinto e a quantidade de linhas em que ele aparece, da maior
-- para a menor quantidade. Os valores NULL também devem aparecer.

-- SELECT DISTINCT location AS location_distintos, COUNT (location) AS contagem
-- FROM raw.cafe_sales
-- GROUP BY location
-- ORDER BY contagem DESC;

-- SELECT DISTINCT payment_method AS payment_method_distintos, COUNT (payment_method) AS contagem
-- FROM raw.cafe_sales
-- GROUP BY payment_method
-- ORDER BY contagem DESC;

-- SELECT DISTINCT item AS itens_distintos, COUNT (item) AS contagem
-- FROM raw.cafe_sales
-- GROUP BY item
-- ORDER BY contagem DESC;

-- Enunciado 3 FÁCIL
-- Importe dirty_cafe_sales.csv para raw.cafe_sales com Import/Export Data… do
-- pgAdmin (Format csv, Encoding UTF8, Header ligado, Delimiter vírgula). Registre em
-- comentário as opções usadas e escreva duas consultas de validação: o total de linhas (10.000
-- esperadas) e o total de valores distintos de transaction_id

-- SELECT COUNT(DISTINCT transaction_id) AS total_distintos_transaction_id
-- FROM raw.cafe_sales;

-- SELECT COUNT (*) AS total_linhas
-- FROM raw.cafe_sales;

-- Configurações de importação do arquivo 'dirty_cafe_sales.csv'
-- FORMAT csv
-- DELIMITER ','
-- HEADER [ True | MATCH ]
-- ENCODING 'UTF8'

-- Enunciado 2 FÁCIL
-- Crie a tabela raw.cafe_sales com as oito colunas da Tabela 1, todas do tipo TEXT, sem
-- nenhuma restrição e na mesma ordem do arquivo CSV. Inicie o bloco com DROP TABLE IF
-- EXISTS ... CASCADE.

-- SELECT * FROM raw.cafe_sales;

-- DROP TABLE IF EXISTS raw.cafe_sales CASCADE;
-- CREATE TABLE raw.cafe_sales(
-- 	transaction_id TEXT,
-- 	item TEXT,
-- 	quantity TEXT,
-- 	price_per_unit TEXT,
-- 	total_spent TEXT,
-- 	payment_method TEXT,
-- 	location TEXT,
-- 	transaction_date TEXT
-- );

-- Enunciado 1 FÁCIL
-- No pgAdmin, crie o banco de dados cafe_dw com codificação UTF8 (registre essa etapa
-- como comentário no script). Na Query Tool desse banco, crie os schemas raw, staging 
-- e dw, usando IF NOT EXISTS, e escreva uma consulta a information_schema.schemata que
-- devolva exatamente essas três linhas.

-- CREATE SCHEMA IF NOT EXISTS raw;
-- CREATE SCHEMA IF NOT EXISTS staging;
-- CREATE SCHEMA IF NOT EXISTS dw;

-- SELECT schema_name
-- FROM information_schema.schemata;

-- CREATE DATABASE cafe_dw
--     WITH
--     OWNER = postgres
--     ENCODING = 'UTF8'
--     LOCALE_PROVIDER = 'libc'
--     CONNECTION LIMIT = -1
--     IS_TEMPLATE = False;