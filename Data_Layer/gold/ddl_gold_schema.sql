-- =============================================
-- GOLD LAYER DDL - DENGUE DATA WAREHOUSE
-- Star Schema: 1 Fact Table + 6 Dimensions
-- Nomenclatura padronizada conforme DICIONARIO_MNEMONICOS.md
-- =============================================

-- Remover schema existente para recriação
DROP SCHEMA IF EXISTS gold CASCADE;

-- Criar schema gold
CREATE SCHEMA gold;

-- =============================================
-- DIMENSÕES
-- =============================================

-- DIMENSÃO 1: dim_tmp (Tempo) - OBRIGATÓRIA
CREATE TABLE gold.dim_tmp (
    sk_tmp SERIAL PRIMARY KEY,
    dt_completa DATE NOT NULL UNIQUE,
    nr_ano INTEGER NOT NULL,
    nr_mes INTEGER NOT NULL,
    nr_dia INTEGER NOT NULL,
    nr_trimestre INTEGER NOT NULL,
    nr_semana_epi INTEGER NOT NULL,
    nr_dia_semana INTEGER NOT NULL,
    nm_dia TEXT NOT NULL,
    flag_fim_semana BOOLEAN NOT NULL,
    ds_mes_ano TEXT NOT NULL,
    ds_ano_trimestre TEXT NOT NULL,
    ts_carga TIMESTAMP DEFAULT NOW()
);

-- Registro UNKNOWN para valores ausentes
INSERT INTO gold.dim_tmp (sk_tmp, dt_completa, nr_ano, nr_mes, nr_dia, nr_trimestre, nr_semana_epi, nr_dia_semana, nm_dia, flag_fim_semana, ds_mes_ano, ds_ano_trimestre)
VALUES (-1, '1900-01-01', 1900, 1, 1, 1, 1, 1, 'UNKNOWN', FALSE, 'UNKNOWN', 'UNKNOWN');

-- DIMENSÃO 2: dim_loc (Localização)
CREATE TABLE gold.dim_loc (
    sk_loc SERIAL PRIMARY KEY,
    sg_uf TEXT NOT NULL UNIQUE,
    nm_uf TEXT NOT NULL,
    nm_regiao TEXT NOT NULL,
    cd_ibge INTEGER,
    nm_capital TEXT,
    ts_carga TIMESTAMP DEFAULT NOW()
);

-- Registro UNKNOWN para valores ausentes
INSERT INTO gold.dim_loc (sk_loc, sg_uf, nm_uf, nm_regiao, cd_ibge, nm_capital)
VALUES (-1, 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', -1, 'UNKNOWN');

-- DIMENSÃO 3: dim_pac (Paciente)
CREATE TABLE gold.dim_pac (
    sk_pac SERIAL PRIMARY KEY,
    nk_demografica TEXT NOT NULL UNIQUE, -- business key
    ds_faixa_etaria TEXT NOT NULL,
    ds_sexo TEXT NOT NULL,
    ds_raca TEXT NOT NULL,
    ds_faixa_etaria_det TEXT NOT NULL,
    ts_carga TIMESTAMP DEFAULT NOW()
);

-- Registro UNKNOWN para valores ausentes
INSERT INTO gold.dim_pac (sk_pac, nk_demografica, ds_faixa_etaria, ds_sexo, ds_raca, ds_faixa_etaria_det)
VALUES (-1, 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN');

-- DIMENSÃO 4: dim_cls (Classificação)
CREATE TABLE gold.dim_cls (
    sk_cls SERIAL PRIMARY KEY,
    cd_classificacao TEXT NOT NULL UNIQUE, -- natural key
    ds_classificacao TEXT NOT NULL,
    ds_grupo TEXT NOT NULL,
    ds_gravidade TEXT NOT NULL,
    cd_cid TEXT,
    flag_confirmado BOOLEAN NOT NULL,
    ts_carga TIMESTAMP DEFAULT NOW()
);

-- Registro UNKNOWN para valores ausentes
INSERT INTO gold.dim_cls (sk_cls, cd_classificacao, ds_classificacao, ds_grupo, ds_gravidade, cd_cid, flag_confirmado)
VALUES (-1, 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', FALSE);

-- DIMENSÃO 5: dim_evl (Evolução)
CREATE TABLE gold.dim_evl (
    sk_evl SERIAL PRIMARY KEY,
    cd_evolucao TEXT NOT NULL UNIQUE, -- natural key
    ds_evolucao TEXT NOT NULL,
    ds_tipo_evolucao TEXT NOT NULL,
    flag_obito BOOLEAN NOT NULL,
    ds_gravidade_desfecho TEXT NOT NULL,
    ts_carga TIMESTAMP DEFAULT NOW()
);

-- Registro UNKNOWN para valores ausentes
INSERT INTO gold.dim_evl (sk_evl, cd_evolucao, ds_evolucao, ds_tipo_evolucao, flag_obito, ds_gravidade_desfecho)
VALUES (-1, 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', FALSE, 'UNKNOWN');

-- DIMENSÃO 6: dim_snt (Sintomas) - Agregada
CREATE TABLE gold.dim_snt (
    sk_snt SERIAL PRIMARY KEY,
    nk_sintomas TEXT NOT NULL UNIQUE, -- business key
    ds_faixa_sintomas TEXT NOT NULL,
    ds_faixa_alarmes TEXT NOT NULL,
    ds_perfil_clinico TEXT NOT NULL,
    flag_tem_sintomas BOOLEAN NOT NULL,
    flag_tem_alarmes BOOLEAN NOT NULL,
    ts_carga TIMESTAMP DEFAULT NOW()
);

-- Registro UNKNOWN para valores ausentes
INSERT INTO gold.dim_snt (sk_snt, nk_sintomas, ds_faixa_sintomas, ds_faixa_alarmes, ds_perfil_clinico, flag_tem_sintomas, flag_tem_alarmes)
VALUES (-1, 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', FALSE, FALSE);

-- =============================================
-- TABELA FATO
-- =============================================

-- FATO: ft_deng (Dengue)
CREATE TABLE gold.ft_deng (
    sk_fato BIGSERIAL PRIMARY KEY,
    nk_notificacao INTEGER NOT NULL,
    
    -- Foreign Keys para Dimensões
    fk_tmp INTEGER NOT NULL REFERENCES gold.dim_tmp(sk_tmp),
    fk_loc INTEGER NOT NULL REFERENCES gold.dim_loc(sk_loc),
    fk_pac INTEGER NOT NULL REFERENCES gold.dim_pac(sk_pac),
    fk_cls INTEGER NOT NULL REFERENCES gold.dim_cls(sk_cls),
    fk_evl INTEGER NOT NULL REFERENCES gold.dim_evl(sk_evl),
    fk_snt INTEGER NOT NULL REFERENCES gold.dim_snt(sk_snt),
    
    -- Métricas Aditivas
    vl_confirmado INTEGER NOT NULL CHECK (vl_confirmado IN (0,1)),
    vl_grave INTEGER NOT NULL CHECK (vl_grave IN (0,1)),
    vl_obito INTEGER NOT NULL CHECK (vl_obito IN (0,1)),
    vl_hospitalizado INTEGER NOT NULL CHECK (vl_hospitalizado IN (0,1)),
    vl_qtd_sintomas INTEGER NOT NULL CHECK (vl_qtd_sintomas >= 0 AND vl_qtd_sintomas <= 9),
    vl_qtd_alarmes INTEGER NOT NULL CHECK (vl_qtd_alarmes >= 0 AND vl_qtd_alarmes <= 8),
    
    -- Métricas Semi-aditivas
    vl_idade_anos REAL CHECK (vl_idade_anos >= 0 AND vl_idade_anos <= 120),
    
    -- Timestamps
    dt_notificacao DATE NOT NULL,
    dt_sintomas DATE,
    ts_carga TIMESTAMP DEFAULT NOW()
);

-- =============================================
-- ÍNDICES DE PERFORMANCE
-- =============================================

-- Índices nas Foreign Keys da fato
CREATE INDEX idx_ft_deng_fk_tmp ON gold.ft_deng(fk_tmp);
CREATE INDEX idx_ft_deng_fk_loc ON gold.ft_deng(fk_loc);
CREATE INDEX idx_ft_deng_fk_pac ON gold.ft_deng(fk_pac);
CREATE INDEX idx_ft_deng_fk_cls ON gold.ft_deng(fk_cls);
CREATE INDEX idx_ft_deng_fk_evl ON gold.ft_deng(fk_evl);
CREATE INDEX idx_ft_deng_fk_snt ON gold.ft_deng(fk_snt);

-- Índices compostos para queries frequentes
CREATE INDEX idx_ft_deng_tmp_loc ON gold.ft_deng(fk_tmp, fk_loc);
CREATE INDEX idx_ft_deng_confirmado_grave ON gold.ft_deng(vl_confirmado, vl_grave);

-- Índices nas dimensões
CREATE INDEX idx_dim_tmp_ano_mes ON gold.dim_tmp(nr_ano, nr_mes);
CREATE INDEX idx_dim_tmp_semana_epi ON gold.dim_tmp(nr_semana_epi);
CREATE INDEX idx_dim_loc_regiao ON gold.dim_loc(nm_regiao);

-- =============================================
-- COMENTÁRIOS PARA DOCUMENTAÇÃO
-- =============================================

COMMENT ON SCHEMA gold IS 'Gold Layer - Data Warehouse Dengue - Star Schema';

COMMENT ON TABLE gold.ft_deng IS 'Tabela Fato: Notificações individuais de dengue';
COMMENT ON TABLE gold.dim_tmp IS 'Dimensão Temporal: Hierarquia de datas epidemiológicas';
COMMENT ON TABLE gold.dim_loc IS 'Dimensão Geográfica: UFs e regiões';
COMMENT ON TABLE gold.dim_pac IS 'Dimensão Demográfica: Perfil dos pacientes';
COMMENT ON TABLE gold.dim_cls IS 'Dimensão Clínica: Classificação epidemiológica';
COMMENT ON TABLE gold.dim_evl IS 'Dimensão Desfecho: Evolução clínica dos casos';
COMMENT ON TABLE gold.dim_snt IS 'Dimensão Sintomatológica: Perfil de sintomas agregado';

-- Comentários colunas fato
COMMENT ON COLUMN gold.ft_deng.vl_confirmado IS 'Flag caso confirmado (0/1) - Métrica aditiva';
COMMENT ON COLUMN gold.ft_deng.vl_grave IS 'Flag caso grave (0/1) - Métrica aditiva';
COMMENT ON COLUMN gold.ft_deng.vl_obito IS 'Flag óbito (0/1) - Métrica aditiva';
COMMENT ON COLUMN gold.ft_deng.vl_hospitalizado IS 'Flag hospitalização (0/1) - Métrica aditiva';
COMMENT ON COLUMN gold.ft_deng.vl_qtd_sintomas IS 'Quantidade sintomas (0-9) - Métrica aditiva';
COMMENT ON COLUMN gold.ft_deng.vl_qtd_alarmes IS 'Quantidade alarmes (0-8) - Métrica aditiva';
COMMENT ON COLUMN gold.ft_deng.vl_idade_anos IS 'Idade em anos - Métrica SEMI-ADITIVA (média válida, soma não)';
