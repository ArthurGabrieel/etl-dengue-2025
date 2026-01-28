-- =============================================
-- GOLD LAYER DDL - DENGUE DATA WAREHOUSE
-- Star Schema: 1 Fact Table + 6 Dimensions
-- Padrao: Nomenclatura corporativa 3 letras UPPERCASE
-- =============================================

CREATE SCHEMA IF NOT EXISTS dw;

COMMENT ON SCHEMA dw IS 'Camada Gold - Star Schema Dengue';

-- Remover tabelas existentes
DROP TABLE IF EXISTS dw.FAT_DEN CASCADE;
DROP TABLE IF EXISTS dw.DIM_TMP CASCADE;
DROP TABLE IF EXISTS dw.DIM_LOC CASCADE;
DROP TABLE IF EXISTS dw.DIM_PAC CASCADE;
DROP TABLE IF EXISTS dw.DIM_CLS CASCADE;
DROP TABLE IF EXISTS dw.DIM_EVL CASCADE;
DROP TABLE IF EXISTS dw.DIM_SNT CASCADE;

-- =============================================
-- DIMENSOES
-- =============================================

-- DIMENSAO 1: DIM_TMP (Tempo)
CREATE TABLE dw.DIM_TMP (
    TMP_SRK BIGINT PRIMARY KEY,
    DAT_COM DATE NOT NULL UNIQUE,
    NUM_ANO INTEGER NOT NULL,
    NUM_MES INTEGER NOT NULL,
    NUM_DIA INTEGER NOT NULL,
    NUM_TRI INTEGER NOT NULL,
    NUM_SEM_EPI INTEGER NOT NULL,
    NUM_DIA_SEM INTEGER NOT NULL,
    NOM_DIA VARCHAR(20) NOT NULL,
    IND_FDS INTEGER NOT NULL,
    DES_MES_ANO VARCHAR(10) NOT NULL,
    DES_ANO_TRI VARCHAR(10) NOT NULL
);

-- Registro UNKNOWN
INSERT INTO dw.DIM_TMP (TMP_SRK, DAT_COM, NUM_ANO, NUM_MES, NUM_DIA, NUM_TRI, NUM_SEM_EPI, NUM_DIA_SEM, NOM_DIA, IND_FDS, DES_MES_ANO, DES_ANO_TRI)
VALUES (-1, '1900-01-01', 1900, 1, 1, 1, 1, 1, 'UNKNOWN', 0, 'UNKNOWN', 'UNKNOWN');

-- DIMENSAO 2: DIM_LOC (Localizacao)
CREATE TABLE dw.DIM_LOC (
    LOC_SRK BIGINT PRIMARY KEY,
    SIG_UNF CHAR(2) NOT NULL UNIQUE,
    NOM_UNF VARCHAR(50) NOT NULL,
    NOM_REG VARCHAR(20) NOT NULL,
    COD_IBG INTEGER,
    NOM_CAP VARCHAR(50)
);

-- Registro UNKNOWN
INSERT INTO dw.DIM_LOC (LOC_SRK, SIG_UNF, NOM_UNF, NOM_REG, COD_IBG, NOM_CAP)
VALUES (-1, 'XX', 'UNKNOWN', 'UNKNOWN', -1, 'UNKNOWN');

-- DIMENSAO 3: DIM_PAC (Paciente)
CREATE TABLE dw.DIM_PAC (
    PAC_SRK BIGINT PRIMARY KEY,
    COD_DEM VARCHAR(50) NOT NULL UNIQUE,
    DES_FAI_ETA VARCHAR(30) NOT NULL,
    DES_SEX VARCHAR(20) NOT NULL,
    DES_RAC VARCHAR(30) NOT NULL,
    DES_FAI_ETA_DET VARCHAR(50) NOT NULL
);

-- Registro UNKNOWN
INSERT INTO dw.DIM_PAC (PAC_SRK, COD_DEM, DES_FAI_ETA, DES_SEX, DES_RAC, DES_FAI_ETA_DET)
VALUES (-1, 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN');

-- DIMENSAO 4: DIM_CLS (Classificacao)
CREATE TABLE dw.DIM_CLS (
    CLS_SRK BIGINT PRIMARY KEY,
    COD_CLS VARCHAR(10) NOT NULL UNIQUE,
    DES_CLS VARCHAR(50) NOT NULL,
    DES_GRP VARCHAR(30) NOT NULL,
    DES_GRA VARCHAR(20) NOT NULL,
    COD_CID VARCHAR(10),
    IND_CON INTEGER NOT NULL
);

-- Registro UNKNOWN
INSERT INTO dw.DIM_CLS (CLS_SRK, COD_CLS, DES_CLS, DES_GRP, DES_GRA, COD_CID, IND_CON)
VALUES (-1, 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 0);

-- DIMENSAO 5: DIM_EVL (Evolucao)
CREATE TABLE dw.DIM_EVL (
    EVL_SRK BIGINT PRIMARY KEY,
    COD_EVL VARCHAR(10) NOT NULL UNIQUE,
    DES_EVL VARCHAR(50) NOT NULL,
    TIP_EVL VARCHAR(30) NOT NULL,
    IND_OBI INTEGER NOT NULL,
    DES_GRA_DES VARCHAR(30) NOT NULL
);

-- Registro UNKNOWN
INSERT INTO dw.DIM_EVL (EVL_SRK, COD_EVL, DES_EVL, TIP_EVL, IND_OBI, DES_GRA_DES)
VALUES (-1, 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 0, 'UNKNOWN');

-- DIMENSAO 6: DIM_SNT (Sintomas)
CREATE TABLE dw.DIM_SNT (
    SNT_SRK BIGINT PRIMARY KEY,
    COD_SNT VARCHAR(20) NOT NULL UNIQUE,
    DES_FAI_SNT VARCHAR(20) NOT NULL,
    DES_FAI_ALR VARCHAR(20) NOT NULL,
    DES_PER_CLI VARCHAR(30) NOT NULL,
    IND_SNT INTEGER NOT NULL,
    IND_ALR INTEGER NOT NULL
);

-- Registro UNKNOWN
INSERT INTO dw.DIM_SNT (SNT_SRK, COD_SNT, DES_FAI_SNT, DES_FAI_ALR, DES_PER_CLI, IND_SNT, IND_ALR)
VALUES (-1, 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN', 0, 0);

-- =============================================
-- TABELA FATO
-- =============================================

CREATE TABLE dw.FAT_DEN (
    FAT_SRK BIGINT PRIMARY KEY,
    NUM_NOT BIGINT NOT NULL,

    -- Foreign Keys para Dimensoes
    TMP_SRK BIGINT NOT NULL,
    LOC_SRK BIGINT NOT NULL,
    PAC_SRK BIGINT NOT NULL,
    CLS_SRK BIGINT NOT NULL,
    EVL_SRK BIGINT NOT NULL,
    SNT_SRK BIGINT NOT NULL,

    -- Metricas Aditivas
    VAL_CON INTEGER NOT NULL,
    VAL_GRA INTEGER NOT NULL,
    VAL_OBI INTEGER NOT NULL,
    VAL_HOS INTEGER NOT NULL,
    QTD_SNT INTEGER NOT NULL,
    QTD_ALR INTEGER NOT NULL,

    -- Metricas Semi-aditivas
    VAL_IDA NUMERIC(5,2),

    -- Datas
    DAT_NOT DATE NOT NULL,
    DAT_SNT DATE,

    -- Constraints
    FOREIGN KEY (TMP_SRK) REFERENCES dw.DIM_TMP(TMP_SRK),
    FOREIGN KEY (LOC_SRK) REFERENCES dw.DIM_LOC(LOC_SRK),
    FOREIGN KEY (PAC_SRK) REFERENCES dw.DIM_PAC(PAC_SRK),
    FOREIGN KEY (CLS_SRK) REFERENCES dw.DIM_CLS(CLS_SRK),
    FOREIGN KEY (EVL_SRK) REFERENCES dw.DIM_EVL(EVL_SRK),
    FOREIGN KEY (SNT_SRK) REFERENCES dw.DIM_SNT(SNT_SRK)
);

-- =============================================
-- COMENTARIOS DIM_TMP (TEMPO)
-- =============================================

COMMENT ON COLUMN dw.DIM_TMP.TMP_SRK IS 'Chave Primaria Artificial (Surrogate Key) do Tempo';
COMMENT ON COLUMN dw.DIM_TMP.DAT_COM IS 'Data completa no formato YYYY-MM-DD';
COMMENT ON COLUMN dw.DIM_TMP.NUM_ANO IS 'Ano (2024, 2025, 2026)';
COMMENT ON COLUMN dw.DIM_TMP.NUM_MES IS 'Mes (1-12)';
COMMENT ON COLUMN dw.DIM_TMP.NUM_DIA IS 'Dia do mes (1-31)';
COMMENT ON COLUMN dw.DIM_TMP.NUM_TRI IS 'Trimestre (1-4)';
COMMENT ON COLUMN dw.DIM_TMP.NUM_SEM_EPI IS 'Semana epidemiologica (1-53)';
COMMENT ON COLUMN dw.DIM_TMP.NUM_DIA_SEM IS 'Dia da semana ISO (1=Segunda, 7=Domingo)';
COMMENT ON COLUMN dw.DIM_TMP.NOM_DIA IS 'Nome do dia da semana';
COMMENT ON COLUMN dw.DIM_TMP.IND_FDS IS 'Indicador de fim de semana (1=Sim, 0=Nao)';
COMMENT ON COLUMN dw.DIM_TMP.DES_MES_ANO IS 'Descricao Mes/Ano formato YYYY-MM';
COMMENT ON COLUMN dw.DIM_TMP.DES_ANO_TRI IS 'Descricao Ano/Trimestre formato YYYY-QN';

-- =============================================
-- COMENTARIOS DIM_LOC (LOCALIZACAO)
-- =============================================

COMMENT ON COLUMN dw.DIM_LOC.LOC_SRK IS 'Chave Primaria Artificial (Surrogate Key) da Localizacao';
COMMENT ON COLUMN dw.DIM_LOC.SIG_UNF IS 'Sigla da Unidade Federativa (SP, MG, RJ)';
COMMENT ON COLUMN dw.DIM_LOC.NOM_UNF IS 'Nome completo da Unidade Federativa';
COMMENT ON COLUMN dw.DIM_LOC.NOM_REG IS 'Nome da Regiao (Norte, Nordeste, Sul, Sudeste, Centro-Oeste)';
COMMENT ON COLUMN dw.DIM_LOC.COD_IBG IS 'Codigo IBGE da UF';
COMMENT ON COLUMN dw.DIM_LOC.NOM_CAP IS 'Nome da capital do estado';

-- =============================================
-- COMENTARIOS DIM_PAC (PACIENTE)
-- =============================================

COMMENT ON COLUMN dw.DIM_PAC.PAC_SRK IS 'Chave Primaria Artificial (Surrogate Key) do Paciente';
COMMENT ON COLUMN dw.DIM_PAC.COD_DEM IS 'Chave natural demografica (faixa+sexo+raca)';
COMMENT ON COLUMN dw.DIM_PAC.DES_FAI_ETA IS 'Descricao da faixa etaria';
COMMENT ON COLUMN dw.DIM_PAC.DES_SEX IS 'Descricao do sexo (Masculino, Feminino, Ignorado)';
COMMENT ON COLUMN dw.DIM_PAC.DES_RAC IS 'Descricao da raca/cor';
COMMENT ON COLUMN dw.DIM_PAC.DES_FAI_ETA_DET IS 'Descricao da faixa etaria detalhada';

-- =============================================
-- COMENTARIOS DIM_CLS (CLASSIFICACAO)
-- =============================================

COMMENT ON COLUMN dw.DIM_CLS.CLS_SRK IS 'Chave Primaria Artificial (Surrogate Key) da Classificacao';
COMMENT ON COLUMN dw.DIM_CLS.COD_CLS IS 'Codigo da classificacao epidemiologica';
COMMENT ON COLUMN dw.DIM_CLS.DES_CLS IS 'Descricao da classificacao (Dengue, Dengue Grave, etc.)';
COMMENT ON COLUMN dw.DIM_CLS.DES_GRP IS 'Grupo (Confirmado, Descartado, Em Investigacao)';
COMMENT ON COLUMN dw.DIM_CLS.DES_GRA IS 'Gravidade (Leve, Moderado, Grave)';
COMMENT ON COLUMN dw.DIM_CLS.COD_CID IS 'Codigo CID-10 (A90, A91.0)';
COMMENT ON COLUMN dw.DIM_CLS.IND_CON IS 'Indicador de caso confirmado (1=Sim, 0=Nao)';

-- =============================================
-- COMENTARIOS DIM_EVL (EVOLUCAO)
-- =============================================

COMMENT ON COLUMN dw.DIM_EVL.EVL_SRK IS 'Chave Primaria Artificial (Surrogate Key) da Evolucao';
COMMENT ON COLUMN dw.DIM_EVL.COD_EVL IS 'Codigo da evolucao clinica';
COMMENT ON COLUMN dw.DIM_EVL.DES_EVL IS 'Descricao da evolucao (Cura, Obito pelo agravo, etc.)';
COMMENT ON COLUMN dw.DIM_EVL.TIP_EVL IS 'Tipo de evolucao (Cura, Obito, Em investigacao)';
COMMENT ON COLUMN dw.DIM_EVL.IND_OBI IS 'Indicador de obito (1=Sim, 0=Nao)';
COMMENT ON COLUMN dw.DIM_EVL.DES_GRA_DES IS 'Gravidade do desfecho (Favoravel, Desfavoravel, Indeterminado)';

-- =============================================
-- COMENTARIOS DIM_SNT (SINTOMAS)
-- =============================================

COMMENT ON COLUMN dw.DIM_SNT.SNT_SRK IS 'Chave Primaria Artificial (Surrogate Key) dos Sintomas';
COMMENT ON COLUMN dw.DIM_SNT.COD_SNT IS 'Chave natural de sintomas (faixa_sint+faixa_alarm)';
COMMENT ON COLUMN dw.DIM_SNT.DES_FAI_SNT IS 'Faixa de quantidade de sintomas (0, 1-2, 3-5, 6+)';
COMMENT ON COLUMN dw.DIM_SNT.DES_FAI_ALR IS 'Faixa de quantidade de alarmes (0, 1, 2+, 3+)';
COMMENT ON COLUMN dw.DIM_SNT.DES_PER_CLI IS 'Perfil clinico (Assintomatico, Leve, Moderado, Grave)';
COMMENT ON COLUMN dw.DIM_SNT.IND_SNT IS 'Indicador de presenca de sintomas (1=Sim, 0=Nao)';
COMMENT ON COLUMN dw.DIM_SNT.IND_ALR IS 'Indicador de presenca de alarmes (1=Sim, 0=Nao)';

-- =============================================
-- COMENTARIOS FAT_DEN (FATO DENGUE)
-- =============================================

COMMENT ON COLUMN dw.FAT_DEN.FAT_SRK IS 'Chave Primaria Artificial (Surrogate Key) do Fato';
COMMENT ON COLUMN dw.FAT_DEN.NUM_NOT IS 'Numero da notificacao SINAN (Chave Natural)';
COMMENT ON COLUMN dw.FAT_DEN.TMP_SRK IS 'Chave Estrangeira para Dimensao Tempo';
COMMENT ON COLUMN dw.FAT_DEN.LOC_SRK IS 'Chave Estrangeira para Dimensao Localizacao';
COMMENT ON COLUMN dw.FAT_DEN.PAC_SRK IS 'Chave Estrangeira para Dimensao Paciente';
COMMENT ON COLUMN dw.FAT_DEN.CLS_SRK IS 'Chave Estrangeira para Dimensao Classificacao';
COMMENT ON COLUMN dw.FAT_DEN.EVL_SRK IS 'Chave Estrangeira para Dimensao Evolucao';
COMMENT ON COLUMN dw.FAT_DEN.SNT_SRK IS 'Chave Estrangeira para Dimensao Sintomas';
COMMENT ON COLUMN dw.FAT_DEN.VAL_CON IS 'Valor indicador de caso confirmado (0/1) - Metrica Aditiva';
COMMENT ON COLUMN dw.FAT_DEN.VAL_GRA IS 'Valor indicador de caso grave (0/1) - Metrica Aditiva';
COMMENT ON COLUMN dw.FAT_DEN.VAL_OBI IS 'Valor indicador de obito (0/1) - Metrica Aditiva';
COMMENT ON COLUMN dw.FAT_DEN.VAL_HOS IS 'Valor indicador de hospitalizacao (0/1) - Metrica Aditiva';
COMMENT ON COLUMN dw.FAT_DEN.QTD_SNT IS 'Quantidade de sintomas (0-9) - Metrica Aditiva';
COMMENT ON COLUMN dw.FAT_DEN.QTD_ALR IS 'Quantidade de alarmes (0-8) - Metrica Aditiva';
COMMENT ON COLUMN dw.FAT_DEN.VAL_IDA IS 'Idade em anos - Metrica SEMI-ADITIVA (media valida, soma nao)';
COMMENT ON COLUMN dw.FAT_DEN.DAT_NOT IS 'Data da notificacao';
COMMENT ON COLUMN dw.FAT_DEN.DAT_SNT IS 'Data dos primeiros sintomas';
