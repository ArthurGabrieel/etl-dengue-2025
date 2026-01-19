# Data Warehouse - Arquitetura Medallion

Este repositório contém o projeto de **Data Warehouse/Lakehouse** baseado na arquitetura **Medallion** (Bronze/Raw, Silver e Gold), utilizando como base de dados o conjunto **Sinan/Dengue 2025**.

O projeto tem como objetivo **armazenar, limpar e modelar dados de dengue**, transformando-os em informações estruturadas para análises de BI, com métricas de acidentes, vítimas, veículos e condições de tráfego.

---

## Contribuidores

<center>
    <table>
    <tr>
        <td align="center"><a href="https://github.com/zzzBECK"><img style="border-radius: 50%;" src="https://github.com/zzzBECK.png" width="130px;" alt=""/><br /><sub><b>Alexandre Beck</b></sub></a><br/></td>
        <td align="center"><a href="https://github.com/ArthurGabrieel"><img style="border-radius: 50%;" src="https://github.com/ArthurGabrieel.png" width="130px;" alt=""/><br /><sub><b>Arthur Gabriel</b></sub></a><br/></td>
        <td align="center"><a href="https://github.com/AlexandreIJr"><img style="border-radius: 50%;" src="https://github.com/AlexandreLJr.png" width="130px;" alt=""/><br /><sub><b>Alexandre Jr.</b></sub></a><br/></td>
        <td align="center"><a href="https://github.com/thiagorfreitas"><img style="border-radius: 50%;" src="https://github.com/thiagorfreitas.png" width="130px;" alt=""/><br /><sub><b>Thiago Freitas</b></sub></a><br/></td>
    </tr>
    </table>
</center>

## 📂 Estrutura do Repositório

```bash
etl-dengue-2025/
 ├── Data_Layer/
 │   ├── raw/      # Dados originais (Bronze)
 │   ├── silver/   # Dados limpos e padronizados
 │   ├── gold/     # Dados modelados para BI (esquema estrela)
 │   └── README.md
 ├── Transformer/  # ETLs e transformações das tabelas
 │   └── etl_raw_to_silver.ipynb    # Transformação Bronze → Silver
 ├── requirements.txt  # Dependências do projeto
 └── README.md
```

---

## 🔹 Camadas

- **RAW (Bronze):** dados originais, preservados como coletados.
- **Silver:** dados tratados, integrados e enriquecidos.
- **Gold:** dados prontos para análise, em modelo estrela (fato e dimensões).
