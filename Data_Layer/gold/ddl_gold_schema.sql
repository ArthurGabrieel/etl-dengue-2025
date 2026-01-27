-- =============================================
-- GOLD LAYER DDL - DENGUE DATA WAREHOUSE
-- Star Schema: 1 Fact Table + 6 Dimensions
-- =============================================

-- Criar schema gold se não existir
CREATE SCHEMA IF NOT EXISTS gold;

-- =============================================
-- DIMENSÕES
-- =============================================

-- DIMENSÃO 1: dim_tempo (OBRIGATÓRIA)
CREATE TABLE gold.dim_tempo (
    sk_tempo SERIAL PRIMARY KEY,
    data_completa DATE NOT NULL UNIQUE,
    ano INTEGER NOT NULL,
    mes INTEGER NOT NULL,
    dia INTEGER NOT NULL,
    trimestre INTEGER NOT NULL,
    semana_epi INTEGER NOT NULL,
    dia_semana INTEGER NOT NULL,
    nome_dia TEXT NOT NULL,
    flag_fim_semana BOOLEAN NOT NULL,
    mes_ano TEXT NOT NULL,
    ano_trimestre TEXT NOT NULL,
    ts_carga TIMESTAMP DEFAULT NOW()
);

-- Registro UNKNOWN para valores ausentes
INSERT INTO gold.dim_tempo (sk_tempo, data_completa, ano, mes, dia, trimestre, semana_epi, dia_semana, nome_dia, flag_fim_semana, mes_ano, ano_trimestre)
VALUES (-1, '1900-01-01', 1900, 1, 1, 1, 1, 1, 'UNKNOWN', FALSE, 'UNKNOWN', 'UNKNOWN');

-- DIMENSÃO 2: dim_localizacao
CREATE TABLE gold.dim_localizacao (
    sk_localizacao SERIAL PRIMARY KEY,
    uf_sigla TEXT NOT NULL UNIQUE,
    uf_nome TEXT NOT NULL,
    regiao TEXT NOT NULL,
    codigo_ibge INTEGER,
    capital TEXT,
    ts_carga TIMESTAMP DEFAULT NOW()
);

-- Registro UNKNOWN para valores ausentes
INSERT INTO gold.dim_localizacao (sk_localizacao, uf_sigla, uf_nome, regiao, codigo_ibge, capital)
VALUES (-1, 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', -1, 'UNKNOWN');

-- DIMENSÃO 3: dim_paciente
CREATE TABLE gold.dim_paciente (
    sk_paciente SERIAL PRIMARY KEY,
    combinacao_demografica TEXT NOT NULL UNIQUE, -- business key
    faixa_etaria TEXT NOT NULL,
    sexo_desc TEXT NOT NULL,
    raca_desc TEXT NOT NULL,
    faixa_etaria_detalhada TEXT NOT NULL,
    ts_carga TIMESTAMP DEFAULT NOW()
);

-- Registro UNKNOWN para valores ausentes
INSERT INTO gold.dim_paciente (sk_paciente, combinacao_demografica, faixa_etaria, sexo_desc, raca_desc, faixa_etaria_detalhada)
VALUES (-1, 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN');

-- DIMENSÃO 4: dim_classificacao
CREATE TABLE gold.dim_classificacao (
    sk_classificacao SERIAL PRIMARY KEY,
    classificacao_codigo TEXT NOT NULL UNIQUE, -- natural key
    classificacao_desc TEXT NOT NULL,
    classificacao_grupo TEXT NOT NULL,
    gravidade TEXT NOT NULL,
    codigo_cid TEXT,
    flag_confirmado BOOLEAN NOT NULL,
    ts_carga TIMESTAMP DEFAULT NOW()
);

-- Registro UNKNOWN para valores ausentes
INSERT INTO gold.dim_classificacao (sk_classificacao, classificacao_codigo, classificacao_desc, classificacao_grupo, gravidade, codigo_cid, flag_confirmado)
VALUES (-1, 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', FALSE);

-- DIMENSÃO 5: dim_evolucao
CREATE TABLE gold.dim_evolucao (
    sk_evolucao SERIAL PRIMARY KEY,
    evolucao_codigo TEXT NOT NULL UNIQUE, -- natural key
    evolucao_desc TEXT NOT NULL,
    tipo_evolucao TEXT NOT NULL,
    flag_obito BOOLEAN NOT NULL,
    gravidade_desfecho TEXT NOT NULL,
    ts_carga TIMESTAMP DEFAULT NOW()
);

-- Registro UNKNOWN para valores ausentes
INSERT INTO gold.dim_evolucao (sk_evolucao, evolucao_codigo, evolucao_desc, tipo_evolucao, flag_obito, gravidade_desfecho)
VALUES (-1, 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', FALSE, 'UNKNOWN');

-- DIMENSÃO 6: dim_sintomas (Agregada)
CREATE TABLE gold.dim_sintomas (
    sk_sintomas SERIAL PRIMARY KEY,
    combinacao_sintomas TEXT NOT NULL UNIQUE, -- business key
    qtd_sintomas_faixa TEXT NOT NULL,
    qtd_alarmes_faixa TEXT NOT NULL,
    perfil_clinico TEXT NOT NULL,
    flag_tem_sintomas BOOLEAN NOT NULL,
    flag_tem_alarmes BOOLEAN NOT NULL,
    ts_carga TIMESTAMP DEFAULT NOW()
);

-- Registro UNKNOWN para valores ausentes
INSERT INTO gold.dim_sintomas (sk_sintomas, combinacao_sintomas, qtd_sintomas_faixa, qtd_alarmes_faixa, perfil_clinico, flag_tem_sintomas, flag_tem_alarmes)
VALUES (-1, 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', FALSE, FALSE);

-- =============================================
-- TABELA FATO
-- =============================================

-- FATO: ft_dengue
CREATE TABLE gold.ft_dengue (
    sk_fato BIGSERIAL PRIMARY KEY,
    id_notificacao_original INTEGER NOT NULL,
    
    -- Foreign Keys para Dimensões
    fk_tempo INTEGER NOT NULL REFERENCES gold.dim_tempo(sk_tempo),
    fk_localizacao INTEGER NOT NULL REFERENCES gold.dim_localizacao(sk_localizacao),
    fk_paciente INTEGER NOT NULL REFERENCES gold.dim_paciente(sk_paciente),
    fk_classificacao INTEGER NOT NULL REFERENCES gold.dim_classificacao(sk_classificacao),
    fk_evolucao INTEGER NOT NULL REFERENCES gold.dim_evolucao(sk_evolucao),
    fk_sintomas INTEGER NOT NULL REFERENCES gold.dim_sintomas(sk_sintomas),
    
    -- Métricas Aditivas
    vl_caso_confirmado INTEGER NOT NULL CHECK (vl_caso_confirmado IN (0,1)),
    vl_caso_grave INTEGER NOT NULL CHECK (vl_caso_grave IN (0,1)),
    vl_obito INTEGER NOT NULL CHECK (vl_obito IN (0,1)),
    vl_hospitalizado INTEGER NOT NULL CHECK (vl_hospitalizado IN (0,1)),
    vl_qtd_sintomas INTEGER NOT NULL CHECK (vl_qtd_sintomas >= 0 AND vl_qtd_sintomas <= 9),
    vl_qtd_alarmes INTEGER NOT NULL CHECK (vl_qtd_alarmes >= 0 AND vl_qtd_alarmes <= 8),
    
    -- Métricas Semi-aditivas
    vl_idade_anos REAL CHECK (vl_idade_anos >= 0 AND vl_idade_anos <= 120),
    
    -- Timestamps
    ts_notificacao DATE NOT NULL,
    ts_sintomas DATE,
    ts_carga TIMESTAMP DEFAULT NOW()
);

-- =============================================
-- ÍNDICES DE PERFORMANCE
-- =============================================

-- Índices nas Foreign Keys da fato
CREATE INDEX idx_ft_dengue_fk_tempo ON gold.ft_dengue(fk_tempo);
CREATE INDEX idx_ft_dengue_fk_localizacao ON gold.ft_dengue(fk_localizacao);
CREATE INDEX idx_ft_dengue_fk_paciente ON gold.ft_dengue(fk_paciente);
CREATE INDEX idx_ft_dengue_fk_classificacao ON gold.ft_dengue(fk_classificacao);
CREATE INDEX idx_ft_dengue_fk_evolucao ON gold.ft_dengue(fk_evolucao);
CREATE INDEX idx_ft_dengue_fk_sintomas ON gold.ft_dengue(fk_sintomas);

-- Índices compostos para queries frequentes
CREATE INDEX idx_ft_dengue_tempo_local ON gold.ft_dengue(fk_tempo, fk_localizacao);
CREATE INDEX idx_ft_dengue_confirmado_grave ON gold.ft_dengue(vl_caso_confirmado, vl_caso_grave);

-- Índices nas dimensões
CREATE INDEX idx_dim_tempo_ano_mes ON gold.dim_tempo(ano, mes);
CREATE INDEX idx_dim_tempo_semana_epi ON gold.dim_tempo(semana_epi);
CREATE INDEX idx_dim_localizacao_regiao ON gold.dim_localizacao(regiao);

-- =============================================
-- COMENTÁRIOS PARA DOCUMENTAÇÃO
-- =============================================

COMMENT ON SCHEMA gold IS 'Gold Layer - Data Warehouse Dengue - Star Schema';

COMMENT ON TABLE gold.ft_dengue IS 'Tabela Fato: Notificações individuais de dengue';
COMMENT ON TABLE gold.dim_tempo IS 'Dimensão Temporal: Hierarquia de datas epidemiológicas';
COMMENT ON TABLE gold.dim_localizacao IS 'Dimensão Geográfica: UFs e regiões';
COMMENT ON TABLE gold.dim_paciente IS 'Dimensão Demográfica: Perfil dos pacientes';
COMMENT ON TABLE gold.dim_classificacao IS 'Dimensão Clínica: Classificação epidemiológica';
COMMENT ON TABLE gold.dim_evolucao IS 'Dimensão Desfecho: Evolução clínica dos casos';
COMMENT ON TABLE gold.dim_sintomas IS 'Dimensão Sintomatológica: Perfil de sintomas agregado';

-- Comentários colunas fato
COMMENT ON COLUMN gold.ft_dengue.vl_caso_confirmado IS 'Flag caso confirmado (0/1) - Métrica aditiva';
COMMENT ON COLUMN gold.ft_dengue.vl_caso_grave IS 'Flag caso grave (0/1) - Métrica aditiva';
COMMENT ON COLUMN gold.ft_dengue.vl_obito IS 'Flag óbito (0/1) - Métrica aditiva';
COMMENT ON COLUMN gold.ft_dengue.vl_hospitalizado IS 'Flag hospitalização (0/1) - Métrica aditiva';
COMMENT ON COLUMN gold.ft_dengue.vl_qtd_sintomas IS 'Quantidade sintomas (0-9) - Métrica aditiva';
COMMENT ON COLUMN gold.ft_dengue.vl_qtd_alarmes IS 'Quantidade alarmes (0-8) - Métrica aditiva';
COMMENT ON COLUMN gold.ft_dengue.vl_idade_anos IS 'Idade em anos - Métrica SEMI-ADITIVA (média válida, soma não)';