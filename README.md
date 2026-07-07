<div align="center">

# 🏪 OXXO CX & Employee Intelligence Platform

### Plataforma de inteligencia operacional para atención al cliente y colaboradores con clasificación automática IA, análisis de sentimiento y predicción de SLA

<br>

![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=for-the-badge&logo=python&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![XGBoost](https://img.shields.io/badge/XGBoost-SLA%20Predictor-FF6600?style=for-the-badge)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Airflow](https://img.shields.io/badge/Apache-Airflow-017CEE?style=for-the-badge&logo=apacheairflow&logoColor=white)

<br>

> **Proof of Concept** — Este proyecto simula la arquitectura de datos y los modelos de IA que una empresa de retail a escala nacional necesitaría para transformar su operación de atención al cliente de reactiva a predictiva. Datos 100% sintéticos.

<br>

[📊 Resultados](#-resultados-clave) · [📐 Arquitectura](#-arquitectura) · [🖥️ Dashboards](#️-dashboards-power-bi) · [🤖 Modelos IA](#-modelos-de-ia) · [🩺 Lecciones](#-lecciones-clave) · [🚀 Quick Start](#-quick-start)

</div>

---

## 📊 Resultados Clave

Simulando **13,000 tickets** a lo largo de 90 días de operación:

| Métrica | Resultado | Nota |
|---|---|---|
| Ticket Classifier — Macro F1 (holdout por plantilla) | **75.0%** | Calibrado; medido sin fuga de datos |
| Ticket Classifier — Cobertura de auto-clasificación | **61.5%** a **90.9%** accuracy | Umbral ajustado el 2026-07-07 |
| Sentiment Analyzer — Macro F1 | **98.98%** | TF-IDF + LogReg, sustituto de BERT |
| SLA Breach Predictor — AUC-ROC | **0.65** | Modelo desplegado hoy |
| Reducción de clasificación manual | de 100% a ~38.5% (revisión humana) | Antes 79.5%-99.4% sin calibrar |
| Tiempo de ejecución del pipeline (13K tickets) | 4m 32s* | *Cifra del POC original, no re-verificada |

**Por qué estos números y no cifras más "bonitas"**: la versión inicial de este proyecto reportaba un F1 de ~87% y una cobertura de 98.1%. Ambos números venían de una evaluación con fuga de datos. Este README documenta las cifras reales, cómo se encontró el problema, y cómo se corrigió — ver [Lecciones Clave](#-lecciones-clave).

---

## 🎯 El Problema

Una empresa de conveniencia con más de **20,000 puntos de venta** y millones de clientes activos enfrenta un desafío de escala operacional que los procesos manuales no pueden resolver:

| Síntoma | Impacto real |
|---|---|
| 6 canales de atención operando en silos | No hay vista unificada del cliente → métricas infladas |
| Clasificación manual de tickets | Inconsistencia entre agentes → datos no confiables |
| Reportes Excel retroactivos | Los SLA se incumplen antes de que alguien lo vea |
| Sin análisis de reincidencia | El mismo problema se resuelve (mal) una y otra vez |
| Miles de comentarios en redes sin procesar | Tendencias y crisis detectadas días tarde |
| Tickets internos sin visibilidad | Colaboradores no saben el estatus de su solicitud |

**La consecuencia**: operación reactiva, costos crecientes y deterioro de la experiencia del cliente y del colaborador que no se puede diagnosticar con precisión porque los datos no son confiables.

## 💡 La Solución

Un pipeline de datos end-to-end que convierte el caos operacional en inteligencia accionable:

```
Datos crudos de 6+ canales  →  ETL validado  →  DWH estrella  →  IA  →  Power BI
```

1. **Centraliza** tickets externos (clientes) e internos (colaboradores) en un único DWH
2. **Valida** la calidad de datos en cada capa antes de que lleguen al análisis
3. **Clasifica** automáticamente cada ticket con un modelo NLP entrenado en español
4. **Predice** qué tickets van a incumplir su SLA con 2+ horas de anticipación
5. **Analiza** el sentimiento de cada interacción para detectar tendencias de insatisfacción
6. **Expone** todo en dashboards Power BI con drill-through, RLS y alertas automáticas

---

## 🖥️ Dashboards Power BI

> 📸 **Nota de portafolio**: reemplaza los mockups de abajo por capturas de pantalla reales (`.png`) del `.pbix` en cuanto estén disponibles — un dashboard real convence mucho más que un diagrama ASCII.

**Dashboard 1 — CX Operations Board** (gerentes CX / supervisores de turno): KPIs en tiempo real (SLA Response/Resolution, FCR, NPS), heatmap de volumen por hora, tabla de tickets en riesgo de SLA con score IA, y monitor de performance del clasificador.

**Dashboard 2 — Employee Service Dashboard** (RRHH / TI / operaciones): backlog aging, SLA interno por departamento, reincidencia y tickets duplicados detectados.

<details>
<summary>Ver mockups ASCII y medidas DAX destacadas</summary>

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  CX OPERATIONS BOARD            Hoy: 18 jun 2025    [Actualizado: 14:32]    │
├───────────────┬───────────────┬──────────────┬──────────────┬───────────────┤
│  TICKETS HOY  │  SLA RESP %   │ SLA RESOL %  │    FCR %     │     NPS       │
│     1,847     │    96.2%  ✓  │   87.1%  ⚠️  │   71.4%  ✓  │    53.2   ✓  │
│  ▲ 43% vs avg │  target >95% │ target >90%  │ target >70%  │  target >50   │
├───────────────┴───────────────┴──────────────┴──────────────┴───────────────┤
│  SENTIMIENTO POR CANAL (hoy)                TICKETS EN RIESGO SLA           │
│  Facebook    ████████░░  0.62 😊           │ CRÍTICO (< 30 min)    ·  8 │
│  Instagram   ██████░░░░  0.41 😐           │ ALTO (30-2h, AI >70%) · 23 │
│  WhatsApp    ████░░░░░░ -0.18 😠 ⚠️         │ MEDIO (2-4h, AI >50%) · 41 │
│  Email       ████████░░  0.55 😊           │ En tiempo              ·  OK│
│  Chat        ███████░░░  0.48 😐
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  EMPLOYEE SERVICE DASHBOARD           [Actualizado: 14:32]                  │
├───────────────┬────────────────────┬──────────────────┬─────────────────────┤
│  BACKLOG TOTAL│  SLA CUMPLIMIENTO  │   REINCIDENCIA   │   BACKLOG > 30 DÍAS │
│      247      │      82.3%  ⚠️     │     18.2%  ⚠️    │     12  🔴           │
└───────────────┴────────────────────┴──────────────────┴─────────────────────┘
```

**Páginas adicionales del CX Operations Board**: Análisis por Canal (heatmap + waterfall de backlog) · Riesgo SLA en Tiempo Real · Reincidencia & Root Cause · IA Performance Monitor.

**Medidas DAX destacadas**:

```dax
SLA Resolution % =
DIVIDE(
    CALCULATE(COUNTROWS(fact_tickets), fact_tickets[resolution_sla_met] = TRUE()),
    COUNTROWS(fact_tickets)
) * 100

NPS Score =
VAR Promoters  = CALCULATE(COUNTROWS(fact_tickets), fact_tickets[nps_score] >= 9)
VAR Detractors = CALCULATE(COUNTROWS(fact_tickets), fact_tickets[nps_score] <= 6)
VAR Total      = CALCULATE(COUNTROWS(fact_tickets), NOT ISBLANK(fact_tickets[nps_score]))
RETURN DIVIDE(Promoters - Detractors, Total) * 100

Tickets At Risk =
CALCULATE(
    COUNTROWS(fact_tickets),
    fact_tickets[sla_risk_level] IN {"CRITICAL_RISK", "HIGH_RISK"},
    fact_tickets[status] IN {"open", "in_progress", "pending"}
)
```

**KPIs monitoreados** — clientes: SLA Response (>95%), SLA Resolution (>90%), FCR (>70%), AHT (<30 min), Reincidence Rate (<15%), NPS (>50), Sentiment Score (>0.3), Escalation Rate (<10%), AI Accuracy (>85%).
**KPIs internos**: Backlog aging >30 días (0%), SLA cumplimiento (>85%), Reincidencia (<10%), Tickets duplicados, Tiempo de resolución por área.

</details>

---

## 📐 Arquitectura

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                      OXXO CX & EMPLOYEE INTELLIGENCE PLATFORM                  │
├─────────────────────────────────────────────────────────────────────────────────┤
│  ① FUENTES DE DATOS (simuladas con generador sintético realista)               │
│  Facebook · Instagram · WhatsApp · Email · Chat · Tickets Internos             │
│                                        │                                        │
│  ② ETL PIPELINE (Python + Airflow)                                             │
│  Extract → Validate (reglas propias, no GE) → Transform → Load                 │
│  • Normalización de fechas UTC     • Cálculo de tiempos SLA                     │
│  • Deduplicación de clientes       • Detección de reincidencias                │
│  • Schema validation               • Surrogate keys para dimensiones           │
│                                        │                                        │
│  ③ DATA WAREHOUSE (PostgreSQL 16 — Modelo Estrella)                            │
│  STAGING (raw) → DWH CORE (fact_tickets, fact_interactions, +9 dims) → MARTS   │
│                                        │                                       │
│  ④ CAPA DE IA (4 módulos): Ticket Classifier · Sentiment Analyzer ·            │
│     SLA Breach Predictor · LLM Executive Summary                              │
│                                        │                                       │
│  ⑤ VISUALIZACIÓN: CX Operations Board · Employee Service Dashboard (Power BI) │
│                                                                                │
│  ⑥ MONITORING: Data Quality Monitor · Pipeline Health · Model Drift Detector  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🗃️ Modelo de Datos

Modelo estrella con 3 tablas de hechos y 9 dimensiones, diseñado para queries analíticos y carga en Power BI (modo Import).

| Tabla de hechos | Grano | Filas (90 días) |
|---|---|---|
| `fact_tickets` | 1 por ticket | ~13,000 |
| `fact_interactions` | 1 por mensaje dentro del ticket | ~52,000 |
| `fact_daily_channel_metrics` | 1 por canal por día (agregada) | ~540 |

`fact_tickets` incluye métricas de tiempo (response/resolution time, SLA met), flags operacionales (reincidencia, escalación, FCR) y enriquecimiento IA (categoría predicha + confianza, sentiment score, probabilidad de breach).

**Dimensiones**: `dim_date`, `dim_time`, `dim_channel`, `dim_category` (SCD2), `dim_subcategory`, `dim_agent` (SCD2), `dim_customer`, `dim_employee` (SCD2), `dim_store`.

---

## 🤖 Modelos de IA

### Módulo 1 — Ticket Classifier
Clasifica automáticamente cada ticket al momento de su creación. **Stack**: TF-IDF (1-2 gram, 10K features) + Logistic Regression, calibrado con `CalibratedClassifierCV`.

- **Macro F1 real (holdout por plantilla): 75.0%** — la primera evaluación con split aleatorio reportaba ~87%, pero medía memorización de plantillas, no generalización. Corregido y con corpus ampliado (147→359 plantillas), el número real subió de 43.3% a 72.0%, luego a 75.0% tras calibrar.
- **Cobertura de auto-clasificación: 61.5%** a 90.9% accuracy (umbral bajado de 0.75 a 0.50 el 2026-07-07; a 0.75 la cobertura era 20.5% con 95.7% accuracy).
- Detalle completo del split, la calibración y el barrido de umbrales: [`FASE_B_RESULTADOS.md`](FASE_B_RESULTADOS.md).

### Módulo 2 — Sentiment Analyzer
Analiza sentimiento por interacción, ponderando más las interacciones recientes. **Stack real**: TF-IDF + Logistic Regression (sustituto de `pysentimiento`/BERT en español — bloqueado en el sandbox de entrenamiento por egress y espacio en disco; el wrapper de inferencia es compatible con ambos).

- **Macro F1 (holdout por plantilla): 98.98%** — a diferencia del clasificador, este número ya se sostenía bajo evaluación correcta antes de ampliar el corpus.
- Detalle: [`FASE_C_RESULTADOS.md`](FASE_C_RESULTADOS.md).

### Módulo 3 — SLA Breach Predictor
Predice en tiempo real qué tickets van a incumplir su SLA. **Stack**: XGBoost con `scale_pos_weight` por desbalance de clases.

- **AUC-ROC: 0.65** (modelo desplegado hoy). La ronda baseline midió 0.49 (fuga causal); una ronda posterior corrigió a 0.56, pero ese código se perdió y tuvo que reconstruirse — el 0.65 actual no es comparable dígito a dígito con el 0.56 histórico (datasets sintéticos distintos).
- Tres features candidatas (carga del agente, historial de SLA, longitud del mensaje) se probaron con un experimento controlado de 5 semillas: +0.0019 AUC, indistinguible de ruido → **no se desplegaron**.
- Detalle: [`FASE_D_RESULTADOS.md`](FASE_D_RESULTADOS.md).

### Módulo 4 — Executive Summary Generator
> ⚠️ Especificación planeada, **no implementada en este checkout**. Generaría el resumen ejecutivo diario vía LLM (Claude API), traduciendo métricas en narrativa orientada a decisiones.

---

## 🩺 Lecciones Clave

Estas son las lecciones más importantes que salieron de construir y auditar este proyecto — el detalle forense completo de cada una vive en `ESTADO_REAL.md` y los archivos `FASE_*_RESULTADOS.md`.

- **Un split aleatorio puede mentir**: evaluar con variantes de la misma plantilla en train y test infló el F1 del clasificador a ~87%; un holdout por plantilla reveló el número real (43%, luego 75% tras ampliar corpus y calibrar). La estrategia de split determina si mides generalización o memorización.
- **Accuracy alta no implica confianza bien calibrada**: el clasificador ya acertaba 73.64% de las veces, pero su softmax casi nunca superaba el umbral de confianza. `CalibratedClassifierCV` resolvió esto sin tocar el modelo base — la causa no era falta de datos, era una probabilidad mal calibrada.
- **El código se pierde si no se versiona explícitamente**: el fix que corregía una fuga causal en el SLA Predictor desapareció por completo; solo sobrevivió la métrica. Tuvo que reconstruirse desde cero.
- **Una feature candidata razonable no siempre ayuda — y hay que medirlo, no asumirlo**: tres features "obvias" para el SLA Predictor no movieron el AUC más allá del ruido en un experimento controlado.
- **Incidente real de datos**: una muestra de prueba reutilizó, sin querer, el mismo esquema de IDs que producción; el `UPSERT` sobrescribió 600 filas reales sin posibilidad de recuperación. Se corrigió con prefijos de ID exclusivos y logging explícito de INSERT vs. UPDATE.

---

## 📦 Tech Stack

| Capa | Tecnología | Propósito |
|---|---|---|
| Lenguaje | Python 3.11 | ETL, IA, scripts |
| Base de datos | PostgreSQL 16 | DWH principal |
| Orquestación | Apache Airflow 3.2.2 | Scheduling del pipeline |
| Calidad de datos | Reglas hechas a mano | Mismas reglas que Great Expectations, sin la dependencia |
| ML clásico | Scikit-learn 1.8 | Ticket Classifier |
| Boosting | XGBoost 2.0 (fijado `<3`, ver nota) | SLA Predictor |
| NLP español | TF-IDF + Logistic Regression | Sustituto de BERT (ver Módulo 2) |
| LLM | Anthropic Claude API | Planeado para resúmenes ejecutivos (no implementado) |
| Visualización | Power BI Desktop | Dashboards ejecutivos |
| Contenedores | Docker Compose | Ambiente reproducible |

> Nota: `sla_breach_predictor.joblib` se serializó con XGBoost 2.x; deserializar con 3.x falla por incompatibilidad de formato entre majors (confirmado: funciona con 2.1.4, falla con 3.3.0).

---

## 🗺️ Roadmap

```
✅ Modelo de datos + generador sintético       ✅ Dashboard CX Operations Board
✅ ETL: extract + validate + transform         ✅ Dashboard Employee Service + AI Monitor
✅ DWH, dimensiones, fact_tickets              ⚠️ Notebooks y suite de tests (pendiente)
✅ Clasificador NLP + Sentiment Analyzer
✅ SLA Predictor (XGBoost) + integración IA

Futuro (fuera del scope del POC):
v2.0  Upgrade a BERT multilingüe · DAG con reintentos y alertas Slack/email
v2.1  API REST (FastAPI) para clasificación en tiempo real · Integración Zendesk/Freshdesk
v3.0  Topic modeling (BERTopic) · Correlación tickets ↔ datos de tienda
```

---

<details>
<summary>📁 Estructura del proyecto</summary>

```
airflow-docker/
├── README.md · ESTADO_REAL.md (fuente de verdad del estado real)
├── FASE_B/C/D_RESULTADOS.md   ← detalle de cada modelo de IA
├── docker-compose.yaml · Dockerfile · requirements-ai.txt · .env.example
├── config/airflow.cfg
├── dags/cx_intelligence_pipeline.py
├── data/
│   ├── synthetic/   ← generadores, corpus semilla, scripts de entrenamiento
│   ├── samples/      ← datos de entrada por canal (JSON/CSV)
│   └── staging/       ← salida intermedia del pipeline (JSONL)
├── etl/
│   ├── extractors/ · transformers/ · loaders/ · validation/ · common/
├── ai/
│   ├── classifier/ · sentiment/ · sla_predictor/   ← wrappers + modelos .joblib + métricas
└── monitoring/pipeline_monitor.py
```

</details>

<details>
<summary>🚀 Quick Start</summary>

**Prerrequisitos**: Python 3.11+ (faker, psycopg2-binary, numpy), Docker & Docker Compose, Git. Power BI Desktop opcional (no hay `.pbix` incluido en este checkout).

```bash
git clone <url-del-repo>
cd airflow-docker
cp .env.example .env
docker-compose up -d
# Airflow en http://localhost:8080
pip install -r requirements-ai.txt
pip install faker psycopg2-binary numpy
```

> El esquema del DWH (`dwh`, `audit`, `marts`, `staging`) no se crea automáticamente en este checkout — requiere un volumen `pgdata_oxxo` con el esquema ya cargado. Ver `ESTADO_REAL.md §3` para detalle.

```bash
# Full-load real (100,000 tickets)
python data/synthetic/generate_data.py --tickets 100000

# Muestra de 600 tickets para probar el DAG punta a punta
cd data/synthetic && python generate_ticket_samples.py --n 600 && cd ../..

# Disparar el DAG
docker exec airflow-docker-airflow-worker-1 airflow dags unpause cx_intelligence_pipeline
docker exec airflow-docker-airflow-worker-1 airflow dags trigger cx_intelligence_pipeline
```

Reentrenar el clasificador: `cd data/synthetic && python train_classifier.py`.

</details>

---

## 📄 Licencia

MIT License — libre para uso educativo y de portafolio.

<div align="center">

<br>

**Desarrollado como Proof of Concept de iniciativa de Transformación Digital en retail**

*Este proyecto utiliza datos completamente sintéticos generados para fines demostrativos.*
*No contiene información real de ninguna empresa u organización.*

<br>

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Conectar-0077B5?style=for-the-badge&logo=linkedin)](https://linkedin.com/in/cesar-rabago-perez)
[![GitHub](https://img.shields.io/badge/GitHub-Ver%20más%20proyectos-181717?style=for-the-badge&logo=github)](https://github.com/cesarrabago)

</div>
