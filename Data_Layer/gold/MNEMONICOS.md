# Dicionário de Mnemônicos - Gold Layer

Este documento define todas as abreviações e convenções de nomenclatura utilizadas no Star Schema da camada Gold do projeto Dengue 2025.

---

## 1. Abreviações de Tabelas

| Abreviação | Significado | Tabela Completa |
|------------|-------------|-----------------|
| `deng` | **Deng**ue | `ft_deng` |
| `tmp` | **T**e**mp**o | `dim_tmp` |
| `loc` | **Loc**alização | `dim_loc` |
| `pac` | **Pac**iente | `dim_pac` |
| `cls` | **Cl**a**s**sificação | `dim_cls` |
| `evl` | **Ev**o**l**ução | `dim_evl` |
| `snt` | **S**i**nt**omas | `dim_snt` |

---

## 2. Prefixos de Tabelas

| Prefixo | Significado | Exemplo |
|---------|-------------|---------|
| `dim_` | **Dim**ensão (tabela dimensional) | `dim_tmp`, `dim_loc`, `dim_pac` |
| `ft_` | **F**ac**t** (tabela fato) | `ft_deng` |
| `vw_` | **V**ie**w** (visão) | `vw_resumo_uf`, `vw_evolucao_semanal` |
| `idx_` | **Idx** (índice) | `idx_ft_deng_fk_tmp` |

---

## 3. Prefixos e Sufixos de Chaves

| Prefixo/Sufixo | Significado | Uso |
|----------------|-------------|-----|
| `sk_` | **S**urrogate **K**ey - Chave primária artificial | Usado nas dimensões como PK |
| `fk_` | **F**oreign **K**ey - Chave estrangeira | Usado na fato como FK para dimensões |
| `nk_` | **N**atural **K**ey - Chave natural/negócio | Identificador original do sistema fonte |

**Exemplos:**
- `sk_tmp` - Chave primária surrogate da tabela `dim_tmp`
- `fk_tmp` - Chave estrangeira na `ft_deng` que referencia `dim_tmp(sk_tmp)`
- `nk_notif` - Chave natural (ID original da notificação SINAN)

---

## 4. Prefixos de Colunas

| Prefixo | Significado | Exemplo de Uso |
|---------|-------------|----------------|
| `vl_` | **V**a**l**or/Métrica numérica | `vl_caso_confirmado`, `vl_idade_anos` |
| `qtd_` | **Q**uan**t**i**d**ade | `qtd_sintomas`, `qtd_alarmes` |
| `fl_` | **Fl**ag booleano (0/1) | `fl_confirmado`, `fl_grave`, `fl_obito` |
| `flag_` | Flag booleano (TRUE/FALSE) | `flag_fim_semana`, `flag_tem_sintomas` |
| `ts_` | **T**ime**s**tamp/Data | `ts_notificacao`, `ts_carga` |
| `dt_` | **D**a**t**a (DATE) | `dt_sintomas`, `dt_notificacao` |
| `cd_` | **C**ó**d**igo | `cd_ibge`, `cd_cid` |
| `nm_` | **N**o**m**e | `nm_uf`, `nm_regiao` |
| `ds_` | **D**e**s**crição | `ds_classificacao`, `ds_evolucao` |
| `sg_` | **S**i**g**la | `sg_uf` |

---

## 5. Sufixos de Colunas

| Sufixo | Significado | Exemplo |
|--------|-------------|---------|
| `_desc` | Descrição textual | `sexo_desc`, `raca_desc` |
| `_codigo` | Código identificador | `classificacao_codigo` |
| `_faixa` | Faixa/Range de valores | `qtd_sintomas_faixa` |
| `_grupo` | Agrupamento/Categoria | `classificacao_grupo` |

---

## 6. Abreviações de Domínio (Epidemiologia)

| Abreviação | Significado | Contexto |
|------------|-------------|----------|
| `epi` | **Epi**demiológico | `semana_epi` (semana epidemiológica) |
| `uf` | **U**nidade **F**ederativa | Estados brasileiros |
| `cid` | **C**lassificação **I**nternacional de **D**oenças | Código CID-10 |
| `sinan` | Sistema de Informação de Agravos de Notificação | Sistema fonte dos dados |
| `ibge` | Instituto Brasileiro de Geografia e Estatística | Códigos geográficos |

---

## 7. Estrutura das Tabelas

### 7.1 Dimensão Tempo (`dim_tmp`)

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `sk_tmp` | SERIAL | Chave primária surrogate |
| `dt_completa` | DATE | Data completa (YYYY-MM-DD) |
| `nr_ano` | INTEGER | Ano (2024, 2025, 2026) |
| `nr_mes` | INTEGER | Mês (1-12) |
| `nr_dia` | INTEGER | Dia do mês (1-31) |
| `nr_trimestre` | INTEGER | Trimestre (1-4) |
| `nr_semana_epi` | INTEGER | Semana epidemiológica (1-53) |
| `nr_dia_semana` | INTEGER | Dia da semana ISO (1=Segunda, 7=Domingo) |
| `nm_dia` | TEXT | Nome do dia (Segunda, Terça, etc.) |
| `flag_fim_semana` | BOOLEAN | Indica se é sábado ou domingo |
| `ds_mes_ano` | TEXT | Mês/Ano no formato YYYY-MM |
| `ds_ano_trimestre` | TEXT | Ano/Trimestre no formato YYYY-QN |
| `ts_carga` | TIMESTAMP | Data/hora da carga ETL |

### 7.2 Dimensão Localização (`dim_loc`)

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `sk_loc` | SERIAL | Chave primária surrogate |
| `sg_uf` | TEXT | Sigla da UF (SP, MG, RJ, etc.) |
| `nm_uf` | TEXT | Nome completo da UF |
| `nm_regiao` | TEXT | Região (Norte, Nordeste, etc.) |
| `cd_ibge` | INTEGER | Código IBGE da UF |
| `nm_capital` | TEXT | Nome da capital |
| `ts_carga` | TIMESTAMP | Data/hora da carga ETL |

### 7.3 Dimensão Paciente (`dim_pac`)

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `sk_pac` | SERIAL | Chave primária surrogate |
| `nk_demografica` | TEXT | Business key (faixa+sexo+raça) |
| `ds_faixa_etaria` | TEXT | Faixa etária (< 1 ano, 1-4 anos, etc.) |
| `ds_sexo` | TEXT | Sexo (Masculino, Feminino, Ignorado) |
| `ds_raca` | TEXT | Raça/Cor (Branca, Preta, Parda, etc.) |
| `ds_faixa_etaria_det` | TEXT | Faixa etária detalhada |
| `ts_carga` | TIMESTAMP | Data/hora da carga ETL |

### 7.4 Dimensão Classificação (`dim_cls`)

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `sk_cls` | SERIAL | Chave primária surrogate |
| `cd_classificacao` | TEXT | Código da classificação (natural key) |
| `ds_classificacao` | TEXT | Descrição (Dengue, Dengue Grave, etc.) |
| `ds_grupo` | TEXT | Grupo (Confirmado, Descartado, Em Investigação) |
| `ds_gravidade` | TEXT | Gravidade (Leve, Moderado, Grave) |
| `cd_cid` | TEXT | Código CID-10 (A90, A91.0) |
| `flag_confirmado` | BOOLEAN | Indica se é caso confirmado |
| `ts_carga` | TIMESTAMP | Data/hora da carga ETL |

### 7.5 Dimensão Evolução (`dim_evl`)

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `sk_evl` | SERIAL | Chave primária surrogate |
| `cd_evolucao` | TEXT | Código da evolução (natural key) |
| `ds_evolucao` | TEXT | Descrição (Cura, Óbito pelo agravo, etc.) |
| `ds_tipo_evolucao` | TEXT | Tipo (Cura, Óbito, Em investigação) |
| `flag_obito` | BOOLEAN | Indica se evoluiu para óbito |
| `ds_gravidade_desfecho` | TEXT | Gravidade (Favorável, Desfavorável, Indeterminado) |
| `ts_carga` | TIMESTAMP | Data/hora da carga ETL |

### 7.6 Dimensão Sintomas (`dim_snt`)

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `sk_snt` | SERIAL | Chave primária surrogate |
| `nk_sintomas` | TEXT | Business key (faixa_sint+faixa_alarm) |
| `ds_faixa_sintomas` | TEXT | Faixa de sintomas (0, 1-2, 3-5, 6+) |
| `ds_faixa_alarmes` | TEXT | Faixa de alarmes (0, 1, 2+, 3+) |
| `ds_perfil_clinico` | TEXT | Perfil (Assintomático, Leve, Moderado, Grave) |
| `flag_tem_sintomas` | BOOLEAN | Possui sintomas |
| `flag_tem_alarmes` | BOOLEAN | Possui sinais de alarme |
| `ts_carga` | TIMESTAMP | Data/hora da carga ETL |

### 7.7 Fato Dengue (`ft_deng`)

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `sk_fato` | BIGSERIAL | Chave primária surrogate |
| `nk_notificacao` | INTEGER | ID original da notificação SINAN |
| `fk_tmp` | INTEGER | FK para dim_tmp(sk_tmp) |
| `fk_loc` | INTEGER | FK para dim_loc(sk_loc) |
| `fk_pac` | INTEGER | FK para dim_pac(sk_pac) |
| `fk_cls` | INTEGER | FK para dim_cls(sk_cls) |
| `fk_evl` | INTEGER | FK para dim_evl(sk_evl) |
| `fk_snt` | INTEGER | FK para dim_snt(sk_snt) |
| `vl_confirmado` | INTEGER | Flag caso confirmado (0/1) - Aditiva |
| `vl_grave` | INTEGER | Flag caso grave (0/1) - Aditiva |
| `vl_obito` | INTEGER | Flag óbito (0/1) - Aditiva |
| `vl_hospitalizado` | INTEGER | Flag hospitalização (0/1) - Aditiva |
| `vl_qtd_sintomas` | INTEGER | Quantidade de sintomas (0-9) - Aditiva |
| `vl_qtd_alarmes` | INTEGER | Quantidade de alarmes (0-8) - Aditiva |
| `vl_idade_anos` | REAL | Idade em anos - Semi-aditiva |
| `dt_notificacao` | DATE | Data da notificação |
| `dt_sintomas` | DATE | Data dos primeiros sintomas |
| `ts_carga` | TIMESTAMP | Data/hora da carga ETL |

---

## 8. Views Analíticas (Propostas)

| View | Descrição |
|------|-----------|
| `vw_resumo_uf` | Agregação de métricas por UF e região |
| `vw_evolucao_semanal` | Evolução de casos por semana epidemiológica |
| `vw_perfil_demografico` | Distribuição por faixa etária, sexo e raça |
| `vw_taxa_letalidade` | Taxa de letalidade por UF e período |
| `vw_top_municipios` | Ranking de municípios por incidência |

---

## 9. Convenções Gerais

1. **Nomes em português** (sem acentos) para colunas de negócio
2. **Nomes em inglês** para termos técnicos (key, flag, timestamp)
3. **Snake_case** para todos os identificadores
4. **Chaves surrogate** sempre com prefixo `sk_`
5. **Chaves estrangeiras** sempre com prefixo `fk_`
6. **Chaves naturais** sempre com prefixo `nk_`
7. **Booleanos** prefixados com `flag_` (dimensões) ou como métricas 0/1 com `vl_` (fato)
8. **Datas** prefixadas com `dt_` (DATE) ou `ts_` (TIMESTAMP)
9. **Descrições** prefixadas com `ds_`
10. **Códigos** prefixados com `cd_`
11. **Nomes** prefixados com `nm_`
12. **Siglas** prefixadas com `sg_`
13. **Números/Contadores** prefixados com `nr_` ou `qtd_`
14. **Valores/Métricas** prefixadas com `vl_`

---

## 10. Diagrama do Star Schema

```
                              +------------------+
                              |     dim_tmp      |
                              +------------------+
                              | sk_tmp (PK)      |
                              | dt_completa      |
                              | nr_ano, nr_mes   |
                              | nr_semana_epi    |
                              | flag_fim_semana  |
                              +--------+---------+
                                       |
                                       | fk_tmp
                                       v
+------------------+           +------------------+           +------------------+
|     dim_loc      |           |     ft_deng      |           |     dim_cls      |
+------------------+           +------------------+           +------------------+
| sk_loc (PK)      |<----------| fk_loc (FK)      |           | sk_cls (PK)      |
| sg_uf            |           | fk_tmp (FK)      |---------->| cd_classificacao |
| nm_uf            |           | fk_pac (FK)      |           | ds_classificacao |
| nm_regiao        |           | fk_cls (FK)      |           | flag_confirmado  |
| cd_ibge          |           | fk_evl (FK)      |           +------------------+
+------------------+           | fk_snt (FK)      |
                               |------------------|
+------------------+           | vl_confirmado    |           +------------------+
|     dim_pac      |           | vl_grave         |           |     dim_evl      |
+------------------+           | vl_obito         |           +------------------+
| sk_pac (PK)      |<----------| vl_hospitalizado |---------->| sk_evl (PK)      |
| ds_faixa_etaria  |           | vl_qtd_sintomas  |           | ds_evolucao      |
| ds_sexo          |           | vl_idade_anos    |           | flag_obito       |
| ds_raca          |           | dt_notificacao   |           +------------------+
+------------------+           +------------------+
                                       |
                                       | fk_snt
                                       v
                              +------------------+
                              |     dim_snt      |
                              +------------------+
                              | sk_snt (PK)      |
                              | ds_faixa_sintomas|
                              | ds_perfil_clinico|
                              | flag_tem_alarmes |
                              +------------------+
```

---

## 11. Checklist de Conformidade - Nomenclatura Implementada

### ✅ Todas as Convenções Implementadas Corretamente

| Categoria | Item | Implementação | Status |
|-----------|------|---------------|--------|
| **Tabelas** | Dimensão Tempo | `gold.dim_tmp` | ✅ |
| | Dimensão Localização | `gold.dim_loc` | ✅ |
| | Dimensão Paciente | `gold.dim_pac` | ✅ |
| | Dimensão Classificação | `gold.dim_cls` | ✅ |
| | Dimensão Evolução | `gold.dim_evl` | ✅ |
| | Dimensão Sintomas | `gold.dim_snt` | ✅ |
| | Tabela Fato | `gold.ft_deng` | ✅ |
| **Surrogate Keys** | Tempo | `sk_tmp` | ✅ |
| | Localização | `sk_loc` | ✅ |
| | Paciente | `sk_pac` | ✅ |
| | Classificação | `sk_cls` | ✅ |
| | Evolução | `sk_evl` | ✅ |
| | Sintomas | `sk_snt` | ✅ |
| **Foreign Keys** | Tempo | `fk_tmp` | ✅ |
| | Localização | `fk_loc` | ✅ |
| | Paciente | `fk_pac` | ✅ |
| | Classificação | `fk_cls` | ✅ |
| | Evolução | `fk_evl` | ✅ |
| | Sintomas | `fk_snt` | ✅ |
| **Prefixos de Data** | Data completa | `dt_completa` | ✅ |
| | Data notificação | `dt_notificacao` | ✅ |
| | Data sintomas | `dt_sintomas` | ✅ |
| | Timestamp carga | `ts_carga` | ✅ |
| **Prefixos Numéricos** | Ano, Mês, Dia | `nr_ano`, `nr_mes`, `nr_dia` | ✅ |
| | Trimestre | `nr_trimestre` | ✅ |
| | Semana epidemiológica | `nr_semana_epi` | ✅ |
| **Prefixos de Nome** | UF (sigla) | `sg_uf` | ✅ |
| | UF (nome) | `nm_uf` | ✅ |
| | Região | `nm_regiao` | ✅ |
| | Capital | `nm_capital` | ✅ |
| **Prefixos de Descrição** | Sexo | `ds_sexo` | ✅ |
| | Raça | `ds_raca` | ✅ |
| | Classificação | `ds_classificacao` | ✅ |
| | Evolução | `ds_evolucao` | ✅ |
| | Faixa etária | `ds_faixa_etaria` | ✅ |
| | Perfil clínico | `ds_perfil_clinico` | ✅ |
| **Prefixos de Código** | CID | `cd_cid` | ✅ |
| | IBGE | `cd_ibge` | ✅ |
| | Classificação | `cd_classificacao` | ✅ |
| | Evolução | `cd_evolucao` | ✅ |
| **Natural Keys** | Notificação | `nk_notificacao` | ✅ |
| | Demográfica | `nk_demografica` | ✅ |
| | Sintomas | `nk_sintomas` | ✅ |
| **Métricas (Fato)** | Confirmado | `vl_confirmado` | ✅ |
| | Grave | `vl_grave` | ✅ |
| | Óbito | `vl_obito` | ✅ |
| | Hospitalizado | `vl_hospitalizado` | ✅ |
| | Qtd sintomas | `vl_qtd_sintomas` | ✅ |
| | Qtd alarmes | `vl_qtd_alarmes` | ✅ |
| | Idade | `vl_idade_anos` | ✅ |
| **Flags (Dimensões)** | Fim de semana | `flag_fim_semana` | ✅ |
| | Tem sintomas | `flag_tem_sintomas` | ✅ |
| | Tem alarmes | `flag_tem_alarmes` | ✅ |
| | Confirmado | `flag_confirmado` | ✅ |
| | Óbito | `flag_obito` | ✅ |
| **Índices** | Prefixo padrão | `idx_*` | ✅ |
| **Registro UNKNOWN** | SK padrão | `-1` | ✅ |

### 📋 Resumo da Validação

- **Total de itens verificados:** 60+
- **Em conformidade:** 100%
- **Data da validação:** Janeiro 2026

---

## 12. Métricas da Tabela Fato

### Tipos de Métricas

| Métrica | Tipo | Agregações Válidas |
|---------|------|-------------------|
| `vl_confirmado` | Aditiva | SUM, COUNT, AVG |
| `vl_grave` | Aditiva | SUM, COUNT, AVG |
| `vl_obito` | Aditiva | SUM, COUNT, AVG |
| `vl_hospitalizado` | Aditiva | SUM, COUNT, AVG |
| `vl_qtd_sintomas` | Aditiva | SUM, AVG, MIN, MAX |
| `vl_qtd_alarmes` | Aditiva | SUM, AVG, MIN, MAX |
| `vl_idade_anos` | Semi-aditiva | AVG, MIN, MAX (NÃO usar SUM) |

### Indicadores Derivados (Calculados)

| Indicador | Fórmula | Descrição |
|-----------|---------|-----------|
| Taxa de Confirmação | `SUM(vl_confirmado) / COUNT(*)` | % de casos confirmados |
| Taxa de Gravidade | `SUM(vl_grave) / SUM(vl_confirmado)` | % de casos graves entre confirmados |
| Taxa de Letalidade | `SUM(vl_obito) / SUM(vl_confirmado)` | % de óbitos entre confirmados |
| Taxa de Hospitalização | `SUM(vl_hospitalizado) / SUM(vl_confirmado)` | % hospitalizados entre confirmados |
| Média de Sintomas | `AVG(vl_qtd_sintomas)` | Média de sintomas por caso |
| Idade Média | `AVG(vl_idade_anos)` | Idade média dos pacientes |

---

## 13. Hierarquias Dimensionais

### Hierarquia Temporal
```
Ano → Trimestre → Mês → Semana Epidemiológica → Dia
```

### Hierarquia Geográfica
```
Região → UF → (Município - não implementado)
```

### Hierarquia Demográfica
```
Faixa Etária Ampla → Faixa Etária Detalhada
```

### Hierarquia de Gravidade (Classificação)
```
Grupo (Confirmado/Descartado) → Gravidade (Leve/Moderado/Grave)
```

---

*Documento gerado para o projeto ETL Dengue 2025 - Arquitetura Medallion*
*Última atualização: Janeiro 2026*
