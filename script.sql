-- Enunciado 4 FÁCIL
-- Para cada uma das colunas item, payment_method e location da camada raw, escreva uma
-- consulta que liste cada valor distinto e a quantidade de linhas em que ele aparece, da maior
-- para a menor quantidade. Os valores NULL também devem aparecer.

SELECT DISTINCT 
item AS valor_distinto
FROM cafe_sales;


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