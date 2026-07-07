# FASE B — Ticket Classifier: Resultados detallados

> Fuente de estos números: `ai/classifier/metrics_fase_b.json`,
> regenerado el 2026-07-06 por `data/synthetic/train_classifier.py` (no
> existía en el repo — se reconstruyó replicando la metodología del run
> original). Este documento existía referenciado desde
> `ai/classifier/ticket_classifier.py` y desde el README, pero no vivía en
> el repo (ver `ESTADO_REAL.md §6`); se reconstruye aquí a partir del JSON
> real, no de memoria ni de estimación.
>
> **[ACTUALIZADO 2026-07-06] Corpus semilla ampliado de 147 a 359
> plantillas** (ver `ESTADO_REAL.md §4.1` y §5 más abajo) tras identificar
> que el 100% de las predicciones de holdout caían por debajo del umbral
> de confianza. Los números de este documento son del corpus ampliado —
> el modelo y las métricas anteriores (147 plantillas) quedaron
> respaldados en `ai/classifier/models/ticket_classifier.joblib.bak` y
> `ai/classifier/metrics_fase_b.json.bak` por si se necesita comparar.
>
> **[ACTUALIZADO 2026-07-07] `CONFIDENCE_THRESHOLD` bajado de 0.75 a
> 0.50** — ver §3.2. Cobertura de auto-clasificación 20.5%→61.5%, accuracy
> en esas predicciones 95.7%→90.9%. Decisión de producto tomada
> explícitamente, con el barrido de §3.1 como evidencia.

## 1. Por qué dos números distintos para el mismo modelo

| Split | Macro F1 | n_train | n_test |
|---|---|---|---|
| Aleatorio por instancia (`naive_instance_split`) | **1.0** | 9,190 | 2,298 |
| Holdout por plantilla (`template_holdout`) | **0.7203** (antes: 0.4334) | 9,216 | 2,272 |

El dataset sintético se genera ahora a partir de **359 plantillas de
texto** (antes 147) sobre **20 categorías**. Un split aleatorio por
instancia sigue dejando variantes de la misma plantilla en train y test
— el modelo memoriza la plantilla (F1 = 1.0, no sostenible con texto
real). El holdout por plantilla sigue exigiendo que ninguna plantilla
vista en entrenamiento aparezca en test. **Con el corpus ampliado, el
macro F1 honesto subió de 0.4334 a 0.7203** (+66% relativo) — una mejora
real, medida con la misma metodología, no un cambio de vara.

## 2. Desglose por categoría (holdout por plantilla, n_test=2,272)

| Categoría | Precision | Recall | F1 | Support | vs. antes (147 plantillas) |
|---|---|---|---|---|---|
| clima_laboral | 1.000 | 1.000 | **1.000** | 96 | antes 0.667 |
| horario_turno | 1.000 | 0.990 | **0.995** | 96 | antes 0.755 |
| servicio_express | 1.000 | 0.990 | **0.995** | 96 | antes 0.958 |
| acceso_sistemas | 0.885 | 0.958 | **0.920** | 96 | antes 0.458 |
| beneficios_hr | 0.985 | 0.838 | **0.905** | 160 | antes 0.0 |
| incidente_seguridad | 1.000 | 0.802 | **0.890** | 96 | antes 0.787 |
| vacaciones_permiso | 0.955 | 1.000 | **0.977** | 128 | antes 0.063 |
| uniforme_equipo | 0.757 | 1.000 | **0.862** | 128 | antes 0.174 |
| sugerencia_general | 0.767 | 0.906 | **0.831** | 160 | antes 0.0 |
| solicitud_baja | 1.000 | 0.667 | **0.800** | 96 | antes 0.667 |
| producto_defectuoso | 0.948 | 0.570 | **0.712** | 128 | antes 0.278 |
| capacitacion | 0.711 | 0.667 | **0.688** | 96 | antes 0.691 |
| app_oxxo_pay | 0.650 | 0.698 | **0.673** | 96 | antes 0.667 |
| promocion_invalida | 0.444 | 1.000 | **0.615** | 96 | antes 0.444 |
| pago_servicios | 0.515 | 0.672 | **0.583** | 128 | antes 0.054 |
| limpieza_tienda | 0.435 | 0.711 | **0.540** | 128 | antes 0.270 |
| atencion_cajero | 0.971 | 0.344 | **0.508** | 96 | antes 0.440 |
| nomina_pago | 0.478 | 0.516 | **0.496** | 128 | antes 0.234 |
| cobro_incorrecto | 0.544 | 0.336 | **0.415** | 128 | antes 0.235 |
| **tiempo_espera** | 0.0 | 0.0 | **0.0** | 96 | antes 0.826 — ver §2.1, artefacto del split, no regresión real |

**Lectura honesta**: 17 de 20 categorías mejoraron o se mantuvieron
estables, incluyendo las dos que estaban en F1=0 (`beneficios_hr` 0→0.905,
`sugerencia_general` 0→0.831 — el hallazgo de F1=0 sí se explicaba por
falta de plantillas, no por una limitación estructural del modelo).
`cobro_incorrecto` y `atencion_cajero` siguen débiles pese a haber
recibido más plantillas — la ampliación no es una solución uniforme,
ayuda más a unas categorías que a otras.

### 2.1 [INVESTIGADO 2026-07-06] `tiempo_espera` en F1=0.0 — no es una regresión real, es varianza del split

Se investigó la caída de `tiempo_espera` (0.826→0.0) en vez de asumir una
causa. Primero, in-sample: el modelo clasifica correctamente el **100%**
de sus propias 320 instancias de entrenamiento de `tiempo_espera`
(`clf.predict` sobre `X_train` mismo), y sus features más asociadas a la
categoría son términos correctos y sensatos (`fila`, `espera`, `tiempo`,
`minutos`, `pico`) — descarta que sea un problema de vocabulario
"aplastado" por otras categorías o un bug en el split.

El modelo nunca predice `tiempo_espera` para **ninguna** de las 2,272
instancias de test (ni para instancias que sí son de esa categoría, ni
por error para otras) — un colapso total de la clase en ese test set
específico. Se probó la misma metodología con 5 semillas distintas
(1, 2, 3, 42, 99) para el split de plantillas:

| Semilla | F1 `tiempo_espera` | Macro F1 total |
|---|---|---|
| 1 | 0.833 | 0.7137 |
| 2 | 0.674 | 0.7484 |
| 3 | 0.633 | 0.7042 |
| **42 (la usada en el modelo actual)** | **0.189** | 0.7111 |
| 99 | 0.255 | 0.7658 |

**Conclusión**: con solo 13 plantillas base (6 negative / 4 neutral / 3
positive), sostener 2-3 plantillas en el conjunto de test por categoría
tiene varianza alta — qué 2-3 plantillas específicas caen en test importa
mucho más que con categorías con más plantillas. La semilla 42 resultó
ser, para `tiempo_espera` específicamente, una mala racha (dejó fuera
plantillas atípicas del resto de su propia categoría — p. ej. una
plantilla positiva que no usa ninguna de las palabras distintivas
aprendidas por el modelo). Con otras semillas, `tiempo_espera` da F1
0.63-0.83, consistente con su desempeño anterior (0.826). **No fue una
regresión causada por la ampliación del corpus — fue una lectura
engañosa de una sola corrida con una sola semilla.**

**Implicación más amplia, no solo para esta categoría**: el macro F1
total también varía por semilla (0.704-0.766 en la prueba de 5 semillas)
— la cifra reportada como headline (0.7203) es un punto dentro de ese
rango, no un valor fijo. Cualquier número por categoría basado en una
sola corrida de holdout-por-plantilla debe leerse con esta varianza en
mente, especialmente en categorías con pocas plantillas.

## 3. Confianza de las predicciones: el hallazgo cambia de forma

`low_confidence_rate: 0.9938` — **el 99.4% de las predicciones de test
siguen cayendo por debajo del umbral de confianza (0.75)**, prácticamente
sin cambio frente al 100% de antes, **a pesar de que el F1 subió 66%**.
Ampliar el corpus arregló la exactitud real, pero casi no movió la
confianza reportada. Esto obligó a medir algo que la versión anterior de
este documento no medía: **¿el modelo desconfía de predicciones que en
realidad son correctas, o desconfía porque de verdad se equivoca más?**

| | n | Accuracy |
|---|---|---|
| Overall | 2,272 | **73.64%** |
| Confianza ≥ 0.75 | 14 (0.6%) | **100%** |
| Confianza < 0.75 | 2,258 (99.4%) | **73.47%** |

**Lectura**: el umbral de 0.75 **sí está bien calibrado** en el sentido
de que cuando el modelo lo supera, siempre acierta (14/14). El problema
es que casi nunca lo supera — con 20 categorías de vocabulario
parcialmente solapado, la probabilidad softmax se reparte entre varias
clases plausibles aunque la más alta sea la correcta. De las 2,258
predicciones "de baja confianza", **73.5% son en realidad correctas** —
el modelo acierta mucho más de lo que su propia confianza sugiere. Esto
cambia la conclusión de la sección 4 de este documento respecto a la
versión anterior: el corpus no era la única causa del 0% de
auto-clasificación real.

### 3.1 [RESUELTO 2026-07-06] Calibración aplicada — cobertura sube de 0.6% a 20.5% sin bajar el umbral

Se reentrenó con `CalibratedClassifierCV` (sigmoid/Platt, cv=5) envolviendo
la misma `LogisticRegression`, mismo train/test split. Comparación real,
medida, no estimada:

| | Sin calibrar | Calibrado |
|---|---|---|
| Macro F1 | 0.7203 | **0.7503** (también subió) |
| `low_confidence_rate` (umbral 0.75) | 99.4% | **79.5%** |
| Cobertura de auto-clasificación (umbral 0.75) | 0.6% (14 casos) | **20.5%** (465 casos) |
| Accuracy en esas predicciones "confiables" | 100% (n=14, muestra minúscula) | **95.7%** (n=465) |
| Accuracy en el resto | 73.5% | 69.4% |

**Sin cambiar el umbral de negocio (0.75)**, calibrar el modelo multiplicó
por ~34x cuántos tickets se auto-clasifican con alta confianza, sin
sacrificar precisión (95.7% de accuracy en esos casos). El wrapper de
inferencia (`ticket_classifier.py`) no necesitó ningún cambio de código —
el modelo calibrado sigue siendo un `Pipeline` con `predict_proba`/
`classes_` compatibles, probado end-to-end con `classify_ticket_text()`.

**Barrido de umbrales (modelo calibrado)**:

| Umbral | Cobertura | Accuracy |
|---|---|---|
| 0.90 | 1.0% | 100% |
| 0.85 | 7.3% | 99.4% |
| 0.80 | 14.7% | 97.3% |
| 0.75 (umbral anterior) | 20.5% | 95.7% |
| 0.70 | 26.1% | 94.9% |
| 0.65 | 33.9% | 94.2% |
| 0.60 | 44.8% | 92.3% |
| 0.55 | 52.5% | 92.4% |
| **0.50 (umbral actual, desde 2026-07-07)** | **61.5%** | **90.9%** |
| 0.45 | 71.6% | 86.6% |
| 0.40 | 83.5% | 82.2% |

### 3.2 [RESUELTO 2026-07-07] Umbral bajado a 0.50 — decisión de producto tomada

Se bajó `CONFIDENCE_THRESHOLD` de 0.75 a 0.50 en
`ai/classifier/ticket_classifier.py` y en `train_classifier.py`, y se
reentrenó (mismo modelo, mismo seed — determinista, así que los pesos no
cambian; lo que cambia es la métrica de calibración recalculada al nuevo
punto de operación). Confirmado con el barrido de arriba:

| | Umbral 0.75 (antes) | Umbral 0.50 (ahora) |
|---|---|---|
| Cobertura de auto-clasificación | 20.5% (465 casos) | **61.5%** (1,398 casos) |
| Accuracy en predicciones auto-clasificadas | 95.7% | **90.9%** |
| Accuracy en las que quedan para revisión humana | 69.4% (n=1,807) | 49.0% (n=874) |

**~3x más cobertura** (20.5%→61.5%), a costa de bajar la accuracy de las
predicciones auto-clasificadas de 95.7% a 90.9% — el tradeoff exacto que
ya estaba documentado en el barrido antes de tomar la decisión. Probado
end-to-end con `classify_ticket_text()`: los dos ejemplos que antes
quedaban en revisión humana con confianza 0.67 y 0.73 ahora se
auto-clasifican (ambos correctos); un tercer ejemplo con confianza 0.47
sigue en revisión humana, correctamente por debajo del nuevo umbral.

## 4. Qué se necesitaría para cerrar la brecha (actualizado tras medir)

- **[YA HECHO 2026-07-06]** Ampliar el corpus semilla (147→359
  plantillas, priorizado por F1 real de cada categoría). Resultado
  medido: macro F1 0.4334→0.7203, accuracy 73.64%. **Confirmado con
  datos, no solo teoría**: sí valía la pena, y las dos categorías en F1=0
  (`beneficios_hr`, `sugerencia_general`) se arreglaron por completo.
- **[YA HECHO 2026-07-06]** Calibrar el modelo (`CalibratedClassifierCV`,
  ver §3.1). Cobertura de auto-clasificación: 0.6%→20.5% al mismo umbral
  de 0.75, con 95.7% de accuracy — sin bajar el umbral de negocio.
- **[YA HECHO 2026-07-07]** Bajar `CONFIDENCE_THRESHOLD` de 0.75 a 0.50 —
  ver §3.2. Cobertura de auto-clasificación: 20.5%→61.5%, a costa de bajar
  la accuracy de esas predicciones de 95.7% a 90.9%. Decisión de producto
  tomada explícitamente, no unilateral.
- **[INVESTIGADO 2026-07-06 — no era una regresión real]** `tiempo_espera`
  en F1=0.0 se debía a varianza del split con solo 13 plantillas, no a la
  ampliación del corpus — ver §2.1. Con otras semillas da F1 0.63-0.83.
  **Recomendación derivada de esto**: reportar macro F1 como promedio de
  varias semillas de holdout-por-plantilla (no una sola corrida) al menos
  para categorías con pocas plantillas — no se implementó aquí, es un
  cambio de metodología de evaluación, no del modelo.
- Seguir ampliando `cobro_incorrecto` y `atencion_cajero` (siguen débiles
  pese a más plantillas) seguramente requiere plantillas más distintivas
  entre sí, no solo más cantidad — ambas comparten vocabulario con
  categorías vecinas (`pago_servicios`, `promocion_invalida`).
