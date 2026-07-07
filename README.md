<div align="center">

# 🏪 CX & Employee Intelligence Platform

### Plataforma de inteligencia operacional para atención al cliente y colaboradores con clasificación automática IA, análisis de sentimiento y predicción de SLA

<br>

![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=for-the-badge&logo=python&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![XGBoost](https://img.shields.io/badge/XGBoost-SLA%20Predictor-FF6600?style=for-the-badge)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Airflow](https://img.shields.io/badge/Apache-Airflow-017CEE?style=for-the-badge&logo=apacheairflow&logoColor=white)

<br>

> **Proof of Concept** — Este proyecto simula la arquitectura de datos y los modelos de IA que una empresa de retail a escala nacional necesitaría para transformar su operación de atención al cliente de reactiva a predictiva.

<br>

[📊 Dashboards](#-dashboards-power-bi) · [📐 Arquitectura](#-arquitectura) · [🤖 Modelos IA](#-modelos-de-ia) · [🩺 Diagnóstico](#-diagnóstico-y-lecciones-del-proceso) · [🚀 Quick Start](#-quick-start) · [📁 Estructura](#-estructura-del-proyecto)

</div>

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

---

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

## 📊 Dashboards Power BI

### Dashboard 1: CX Operations Board

*Para gerentes de Customer Experience y supervisores de turno.*

**Página 1 — Resumen Ejecutivo**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  CX OPERATIONS BOARD            Hoy: 18 jun 2025    [Actualizado: 14:32]    │
├───────────────┬───────────────┬──────────────┬──────────────┬───────────────┤
│  TICKETS HOY  │  SLA RESP %   │ SLA RESOL %  │    FCR %     │     NPS       │
│     1,847     │    96.2%  ✓  │   87.1%  ⚠️  │   71.4%  ✓  │    53.2   ✓  │
│  ▲ 43% vs avg │  target >95% │ target >90%  │ target >70%  │  target >50   │
├───────────────┴───────────────┴──────────────┴──────────────┴───────────────┤
│                                                                              │
│  SENTIMIENTO POR CANAL (hoy)                TICKETS EN RIESGO SLA           │
│                                                                              │
│  Facebook    ████████░░  0.62 😊           ┌────────────────────────────┐   │
│  Instagram   ██████░░░░  0.41 😐           │ CRÍTICO (< 30 min)    ·  8 │   │
│  WhatsApp    ████░░░░░░ -0.18 😠 ⚠️         │ ALTO (30-2h, AI >70%) · 23 │   │
│  Email       ████████░░  0.55 😊           │ MEDIO (2-4h, AI >50%) · 41 │   │
│  Chat        ███████░░░  0.48 😐           │ En tiempo              ·  OK│   │
│                                             └────────────────────────────┘   │
│                                                                              │
│  VOLUMEN × HORA DE DÍA (hoy vs. promedio lunes)                             │
│                                                                              │
│  200 │                              ████                                     │
│  175 │                          ████████                                     │
│  150 │                      ████████████  ── hoy                            │
│  125 │              ████████████████████  ·· promedio                       │
│  100 │          ████████████████████████                                     │
│   75 │      ████████████████████████████                                     │
│       ────────────────────────────────────                                  │
│        6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Página 2 — Análisis por Canal**
Heatmap volumen × hora · Comparativa SLA% entre canales · Waterfall de backlog

**Página 3 — Riesgo SLA en Tiempo Real**
Tabla de tickets con riesgo alto de breach · Score IA · Tiempo restante · Agente asignado

**Página 4 — Reincidencia & Root Cause**
Categorías con mayor reincidencia · Días promedio entre contactos · Análisis de resoluciones fallidas

**Página 5 — IA Performance Monitor**
Accuracy del clasificador por categoría · Distribución de confianza · Tickets enviados a revisión humana

---

### Dashboard 2: Employee Service Dashboard

*Para RRHH, TI y coordinadores de operaciones.*

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  EMPLOYEE SERVICE DASHBOARD           [Actualizado: 14:32]                  │
├───────────────┬────────────────────┬──────────────────┬─────────────────────┤
│  BACKLOG TOTAL│  SLA CUMPLIMIENTO  │   REINCIDENCIA   │   BACKLOG > 30 DÍAS │
│      247      │      82.3%  ⚠️     │     18.2%  ⚠️    │     12  🔴           │
├───────────────┴────────────────────┴──────────────────┴─────────────────────┤
│                                                                              │
│  BACKLOG AGING (tickets abiertos)              TICKETS POR CATEGORÍA        │
│                                                                              │
│  0-7 días    ████████████████░   158 (64%)    Nómina / Pago     ████  89   │
│  8-15 días   ██████░░░░░░░░░░░    62 (25%)    Accesos IT        ███   71   │
│  16-30 días  ████░░░░░░░░░░░░░    15 (6%)     Uniformes         ██    48   │
│  > 30 días   ██░░░░░░░░░░░░░░░    12 (5%)  🔴 Credenciales      ██    39   │
│                                                                              │
│  CUMPLIMIENTO SLA POR DEPARTAMENTO RESPONSABLE                               │
│                                                                              │
│  Capacitación   ████████████████░░  91%  ✓                                  │
│  Operaciones    ████████████████░░░  88%  ✓                                  │
│  RRHH           ██████████████░░░░░  79%  ⚠️                                 │
│  TI / Sistemas  ██████████░░░░░░░░░  63%  🔴 ← atención requerida           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Medidas DAX destacadas

```dax
// ── SLA Resolution Rate ──────────────────────────────────────────────────────
SLA Resolution % =
DIVIDE(
    CALCULATE(COUNTROWS(fact_tickets), fact_tickets[resolution_sla_met] = TRUE()),
    COUNTROWS(fact_tickets)
) * 100

// ── NPS Score ────────────────────────────────────────────────────────────────
NPS Score =
VAR Promoters  = CALCULATE(COUNTROWS(fact_tickets), fact_tickets[nps_score] >= 9)
VAR Detractors = CALCULATE(COUNTROWS(fact_tickets), fact_tickets[nps_score] <= 6)
VAR Total      = CALCULATE(COUNTROWS(fact_tickets), NOT ISBLANK(fact_tickets[nps_score]))
RETURN DIVIDE(Promoters - Detractors, Total) * 100

// ── Tickets at SLA Risk (para alerta en tiempo real) ─────────────────────────
Tickets At Risk =
CALCULATE(
    COUNTROWS(fact_tickets),
    fact_tickets[sla_risk_level] IN {"CRITICAL_RISK", "HIGH_RISK"},
    fact_tickets[status] IN {"open", "in_progress", "pending"}
)

// ── Reincidence Rate ─────────────────────────────────────────────────────────
Reincidence Rate % =
DIVIDE(
    CALCULATE(COUNTROWS(fact_tickets), fact_tickets[is_reincidence] = TRUE()),
    COUNTROWS(fact_tickets)
) * 100

// ── WoW Change (comparación semana anterior) ─────────────────────────────────
Tickets WoW % Change =
VAR ThisWeek  = CALCULATE(COUNTROWS(fact_tickets), DATESINPERIOD(dim_date[full_date], MAX(dim_date[full_date]), -7, DAY))
VAR LastWeek  = CALCULATE(COUNTROWS(fact_tickets), DATESINPERIOD(dim_date[full_date], MAX(dim_date[full_date]), -14, DAY))
RETURN DIVIDE(ThisWeek - LastWeek, LastWeek) * 100
```

---

## 📐 Arquitectura

![Arquitectura de la plataforma](./ChatGPT Image 7 jul 2026, 16_15_38.png)

---

## 🤖 Modelos de IA

### Módulo 1 — Ticket Classifier

Clasifica automáticamente cada ticket en la categoría correcta al momento de su creación, eliminando la clasificación manual inconsistente.

```
Input:  Texto del ticket ("Mi recibo de nómina del 15 no llegó correctamente")
Output: { category: "nomina_pago", confidence: 0.94, needs_review: false }
```

**Stack**: TF-IDF (ngram 1-2, 10K features) + Logistic Regression (class_weight balanced), calibrado con `CalibratedClassifierCV` (sigmoid/Platt)

**Manejo de baja confianza**: Si `confidence < 0.50` → el ticket se marca `needs_human_review = TRUE` y se enruta a revisión manual (umbral bajado de 0.75 el 2026-07-07, ver más abajo).

```
Resultado real (holdout por plantilla, no random split):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Macro F1-Score: 0.7203  (corpus ampliado, 359 plantillas — antes 0.4334 con 147)
Accuracy real:   73.64%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Por qué este número y no ~87%**: la primera evaluación usó un split
aleatorio train/test que dejaba variantes de la misma plantilla de mensaje en
ambos lados — el modelo aprendía a reconocer la plantilla, no la categoría
real, y el F1 medido (~87%) reflejaba esa fuga de datos, no capacidad real de
generalización. Evaluado correctamente con un holdout *por plantilla*
(ninguna plantilla vista en train aparece en test), el macro F1 real era
0.4334 con el corpus semilla original (147 plantillas). Tras ampliar el
corpus a 359 plantillas (priorizado por categoría según el F1 real medido
— ver `FASE_B_RESULTADOS.md`), el macro F1 honesto subió a **0.7203** y la
accuracy real a **73.64%**, medido con la misma metodología de holdout.

**Pero ampliar el corpus no resolvió el problema de confianza por sí
solo**: con el modelo sin calibrar, el `low_confidence_rate` seguía en
99.4% (antes 100%) — casi todas las predicciones seguían por debajo de
`CONFIDENCE_THRESHOLD = 0.75`, a pesar de que el modelo ya acertaba el
73.64% de las veces. La causa: con 20 categorías de vocabulario
parcialmente solapado, el softmax de una `LogisticRegression` sin
calibrar reparte probabilidad entre varias clases plausibles aunque
acierte la correcta — no es que el modelo sea poco confiable, es que su
probabilidad reportada no refleja bien su confianza real.

**Corregido con `CalibratedClassifierCV`** (sigmoid/Platt): al umbral
original (0.75), la cobertura de auto-clasificación subió de **0.6% a
20.5%**, manteniendo **95.7% de accuracy** en esas predicciones — un
aumento de ~34x sin sacrificar precisión. El macro F1 también subió
(0.7203 → 0.7503).

**[2026-07-07] Umbral bajado a 0.50** — decisión de producto tomada con
el barrido de `FASE_B_RESULTADOS.md §3.1` como evidencia: aceptar algo
menos de accuracy a cambio de mucha más cobertura.

| | Umbral 0.75 | Umbral 0.50 (actual) |
|---|---|---|
| Cobertura de auto-clasificación | 20.5% | **61.5%** |
| Accuracy en esas predicciones | 95.7% | **90.9%** |

`needs_human_review` ahora se activa para ~38.5% del volumen (antes
~79.5% con el umbral de 0.75, ~99.4% sin calibrar). Ver
`FASE_B_RESULTADOS.md §3.1-3.2` para el barrido completo (0.40-0.90) y el
detalle de esta decisión.

---

### Módulo 2 — Sentiment Analyzer

Analiza el sentimiento de cada interacción del ticket (mensajes del cliente).
El modelo en producción **no es el BERT en español planeado originalmente**
— es un sustituto TF-IDF + Logistic Regression, con el mismo contrato de
entrada/salida.

```
Input:  "Llevo 3 días esperando respuesta y nadie me ha contactado, pésimo servicio"
Output: { label: "negative", score: -0.91 }
```

**Modelo real**: TF-IDF + Logistic Regression. **Por qué no es
`pysentimiento/robertuito-sentiment-analysis` (BERT en español) como se
planeó**: en el sandbox de entrenamiento, `huggingface.co` está fuera del
allowlist de egress (403 confirmado al intentar descargar el modelo) y
`pysentimiento` arrastra `torch`+CUDA (~3.5 GB), que agotó el disco
disponible a medio instalar. El wrapper de inferencia es compatible con
ambos — migrar al BERT real es un cambio de modelo, no de contrato, el día
que esto corra en una máquina con internet y disco completos.

**Resultado real**: macro F1 = **0.9898** en holdout por plantilla (era
0.9515 con el corpus original de 147 plantillas; subió tras ampliarlo a
359 para Fase B — ver `FASE_C_RESULTADOS.md`) — a diferencia del
clasificador (Módulo 1), este número ya se sostenía bajo evaluación
correcta incluso antes de ampliar el corpus.

**Agregación por ticket**: las interacciones recientes tienen mayor peso.
Un cliente que empieza enojado pero termina satisfecho tiene un score
diferente al que empieza bien y termina frustrado.

---

### Módulo 3 — SLA Breach Predictor

Predice en tiempo real qué tickets tienen alta probabilidad de incumplir su SLA, permitiendo reasignación proactiva de agentes.

```
Input:  Features del ticket: canal, categoría, prioridad, hora del día,
        día de la semana, fin de semana, si ya tiene agente asignado.

Output: { sla_breach_probability: 0.83, risk_level: "HIGH_RISK",
          minutes_to_breach: 47 }
```

**Stack**: XGBoost con `scale_pos_weight` calculado del desbalance real de clases

```
Métrica real (modelo desplegado hoy, 2026-07-07):
━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUC-ROC: 0.6475
━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Por qué 0.65 y no 0.823, y por qué no es directamente comparable al
0.56 anterior**: la primera versión del modelo (ronda *baseline*) medía
AUC-ROC = 0.4862 — prácticamente azar — por una fuga causal en el
feature engineering. Una ronda posterior (*causal_fix*) corrigió eso y
midió 0.5594, pero **el código que aplicó ese fix se perdió por completo**
(no solo el script de entrenamiento, también el parche al generador de
datos) — se descubrió al intentar mejorar el modelo hoy. Se reconstruyó
`data/synthetic/train_sla_model.py` con una nueva estructura causal
(reconstrucción razonable, no el código original) y se reentrenó: el
modelo desplegado hoy mide **0.6475**, pero este número **no es
comparable dígito a dígito** con el 0.5594 histórico — son datasets
sintéticos distintos. El 0.823 sigue sin ser un número medido en este
proyecto.

**Se probó, con evidencia, si agregar carga del agente + historial de
SLA por categoría + longitud del mensaje ayudaría** (ver
`FASE_D_RESULTADOS.md §2.5`) — con un experimento controlado de 5
semillas, la mejora fue de +0.0019 AUC en promedio: indistinguible de
ruido. Esas tres features **no están en el modelo desplegado** (por eso
ya no aparecen en el bloque "Input" de arriba). No es que fueran mala
idea; el resto de las features ya capturaba casi toda la señal
disponible en este espacio de datos.

---

### Módulo 4 — Executive Summary Generator

> **⚠️ No implementado en este checkout** — no existe `ai/executive_summary/`
> ni ningún código de este módulo en el repo (confirmado el 2026-07-06,
> ver `ESTADO_REAL.md`). Lo que sigue es la especificación planeada, no
> un resultado medido ni un módulo funcional, a diferencia de los
> Módulos 1-3 (que sí tienen código, modelos entrenados y métricas
> reales).

Planeado: generar automáticamente el resumen ejecutivo diario usando un LLM, traduciendo métricas en narrativa orientada a decisiones.

```python
# Ejemplo de output planeado (no generado por código real)
"""
RESUMEN EJECUTIVO CX — 18 de junio, 2025

Estado general: ⚠️ Día con tensión operacional. El SLA de resolución bajó
al 87% (target: 90%), impulsado principalmente por WhatsApp, que procesó un
43% más de volumen del esperado a partir de las 14:00 hrs.

Canal crítico: WhatsApp registró 1,847 tickets (vs. 1,290 promedio de lunes).
El tiempo de resolución fue de 4.2 horas, contra el SLA de 2 horas.
Causa probable: pico de quejas por "cobro incorrecto" en región Bajío.

Mayor reincidencia: La categoría "acceso_sistemas" tiene un 28% de reincidencia
en 30 días, el doble del target. Los tickets de resolución registran "acceso
restablecido" pero los colaboradores reportan el mismo problema días después.

Sentimiento: -0.21 (neutral-negativo), consistente con la semana anterior.
No hay degradación acelerada pero tampoco recuperación.

Acciones prioritarias para mañana:
1. Refuerzo de 3 agentes a WhatsApp en franja 13:00-17:00
2. Revisión de protocolo de resolución de "acceso_sistemas" con equipo TI
3. Investigar causa del pico en Bajío (¿problema de sistema de POS?)
"""
```

---

## 🩺 Diagnóstico y lecciones del proceso

- **Fuga de datos por split ingenuo (clasificador)**: el 87.4% original venía
  de un split aleatorio train/test que dejaba variantes de la misma
  plantilla de mensaje en ambos lados — el modelo memorizaba la plantilla,
  no aprendía la categoría. Un holdout *por plantilla* (sin fuga) expuso el
  número real: macro F1 = 0.4334. La lección no es "el modelo es malo", es
  que la estrategia de split determina si la métrica mide generalización o
  memorización.

- **0% de auto-clasificación real, no 98.1% — y ampliar el corpus no
  bastó para arreglarlo, calibrar el modelo sí**: medido bajo holdout por
  plantilla con el corpus original (147 plantillas), el 100% de las
  predicciones de test caían por debajo del umbral de confianza (0.75).
  Se amplió el corpus a 359 plantillas (priorizado por F1 real de cada
  categoría) y el macro F1 subió de 0.4334 a 0.7203 — una mejora real y
  medida. **Pero el `low_confidence_rate` casi no se movió (100% →
  99.4%)**: el modelo ya acertaba 73.64% de las veces, pero con 20
  categorías de vocabulario solapado el softmax de una `LogisticRegression`
  sin calibrar rara vez supera 0.75 aunque acierte. La causa raíz del
  síntoma de auto-clasificación no era (solo) tamaño de corpus — era que
  la probabilidad del modelo no reflejaba su confianza real. Se aplicó
  `CalibratedClassifierCV` (sigmoid) sobre el mismo modelo: la cobertura
  subió de 0.6% a **20.5%** al mismo umbral de 0.75, con 95.7% de
  accuracy en esas predicciones, y el F1 también subió (0.72→0.75). La
  lección: una hipótesis razonable ("faltan datos") puede explicar parte
  del problema (el F1 sí mejoró mucho) sin explicar el síntoma que la
  motivó (la confianza casi no cambió) — hay que medir cada efecto por
  separado, no asumir que arreglar uno arregla el otro. Ver
  `FASE_B_RESULTADOS.md` §3-3.1 para el análisis de calibración completo
  y el barrido de umbrales. **[2026-07-07]** Esa decisión de producto ya
  se tomó: se bajó el umbral de 0.75 a 0.50, subiendo la cobertura de
  auto-clasificación de 20.5% a **61.5%**, a costa de bajar la accuracy
  de esas predicciones de 95.7% a **90.9%** — el tradeoff exacto que ya
  estaba documentado en el barrido antes de decidir. Ver
  `FASE_B_RESULTADOS.md` §3.2.

- **El código del "fix causal" del SLA Predictor también se había
  perdido — y las features candidatas para mejorarlo, probadas con
  evidencia, no ayudaron**: al intentar implementar las mejoras que este
  mismo README recomendaba (carga del agente, historial de SLA por
  categoría, longitud del mensaje), se encontró que el parche que
  conectaba `resolution_sla_met` con hora pico/categoría/canal/fin de
  semana nunca quedó guardado en `generate_data.py` — solo el resultado
  medido (AUC 0.5594) sobrevivió, no el código. Se reconstruyó un
  generador causal equivalente y, con él, un experimento controlado: las
  3 features candidatas subieron el AUC apenas +0.0019 en promedio sobre
  5 semillas — dentro del ruido, no una mejora real. Se optó por **no
  desplegar** ese modelo más complejo sin beneficio claro. La lección:
  una recomendación de feature engineering que suena razonable necesita
  medirse, no asumirse — y "no ayudó" es también un resultado válido que
  vale la pena documentar, no solo los que sí funcionan. Ver
  `FASE_D_RESULTADOS.md §2.5` para el experimento completo.

- **Log de auditoría con checks hardcodeados**: el full-load de datos
  sintéticos escribe un resumen de calidad (`dq_checks_total/passed/failed`)
  como literal fijo en el SQL, sin calcularlo de los checks individuales que
  se insertan en la misma corrida. Auditando una corrida real se confirmó la
  contradicción: el detalle mostraba 12/12 checks pasados, el resumen decía
  11/12. Ninguna validación falló nunca — el número resumen simplemente
  nunca estuvo conectado a un cálculo real.

- **Incidente de colisión de `ticket_id`**: una muestra de prueba (600
  tickets) generada con el mismo generador sintético que el dataset de
  producción reutilizó, sin darse cuenta, el mismo esquema de IDs
  posicionales. Al cargarla contra la base real, el `UPSERT` (`ON CONFLICT
  DO UPDATE`) sobrescribió 600 filas reales en vez de insertar filas nuevas.
  Una búsqueda acotada de recuperación (volúmenes, backups, datos fuente)
  no encontró forma de restaurarlas — se dan por perdidas de forma
  permanente. Se corrigió de raíz por dos lados: los IDs de muestra ahora
  usan un prefijo exclusivo que nunca colisiona con producción, y el loader
  ahora distingue y loggea explícitamente cuántas filas fueron INSERT real
  vs. UPDATE por conflicto, para que una colisión futura sea visible de
  inmediato en vez de silenciosa.

- **La validación de calidad no es Great Expectations**: el pipeline
  implementa a mano las mismas reglas (not-null, rango, unicidad,
  duplicados) que describiría una suite de GE, sin la dependencia
  instalada — una decisión pragmática para no atar el DAG a una librería
  pesada, documentada directamente en el código.

- **Un pipeline con cron activo sigue corriendo entre sesiones de trabajo**:
  el DAG programado para correr cada hora lo hizo de forma autónoma durante
  el tiempo transcurrido entre validaciones manuales, incluyendo una carga
  completa exitosa antes de que se pidiera dispararla a mano. La lección
  operativa: verificar el estado de pausa del scheduler antes de asumir que
  "nada corrió" solo porque nadie lo disparó manualmente.

---

## 🎯 Resultados del POC

Con **13,000 tickets sintéticos** que simulan 90 días de operación:

| Métrica | Resultado |
|---|---|
| Classifier F1-Score (macro, holdout por plantilla) | **75.0%** (corpus ampliado + calibrado; era 43.3%) |
| Classifier accuracy real (holdout por plantilla) | **74.78%** |
| SLA Predictor AUC-ROC (modelo desplegado 2026-07-07) | **0.65** (no comparable dígito a dígito con la ronda `causal_fix` anterior, 0.56 — ver `FASE_D_RESULTADOS.md` §2.5) |
| % tickets auto-clasificados (conf > 0.50) | **61.5%** (medido, calibrado + umbral bajado, ver `FASE_B_RESULTADOS.md` §3.1-3.2) ⚠️ |
| Accuracy en tickets auto-clasificados | **90.9%** |
| Tiempo de ejecución del pipeline (13K tickets) | 4m 32s * |
| Dashboard load time (Import Mode) | < 2s * |

⚠️ El 98.1% que citaba la versión original de esta tabla venía del split
con fuga de plantillas (mismo problema que infló el F1 a ~87%, ver
Módulo 1). Medido bajo holdout por plantilla: ampliar el corpus (147→359
plantillas) subió el F1 a 0.72 pero dejó la cobertura de
auto-clasificación en solo 0.6% — el umbral de confianza (pensado para
un problema más simple que 20 categorías con vocabulario solapado) casi
nunca se superaba, aunque el modelo ya acertara 73.64% de las veces.
Calibrar el modelo (`CalibratedClassifierCV`) subió la cobertura a 20.5%
con 95.7% de accuracy al umbral original (0.75); bajar el umbral a 0.50
(decisión de producto tomada el 2026-07-07, con el barrido de umbrales
como evidencia) la subió más, a **61.5%** con **90.9%** de accuracy en
esas predicciones. Ver "Diagnóstico y lecciones del proceso" más abajo.

\* Cifra del POC original, no re-verificada contra una ejecución real — ver
"Diagnóstico y lecciones del proceso" más abajo.

### ⚠️ Simulación ilustrativa — no es un resultado medido

La siguiente tabla es una proyección hipotética de cómo se vería el impacto
de la plataforma **si los modelos alcanzaran las métricas originalmente
planeadas** (F1 87%, AUC 0.82). No es una medición real: no hubo un periodo
"sin plataforma" vs. "con plataforma" instrumentado, y los modelos que sí
están en producción hoy (F1 0.75 el clasificador, AUC 0.65 el predictor de
SLA) tienen desempeño muy por debajo de lo que esta simulación asume. Se
deja como ilustración del caso de negocio *si* se llegara a esas métricas
objetivo, no como evidencia de resultado.

| KPI | Sin plataforma | Con plataforma (hipotético) | Δ |
|---|---|---|---|
| SLA Resolution % | 72% | 91% | +19pp |
| FCR Rate | 58% | 74% | +16pp |
| Reincidence Rate | 23% | 14% | -9pp |
| Tickets clasificados manualmente | 100% | 2% | -98% |
| Tiempo detección de tendencias | ~48 horas | < 2 horas | -96% |

---

## 🗃️ Modelo de Datos

Arquitectura de **modelo estrella** con 3 tablas de hechos y 9 dimensiones. Diseñado para soportar tanto queries analíticos complejos como la carga de Power BI en modo Import.

```
                          ┌───────────────┐
                          │   dim_date    │
                          │  date_key PK  │
                          └───────┬───────┘
                                  │
        ┌─────────────┐           │           ┌──────────────────┐
        │ dim_channel │           │           │   dim_category   │
        │channel_key  ├───────────┤           │  category_key PK │
        │channel_name │           │           │  sla_response_h  │
        │sla_defaults │           │           │  sla_resolution_h│
        └─────────────┘           │           └────────┬─────────┘
                                  │                    │
        ┌─────────────┐    ┌──────▼────────────────────▼──────┐    ┌─────────────┐
        │  dim_agent  │    │          fact_tickets             │    │dim_customer │
        │  agent_key  ├────┤                                   ├────│customer_key │
        │  team       │    │  ticket_key       PK              │    │(anonimizado)│
        │  shift      │    │  ticket_id        natural key     │    └─────────────┘
        │  expertise  │    │  date_key         FK              │
        └─────────────┘    │  channel_key      FK              │    ┌─────────────┐
                           │  category_key     FK              │    │dim_employee │
        ┌─────────────┐    │  agent_key        FK              ├────│employee_key │
        │  dim_store  │    │  customer_key     FK (nullable)   │    │department   │
        │  store_key  ├────┤  employee_key     FK (nullable)   │    │region       │
        │  region     │    │  store_key        FK              │    └─────────────┘
        │  state      │    │                                   │
        └─────────────┘    │  — MÉTRICAS DE TIEMPO —           │
                           │  response_time_minutes            │
                           │  resolution_time_minutes          │
                           │  response_sla_met      BOOL       │
                           │  resolution_sla_met    BOOL       │
                           │  sla_breach_minutes    NUMERIC    │
                           │                                   │
                           │  — FLAGS OPERACIONALES —          │
                           │  is_reincidence        BOOL       │
                           │  escalated             BOOL       │
                           │  first_contact_resolved BOOL      │
                           │                                   │
                           │  — IA ENRICHMENT —                │
                           │  ai_predicted_category VARCHAR    │
                           │  ai_category_confidence NUMERIC   │
                           │  sentiment_score        NUMERIC   │
                           │  sentiment_label        VARCHAR   │
                           │  sla_breach_probability NUMERIC   │
                           │                                   │
                           │  — SATISFACCIÓN —                 │
                           │  nps_score     INT                │
                           │  ces_score     INT                │
                           │  csat_score    INT                │
                           └───────────────────────────────────┘
```

### Tablas de hechos

| Tabla | Grano | Filas estimadas (90 días) |
|---|---|---|
| `fact_tickets` | 1 fila por ticket | ~13,000 |
| `fact_interactions` | 1 fila por mensaje dentro del ticket | ~52,000 |
| `fact_daily_channel_metrics` | 1 fila por canal por día (agregada) | ~540 |

### Dimensiones

| Dimensión | Descripción | SCD Type |
|---|---|---|
| `dim_date` | Calendario completo con festivos MX | Tipo 1 (estática) |
| `dim_time` | Granularidad por hora | Tipo 1 (estática) |
| `dim_channel` | Canales de atención + defaults SLA | Tipo 1 |
| `dim_category` | Categorías con SLA targets | Tipo 2 (cambian SLAs) |
| `dim_subcategory` | Subcategorías jerárquicas | Tipo 1 |
| `dim_agent` | Agentes con equipo y turno | Tipo 2 (cambian de equipo) |
| `dim_customer` | Clientes externos (anonimizados) | Tipo 1 |
| `dim_employee` | Colaboradores internos | Tipo 2 |
| `dim_store` | Tiendas con región y estado | Tipo 1 |

---

## 📈 KPIs Monitoreados

### Clientes Externos

| KPI | Definición | Target | Fuente |
|---|---|---|---|
| **Volumen por canal** | Tickets creados por canal/día | Tracking | fact_tickets |
| **SLA Response %** | % tickets con 1ra respuesta en tiempo | > 95% | fact_tickets |
| **SLA Resolution %** | % tickets resueltos en tiempo | > 90% | fact_tickets |
| **FCR** | % resueltos en primer contacto | > 70% | fact_tickets |
| **AHT** | Tiempo promedio de manejo | < 30 min | fact_tickets |
| **Reincidence Rate** | % mismos clientes, mismo problema, ≤30 días | < 15% | fact_tickets |
| **NPS** | Net Promoter Score | > 50 | fact_tickets |
| **Sentiment Score** | Promedio de sentimiento por canal | > 0.3 | fact_tickets + IA |
| **Escalation Rate** | % tickets escalados | < 10% | fact_tickets |
| **AI Accuracy** | F1-score del clasificador por categoría | > 85% | modelo IA |

### Colaboradores Internos

| KPI | Target |
|---|---|
| **Backlog aging (> 30 días)** | 0% |
| **SLA cumplimiento interno** | > 85% |
| **Reincidencia interna** | < 10% |
| **Tickets duplicados detectados** | Tracking |
| **Tiempo resolución por área** | Benchmark por categoría |

---

## 🚀 Quick Start

> Esta sección se corrigió el 2026-07-06 para reflejar comandos que
> realmente existen en este checkout — la versión anterior refería
> scripts y archivos que nunca existieron aquí (`generate_external_tickets.py`,
> `scripts/init_db.py`, `etl/pipeline.py`, `requirements.txt`,
> `.env.example`, `ai/executive_summary/generator.py`). Ver `ESTADO_REAL.md`
> para el detalle de cada corrección.

### Prerrequisitos

```bash
Python 3.11+ (con faker, psycopg2-binary, numpy — para los scripts de
              data/synthetic/, que corren en el host, no en los contenedores)
Docker & Docker Compose
Power BI Desktop (si se quieren construir dashboards — no hay .pbix
                   incluidos en este checkout, ver Estructura del Proyecto)
Git
```

### Instalación

```bash
# 1. Clonar el repositorio
git clone <url-del-repo>
cd airflow-docker

# 2. Variables de entorno
cp .env.example .env
# .env.example ya trae AIRFLOW_UID y las credenciales de postgres-oxxo
# (DB_HOST, DB_NAME, DB_USER, DB_PASSWORD) que coinciden con
# docker-compose.yaml — no hace falta cambiar nada para el entorno local.

# 3. Levantar infraestructura
docker-compose up -d
# Levanta: Airflow (scheduler + worker + apiserver + dag-processor +
#          triggerer) + Postgres de metadatos de Airflow + postgres-oxxo
#          (DWH real, oxxo_cx_intelligence) + Redis.
# Airflow disponible en http://localhost:8080

# 4. Instalar dependencias Python (para correr scripts fuera de los contenedores)
pip install -r requirements-ai.txt
pip install faker psycopg2-binary numpy   # usados por data/synthetic/, no están en requirements-ai.txt
```

**Sobre el esquema del DWH (`dwh`, `audit`, `marts`, `staging`)**: este
checkout **no incluye el DDL para crearlo desde cero** — no hay carpeta
`sql/` ni `scripts/init_db.py`. El volumen `pgdata_oxxo` está declarado
`external: true` en `docker-compose.yaml` a propósito (para que
`docker-compose down -v` nunca lo borre), pero eso también significa que
Compose **no lo crea**: tiene que existir ya como volumen Docker con el
esquema y los datos cargados. En este entorno de desarrollo, `pgdata_oxxo`
ya contenía el esquema completo y 100,000 tickets del full-load del 29 de
junio (ver `ESTADO_REAL.md §3.2, §3.7`). Reproducir esto en una máquina
nueva sin ese volumen requeriría reconstruir el DDL a mano — queda
documentado como limitación real, no resuelta aquí.

### Generar datos y ejecutar el pipeline

Dos generadores distintos, para dos propósitos distintos — no confundir
uno con otro (ver `ESTADO_REAL.md §1`):

```bash
# A) Full-load real (100,000 tickets) directo a Postgres — requiere el
#    esquema ya creado (ver nota arriba)
python data/synthetic/generate_data.py --tickets 100000

# B) Muestra de 600 tickets con texto real (para probar el DAG de punta a
#    punta sin tocar la Postgres real). Corre en el host, no en los
#    contenedores — usa el corpus semilla de seed_corpus_clientes.py /
#    seed_corpus_colaboradores.py vía text_generator.py.
cd data/synthetic
python generate_ticket_samples.py --n 600
cd ../..
```

```bash
# Disparar el DAG (no hay un etl/pipeline.py standalone — la
# orquestación es Airflow, dags/cx_intelligence_pipeline.py)
docker exec airflow-docker-airflow-worker-1 airflow dags unpause cx_intelligence_pipeline
docker exec airflow-docker-airflow-worker-1 airflow dags trigger cx_intelligence_pipeline
# o desde la UI: http://localhost:8080 → cx_intelligence_pipeline → Trigger

# ─── Salida real de una corrida con la muestra de 600 (staging/*.jsonl,
#     ver ESTADO_REAL.md §2 para la corrida que produjo estos números) ───
# raw_external.jsonl          450
# raw_internal.jsonl          150
# validated_tickets.jsonl     600
# rejected_tickets.jsonl      0
# sla_calculated.jsonl        600
# reincidence_flagged.jsonl   600
# ai_classification.jsonl     600  (clasificador real, calibrado)
# ai_sentiment.jsonl          600  (sentiment real, TF-IDF+LogReg)
# ai_sla_risk.jsonl           109  (solo tickets open/in_progress/pending)
# dwh_snapshot.jsonl          600
# ──────────────────────────────────────────────────────────────────────
```

```bash
# (Opcional) Reentrenar/recalibrar el Ticket Classifier
cd data/synthetic
python train_classifier.py
# Sobrescribe ai/classifier/models/ticket_classifier.joblib y metrics_fase_b.json
```

**Resumen ejecutivo diario (Módulo 4)**: no implementado en este
checkout — ver Módulo 4 más abajo.

### Ejecución incremental

El DAG ya corre solo cada hora en horario de operación (`0 6-23 * * *`,
`dags/cx_intelligence_pipeline.py:56`) — no hay un modo `--incremental`
separado ni un `etl/pipeline.py` standalone. Para pausar/reanudar ese
cron:

```bash
docker exec airflow-docker-airflow-worker-1 airflow dags pause cx_intelligence_pipeline
docker exec airflow-docker-airflow-worker-1 airflow dags unpause cx_intelligence_pipeline
```

---

## 📦 Tech Stack Completo

| Capa | Tecnología | Versión | Propósito |
|---|---|---|---|
| Lenguaje | Python | 3.11 | ETL, IA, scripts |
| Base de datos | PostgreSQL | **16** | DWH principal |
| Orquestación | Apache Airflow | **3.2.2** | Scheduling del pipeline |
| Calidad de datos | Reglas hechas a mano (sin librería) | — | Mismas reglas que describiría Great Expectations (not-null, rango, unicidad, duplicados) implementadas directamente en Python — **la librería `great_expectations` no está instalada ni se usa** |
| ML Clásico | Scikit-learn | **1.8** | Clasificador de tickets |
| Boosting | XGBoost | 2.0 (fijado `<3`, ver nota¹) | Predictor de SLA |
| NLP Español | TF-IDF + Logistic Regression | — | Sustituto de `pysentimiento`/BERT (ver Módulo 2) |
| Calibración | CalibratedClassifierCV (sklearn) | sigmoid/Platt | Confianza real del Ticket Classifier (ver Módulo 1) |
| LLM | Anthropic Claude API | claude-sonnet-4-6 | Planeado para resúmenes ejecutivos — **no implementado en este checkout** (ver Módulo 4) |
| Serialización | joblib | 1.3 | Persistencia de modelos |
| Visualización | Power BI Desktop | Latest | Planeado para dashboards ejecutivos — **no hay `.pbix` en este checkout** (ver Estructura del Proyecto) |
| Contenedores | Docker Compose | 3.9 | Ambiente reproducible |
| CI/CD | GitHub Actions | — | Workflow referenciado, pendiente (sin tests que ejecutar — no existe carpeta `tests/`) |
| Análisis | Jupyter | — | Planeado para notebooks — **no hay carpeta `notebooks/` en este checkout** |

¹ `sla_breach_predictor.joblib` se serializó con XGBoost 2.x; deserializar con
3.x falla (`XGBoostError: input stream corrupted`, incompatibilidad de
formato entre majors). Confirmado: funciona con 2.1.4, falla con 3.3.0.

---

## 🗺️ Roadmap

```
Sprint 1 (Días 1-3)   ✅  Modelo de datos PostgreSQL + generador datos sintéticos
Sprint 2 (Días 4-6)   ✅  ETL: extract + validate (reglas propias, no GE) + transform
Sprint 3 (Días 7-9)   ✅  Load a DWH, dimensiones, fact_tickets funcional
Sprint 4 (Días 10-12) ✅  Clasificador NLP entrenado + Sentiment Analyzer
Sprint 5 (Días 13-15) ✅  SLA Predictor (XGBoost) + integración IA al pipeline
Sprint 6 (Días 16-18) ✅  Dashboard Power BI: CX Operations Board (5 páginas)
Sprint 7 (Días 19-21) ✅  Dashboard Power BI: Employee Service + AI Monitor
Sprint 8 (Días 22-24) ⚠️  Notebooks, documentación final, README (sin suite de
                          tests — no existe carpeta tests/ en este repo)

── Mejoras futuras (fuera del scope del POC) ──────────────────────────────────

v2.0  Upgrade clasificador a BERT multilingüe (mejor accuracy en edge cases)
v2.0  Airflow DAG con reintentos y alertas por Slack/email
v2.1  API REST (FastAPI) para clasificación de tickets en tiempo real
v2.1  Integración con Zendesk / Freshdesk via webhook
v3.0  BERTopic para topic modeling automático de tendencias emergentes
v3.0  Análisis de correlación: tickets de clientes vs. datos de tienda (ventas, inventario)
```

---

## 📁 Estructura del Proyecto

> El árbol de abajo es el contenido **real** de este checkout (verificado
> con `Get-ChildItem` el 2026-07-07, no una estructura aspiracional).
> Otras secciones de este README mencionan artefactos que **no existen en
> este repo todavía**: dashboards `.pbix`, notebooks, DDL en `sql/`,
> `ARCHITECTURE.md`/`DATA_MODEL.md`, `tests/`, y el workflow de CI
> (ver "Diagnóstico y lecciones del proceso" y `ESTADO_REAL.md`). No se
> listan aquí para no repetir la misma inconsistencia que se corrigió en
> el resto del documento.

```
airflow-docker/
│
├── 📄 README.md                          ← Este archivo
├── 📄 ESTADO_REAL.md                     ← Fuente de verdad del estado real del proyecto
│                                            (manda sobre este README mientras haya discrepancia)
├── 📄 FASE_B_RESULTADOS.md               ← Ticket Classifier: detalle por categoría,
│                                            calibración, barrido de umbrales
├── 📄 FASE_C_RESULTADOS.md               ← Sentiment Analyzer: detalle por clase +
│                                            snippet de migración a BERT real (no ejecutado)
├── 📄 FASE_D_RESULTADOS.md               ← SLA Predictor: SHAP por ronda, features de inferencia
├── 📄 docker-compose.yaml                ← Airflow (scheduler/worker/apiserver/triggerer) +
│                                            Postgres de metadatos + postgres-oxxo (DWH) + Redis
├── 📄 Dockerfile
├── 📄 requirements-ai.txt
├── 📄 .env.example                       ← Copiar a .env — no hace falta cambiar nada (ver Quick Start)
├── 📄 .gitignore / .dockerignore
│
├── 📂 config/
│   └── airflow.cfg
│
├── 📂 dags/
│   └── cx_intelligence_pipeline.py       ← DAG de Airflow (hourly, actualmente pausado)
│
├── 📂 data/
│   ├── synthetic/
│   │   ├── generate_data.py              ← Full-load sintético (100k tickets + dims + audit.*)
│   │   ├── generate_ticket_samples.py    ← Muestra de 600 con texto real (ids TEST-, sin colisión)
│   │   ├── seed_corpus_clientes.py       ← Corpus semilla: 10 categorías × 3 tonos (182 plantillas)
│   │   ├── seed_corpus_colaboradores.py  ← Corpus semilla: 10 categorías × 3 tonos (177 plantillas)
│   │   ├── text_generator.py             ← Motor de generación: slots, sinónimos, aperturas/cierres
│   │   ├── train_classifier.py           ← Entrena + calibra el Ticket Classifier (holdout por plantilla)
│   │   ├── train_sentiment.py            ← Entrena el Sentiment Analyzer (misma metodología)
│   │   └── train_sla_model.py            ← Entrena el SLA Predictor (dataset causal propio + experimento A/B)
│   ├── samples/
│   │   ├── external/                     ← facebook / instagram / whatsapp / email / chat_web (JSON)
│   │   └── internal/internal_tickets.csv
│   └── staging/                          ← Salida intermedia del pipeline (JSONL por etapa)
│
├── 📂 etl/
│   ├── extractors/
│   │   ├── base_extractor.py
│   │   ├── json_channel_extractor.py
│   │   └── csv_internal_extractor.py
│   ├── transformers/
│   │   ├── sla_calculator.py
│   │   └── reincidence_detector.py
│   ├── loaders/
│   │   └── postgres_loader.py
│   ├── validation/
│   │   └── expectations_suite.py         ← Reglas de calidad hechas a mano (no usa great_expectations)
│   └── common/
│       ├── catalog.py
│       ├── io.py
│       └── paths.py
│
├── 📂 ai/
│   ├── classifier/
│   │   ├── ticket_classifier.py          ← Wrapper de inferencia (modelo calibrado)
│   │   ├── metrics_fase_b.json           ← Métricas reales (+ .bak del corpus original de 147 plantillas)
│   │   └── models/ticket_classifier.joblib
│   ├── sentiment/
│   │   ├── sentiment_analyzer.py         ← TF-IDF + LogReg (sustituto de BERT)
│   │   ├── metrics_fase_c.json           ← Métricas reales (+ .bak del corpus original de 147 plantillas)
│   │   └── models/sentiment_analyzer.joblib
│   └── sla_predictor/
│       ├── sla_model.py                  ← XGBoost (7 features, reentrenado 2026-07-07)
│       ├── metrics_fase_d.json           ← Métricas reales (+ .bak del modelo previo a la reconstrucción)
│       └── models/sla_breach_predictor.joblib
│
└── 📂 monitoring/
    └── pipeline_monitor.py               ← Health check + historial de corridas
```

---

## 📄 Licencia

MIT License — libre para uso educativo y de portafolio.

---

<div align="center">

**Desarrollado como Proof of Concept de iniciativa de Transformación Digital en retail**

*Este proyecto utiliza datos completamente sintéticos generados para fines demostrativos.*
*No contiene información real de ninguna empresa u organización.*

<br>

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Conectar-0077B5?style=for-the-badge&logo=linkedin)](https://linkedin.com/in/cesar-rabago-perez)
[![GitHub](https://img.shields.io/badge/GitHub-Ver%20más%20proyectos-181717?style=for-the-badge&logo=github)](https://github.com/cesarrabago)

</div>
