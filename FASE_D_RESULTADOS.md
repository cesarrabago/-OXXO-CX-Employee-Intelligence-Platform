# FASE D — SLA Breach Predictor: Resultados detallados

> Fuente original de los números de §1-2: `ai/sla_predictor/metrics_fase_d.json`
> tal como existía el 2026-07-02 (respaldado en `metrics_fase_d.json.bak`
> antes de sobrescribirlo). Documento referenciado desde
> `ai/sla_predictor/sla_model.py` pero ausente del repo (ver
> `ESTADO_REAL.md §6`); se reconstruyó aquí originalmente a partir de ese
> JSON.
>
> **[HALLAZGO 2026-07-07] El código del "fix causal" también se había
> perdido, no solo este documento.** Al intentar mejorar el SLA Predictor
> siguiendo las recomendaciones de §5, se encontró que `generate_times()`
> en `data/synthetic/generate_data.py` **sigue con el volado fijo de ~74%
> sin relación a ninguna feature** (la lógica de la ronda `baseline`) — el
> parche que ató `resolution_sla_met` a hora pico/categoría/canal/fin de
> semana (ronda `causal_fix`, AUC 0.5594) nunca quedó guardado en el
> repo, ni tampoco `train_sla_model.py`. Ver §2.5 para lo que se hizo al
> respecto: una reconstrucción nueva, con un experimento controlado que sí
> responde la pregunta abierta de §5 (los §1-2 de abajo quedan como
> registro histórico del modelo/JSON que existían antes de esta sesión,
> no como el estado actual del modelo desplegado).

## 1. [HISTÓRICO — modelo/JSON de antes del 2026-07-07] Dos rondas, una fuga causal de por medio

| Ronda | AUC-ROC | Breach rate | n_train | n_test |
|---|---|---|---|---|
| `baseline` | **0.4862** (≈ azar) | 38.0% | 10,761 | 3,587 |
| `causal_fix` | **0.5594** | 45.4% | 10,776 | 3,593 |

**Ronda `baseline`**: `resolution_sla_met` en `generate_data.py` se
decidía con un volado fijo (~74% de probabilidad de cumplir SLA), **sin
relación real con ninguna feature disponible al momento de crear el
ticket**. Un modelo no puede aprender de una etiqueta que es
estructuralmente independiente de sus features — de ahí el AUC ≈ 0.49,
prácticamente indistinguible de azar.

**Ronda `causal_fix`**: se parchó `generate_times()` para que la
probabilidad de incumplimiento dependa de hora pico, complejidad de
categoría, canal y fin de semana — factores que el modelo sí puede ver
como features. El AUC subió a 0.5594: una señal real y reproducible por
encima del azar, pero modesta. **El 0.823 que documentaba el plan
original no es un número medido en ninguna ronda de este proyecto.**

## 2. [HISTÓRICO] Features más importantes por ronda (SHAP, mean |valor|)

**Baseline** (antes del fix causal — el modelo se apoya en ruido, ya que
la etiqueta no depende de features reales):

| # | Feature | Mean \|SHAP\| |
|---|---|---|
| 1 | hour_of_day | 0.0802 |
| 2 | day_of_week | 0.0485 |
| 3 | category_key_1 | 0.0329 |
| 4 | channel_key_1 | 0.0265 |
| 5 | priority | 0.0193 |

**Causal fix** (tras el parche — el ranking se reordena y `hour_of_day`
se vuelve aún más dominante, consistente con que el fix inyectó
dependencia explícita en hora pico):

| # | Feature | Mean \|SHAP\| |
|---|---|---|
| 1 | hour_of_day | 0.1718 |
| 2 | day_of_week | 0.0636 |
| 3 | channel_key_3 | 0.0545 |
| 4 | category_key_4 | 0.0386 |
| 5 | category_key_1 | 0.0313 |

**Lectura**: `hour_of_day` es, en ambas rondas, el feature más influyente
— y su peso casi se duplica (0.080 → 0.172) tras el fix causal, lo cual
es consistente con que el parche de `generate_times()` ató explícitamente
el incumplimiento a "hora pico". Esto no prueba que el modelo aprendió la
relación *correcta*, solo que el feature que el fix hizo relevante es,
en efecto, el que el modelo más usa — evidencia indirecta a favor del
fix, no una validación causal completa.

## 2.5 [2026-07-07] El código del fix causal estaba perdido — reconstrucción + experimento controlado sobre las recomendaciones de §5

Al intentar implementar las recomendaciones de §5 (agregar carga del
agente, historial de SLA por categoría, longitud del mensaje), se
encontró que **no había nada que extender**: `generate_times()` en
`data/synthetic/generate_data.py` nunca tuvo el parche causal guardado —
sigue siendo la versión `baseline` (volado fijo ~74%, sin relación a
ninguna feature). Tampoco existía `train_sla_model.py`. El AUC=0.5594 de
`causal_fix` en §1 es un número real que se midió en su momento, pero el
código exacto que lo produjo se perdió — mismo patrón que Fase B/C, pero
aquí afectó al generador de datos, no solo al script de entrenamiento.

**Qué se hizo**: se reconstruyó `data/synthetic/train_sla_model.py`
(mismo patrón que `train_classifier.py`/`train_sentiment.py` — genera su
propio dataset sintético, no toca `generate_data.py` ni Postgres) con una
reconstrucción *cualitativa* razonable de la estructura causal descrita
en §1 (hora pico, complejidad de categoría, canal, fin de semana). **Esta
reconstrucción no pretende reproducir 0.5594 al dígito** — son pesos
inventados de nuevo, no el código original perdido. Se documenta como tal
en el propio script.

**Aprovechando que había que reconstruir el generador desde cero, se
diseñó un experimento controlado para responder la pregunta abierta de
§5**: sobre el *mismo* dataset causal reconstruido, se entrenaron dos
modelos —

| Modelo | Features | AUC-ROC |
|---|---|---|
| A — originales | priority, hour_of_day, day_of_week, is_weekend, has_agent, channel_key, category_key | **0.6475** |
| B — + 3 candidatas de §5 | A + agent_load, category_recent_breach_rate, message_length_chars | **0.6492** |

Delta: **+0.0018**. Verificado con 5 semillas distintas (1, 2, 3, 42, 99)
para no repetir el error de leer un solo split como si fuera la verdad
(misma lección que `tiempo_espera` en `FASE_B_RESULTADOS.md §2.1`):

| Semilla | Delta (B − A) |
|---|---|
| 1 | −0.0033 |
| 2 | +0.0054 |
| 3 | +0.0001 |
| 42 | +0.0018 |
| 99 | +0.0054 |

Promedio: **+0.0019** (std 0.0033) — el delta está dentro de 1 desviación
estándar de cero. **Conclusión honesta: las 3 features candidatas de §5
no mueven el AUC de forma distinguible del ruido, ni siquiera en un
experimento donde se construyeron a propósito con un efecto causal real
y no nulo sobre la etiqueta.** No es que sean malas ideas — es que, dado
el resto de las features ya disponibles (especialmente `category_key` y
`hour_of_day`, que ya capturan buena parte de la señal que
`category_recent_breach_rate` y `agent_load` intentarían aportar), el
XGBoost ya extrae casi toda la señal aprovechable de este espacio de
features. La brecha al 0.82 planeado no se cierra solo agregando estas
tres.

**Decisión de despliegue**: el Modelo B **no se desplegó** — requeriría
que `sla_model.py` calculara `agent_load`/`category_recent_breach_rate`/
`message_length_chars` en tiempo real (el wrapper actual no lo hace, y
`row_num` en `predict_breach_probability()` está hardcodeado a las 5
features originales; usar el bundle de B ahí habría lanzado `KeyError`).
Sin un beneficio claro, no se justifica esa complejidad adicional. Se
desplegó el **Modelo A** (mismo contrato que ya esperaba
`sla_model.py`), probado end-to-end con `predict_breach_probability()`
sobre un ticket de ejemplo — funciona sin cambios de código.

**Nota importante sobre comparabilidad**: el AUC=0.6475 del Modelo A
desplegado hoy **no es directamente comparable** al 0.5594 histórico de
§1 — vienen de datasets sintéticos distintos (pesos causales
reconstruidos de forma independiente, no el código original). No se
reporta esto como "mejoramos el SLA Predictor de 0.56 a 0.65"; se reporta
como "el modelo desplegado hoy, medido con esta reconstrucción, da
0.6475" — la comparación válida y con evidencia real es la interna
(Modelo A vs. Modelo B, mismo dataset, mismo split), no la externa contra
el número de julio. Respaldo del modelo/métricas de antes de esta sesión
en `ai/sla_predictor/models/sla_breach_predictor.joblib.bak` y
`ai/sla_predictor/metrics_fase_d.json.bak`.

## 3. Features usadas en entrenamiento (contrato de inferencia)

De `predict_breach_probability()` (`ai/sla_predictor/sla_model.py:52-84`)
— **sin cambios tras el reentrenamiento de hoy**, el modelo desplegado
sigue usando exactamente estas 7 features:

- **Numéricas**: `priority`, `hour_of_day`, `day_of_week`, `is_weekend`,
  `has_agent` (booleano: ¿el ticket ya tiene agente asignado?).
- **Categóricas (one-hot)**: `channel_key`, `category_key` — de ahí los
  nombres `channel_key_N` / `category_key_N` en las tablas SHAP de §2.

## 4. Nota de compatibilidad de versión (no relacionada con el AUC)

`sla_breach_predictor.joblib` se serializó con **XGBoost 2.x**;
deserializar con 3.x falla (`XGBoostError: input stream corrupted`,
incompatibilidad de formato entre majors). Confirmado: funciona con
2.1.4, falla con 3.3.0 (ver también README, Tech Stack, nota 1). Esto es
un problema de serialización, no de calidad del modelo — no afecta al
AUC reportado arriba, pero sí a poder cargarlo en un entorno con XGBoost
3.x sin re-entrenar.

## 5. [ACTUALIZADO 2026-07-07] Qué acercaría esto al 0.82 planeado

Las tres recomendaciones originales de esta sección (carga del agente,
historial de SLA por categoría, longitud del mensaje) **ya se probaron
— ver §2.5 — y no ayudaron** (delta +0.0019, indistinguible de ruido en
5 semillas). No se descartan por malas ideas conceptualmente, pero la
evidencia de un experimento controlado no las respalda como vía para
cerrar la brecha al 0.82. Candidatos que **no** se han probado todavía:

- **Interacciones entre features** (p. ej. categoría × hora pico como
  feature explícita, no solo dejar que el árbol las encuentre solo) —
  XGBoost ya captura interacciones hasta `max_depth`, así que el techo
  real de esta vía no está claro sin probarla.
- **Más datos**: el experimento de §2.5 usa ~14,350 filas sintéticas: no
  se probó si un dataset más grande (100k+, como el de producción) sube
  el AUC o si el techo de ~0.65 es del espacio de features, no del
  tamaño de muestra.
- **Reconsiderar si 0.82 fue nunca un objetivo realista para este
  problema** — con un espacio de 7-10 features de esta naturaleza (sin
  texto, sin historial real de agentes), un AUC en el rango 0.55-0.65
  podría ser el techo genuino, no una limitación de ingeniería
  corregible. Esta pregunta no se resuelve aquí — es una decisión de
  producto/expectativas, no algo para asumir unilateralmente.
- Ninguna de estas tres se ha probado en este proyecto — quedan como
  candidatas para una futura sesión, no como hoja de ruta validada.
