-- silver.dengue_silver definition

-- Drop table

-- DROP TABLE silver.dengue_silver;

CREATE TABLE silver.dengue_silver (
	id_notificacao serial4 NOT NULL,
	uf_sigla text NOT NULL,
	data_notificacao date NULL,
	data_sintomas date NULL,
	data_obito date NULL,
	ano_notificacao int4 NULL,
	mes_notificacao int4 NULL,
	semana_epi int4 NULL,
	dias_notificacao int4 NULL,
	idade_anos float4 NULL,
	faixa_etaria text NOT NULL,
	sexo_desc text NOT NULL,
	raca_desc text NOT NULL,
	escolaridade_desc text NOT NULL,
	gestante_desc text NOT NULL,
	qtd_sintomas int4 NOT NULL,
	qtd_alarmes int4 NOT NULL,
	fl_comorbidade int4 NOT NULL,
	resultado_sorologia_desc text NOT NULL,
	resultado_ns1_desc text NOT NULL,
	classificacao_desc text NOT NULL,
	criterio_desc text NOT NULL,
	evolucao_desc text NOT NULL,
	autoctone_desc text NOT NULL,
	fl_confirmado int4 NOT NULL,
	fl_grave int4 NOT NULL,
	fl_obito int4 NOT NULL,
	fl_hospitalizado int4 NOT NULL,
	CONSTRAINT dengue_silver_pkey PRIMARY KEY (id_notificacao)
);

CREATE INDEX idx_dengue_silver_ano ON silver.dengue_silver USING btree (ano_notificacao);
CREATE INDEX idx_dengue_silver_classificacao ON silver.dengue_silver USING btree (classificacao_desc);
CREATE INDEX idx_dengue_silver_confirmado ON silver.dengue_silver USING btree (fl_confirmado);
CREATE INDEX idx_dengue_silver_data_notif ON silver.dengue_silver USING btree (data_notificacao);
CREATE INDEX idx_dengue_silver_data_sintomas ON silver.dengue_silver USING btree (data_sintomas);
CREATE INDEX idx_dengue_silver_semana ON silver.dengue_silver USING btree (semana_epi);
CREATE INDEX idx_dengue_silver_uf ON silver.dengue_silver USING btree (uf_sigla);

-- ============================================================
-- COMENTÁRIOS DAS COLUNAS
-- ============================================================

-- Identificação
COMMENT ON COLUMN silver.dengue_silver.id_notificacao IS 'Identificador único da notificação (chave primária serial)';

-- Localização
COMMENT ON COLUMN silver.dengue_silver.uf_sigla IS 'Sigla da UF de notificação (ex: SP, RJ, MG)';

-- Datas
COMMENT ON COLUMN silver.dengue_silver.data_notificacao IS 'Data da notificação do caso';
COMMENT ON COLUMN silver.dengue_silver.data_sintomas IS 'Data dos primeiros sintomas';
COMMENT ON COLUMN silver.dengue_silver.data_obito IS 'Data do óbito (se aplicável)';

-- Campos Temporais Derivados
COMMENT ON COLUMN silver.dengue_silver.ano_notificacao IS 'Ano extraído da data de notificação';
COMMENT ON COLUMN silver.dengue_silver.mes_notificacao IS 'Mês extraído da data de notificação (1-12)';
COMMENT ON COLUMN silver.dengue_silver.semana_epi IS 'Semana epidemiológica calculada (1-53)';
COMMENT ON COLUMN silver.dengue_silver.dias_notificacao IS 'Intervalo em dias entre data de sintomas e notificação';

-- Dados do Paciente
COMMENT ON COLUMN silver.dengue_silver.idade_anos IS 'Idade do paciente em anos (calculada a partir do código SINAN)';
COMMENT ON COLUMN silver.dengue_silver.faixa_etaria IS 'Faixa etária categorizada (< 1 ano, 1-4, 5-9, 10-19, 20-39, 40-59, 60+)';
COMMENT ON COLUMN silver.dengue_silver.sexo_desc IS 'Sexo do paciente (Masculino/Feminino/Ignorado)';
COMMENT ON COLUMN silver.dengue_silver.raca_desc IS 'Raça/cor do paciente (Branca/Preta/Amarela/Parda/Indígena/Ignorado)';
COMMENT ON COLUMN silver.dengue_silver.escolaridade_desc IS 'Nível de escolaridade do paciente';
COMMENT ON COLUMN silver.dengue_silver.gestante_desc IS 'Situação gestacional (trimestre ou não gestante)';

-- Agregados Clínicos
COMMENT ON COLUMN silver.dengue_silver.qtd_sintomas IS 'Quantidade total de sintomas presentes (0-9)';
COMMENT ON COLUMN silver.dengue_silver.qtd_alarmes IS 'Quantidade total de sinais de alarme presentes (0-8)';
COMMENT ON COLUMN silver.dengue_silver.fl_comorbidade IS 'Flag de presença de comorbidade (0=Não, 1=Sim)';

-- Exames Laboratoriais
COMMENT ON COLUMN silver.dengue_silver.resultado_sorologia_desc IS 'Resultado da sorologia (Reagente/Não Reagente/Inconclusivo/Não Realizado/Ignorado)';
COMMENT ON COLUMN silver.dengue_silver.resultado_ns1_desc IS 'Resultado do teste NS1 (Positivo/Negativo/Inconclusivo/Não Realizado/Ignorado)';

-- Classificação e Evolução
COMMENT ON COLUMN silver.dengue_silver.classificacao_desc IS 'Classificação final (Dengue/Dengue com Sinais de Alarme/Dengue Grave/Descartado/Inconclusivo/Chikungunya)';
COMMENT ON COLUMN silver.dengue_silver.criterio_desc IS 'Critério de confirmação (Laboratorial/Clínico-epidemiológico/Em investigação)';
COMMENT ON COLUMN silver.dengue_silver.evolucao_desc IS 'Evolução do caso (Cura/Óbito pelo agravo/Óbito por outras causas/Ignorado)';
COMMENT ON COLUMN silver.dengue_silver.autoctone_desc IS 'Classificação de autoctonia (Autóctone/Importado/Indeterminado)';

-- Flags Derivados
COMMENT ON COLUMN silver.dengue_silver.fl_confirmado IS 'Flag de caso confirmado de Dengue (0=Não, 1=Sim) - CLASSI_FIN in (10, 11, 12)';
COMMENT ON COLUMN silver.dengue_silver.fl_grave IS 'Flag de caso grave (0=Não, 1=Sim) - CLASSI_FIN in (11, 12)';
COMMENT ON COLUMN silver.dengue_silver.fl_obito IS 'Flag de óbito pelo agravo (0=Não, 1=Sim) - EVOLUCAO = 2';
COMMENT ON COLUMN silver.dengue_silver.fl_hospitalizado IS 'Flag de hospitalização (0=Não, 1=Sim) - HOSPITALIZ = 1';

-- Comentário da Tabela
COMMENT ON TABLE silver.dengue_silver IS 'Tabela Silver (camada intermediária) com dados de notificações de Dengue do SINAN 2024-2025. Contém dados tratados, decodificados e enriquecidos com variáveis derivadas para análise epidemiológica.';
