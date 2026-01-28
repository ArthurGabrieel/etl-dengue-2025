-- ============================================================================
-- QUERIES ANALITICAS - DATA WAREHOUSE DENGUE 2025
-- ============================================================================
-- Autor: ETL Dengue 2025
-- Schema: gold
-- Descricao: Conjunto de 5 queries complexas para analise epidemiologica
-- Nomenclatura: Padrao corporativo 3 letras UPPERCASE (ver MNEMONICOS.md)
-- ============================================================================


-- ============================================================================
-- QUERY 1: TOP 5 UFs COM MELHOR E PIOR DESEMPENHO EM LETALIDADE
-- ============================================================================
-- Objetivo: Identificar os estados com menor e maior taxa de letalidade
-- entre os casos confirmados, considerando apenas UFs com volume significativo
-- de casos (minimo 1000 confirmados) para evitar distorcoes estatisticas.
-- ============================================================================

WITH LetalidadeUF AS (
    SELECT 
        l.SIG_UNF AS Sigla_UF,
        l.NOM_UNF AS Nome_UF,
        l.NOM_REG AS Regiao,
        SUM(f.VAL_CON) AS Casos_Confirmados,
        SUM(f.VAL_OBI) AS Obitos,
        SUM(f.VAL_GRA) AS Casos_Graves,
        ROUND(
            CASE WHEN SUM(f.VAL_CON) > 0 
                THEN (SUM(f.VAL_OBI)::NUMERIC / SUM(f.VAL_CON)) * 100000 
                ELSE 0 
            END, 2
        ) AS Taxa_Letalidade_100k,
        ROUND(
            CASE WHEN SUM(f.VAL_CON) > 0 
                THEN (SUM(f.VAL_GRA)::NUMERIC / SUM(f.VAL_CON)) * 100 
                ELSE 0 
            END, 2
        ) AS Percentual_Gravidade
    FROM gold.FAT_DEN f
    JOIN gold.DIM_LOC l ON f.LOC_SRK = l.LOC_SRK
    WHERE f.VAL_CON = 1
    GROUP BY l.SIG_UNF, l.NOM_UNF, l.NOM_REG
    HAVING SUM(f.VAL_CON) >= 1000  -- Filtro para significancia estatistica
),
Top5_Menor_Letalidade AS (
    SELECT 
        'Menor Letalidade (Melhor Desempenho)' AS Categoria,
        Sigla_UF, Nome_UF, Regiao,
        Casos_Confirmados, Obitos, Casos_Graves,
        Taxa_Letalidade_100k, Percentual_Gravidade
    FROM LetalidadeUF
    ORDER BY Taxa_Letalidade_100k ASC
    LIMIT 5
),
Top5_Maior_Letalidade AS (
    SELECT 
        'Maior Letalidade (Pior Desempenho)' AS Categoria,
        Sigla_UF, Nome_UF, Regiao,
        Casos_Confirmados, Obitos, Casos_Graves,
        Taxa_Letalidade_100k, Percentual_Gravidade
    FROM LetalidadeUF
    ORDER BY Taxa_Letalidade_100k DESC
    LIMIT 5
)
SELECT * FROM Top5_Menor_Letalidade
UNION ALL
SELECT * FROM Top5_Maior_Letalidade
ORDER BY Taxa_Letalidade_100k ASC;


-- ============================================================================
-- QUERY 2: ANALISE DE VULNERABILIDADE POR PERFIL DEMOGRAFICO
-- ============================================================================
-- Objetivo: Cruzar faixa etaria, sexo e raca para identificar perfis 
-- demograficos mais vulneraveis (maior taxa de gravidade e letalidade).
-- Essencial para direcionar politicas publicas de prevencao.
-- ============================================================================

WITH PerfilDemografico AS (
    SELECT 
        p.DES_FAI_ETA_DET AS Faixa_Etaria,
        p.DES_SEX AS Sexo,
        p.DES_RAC AS Raca,
        COUNT(*) AS Total_Notificacoes,
        SUM(f.VAL_CON) AS Casos_Confirmados,
        SUM(f.VAL_GRA) AS Casos_Graves,
        SUM(f.VAL_OBI) AS Obitos,
        SUM(f.VAL_HOS) AS Hospitalizacoes,
        ROUND(AVG(f.VAL_IDA), 1) AS Idade_Media
    FROM gold.FAT_DEN f
    JOIN gold.DIM_PAC p ON f.PAC_SRK = p.PAC_SRK
    WHERE f.VAL_CON = 1
    GROUP BY p.DES_FAI_ETA_DET, p.DES_SEX, p.DES_RAC
    HAVING COUNT(*) >= 100  -- Minimo para relevancia estatistica
)
SELECT 
    Faixa_Etaria,
    Sexo,
    Raca,
    Casos_Confirmados,
    Casos_Graves,
    Obitos,
    Hospitalizacoes,
    Idade_Media,
    ROUND(
        (Casos_Graves::NUMERIC / NULLIF(Casos_Confirmados, 0)) * 100, 2
    ) AS Perc_Gravidade,
    ROUND(
        (Obitos::NUMERIC / NULLIF(Casos_Confirmados, 0)) * 100000, 2
    ) AS Taxa_Letalidade_100k,
    ROUND(
        (Hospitalizacoes::NUMERIC / NULLIF(Casos_Confirmados, 0)) * 100, 2
    ) AS Perc_Hospitalizacao,
    -- Indice de Vulnerabilidade Composto (IVC)
    ROUND(
        ((Casos_Graves::NUMERIC / NULLIF(Casos_Confirmados, 0)) * 50) +
        ((Obitos::NUMERIC / NULLIF(Casos_Confirmados, 0)) * 100000 * 0.3) +
        ((Hospitalizacoes::NUMERIC / NULLIF(Casos_Confirmados, 0)) * 20), 2
    ) AS Indice_Vulnerabilidade
FROM PerfilDemografico
ORDER BY Indice_Vulnerabilidade DESC
LIMIT 20;


-- ============================================================================
-- QUERY 3: SAZONALIDADE E TENDENCIA TEMPORAL POR REGIAO
-- ============================================================================
-- Objetivo: Analisar a distribuicao temporal dos casos por regiao,
-- identificando picos epidemicos, semanas epidemiologicas criticas
-- e comparando comportamento entre regioes do Brasil.
-- ============================================================================

WITH CasosPorSemana AS (
    SELECT 
        t.NUM_ANO AS Ano,
        t.NUM_MES AS Mes,
        t.NUM_SEM_EPI AS Semana_Epidemiologica,
        l.NOM_REG AS Regiao,
        SUM(f.VAL_CON) AS Casos_Confirmados,
        SUM(f.VAL_GRA) AS Casos_Graves,
        SUM(f.VAL_OBI) AS Obitos,
        AVG(f.QTD_SNT) AS Media_Sintomas,
        AVG(f.QTD_ALR) AS Media_Alarmes
    FROM gold.FAT_DEN f
    JOIN gold.DIM_TMP t ON f.TMP_SRK = t.TMP_SRK
    JOIN gold.DIM_LOC l ON f.LOC_SRK = l.LOC_SRK
    WHERE f.VAL_CON = 1
    GROUP BY t.NUM_ANO, t.NUM_MES, t.NUM_SEM_EPI, l.NOM_REG
),
MediaMovel AS (
    SELECT 
        Ano, Mes, Semana_Epidemiologica, Regiao,
        Casos_Confirmados, Casos_Graves, Obitos,
        ROUND(Media_Sintomas, 2) AS Media_Sintomas,
        ROUND(Media_Alarmes, 2) AS Media_Alarmes,
        -- Media movel de 4 semanas para suavizar tendencia
        ROUND(
            AVG(Casos_Confirmados) OVER (
                PARTITION BY Regiao 
                ORDER BY Ano, Semana_Epidemiologica 
                ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
            ), 0
        ) AS Media_Movel_4Sem,
        -- Variacao percentual semana a semana
        ROUND(
            ((Casos_Confirmados - LAG(Casos_Confirmados) OVER (
                PARTITION BY Regiao ORDER BY Ano, Semana_Epidemiologica
            ))::NUMERIC / NULLIF(LAG(Casos_Confirmados) OVER (
                PARTITION BY Regiao ORDER BY Ano, Semana_Epidemiologica
            ), 0)) * 100, 2
        ) AS Variacao_Semanal_Perc
    FROM CasosPorSemana
)
SELECT 
    Ano, Mes, Semana_Epidemiologica, Regiao,
    Casos_Confirmados, Casos_Graves, Obitos,
    Media_Sintomas, Media_Alarmes,
    Media_Movel_4Sem,
    Variacao_Semanal_Perc,
    CASE 
        WHEN Variacao_Semanal_Perc > 50 THEN 'ALERTA - Crescimento Acelerado'
        WHEN Variacao_Semanal_Perc > 20 THEN 'Atencao - Em Crescimento'
        WHEN Variacao_Semanal_Perc BETWEEN -20 AND 20 THEN 'Estavel'
        WHEN Variacao_Semanal_Perc < -20 THEN 'Em Declinio'
        ELSE 'Sem Dados Anteriores'
    END AS Situacao_Epidemiologica
FROM MediaMovel
WHERE Ano = 2025
ORDER BY Regiao, Ano, Semana_Epidemiologica;


-- ============================================================================
-- QUERY 4: ANALISE DE PERFIL CLINICO E PROGRESSAO DA DOENCA
-- ============================================================================
-- Objetivo: Correlacionar quantidade de sintomas e alarmes com desfecho 
-- clinico (cura, obito, hospitalizacao). Identificar padroes que podem 
-- prever evolucao para casos graves.
-- ============================================================================

WITH PerfilClinico AS (
    SELECT 
        s.DES_PER_CLI AS Perfil_Clinico,
        s.DES_FAI_SNT AS Faixa_Sintomas,
        s.DES_FAI_ALR AS Faixa_Alarmes,
        c.DES_CLS AS Classificacao,
        c.DES_GRA AS Gravidade_Classificacao,
        e.TIP_EVL AS Tipo_Evolucao,
        e.DES_GRA_DES AS Gravidade_Desfecho,
        COUNT(*) AS Total_Casos,
        SUM(f.VAL_CON) AS Confirmados,
        SUM(f.VAL_GRA) AS Graves,
        SUM(f.VAL_OBI) AS Obitos,
        SUM(f.VAL_HOS) AS Hospitalizados,
        ROUND(AVG(f.QTD_SNT), 2) AS Media_Sintomas,
        ROUND(AVG(f.QTD_ALR), 2) AS Media_Alarmes,
        ROUND(AVG(f.VAL_IDA), 1) AS Idade_Media
    FROM gold.FAT_DEN f
    JOIN gold.DIM_SNT s ON f.SNT_SRK = s.SNT_SRK
    JOIN gold.DIM_CLS c ON f.CLS_SRK = c.CLS_SRK
    JOIN gold.DIM_EVL e ON f.EVL_SRK = e.EVL_SRK
    WHERE f.VAL_CON = 1
    GROUP BY s.DES_PER_CLI, s.DES_FAI_SNT, s.DES_FAI_ALR, 
             c.DES_CLS, c.DES_GRA, e.TIP_EVL, e.DES_GRA_DES
)
SELECT 
    Perfil_Clinico,
    Faixa_Sintomas,
    Faixa_Alarmes,
    Classificacao,
    Tipo_Evolucao,
    Total_Casos,
    Confirmados,
    Graves,
    Obitos,
    Hospitalizados,
    Media_Sintomas,
    Media_Alarmes,
    Idade_Media,
    ROUND(
        (Graves::NUMERIC / NULLIF(Confirmados, 0)) * 100, 2
    ) AS Taxa_Gravidade_Perc,
    ROUND(
        (Obitos::NUMERIC / NULLIF(Confirmados, 0)) * 100, 4
    ) AS Taxa_Letalidade_Perc,
    ROUND(
        (Hospitalizados::NUMERIC / NULLIF(Confirmados, 0)) * 100, 2
    ) AS Taxa_Hospitalizacao_Perc,
    -- Score de Risco Clinico (quanto maior, mais grave o perfil)
    ROUND(
        (Media_Alarmes * 20) + 
        ((Graves::NUMERIC / NULLIF(Confirmados, 0)) * 100) +
        ((Obitos::NUMERIC / NULLIF(Confirmados, 0)) * 1000), 2
    ) AS Score_Risco_Clinico
FROM PerfilClinico
WHERE Confirmados >= 50  -- Minimo para relevancia
ORDER BY Score_Risco_Clinico DESC
LIMIT 30;


-- ============================================================================
-- QUERY 5: RANKING UFs COM MAIOR E MENOR VARIABILIDADE (DESVIO PADRAO)
-- ============================================================================
-- Objetivo: Identificar estados com maior heterogeneidade na distribuicao
-- de casos graves e letalidade. Alta variabilidade pode indicar 
-- desigualdade no acesso ao tratamento ou subnotificacao.
-- ============================================================================

WITH EstatisticasUF AS (
    SELECT 
        l.SIG_UNF AS Sigla_UF,
        l.NOM_UNF AS Nome_UF,
        l.NOM_REG AS Regiao,
        COUNT(*) AS Total_Casos,
        SUM(f.VAL_CON) AS Confirmados,
        SUM(f.VAL_GRA) AS Graves,
        SUM(f.VAL_OBI) AS Obitos,
        -- Media de sintomas e alarmes
        ROUND(AVG(f.QTD_SNT), 2) AS Media_Sintomas,
        ROUND(AVG(f.QTD_ALR), 2) AS Media_Alarmes,
        -- Desvio padrao para avaliar variabilidade
        ROUND(STDDEV(f.QTD_SNT), 2) AS Desvio_Padrao_Sintomas,
        ROUND(STDDEV(f.QTD_ALR), 2) AS Desvio_Padrao_Alarmes,
        ROUND(STDDEV(f.VAL_IDA), 2) AS Desvio_Padrao_Idade,
        -- Coeficiente de variacao (CV = DP/Media * 100)
        ROUND(
            CASE WHEN AVG(f.QTD_SNT) > 0 
                THEN (STDDEV(f.QTD_SNT) / AVG(f.QTD_SNT)) * 100 
                ELSE 0 
            END, 2
        ) AS CV_Sintomas
    FROM gold.FAT_DEN f
    JOIN gold.DIM_LOC l ON f.LOC_SRK = l.LOC_SRK
    WHERE f.VAL_CON = 1
    GROUP BY l.SIG_UNF, l.NOM_UNF, l.NOM_REG
    HAVING COUNT(*) >= 500  -- Minimo para calculo de desvio padrao confiavel
),
RankingVariabilidade AS (
    SELECT 
        *,
        -- Indice de Heterogeneidade (combina os desvios padrao)
        ROUND(
            (Desvio_Padrao_Sintomas * 10) + 
            (Desvio_Padrao_Alarmes * 15) + 
            (CV_Sintomas * 0.5), 2
        ) AS Indice_Heterogeneidade,
        -- Taxa de gravidade e letalidade para contexto
        ROUND((Graves::NUMERIC / NULLIF(Confirmados, 0)) * 100, 2) AS Taxa_Gravidade,
        ROUND((Obitos::NUMERIC / NULLIF(Confirmados, 0)) * 100000, 2) AS Taxa_Letalidade_100k
    FROM EstatisticasUF
),
Top5_Maior_Variabilidade AS (
    SELECT 
        'Maior Heterogeneidade (Mais Desigual)' AS Categoria,
        Sigla_UF, Nome_UF, Regiao, Confirmados,
        Media_Sintomas, Desvio_Padrao_Sintomas, CV_Sintomas,
        Media_Alarmes, Desvio_Padrao_Alarmes,
        Taxa_Gravidade, Taxa_Letalidade_100k,
        Indice_Heterogeneidade
    FROM RankingVariabilidade
    ORDER BY Indice_Heterogeneidade DESC
    LIMIT 5
),
Top5_Menor_Variabilidade AS (
    SELECT 
        'Menor Heterogeneidade (Mais Homogeneo)' AS Categoria,
        Sigla_UF, Nome_UF, Regiao, Confirmados,
        Media_Sintomas, Desvio_Padrao_Sintomas, CV_Sintomas,
        Media_Alarmes, Desvio_Padrao_Alarmes,
        Taxa_Gravidade, Taxa_Letalidade_100k,
        Indice_Heterogeneidade
    FROM RankingVariabilidade
    ORDER BY Indice_Heterogeneidade ASC
    LIMIT 5
)
SELECT * FROM Top5_Maior_Variabilidade
UNION ALL
SELECT * FROM Top5_Menor_Variabilidade
ORDER BY Indice_Heterogeneidade DESC;


-- ============================================================================
-- BONUS: RESUMO EXECUTIVO CONSOLIDADO
-- ============================================================================
-- Query adicional que gera um dashboard consolidado com os principais KPIs
-- ============================================================================

SELECT 
    '=== DASHBOARD EXECUTIVO DENGUE 2025 ===' AS Indicador,
    NULL AS Valor,
    NULL AS Observacao
UNION ALL
SELECT 
    'Total de Notificacoes',
    TO_CHAR(COUNT(*), 'FM999,999,999'),
    'Volume total de registros no DW'
FROM gold.FAT_DEN
UNION ALL
SELECT 
    'Casos Confirmados',
    TO_CHAR(SUM(VAL_CON), 'FM999,999,999'),
    'Casos com VAL_CON = 1'
FROM gold.FAT_DEN
UNION ALL
SELECT 
    'Taxa de Confirmacao (%)',
    TO_CHAR(ROUND((SUM(VAL_CON)::NUMERIC / COUNT(*)) * 100, 2), 'FM990.00') || '%',
    'Confirmados / Total'
FROM gold.FAT_DEN
UNION ALL
SELECT 
    'Casos Graves',
    TO_CHAR(SUM(VAL_GRA), 'FM999,999,999'),
    'Casos com VAL_GRA = 1'
FROM gold.FAT_DEN
UNION ALL
SELECT 
    'Taxa de Gravidade (%)',
    TO_CHAR(ROUND((SUM(VAL_GRA)::NUMERIC / NULLIF(SUM(VAL_CON), 0)) * 100, 2), 'FM990.00') || '%',
    'Graves / Confirmados'
FROM gold.FAT_DEN
UNION ALL
SELECT 
    'Total de Obitos',
    TO_CHAR(SUM(VAL_OBI), 'FM999,999,999'),
    'Casos com VAL_OBI = 1'
FROM gold.FAT_DEN
UNION ALL
SELECT 
    'Taxa de Letalidade (por 100k)',
    TO_CHAR(ROUND((SUM(VAL_OBI)::NUMERIC / NULLIF(SUM(VAL_CON), 0)) * 100000, 2), 'FM9,990.00'),
    'Obitos por 100k confirmados'
FROM gold.FAT_DEN
UNION ALL
SELECT 
    'Hospitalizacoes',
    TO_CHAR(SUM(VAL_HOS), 'FM999,999,999'),
    'Casos com VAL_HOS = 1'
FROM gold.FAT_DEN
UNION ALL
SELECT 
    'Taxa de Hospitalizacao (%)',
    TO_CHAR(ROUND((SUM(VAL_HOS)::NUMERIC / NULLIF(SUM(VAL_CON), 0)) * 100, 2), 'FM990.00') || '%',
    'Hospitalizados / Confirmados'
FROM gold.FAT_DEN;
