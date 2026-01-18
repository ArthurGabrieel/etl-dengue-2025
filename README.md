# Data Warehouse - Arquitetura Medallion

Este repositório contém o projeto de **Data Warehouse/Lakehouse** baseado na arquitetura **Medallion** (Bronze/Raw, Silver e Gold), utilizando como base de dados o conjunto **Sinan/Dengue 2025**.

O projeto tem como objetivo **armazenar, limpar e modelar dados de dengue**, transformando-os em informações estruturadas para análises de BI, com métricas de acidentes, vítimas, veículos e condições de tráfego.

---

## � Configuração do Ambiente

### Pré-requisitos

- Python 3.8 ou superior
- pip (gerenciador de pacotes Python)

### 1. Criar e Ativar o Ambiente Virtual

**Windows (PowerShell/CMD):**

```bash
# Criar o ambiente virtual
python -m venv .venv

# Ativar o ambiente
.venv\Scripts\activate
```

**Linux/MacOS:**

```bash
# Criar o ambiente virtual
python3 -m venv .venv

# Ativar o ambiente
source .venv/bin/activate
```

### 2. Instalar Dependências

```bash
# Instalar todas as bibliotecas necessárias
pip install -r requirements.txt
```

### 3. Verificar Instalação

```bash
# Listar pacotes instalados
pip list

# Executar Jupyter Notebook
jupyter notebook
```

---

## 📂 Estrutura do Repositório

```bash
etl-dengue-2025/
 ├── Data_Layer/
 │   ├── raw/      # Dados originais (Bronze)
 │   ├── silver/   # Dados limpos e padronizados
 │   ├── gold/     # Dados modelados para BI (esquema estrela)
 │   └── README.md
 ├── Transformer/  # ETLs e transformações das tabelas
 │   ├── bronze_analysis.ipynb      # Análise exploratória da camada Bronze
 │   └── etl_raw_to_silver.ipynb    # Transformação Bronze → Silver
 ├── requirements.txt  # Dependências do projeto
 └── README.md
```

---

## 🔹 Camadas

- **RAW (Bronze):** dados originais, preservados como coletados.
- **Silver:** dados tratados, integrados e enriquecidos.
- **Gold:** dados prontos para análise, em modelo estrela (fato e dimensões).
