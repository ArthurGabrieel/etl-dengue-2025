-- QUERY 1: TOP 5 UFs COM MELHOR E PIOR DESEMPENHO EM LETALIDADE

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
    FROM dw.FAT_DEN f
    JOIN dw.DIM_LOC l ON f.LOC_SRK = l.LOC_SRK
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


-- QUERY 2: ANALISE DE VULNERABILIDADE POR PERFIL DEMOGRAFICO

WITH PerfilPaciente AS (
    SELECT 
        p.DES_FAI_ETA_DET AS Faixa_Etaria,
        p.DES_SEX AS Sexo,
        p.DES_RAC AS Raca,
        f.VAL_IDA AS Idade,
        f.QTD_SNT AS Qtd_Sintomas,
        f.QTD_ALR AS Qtd_Alarmes,
        f.VAL_GRA AS Grave,
        f.VAL_OBI AS Obito,
        f.VAL_HOS AS Hospitalizado,
        f.VAL_CON
    FROM dw.FAT_DEN f
    JOIN dw.DIM_PAC p ON f.PAC_SRK = p.PAC_SRK
    WHERE f.VAL_CON = 1
),
AnaliseGrupos AS (
    SELECT 
        Faixa_Etaria,
        Sexo,
        Raca,
        COUNT(*) AS Total_Casos,
        SUM(Grave) AS Casos_Graves,
        SUM(Obito) AS Obitos,
        SUM(Hospitalizado) AS Hospitalizacoes,
        ROUND(AVG(Idade), 1) AS Idade_Media,
        ROUND(AVG(Qtd_Sintomas), 2) AS Media_Sintomas,
        ROUND(AVG(Qtd_Alarmes), 2) AS Media_Alarmes,
        -- Probabilidade de evolucao para caso grave
        ROUND((SUM(Grave)::NUMERIC / COUNT(*)) * 100, 2) AS Prob_Gravidade_Perc,
        -- Probabilidade de obito
        ROUND((SUM(Obito)::NUMERIC / COUNT(*)) * 100, 4) AS Prob_Obito_Perc,
        -- Probabilidade de hospitalizacao
        ROUND((SUM(Hospitalizado)::NUMERIC / COUNT(*)) * 100, 2) AS Prob_Hospitalizacao_Perc
    FROM PerfilPaciente
    GROUP BY Faixa_Etaria, Sexo, Raca
    HAVING COUNT(*) >= 100
),
RankingRisco AS (
    SELECT 
        *,
        -- Indice de Risco Composto (IRC): combina probabilidades ponderadas
        ROUND(
            (Prob_Obito_Perc * 100) +
            (Prob_Gravidade_Perc * 2) +
            (Prob_Hospitalizacao_Perc * 1) +
            (Media_Alarmes * 5), 2
        ) AS Indice_Risco_Composto,
        -- Razao de Risco comparada com media geral
        ROUND(
            Prob_Obito_Perc / NULLIF(
                (SELECT AVG(Prob_Obito_Perc) FROM AnaliseGrupos), 0
            ), 2
        ) AS Razao_Risco_Obito
    FROM AnaliseGrupos
)
SELECT 
    Faixa_Etaria,
    Sexo,
    Raca,
    Total_Casos,
    Casos_Graves,
    Obitos,
    Idade_Media,
    Media_Sintomas,
    Media_Alarmes,
    Prob_Gravidade_Perc,
    Prob_Obito_Perc,
    Prob_Hospitalizacao_Perc,
    Indice_Risco_Composto,
    Razao_Risco_Obito,
    CASE 
        WHEN Indice_Risco_Composto >= 100 THEN 'RISCO MUITO ALTO - Grupo Prioritario'
        WHEN Indice_Risco_Composto >= 50 THEN 'RISCO ALTO - Atencao Especial'
        WHEN Indice_Risco_Composto >= 25 THEN 'RISCO MODERADO - Monitoramento'
        ELSE 'RISCO BAIXO - Grupo Protegido'
    END AS Classificacao_Risco,
    CASE 
        WHEN Razao_Risco_Obito >= 2.0 THEN 'Risco 2x Maior que Media'
        WHEN Razao_Risco_Obito >= 1.5 THEN 'Risco 50% Maior que Media'
        WHEN Razao_Risco_Obito <= 0.5 THEN 'Fator Protetor - 50% Menor'
        ELSE 'Similar a Media'
    END AS Comparacao_Risco
FROM RankingRisco
ORDER BY Indice_Risco_Composto DESC;


-- QUERY 3: SAZONALIDADE E TENDENCIA TEMPORAL POR REGIAO

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
    FROM dw.FAT_DEN f
    JOIN dw.DIM_TMP t ON f.TMP_SRK = t.TMP_SRK
    JOIN dw.DIM_LOC l ON f.LOC_SRK = l.LOC_SRK
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


-- QUERY 4: ANALISE DE PERFIL CLINICO E PROGRESSAO DA DOENCA

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
    FROM dw.FAT_DEN f
    JOIN dw.DIM_SNT s ON f.SNT_SRK = s.SNT_SRK
    JOIN dw.DIM_CLS c ON f.CLS_SRK = c.CLS_SRK
    JOIN dw.DIM_EVL e ON f.EVL_SRK = e.EVL_SRK
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
ORDER BY Score_Risco_Clinico DESC;


-- QUERY 5: RANKING UFs COM MAIOR E MENOR VARIABILIDADE (DESVIO PADRAO)

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
    FROM dw.FAT_DEN f
    JOIN dw.DIM_LOC l ON f.LOC_SRK = l.LOC_SRK
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


-- QUERY 6: RESUMO GERAL PARA DASHBOARD

SELECT 
    'Total de Notificacoes',
    TO_CHAR(COUNT(*), 'FM999,999,999'),
    'Volume total de registros no DW'
FROM dw.FAT_DEN
UNION ALL
SELECT 
    'Casos Confirmados',
    TO_CHAR(SUM(VAL_CON), 'FM999,999,999'),
    'Casos com VAL_CON = 1'
FROM dw.FAT_DEN
UNION ALL
SELECT 
    'Taxa de Confirmacao (%)',
    TO_CHAR(ROUND((SUM(VAL_CON)::NUMERIC / COUNT(*)) * 100, 2), 'FM990.00') || '%',
    'Confirmados / Total'
FROM dw.FAT_DEN
UNION ALL
SELECT 
    'Casos Graves',
    TO_CHAR(SUM(VAL_GRA), 'FM999,999,999'),
    'Casos com VAL_GRA = 1'
FROM dw.FAT_DEN
UNION ALL
SELECT 
    'Taxa de Gravidade (%)',
    TO_CHAR(ROUND((SUM(VAL_GRA)::NUMERIC / NULLIF(SUM(VAL_CON), 0)) * 100, 2), 'FM990.00') || '%',
    'Graves / Confirmados'
FROM dw.FAT_DEN
UNION ALL
SELECT 
    'Total de Obitos',
    TO_CHAR(SUM(VAL_OBI), 'FM999,999,999'),
    'Casos com VAL_OBI = 1'
FROM dw.FAT_DEN
UNION ALL
SELECT 
    'Taxa de Letalidade (por 100k)',
    TO_CHAR(ROUND((SUM(VAL_OBI)::NUMERIC / NULLIF(SUM(VAL_CON), 0)) * 100000, 2), 'FM9,990.00'),
    'Obitos por 100k confirmados'
FROM dw.FAT_DEN
UNION ALL
SELECT 
    'Hospitalizacoes',
    TO_CHAR(SUM(VAL_HOS), 'FM999,999,999'),
    'Casos com VAL_HOS = 1'
FROM dw.FAT_DEN
UNION ALL
SELECT 
    'Taxa de Hospitalizacao (%)',
    TO_CHAR(ROUND((SUM(VAL_HOS)::NUMERIC / NULLIF(SUM(VAL_CON), 0)) * 100, 2), 'FM990.00') || '%',
    'Hospitalizados / Confirmados'
FROM dw.FAT_DEN;


-- QUERY 7 : ANALISE EPIDEMIOLOGICA TRIMESTRAL POR REGIAO

WITH CasosTrimestre AS (
    SELECT 
        t.NUM_ANO AS Ano,
        t.NUM_TRI AS Trimestre,
        t.DES_ANO_TRI AS Periodo,
        l.NOM_REG AS Regiao,
        SUM(f.VAL_CON) AS Confirmados,
        SUM(f.VAL_GRA) AS Graves,
        SUM(f.VAL_OBI) AS Obitos,
        SUM(f.VAL_HOS) AS Hospitalizados,
        ROUND(AVG(f.QTD_SNT), 2) AS Media_Sintomas,
        ROUND(AVG(f.QTD_ALR), 2) AS Media_Alarmes
    FROM gold.FAT_DEN f
    JOIN gold.DIM_TMP t ON f.TMP_SRK = t.TMP_SRK
    JOIN gold.DIM_LOC l ON f.LOC_SRK = l.LOC_SRK
    WHERE f.VAL_CON = 1
    GROUP BY t.NUM_ANO, t.NUM_TRI, t.DES_ANO_TRI, l.NOM_REG
),
ComVariacao AS (
    SELECT 
        *,
        -- Casos do trimestre anterior (mesma região)
        LAG(Confirmados) OVER (PARTITION BY Regiao ORDER BY Ano, Trimestre) AS Confirmados_Tri_Anterior,
        -- Variação percentual trimestral
        ROUND(
            ((Confirmados - LAG(Confirmados) OVER (PARTITION BY Regiao ORDER BY Ano, Trimestre))::NUMERIC 
            / NULLIF(LAG(Confirmados) OVER (PARTITION BY Regiao ORDER BY Ano, Trimestre), 0)) * 100, 2
        ) AS Variacao_Trimestral_Perc,
        -- Ranking de casos por trimestre
        RANK() OVER (PARTITION BY Ano, Trimestre ORDER BY Confirmados DESC) AS Ranking_Regiao
    FROM CasosTrimestre
),
TotalTrimestre AS (
    SELECT Ano, Trimestre, SUM(Confirmados) AS Total_Brasil
    FROM CasosTrimestre
    GROUP BY Ano, Trimestre
)
SELECT 
    c.Periodo,
    c.Ano,
    c.Trimestre,
    c.Regiao,
    c.Confirmados,
    c.Graves,
    c.Obitos,
    c.Hospitalizados,
    c.Media_Sintomas,
    c.Media_Alarmes,
    c.Ranking_Regiao,
    -- Percentual do Brasil
    ROUND((c.Confirmados::NUMERIC / tt.Total_Brasil) * 100, 2) AS Perc_Brasil,
    -- Taxas
    ROUND((c.Graves::NUMERIC / c.Confirmados) * 100, 2) AS Taxa_Gravidade_Perc,
    ROUND((c.Obitos::NUMERIC / c.Confirmados) * 100000, 2) AS Taxa_Letalidade_100k,
    -- Variação
    c.Confirmados_Tri_Anterior,
    c.Variacao_Trimestral_Perc,
    -- Tendência
    CASE 
        WHEN c.Variacao_Trimestral_Perc IS NULL THEN 'Primeiro Período'
        WHEN c.Variacao_Trimestral_Perc > 100 THEN 'CRÍTICO - Explosão de Casos (+100%)'
        WHEN c.Variacao_Trimestral_Perc > 50 THEN 'ALERTA - Crescimento Acelerado (+50%)'
        WHEN c.Variacao_Trimestral_Perc > 0 THEN 'Crescimento Moderado'
        WHEN c.Variacao_Trimestral_Perc BETWEEN -30 AND 0 THEN 'Estabilização/Leve Queda'
        ELSE 'Queda Significativa'
    END AS Tendencia_Epidemiologica
FROM ComVariacao c
JOIN TotalTrimestre tt ON c.Ano = tt.Ano AND c.Trimestre = tt.Trimestre
ORDER BY c.Ano, c.Trimestre, c.Ranking_Regiao;


-- QUERY 8: ANALISE DE EFETIVIDADE DO SISTEMA DE SAUDE POR REGIAO

WITH IndicadoresRegionais AS (
    SELECT 
        l.NOM_REG AS Regiao,
        l.SIG_UNF AS UF,
        COUNT(*) AS Total_Notificacoes,
        SUM(f.VAL_CON) AS Confirmados,
        SUM(f.VAL_GRA) AS Graves,
        SUM(f.VAL_OBI) AS Obitos,
        SUM(f.VAL_HOS) AS Hospitalizados,
        -- Casos graves que receberam hospitalizacao
        SUM(CASE WHEN f.VAL_GRA = 1 AND f.VAL_HOS = 1 THEN 1 ELSE 0 END) AS Graves_Hospitalizados,
        -- Casos graves que nao foram hospitalizados (falha do sistema?)
        SUM(CASE WHEN f.VAL_GRA = 1 AND f.VAL_HOS = 0 THEN 1 ELSE 0 END) AS Graves_Nao_Hospitalizados,
        -- Obitos que foram hospitalizados
        SUM(CASE WHEN f.VAL_OBI = 1 AND f.VAL_HOS = 1 THEN 1 ELSE 0 END) AS Obitos_Com_Hospitalizacao,
        -- Obitos sem hospitalizacao (morte antes de chegar ao hospital)
        SUM(CASE WHEN f.VAL_OBI = 1 AND f.VAL_HOS = 0 THEN 1 ELSE 0 END) AS Obitos_Sem_Hospitalizacao,
        ROUND(AVG(f.QTD_ALR), 2) AS Media_Sinais_Alarme
    FROM dw.FAT_DEN f
    JOIN dw.DIM_LOC l ON f.LOC_SRK = l.LOC_SRK
    WHERE f.VAL_CON = 1
    GROUP BY l.NOM_REG, l.SIG_UNF
),
MetricasEfetividade AS (
    SELECT 
        Regiao,
        UF,
        Confirmados,
        Graves,
        Obitos,
        Hospitalizados,
        Graves_Hospitalizados,
        Graves_Nao_Hospitalizados,
        Obitos_Com_Hospitalizacao,
        Obitos_Sem_Hospitalizacao,
        Media_Sinais_Alarme,
        -- Taxa de cobertura hospitalar para casos graves
        ROUND(
            (Graves_Hospitalizados::NUMERIC / NULLIF(Graves, 0)) * 100, 2
        ) AS Taxa_Cobertura_Hospitalar_Perc,
        -- Percentual de obitos que chegaram ao hospital
        ROUND(
            (Obitos_Com_Hospitalizacao::NUMERIC / NULLIF(Obitos, 0)) * 100, 2
        ) AS Perc_Obitos_Hospitalizados,
        -- Taxa de letalidade hospitalar (obitos entre hospitalizados)
        ROUND(
            (Obitos_Com_Hospitalizacao::NUMERIC / NULLIF(Hospitalizados, 0)) * 100, 2
        ) AS Taxa_Letalidade_Hospitalar_Perc,
        -- Taxa de letalidade geral
        ROUND(
            (Obitos::NUMERIC / NULLIF(Confirmados, 0)) * 100, 4
        ) AS Taxa_Letalidade_Geral_Perc
    FROM IndicadoresRegionais
)
SELECT 
    Regiao,
    UF,
    Confirmados,
    Graves,
    Obitos,
    Hospitalizados,
    Taxa_Cobertura_Hospitalar_Perc,
    Perc_Obitos_Hospitalizados,
    Taxa_Letalidade_Hospitalar_Perc,
    Taxa_Letalidade_Geral_Perc,
    Media_Sinais_Alarme,
    -- Score de Efetividade do Sistema (0-100, maior = melhor)
    ROUND(
        (Taxa_Cobertura_Hospitalar_Perc * 0.4) +
        (Perc_Obitos_Hospitalizados * 0.3) +
        ((100 - Taxa_Letalidade_Hospitalar_Perc) * 0.3), 2
    ) AS Score_Efetividade_Sistema,
    CASE 
        WHEN Taxa_Cobertura_Hospitalar_Perc >= 90 AND Taxa_Letalidade_Hospitalar_Perc < 5 
            THEN 'EXCELENTE - Sistema Eficiente'
        WHEN Taxa_Cobertura_Hospitalar_Perc >= 75 AND Taxa_Letalidade_Hospitalar_Perc < 10 
            THEN 'BOM - Atendimento Adequado'
        WHEN Taxa_Cobertura_Hospitalar_Perc >= 60 OR Taxa_Letalidade_Hospitalar_Perc < 15 
            THEN 'REGULAR - Necessita Melhorias'
        ELSE 'CRITICO - Sistema Sobrecarregado'
    END AS Avaliacao_Sistema
FROM MetricasEfetividade
WHERE Confirmados >= 1000
ORDER BY Score_Efetividade_Sistema DESC;

-- QUERY 9: CORRELACAO ESCOLARIDADE x DESFECHO CLINICO (Analise Detalhada)

WITH DadosEscolaridade AS (
    SELECT 
        p.DES_ESC AS Escolaridade,
        CASE 
            WHEN p.DES_ESC IN ('Analfabeto', '1-4 serie incompleta', '4 serie completa', '5-8 serie incompleta') 
                THEN 'Fundamental Incompleto ou Menos'
            WHEN p.DES_ESC IN ('Fundamental completo', 'Medio incompleto', 'Medio completo') 
                THEN 'Fundamental Completo a Medio'
            WHEN p.DES_ESC IN ('Superior incompleto', 'Superior completo') 
                THEN 'Superior (Parcial ou Completo)'
            ELSE 'Nao Informado/NA'
        END AS Grupo_Escolaridade,
        CASE 
            WHEN p.DES_ESC = 'Analfabeto' THEN 1
            WHEN p.DES_ESC = '1-4 serie incompleta' THEN 2
            WHEN p.DES_ESC = '4 serie completa' THEN 3
            WHEN p.DES_ESC = '5-8 serie incompleta' THEN 4
            WHEN p.DES_ESC = 'Fundamental completo' THEN 5
            WHEN p.DES_ESC = 'Medio incompleto' THEN 6
            WHEN p.DES_ESC = 'Medio completo' THEN 7
            WHEN p.DES_ESC = 'Superior incompleto' THEN 8
            WHEN p.DES_ESC = 'Superior completo' THEN 9
            ELSE 0
        END AS Ordem_Escolaridade,
        f.VAL_CON,
        f.VAL_GRA,
        f.VAL_OBI,
        f.VAL_HOS,
        f.QTD_SNT,
        f.QTD_ALR,
        f.VAL_IDA
    FROM dw.FAT_DEN f
    JOIN dw.DIM_PAC p ON f.PAC_SRK = p.PAC_SRK
    WHERE f.VAL_CON = 1
      AND p.DES_ESC NOT IN ('Ignorado', 'Nao se aplica', 'Nao informado')
),
EstatisticasPorEscolaridade AS (
    SELECT 
        Escolaridade,
        Grupo_Escolaridade,
        Ordem_Escolaridade,
        COUNT(*) AS Total_Casos,
        SUM(VAL_GRA) AS Casos_Graves,
        SUM(VAL_OBI) AS Obitos,
        SUM(VAL_HOS) AS Hospitalizacoes,
        ROUND(AVG(QTD_SNT), 2) AS Media_Sintomas,
        ROUND(AVG(QTD_ALR), 2) AS Media_Alarmes,
        ROUND(AVG(VAL_IDA), 1) AS Idade_Media,
        -- Taxas
        ROUND((SUM(VAL_GRA)::NUMERIC / COUNT(*)) * 100, 2) AS Taxa_Gravidade_Perc,
        ROUND((SUM(VAL_OBI)::NUMERIC / COUNT(*)) * 100000, 2) AS Taxa_Letalidade_100k,
        ROUND((SUM(VAL_HOS)::NUMERIC / COUNT(*)) * 100, 2) AS Taxa_Hospitalizacao_Perc
    FROM DadosEscolaridade
    GROUP BY Escolaridade, Grupo_Escolaridade, Ordem_Escolaridade
),
ComparativoGrupos AS (
    SELECT 
        Grupo_Escolaridade,
        SUM(Total_Casos) AS Total_Casos_Grupo,
        SUM(Casos_Graves) AS Graves_Grupo,
        SUM(Obitos) AS Obitos_Grupo,
        SUM(Hospitalizacoes) AS Hosp_Grupo,
        ROUND(AVG(Media_Alarmes), 2) AS Media_Alarmes_Grupo,
        ROUND((SUM(Casos_Graves)::NUMERIC / SUM(Total_Casos)) * 100, 2) AS Taxa_Gravidade_Grupo,
        ROUND((SUM(Obitos)::NUMERIC / SUM(Total_Casos)) * 100000, 2) AS Taxa_Letalidade_Grupo
    FROM EstatisticasPorEscolaridade
    WHERE Grupo_Escolaridade != 'Nao Informado/NA'
    GROUP BY Grupo_Escolaridade
)
SELECT 
    e.Escolaridade,
    e.Grupo_Escolaridade,
    e.Total_Casos,
    e.Casos_Graves,
    e.Obitos,
    e.Hospitalizacoes,
    e.Media_Sintomas,
    e.Media_Alarmes,
    e.Idade_Media,
    e.Taxa_Gravidade_Perc,
    e.Taxa_Letalidade_100k,
    e.Taxa_Hospitalizacao_Perc,
    -- Percentual do total
    ROUND((e.Total_Casos::NUMERIC / SUM(e.Total_Casos) OVER()) * 100, 2) AS Perc_Total_Casos,
    -- Comparacao com grupo Superior (referencia)
    ROUND(
        e.Taxa_Letalidade_100k / NULLIF(
            (SELECT Taxa_Letalidade_Grupo FROM ComparativoGrupos WHERE Grupo_Escolaridade = 'Superior (Parcial ou Completo)'), 0
        ), 2
    ) AS Razao_Letalidade_vs_Superior,
    -- Classificacao de risco
    CASE 
        WHEN e.Taxa_Letalidade_100k > 100 AND e.Media_Alarmes > 0.5 
            THEN 'ALTO RISCO - Intervencao Prioritaria'
        WHEN e.Taxa_Gravidade_Perc > 5 
            THEN 'RISCO MODERADO - Atencao Especial'
        ELSE 'RISCO PADRAO'
    END AS Classificacao_Risco,
    -- Insight sobre determinantes sociais
    CASE 
        WHEN e.Ordem_Escolaridade <= 4 AND e.Taxa_Letalidade_100k > 50 
            THEN 'DETERMINANTE SOCIAL: Baixa escolaridade associada a pior desfecho'
        WHEN e.Ordem_Escolaridade <= 4 
            THEN 'GRUPO VULNERAVEL: Requer atencao em politicas publicas'
        ELSE 'GRUPO COM MAIOR ACESSO A INFORMACAO/SAUDE'
    END AS Insight_Determinante_Social
FROM EstatisticasPorEscolaridade e
WHERE e.Grupo_Escolaridade != 'Nao Informado/NA'
ORDER BY e.Ordem_Escolaridade;


-- QUERY 10: ANALISE DE TEMPO ENTRE SINTOMAS E NOTIFICACAO
WITH TempoNotificacao AS (
    SELECT 
        f.FAT_SRK,
        f.VAL_CON,
        f.VAL_GRA,
        f.VAL_OBI,
        f.VAL_HOS,
        f.DAT_NOT,
        f.DAT_SNT,
        CASE 
            WHEN f.DAT_SNT IS NULL THEN 'Sem data sintomas'
            WHEN f.DAT_NOT - f.DAT_SNT < 0 THEN 'Inconsistente (erro)'
            WHEN f.DAT_NOT - f.DAT_SNT = 0 THEN '0 - Mesmo dia'
            WHEN f.DAT_NOT - f.DAT_SNT BETWEEN 1 AND 3 THEN '1 - Até 3 dias'
            WHEN f.DAT_NOT - f.DAT_SNT BETWEEN 4 AND 7 THEN '2 - 4 a 7 dias'
            WHEN f.DAT_NOT - f.DAT_SNT BETWEEN 8 AND 14 THEN '3 - 8 a 14 dias'
            ELSE '4 - Mais de 14 dias'
        END AS Faixa_Tempo_Notificacao,
        CASE 
            WHEN f.DAT_SNT IS NULL THEN NULL
            ELSE f.DAT_NOT - f.DAT_SNT 
        END AS Dias_Ate_Notificacao
    FROM dw.FAT_DEN f
),
EstatisticasTempo AS (
    SELECT 
        Faixa_Tempo_Notificacao,
        COUNT(*) AS Total_Casos,
        SUM(VAL_CON) AS Confirmados,
        SUM(VAL_GRA) AS Graves,
        SUM(VAL_OBI) AS Obitos,
        SUM(VAL_HOS) AS Hospitalizados,
        ROUND(AVG(Dias_Ate_Notificacao), 1) AS Media_Dias
    FROM TempoNotificacao
    WHERE Faixa_Tempo_Notificacao != 'Inconsistente (erro)'
    GROUP BY Faixa_Tempo_Notificacao
)
SELECT 
    Faixa_Tempo_Notificacao,
    Total_Casos,
    Confirmados,
    Graves,
    Obitos,
    Hospitalizados,
    Media_Dias,
    ROUND((Total_Casos::NUMERIC / SUM(Total_Casos) OVER()) * 100, 2) AS Perc_do_Total,
    ROUND((Graves::NUMERIC / NULLIF(Confirmados, 0)) * 100, 2) AS Taxa_Gravidade_Perc,
    ROUND((Obitos::NUMERIC / NULLIF(Confirmados, 0)) * 100000, 2) AS Taxa_Letalidade_100k,
    -- Insight: notificações tardias tendem a ter casos mais graves?
    CASE 
        WHEN Faixa_Tempo_Notificacao IN ('3 - 8 a 14 dias', '4 - Mais de 14 dias') 
        THEN 'ALERTA: Notificação Tardia'
        WHEN Faixa_Tempo_Notificacao = '0 - Mesmo dia' 
        THEN 'EXCELENTE: Vigilância Ágil'
        ELSE 'ADEQUADO'
    END AS Avaliacao_Vigilancia
FROM EstatisticasTempo
ORDER BY Faixa_Tempo_Notificacao;
