# Dicionario de Mnemonicos - Gold Layer

Este documento define todas as abreviacoes e convencoes de nomenclatura utilizadas no Star Schema da camada Gold do projeto Dengue 2025.

**Padrao adotado**: Nomenclatura corporativa de 3 letras UPPERCASE.

---

## 1. Abreviacoes de Tabelas (3 letras)

| Abreviacao | Significado | Tabela Completa |
|------------|-------------|-----------------|
| `DEN` | **Den**gue | `FAT_DEN` |
| `TMP` | **T**e**mp**o | `DIM_TMP` |
| `LOC` | **Loc**alizacao | `DIM_LOC` |
| `PAC` | **Pac**iente | `DIM_PAC` |
| `CLS` | **Cl**a**s**sificacao | `DIM_CLS` |
| `EVL` | **Ev**o**l**ucao | `DIM_EVL` |
| `SNT` | **S**i**nt**omas | `DIM_SNT` |

---

## 2. Prefixos de Tabelas

| Prefixo | Significado | Exemplo |
|---------|-------------|---------|
| `DIM_` | **Dim**ensao (tabela dimensional) | `DIM_TMP`, `DIM_LOC`, `DIM_PAC` |
| `FAT_` | **Fat**o (tabela fato) | `FAT_DEN` |

---

## 3. Sufixo de Chaves

| Sufixo | Significado | Uso |
|--------|-------------|-----|
| `_SRK` | **S**u**r**rogate **K**ey - Chave primaria artificial | PK em todas as tabelas |

**Padrao de Surrogate Key**: `[TABELA_3LETRAS]_SRK`

| Tabela | Surrogate Key |
|--------|---------------|
| `DIM_TMP` | `TMP_SRK` |
| `DIM_LOC` | `LOC_SRK` |
| `DIM_PAC` | `PAC_SRK` |
| `DIM_CLS` | `CLS_SRK` |
| `DIM_EVL` | `EVL_SRK` |
| `DIM_SNT` | `SNT_SRK` |
| `FAT_DEN` | `FAT_SRK` |

---

## 4. Prefixos de Colunas (3 letras)

| Prefixo | Significado | Exemplo de Uso |
|---------|-------------|----------------|
| `VAL_` | **Val**or/Metrica numerica | `VAL_CON`, `VAL_GRA`, `VAL_OBI` |
| `QTD_` | **Q**uan**t**i**d**ade | `QTD_SNT`, `QTD_ALR` |
| `IND_` | **Ind**icador booleano (0/1) | `IND_FDS`, `IND_SNT`, `IND_ALR` |
| `DAT_` | **Dat**a (DATE) | `DAT_COM`, `DAT_NOT`, `DAT_SNT` |
| `COD_` | **Cod**igo | `COD_IBG`, `COD_CID`, `COD_CLS` |
| `NOM_` | **Nom**e | `NOM_UNF`, `NOM_REG`, `NOM_DIA` |
| `DES_` | **Des**cricao | `DES_CLS`, `DES_EVL`, `DES_SEX` |
| `SIG_` | **Sig**la | `SIG_UNF` |
| `NUM_` | **Num**ero | `NUM_ANO`, `NUM_MES`, `NUM_DIA` |
| `TIP_` | **Tip**o | `TIP_EVL`, `TIP_GRA` |

---

## 5. Abreviacoes de Dominio (3 letras)

| Abreviacao | Significado | Contexto |
|------------|-------------|----------|
| `EPI` | **Epi**demiologico | `NUM_SEM_EPI` (semana epidemiologica) |
| `UNF` | **U**nidade **F**ederativa | Estados brasileiros |
| `CID` | **C**lassificacao **I**nternacional **D**oencas | Codigo CID-10 |
| `IBG` | Instituto Brasileiro Geografia | Codigos geograficos IBGE |
| `NOT` | **Not**ificacao | ID original SINAN |
| `CON` | **Con**firmado | Caso confirmado |
| `GRA` | **Gra**ve | Caso grave |
| `OBI` | **Obi**to | Obito |
| `HOS` | **Hos**pitalizado | Hospitalizacao |
| `SNT` | **S**i**nt**omas | Sintomas clinicos |
| `ALR` | **Al**a**r**mes | Sinais de alarme |
| `IDA` | **Ida**de | Idade do paciente |
| `FDS` | **F**im **d**e **S**emana | Sabado/Domingo |
| `ETA` | F. **Eta**ria | Faixa etaria |
| `SEX` | **Sex**o | Sexo do paciente |
| `RAC` | **Rac**a | Raca/Cor |
| `REG` | **Reg**iao | Regiao geografica |
| `CAP` | **Cap**ital | Capital do estado |
| `TRI` | **Tri**mestre | Trimestre do ano |
| `DEM` | **Dem**ografica | Chave demografica |
| `CLI` | **Cli**nico | Perfil clinico |
| `DES` | **Des**fecho | Desfecho do caso |
| `GRP` | **Gr**u**p**o | Grupo/Categoria |

---

## 6. Estrutura das Tabelas

### 6.1 Dimensao Tempo (`DIM_TMP`)

| Coluna | Tipo | Descricao |
|--------|------|-----------|
| `TMP_SRK` | BIGINT | Chave primaria surrogate |
| `DAT_COM` | DATE | Data completa (YYYY-MM-DD) |
| `NUM_ANO` | INTEGER | Ano (2024, 2025, 2026) |
| `NUM_MES` | INTEGER | Mes (1-12) |
| `NUM_DIA` | INTEGER | Dia do mes (1-31) |
| `NUM_TRI` | INTEGER | Trimestre (1-4) |
| `NUM_SEM_EPI` | INTEGER | Semana epidemiologica (1-53) |
| `NUM_DIA_SEM` | INTEGER | Dia da semana ISO (1=Segunda, 7=Domingo) |
| `NOM_DIA` | VARCHAR(20) | Nome do dia (Segunda, Terca, etc.) |
| `IND_FDS` | INTEGER | Indica fim de semana (0/1) |
| `DES_MES_ANO` | VARCHAR(10) | Mes/Ano formato YYYY-MM |
| `DES_ANO_TRI` | VARCHAR(10) | Ano/Trimestre formato YYYY-QN |

### 6.2 Dimensao Localizacao (`DIM_LOC`)

| Coluna | Tipo | Descricao |
|--------|------|-----------|
| `LOC_SRK` | BIGINT | Chave primaria surrogate |
| `SIG_UNF` | CHAR(2) | Sigla da UF (SP, MG, RJ, etc.) |
| `NOM_UNF` | VARCHAR(50) | Nome completo da UF |
| `NOM_REG` | VARCHAR(20) | Regiao (Norte, Nordeste, etc.) |
| `COD_IBG` | INTEGER | Codigo IBGE da UF |
| `NOM_CAP` | VARCHAR(50) | Nome da capital |

### 6.3 Dimensao Paciente (`DIM_PAC`)

| Coluna | Tipo | Descricao |
|--------|------|-----------|
| `PAC_SRK` | BIGINT | Chave primaria surrogate |
| `COD_DEM` | VARCHAR(50) | Chave natural (faixa+sexo+raca) |
| `DES_FAI_ETA` | VARCHAR(30) | Faixa etaria (< 1 ano, 1-4 anos, etc.) |
| `DES_SEX` | VARCHAR(20) | Sexo (Masculino, Feminino, Ignorado) |
| `DES_RAC` | VARCHAR(30) | Raca/Cor (Branca, Preta, Parda, etc.) |
| `DES_FAI_ETA_DET` | VARCHAR(50) | Faixa etaria detalhada |

### 6.4 Dimensao Classificacao (`DIM_CLS`)

| Coluna | Tipo | Descricao |
|--------|------|-----------|
| `CLS_SRK` | BIGINT | Chave primaria surrogate |
| `COD_CLS` | VARCHAR(10) | Codigo da classificacao (natural key) |
| `DES_CLS` | VARCHAR(50) | Descricao (Dengue, Dengue Grave, etc.) |
| `DES_GRP` | VARCHAR(30) | Grupo (Confirmado, Descartado, Em Investigacao) |
| `DES_GRA` | VARCHAR(20) | Gravidade (Leve, Moderado, Grave) |
| `COD_CID` | VARCHAR(10) | Codigo CID-10 (A90, A91.0) |
| `IND_CON` | INTEGER | Indica caso confirmado (0/1) |

### 6.5 Dimensao Evolucao (`DIM_EVL`)

| Coluna | Tipo | Descricao |
|--------|------|-----------|
| `EVL_SRK` | BIGINT | Chave primaria surrogate |
| `COD_EVL` | VARCHAR(10) | Codigo da evolucao (natural key) |
| `DES_EVL` | VARCHAR(50) | Descricao (Cura, Obito pelo agravo, etc.) |
| `TIP_EVL` | VARCHAR(30) | Tipo (Cura, Obito, Em investigacao) |
| `IND_OBI` | INTEGER | Indica obito (0/1) |
| `DES_GRA_DES` | VARCHAR(30) | Gravidade desfecho (Favoravel, Desfavoravel) |

### 6.6 Dimensao Sintomas (`DIM_SNT`)

| Coluna | Tipo | Descricao |
|--------|------|-----------|
| `SNT_SRK` | BIGINT | Chave primaria surrogate |
| `COD_SNT` | VARCHAR(20) | Chave natural (faixa_sint+faixa_alarm) |
| `DES_FAI_SNT` | VARCHAR(20) | Faixa de sintomas (0, 1-2, 3-5, 6+) |
| `DES_FAI_ALR` | VARCHAR(20) | Faixa de alarmes (0, 1, 2+, 3+) |
| `DES_PER_CLI` | VARCHAR(30) | Perfil (Assintomatico, Leve, Moderado, Grave) |
| `IND_SNT` | INTEGER | Possui sintomas (0/1) |
| `IND_ALR` | INTEGER | Possui sinais de alarme (0/1) |

### 6.7 Fato Dengue (`FAT_DEN`)

| Coluna | Tipo | Descricao |
|--------|------|-----------|
| `FAT_SRK` | BIGINT | Chave primaria surrogate |
| `NUM_NOT` | BIGINT | ID original da notificacao SINAN |
| `TMP_SRK` | BIGINT | FK para DIM_TMP(TMP_SRK) |
| `LOC_SRK` | BIGINT | FK para DIM_LOC(LOC_SRK) |
| `PAC_SRK` | BIGINT | FK para DIM_PAC(PAC_SRK) |
| `CLS_SRK` | BIGINT | FK para DIM_CLS(CLS_SRK) |
| `EVL_SRK` | BIGINT | FK para DIM_EVL(EVL_SRK) |
| `SNT_SRK` | BIGINT | FK para DIM_SNT(SNT_SRK) |
| `VAL_CON` | INTEGER | Flag caso confirmado (0/1) - Aditiva |
| `VAL_GRA` | INTEGER | Flag caso grave (0/1) - Aditiva |
| `VAL_OBI` | INTEGER | Flag obito (0/1) - Aditiva |
| `VAL_HOS` | INTEGER | Flag hospitalizacao (0/1) - Aditiva |
| `QTD_SNT` | INTEGER | Quantidade de sintomas (0-9) - Aditiva |
| `QTD_ALR` | INTEGER | Quantidade de alarmes (0-8) - Aditiva |
| `VAL_IDA` | NUMERIC(5,2) | Idade em anos - Semi-aditiva |
| `DAT_NOT` | DATE | Data da notificacao |
| `DAT_SNT` | DATE | Data dos primeiros sintomas |

---

## 7. Convencoes Gerais

1. **UPPERCASE** para todos os identificadores
2. **Prefixos de 3 letras** para colunas
3. **Sufixo `_SRK`** para todas as surrogate keys
4. **Underscore** como separador
5. **Sem acentos** em todos os nomes
6. **Indicadores** com prefixo `IND_` e valores 0/1
7. **Datas** com prefixo `DAT_`
8. **Descricoes** com prefixo `DES_`
9. **Codigos** com prefixo `COD_`
10. **Nomes** com prefixo `NOM_`
11. **Siglas** com prefixo `SIG_`
12. **Numeros** com prefixo `NUM_`
13. **Quantidades** com prefixo `QTD_`
14. **Valores/Metricas** com prefixo `VAL_`
15. **Tipos** com prefixo `TIP_`
16. **Registro UNKNOWN** com SRK = `-1`

---

## 8. Diagrama do Star Schema

```
                              +------------------+
                              |     DIM_TMP      |
                              +------------------+
                              | TMP_SRK (PK)     |
                              | DAT_COM          |
                              | NUM_ANO, NUM_MES |
                              | NUM_SEM_EPI      |
                              | IND_FDS          |
                              +--------+---------+
                                       |
                                       | TMP_SRK
                                       v
+------------------+           +------------------+           +------------------+
|     DIM_LOC      |           |     FAT_DEN      |           |     DIM_CLS      |
+------------------+           +------------------+           +------------------+
| LOC_SRK (PK)     |<----------| LOC_SRK (FK)     |           | CLS_SRK (PK)     |
| SIG_UNF          |           | TMP_SRK (FK)     |---------->| COD_CLS          |
| NOM_UNF          |           | PAC_SRK (FK)     |           | DES_CLS          |
| NOM_REG          |           | CLS_SRK (FK)     |           | IND_CON          |
| COD_IBG          |           | EVL_SRK (FK)     |           +------------------+
+------------------+           | SNT_SRK (FK)     |
                               |------------------|
+------------------+           | VAL_CON          |           +------------------+
|     DIM_PAC      |           | VAL_GRA          |           |     DIM_EVL      |
+------------------+           | VAL_OBI          |           +------------------+
| PAC_SRK (PK)     |<----------| VAL_HOS          |---------->| EVL_SRK (PK)     |
| DES_FAI_ETA      |           | QTD_SNT          |           | DES_EVL          |
| DES_SEX          |           | VAL_IDA          |           | IND_OBI          |
| DES_RAC          |           | DAT_NOT          |           +------------------+
+------------------+           +------------------+
                                       |
                                       | SNT_SRK
                                       v
                              +------------------+
                              |     DIM_SNT      |
                              +------------------+
                              | SNT_SRK (PK)     |
                              | DES_FAI_SNT      |
                              | DES_PER_CLI      |
                              | IND_ALR          |
                              +------------------+
```

---

## 9. Metricas da Tabela Fato

### Tipos de Metricas

| Metrica | Tipo | Agregacoes Validas |
|---------|------|-------------------|
| `VAL_CON` | Aditiva | SUM, COUNT, AVG |
| `VAL_GRA` | Aditiva | SUM, COUNT, AVG |
| `VAL_OBI` | Aditiva | SUM, COUNT, AVG |
| `VAL_HOS` | Aditiva | SUM, COUNT, AVG |
| `QTD_SNT` | Aditiva | SUM, AVG, MIN, MAX |
| `QTD_ALR` | Aditiva | SUM, AVG, MIN, MAX |
| `VAL_IDA` | Semi-aditiva | AVG, MIN, MAX (NAO usar SUM) |

### Indicadores Derivados (Calculados)

| Indicador | Formula | Descricao |
|-----------|---------|-----------|
| Taxa de Confirmacao | `SUM(VAL_CON) / COUNT(*)` | % de casos confirmados |
| Taxa de Gravidade | `SUM(VAL_GRA) / SUM(VAL_CON)` | % de casos graves entre confirmados |
| Taxa de Letalidade | `SUM(VAL_OBI) / SUM(VAL_CON)` | % de obitos entre confirmados |
| Taxa de Hospitalizacao | `SUM(VAL_HOS) / SUM(VAL_CON)` | % hospitalizados entre confirmados |
| Media de Sintomas | `AVG(QTD_SNT)` | Media de sintomas por caso |
| Idade Media | `AVG(VAL_IDA)` | Idade media dos pacientes |

---

## 10. Hierarquias Dimensionais

### Hierarquia Temporal
```
Ano -> Trimestre -> Mes -> Semana Epidemiologica -> Dia
```

### Hierarquia Geografica
```
Regiao -> UF -> (Municipio - nao implementado)
```

### Hierarquia Demografica
```
Faixa Etaria Ampla -> Faixa Etaria Detalhada
```

### Hierarquia de Gravidade (Classificacao)
```
Grupo (Confirmado/Descartado) -> Gravidade (Leve/Moderado/Grave)
```

---

*Documento gerado para o projeto ETL Dengue 2025 - Arquitetura Medallion*
*Padrao: Nomenclatura corporativa 3 letras UPPERCASE*
*Ultima atualizacao: Janeiro 2026*
