-- Enunciado 1 FÁCIL
-- No pgAdmin, crie o banco de dados cafe_dw com codificação UTF8 (registre essa etapa
-- como comentário no script). Na Query Tool desse banco, crie os schemas raw, staging 
-- e dw, usando IF NOT EXISTS, e escreva uma consulta a information_schema.schemata que
-- devolva exatamente essas três linhas.

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dw;

SELECT schema_name
FROM information_schema.schemata;

-- CREATE DATABASE cafe_dw
--     WITH
--     OWNER = postgres
--     ENCODING = 'UTF8'
--     LOCALE_PROVIDER = 'libc'
--     CONNECTION LIMIT = -1
--     IS_TEMPLATE = False;