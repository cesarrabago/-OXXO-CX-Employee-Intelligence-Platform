# FASE C — Sentiment Analyzer: Resultados detallados

> Fuente de estos números: `ai/sentiment/metrics_fase_c.json`,
> regenerado el 2026-07-07 por `data/synthetic/train_sentiment.py` (no
> existía en el repo). Documento referenciado desde
> `ai/sentiment/sentiment_analyzer.py` (sección 5, snippet BERT) pero
> ausente del repo (ver `ESTADO_REAL.md §6`); se reconstruye aquí.
>
> **[ACTUALIZADO 2026-07-07] Reentrenado con el corpus ampliado** (147→359
> plantillas, ver `FASE_B_RESULTADOS.md`). Este módulo había quedado
> desactualizado tras la ampliación del corpus para Fase B (mismos
> archivos `seed_corpus_clientes.py`/`seed_corpus_colaboradores.py`,
> compartidos entre ambos módulos) — el modelo y las métricas anteriores
> (corpus de 147 plantillas, entrenado 2026-07-02) quedaron respaldados
> en `ai/sentiment/models/sentiment_analyzer.joblib.bak` y
> `ai/sentiment/metrics_fase_c.json.bak`.

## 1. Por qué este modelo sí sostiene su número bajo evaluación honesta

| Split | Macro F1 | n_train | n_test |
|---|---|---|---|
| Aleatorio por instancia (`naive_instance_split`) | 1.0 (inflado, misma fuga que Fase B) | 9,190 | 2,298 |
| Holdout por plantilla (`template_holdout`) | **0.9898** (antes: 0.9515, corpus de 147 plantillas) | 9,216 | 2,272 |

A diferencia del clasificador de tickets (Fase B), la tarea de sentimiento
(negative/neutral/positive) es más simple y con señales léxicas más
directas (palabras claramente positivas/negativas) — el macro F1 ya era
alto con el corpus original (0.9515) y **subió más** con el corpus
ampliado (**0.9898**), sin ningún síntoma como la regresión puntual que
sí apareció en Fase B (`tiempo_espera`) — las tres clases mejoraron de
forma consistente (ver §2).

## 2. Desglose por clase (holdout por plantilla, n_test=2,272)

| Clase | Precision | Recall | F1 | Support | vs. antes (147 plantillas) |
|---|---|---|---|---|---|
| negative | 0.991 | 0.997 | **0.994** | 928 | antes 0.981 |
| neutral | 0.982 | 0.994 | **0.988** | 704 | antes 0.899 |
| positive | 0.998 | 0.977 | **0.987** | 640 | antes 0.974 |

**Lectura**: el modelo sigue siendo prácticamente perfecto en las tres
clases; el que era su punto más débil (`neutral`, precision 0.826 antes)
mejoró de forma notable (0.982) — consistente con que más plantillas le
dieron más ejemplos de vocabulario "neutral" que antes eran escasos.

## 3. Por qué no es el BERT planeado originalmente

El modelo en producción es **TF-IDF + Logistic Regression**, no
`pysentimiento/robertuito-sentiment-analysis` (BERT en español) como
documentaba el plan original. Razón operativa, no de diseño:

- `huggingface.co` está fuera del allowlist de egress del sandbox de
  entrenamiento — **403 confirmado** al intentar descargar el modelo.
- `pysentimiento` arrastra `torch` + CUDA (~3.5 GB), que agotó el disco
  disponible a medio instalar.

## 4. Contrato de compatibilidad

`analyze_text()` (`ai/sentiment/sentiment_analyzer.py:43-53`) devuelve
`{"sentiment_label": str, "sentiment_score": float}`, con
`sentiment_score = P(positive) - P(negative)`. `aggregate_ticket_sentiment()`
(líneas 56-77) opera solo sobre las etiquetas por interacción, ponderando
las más recientes — es agnóstico a qué modelo generó esas etiquetas. El
día que este proyecto corra en una máquina con internet y disco
completos, el reemplazo es un cambio de modelo, no de contrato.

## 5. Snippet propuesto para migrar a BERT real (no ejecutado ni medido aquí)

Este snippet **no se ha corrido** en este entorno (bloqueado por el 403
de egress, ver §3) — se documenta como referencia de la migración
pendiente, respetando el mismo contrato de `analyze_text()`:

```python
# ai/sentiment/sentiment_analyzer_bert.py (propuesto, no implementado)
from pysentimiento import create_analyzer

_analyzer = create_analyzer(task="sentiment", lang="es")

_LABEL_MAP = {"POS": "positive", "NEG": "negative", "NEU": "neutral"}


def analyze_text_bert(text: str) -> dict:
    """Mismo contrato que analyze_text() (TF-IDF+LogReg): {sentiment_label, sentiment_score}."""
    result = _analyzer.predict(text)
    label = _LABEL_MAP[result.output]
    score = result.probas["POS"] - result.probas["NEG"]
    return {"sentiment_label": label, "sentiment_score": round(float(score), 3)}
```

Para activar esta ruta: instalar `pysentimiento` + `torch` (requiere
disco y egress a `huggingface.co` habilitados), y sustituir la
implementación de `analyze_text()` por `analyze_text_bert()` — sin tocar
`aggregate_ticket_sentiment()` ni el resto del pipeline, ya que el
contrato de entrada/salida es idéntico.
