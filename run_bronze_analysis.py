#!/usr/bin/env python3
"""
Script de execução do notebook Bronze Analysis
Extrai e executa as análises do notebook de forma programática
"""

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')  # Backend sem GUI para gerar gráficos
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
import warnings
import json
import sys

warnings.filterwarnings('ignore')
plt.style.use('seaborn-v0_8-whitegrid')
pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', 100)

# Caminho correto do arquivo CSV
DATA_PATH = 'Data_Layer/raw/data/DENGBR25.csv'

print("=" * 80)
print("🔶 BRONZE LAYER - Análise Exploratória Inicial")
print("=" * 80)
print()

# ============================================================
# CARREGAMENTO DOS DADOS
# ============================================================
print("📂 Carregando dados...")
try:
    df = pd.read_csv(DATA_PATH, encoding='latin-1', low_memory=False)
    print(f"✅ Dataset carregado com sucesso!")
    print()
except FileNotFoundError:
    print(f"❌ Erro: Arquivo não encontrado em {DATA_PATH}")
    sys.exit(1)
except Exception as e:
    print(f"❌ Erro ao carregar arquivo: {e}")
    sys.exit(1)

# ============================================================
# 1️⃣ EXPLORAÇÃO INICIAL
# ============================================================
print("=" * 80)
print("1️⃣ EXPLORAÇÃO INICIAL")
print("=" * 80)
print()

print("📊 DIMENSÕES DO DATASET")
print("-" * 80)
print(f"Número de linhas (notificações): {df.shape[0]:,}")
print(f"Número de colunas (variáveis): {df.shape[1]}")
print(f"Total de células: {df.shape[0] * df.shape[1]:,}")
print()

print("📋 TIPOS DE DADOS POR COLUNA")
print("-" * 80)
print(df.dtypes.value_counts())
print()

print("📌 PRIMEIRAS 5 COLUNAS:")
print("-" * 80)
print(df.iloc[:5, :10])
print()

# ============================================================
# 2️⃣ QUALIDADE DOS DADOS
# ============================================================
print("=" * 80)
print("2️⃣ QUALIDADE DOS DADOS")
print("=" * 80)
print()

print("🔍 VALORES AUSENTES")
print("-" * 80)
missing_data = df.isnull().sum()
missing_percent = (missing_data / len(df)) * 100
missing_df = pd.DataFrame({
    'Coluna': missing_data.index,
    'Missing Count': missing_data.values,
    'Missing %': missing_percent.values
})
missing_df = missing_df[missing_df['Missing Count'] > 0].sort_values('Missing %', ascending=False)
print(f"Total de colunas com valores ausentes: {len(missing_df)}")
print()
print("Top 20 colunas com mais valores ausentes:")
print(missing_df.head(20).to_string(index=False))
print()

# ============================================================
# 3️⃣ ANÁLISES TEMPORAIS
# ============================================================
print("=" * 80)
print("3️⃣ ANÁLISES TEMPORAIS")
print("=" * 80)
print()

print("📅 DISTRIBUIÇÃO POR ANO")
print("-" * 80)
if 'NU_ANO' in df.columns:
    ano_dist = df['NU_ANO'].value_counts().sort_index()
    print(ano_dist)
    print()

print("📅 DISTRIBUIÇÃO POR SEMANA EPIDEMIOLÓGICA")
print("-" * 80)
if 'SEM_NOT' in df.columns:
    sem_dist = df['SEM_NOT'].value_counts().sort_index().head(10)
    print("Primeiras 10 semanas epidemiológicas:")
    print(sem_dist)
    print()

# ============================================================
# 4️⃣ ANÁLISES GEOGRÁFICAS
# ============================================================
print("=" * 80)
print("4️⃣ ANÁLISES GEOGRÁFICAS")
print("=" * 80)
print()

print("🗺️ DISTRIBUIÇÃO POR UF")
print("-" * 80)
if 'SG_UF_NOT' in df.columns:
    uf_dist = df['SG_UF_NOT'].value_counts().head(10)
    print("Top 10 UFs com mais notificações:")
    print(uf_dist)
    print()
    print(f"Total de UFs: {df['SG_UF_NOT'].nunique()}")
    print()

# ============================================================
# 5️⃣ ANÁLISES DEMOGRÁFICAS
# ============================================================
print("=" * 80)
print("5️⃣ ANÁLISES DEMOGRÁFICAS")
print("=" * 80)
print()

print("👥 DISTRIBUIÇÃO POR SEXO")
print("-" * 80)
if 'CS_SEXO' in df.columns:
    sexo_dist = df['CS_SEXO'].value_counts()
    print(sexo_dist)
    print()

print("📊 ESTATÍSTICAS DE IDADE")
print("-" * 80)
if 'NU_IDADE_N' in df.columns:
    print(df['NU_IDADE_N'].describe())
    print()

print("🎨 DISTRIBUIÇÃO POR RAÇA/COR")
print("-" * 80)
if 'CS_RACA' in df.columns:
    raca_dist = df['CS_RACA'].value_counts()
    print(raca_dist)
    print()

# ============================================================
# 6️⃣ ANÁLISES CLÍNICAS
# ============================================================
print("=" * 80)
print("6️⃣ ANÁLISES CLÍNICAS")
print("=" * 80)
print()

print("🌡️ CLASSIFICAÇÃO FINAL")
print("-" * 80)
if 'CLASSI_FIN' in df.columns:
    classi_dist = df['CLASSI_FIN'].value_counts()
    print(classi_dist)
    print()

print("🏥 HOSPITALIZAÇÃO")
print("-" * 80)
if 'HOSPITALIZ' in df.columns:
    hosp_dist = df['HOSPITALIZ'].value_counts()
    print(hosp_dist)
    print()

print("💉 EVOLUÇÃO DOS CASOS")
print("-" * 80)
if 'EVOLUCAO' in df.columns:
    evol_dist = df['EVOLUCAO'].value_counts()
    print(evol_dist)
    print()

# ============================================================
# 7️⃣ RESUMO EXECUTIVO
# ============================================================
print("=" * 80)
print("7️⃣ RESUMO EXECUTIVO")
print("=" * 80)
print()

summary = {
    "total_notificacoes": int(df.shape[0]),
    "total_variaveis": int(df.shape[1]),
    "periodo_analise": f"{df['NU_ANO'].min():.0f} - {df['NU_ANO'].max():.0f}" if 'NU_ANO' in df.columns else "N/A",
    "ufs_cobertas": int(df['SG_UF_NOT'].nunique()) if 'SG_UF_NOT' in df.columns else 0,
    "percentual_missing_geral": f"{df.isnull().sum().sum() / (df.shape[0] * df.shape[1]) * 100:.2f}%",
    "colunas_com_missing": int(len(missing_df)),
}

print("📊 SUMÁRIO ESTATÍSTICO")
print("-" * 80)
for key, value in summary.items():
    print(f"{key.replace('_', ' ').title()}: {value}")
print()

# Salvar resumo em JSON
print("💾 Salvando resumo em JSON...")
with open('Data_Layer/raw/bronze_analysis_summary.json', 'w', encoding='utf-8') as f:
    json.dump(summary, f, indent=2, ensure_ascii=False)
print("✅ Resumo salvo em: Data_Layer/raw/bronze_analysis_summary.json")
print()

print("=" * 80)
print("✨ ANÁLISE CONCLUÍDA COM SUCESSO!")
print("=" * 80)
