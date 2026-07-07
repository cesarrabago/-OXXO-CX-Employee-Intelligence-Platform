# ESTADO_REAL.md

> Fuente única de verdad del estado **actual** del proyecto. Este documento
> no reemplaza al README (Fase G, decisión aparte) — mientras esa fase no
> ocurra, lo que dice este archivo manda sobre lo que diga o no diga el
> README.
>
> Última actualización: 2026-07-07. **§4.4: el Sentiment Analyzer (Fase C)
> se reentrenó con el corpus ampliado — había quedado desactualizado tras
> el trabajo de Fase B (mismos archivos de corpus). F1 0.9515→0.9898, sin
> regresiones. §8.6: el árbol de estructura del README volvió a
> desactualizarse (le faltaba `train_sentiment.py`) — ya corregido, y
> anotado como patrón a vigilar en sesiones futuras. §4.5: al atacar el
> SLA Predictor, se encontró que el código del "fix causal" (no solo el
> script de entrenamiento) también se había perdido — se reconstruyó
> `train_sla_model.py` y se probó, con un experimento controlado de 5
> semillas, si las 3 features candidatas de `FASE_D_RESULTADOS.md §5`
> ayudarían: **no** (+0.0019 AUC promedio, ruido). Se desplegó el modelo
> con las features originales (compatible con el wrapper), no el que las
> incluye. §4.6: se bajó `CONFIDENCE_THRESHOLD` de 0.75 a 0.50 (decisión
> de producto pedida explícitamente) — cobertura de auto-clasificación
> 20.5%→61.5%, accuracy en esas predicciones 95.7%→90.9%.**
>
> Resto del historial (2026-07-06) — incluye un incidente real: al corregir
> el bug de `customer_key` y reintentar la carga contra Postgres, una
> muestra de prueba sobrescribió 600 filas del dataset real de 100k por
> colisión de `ticket_id`. Ver §3.4-3.5 antes de asumir que "bug arreglado"
> = "todo bien" — léase completo, no solo el checkbox. `data/samples/` ya
> se regeneró con ids `TEST-` sin colisión (§3.6), y `postgres-oxxo` ya
> quedó formalizado en `docker-compose.yaml` sobre su volumen real,
> `pgdata_oxxo` (§3.7) — `dwh.fact_tickets` confirmado en 100,000 antes y
> después, sin cambios. §3.8: la carga limpia de principio a fin
> (100,000→100,600) ya ocurrió, sola, vía el cron horario, antes de que se
> pidiera dispararla a mano — el DAG queda **pausado** desde ahora.
> **§8: `README.md` ya existe, corregido y consistente (incluye el
> hallazgo de 0% de auto-clasificación real, no 98.1% — ver §4.1). Docker
> Desktop dejó de responder tras un ENOSPC (§8.2); tras el reinicio de la
> PC, la checklist de §8.3 se verificó completa (100,600 filas,
> `pgdata_oxxo` intacto, `postgres-oxxo` healthy, DAG pausado) y el riesgo
> de espacio en `C:` (1.88 GB libres) también se resolvió: vdisk de Docker
> movido a `D:`, `C:` con 15.64 GB libres. Los `FASE_{B,C,D}_RESULTADOS.md`
> se reconstruyeron a partir de métricas reales encontradas en `ai/`
> (§6). El log de calidad simulado se corrigió en código y en el registro
> histórico (§5.1). **§4.2-4.3: se amplió el corpus semilla del
> clasificador (147→359 plantillas, F1 0.4334→0.7203) y se calibró el
> modelo (`CalibratedClassifierCV`), que era el problema real de
> confianza (no el tamaño de corpus) — cobertura de auto-clasificación
> 0.6%→20.5% al mismo umbral de 0.75, con 95.7% de accuracy, F1 final
> 0.7503. La aparente regresión de `tiempo_espera` (F1 0.826→0.0) se
> investigó y resultó ser varianza del split, no un efecto real (§4.2).
> A la fecha de esta actualización, no queda ningún punto abierto en §7.**

## 1. Qué corrió hoy y sobre qué datos (no confundir)

Hoy corrió el DAG `cx_intelligence_pipeline` dos veces:

| run_id | trigger | hora (UTC) |
|---|---|---|
| `scheduled__2026-07-03T22:00:00+00:00` | cron horario | 22:00 |
| `manual__2026-07-03T22:22:44.466778+00:00` | manual | 22:22 |

Ambas corridas procesaron **los 600 tickets de muestra en `data/samples/`**
(`data/samples/external/*.json` + `data/samples/internal/internal_tickets.csv`),
generados por `data/synthetic/generate_ticket_samples.py --n 600 --seed 42`
(450 externos / 150 internos).

Esto **no tiene nada que ver** con los **100,000 tickets reales** que ya
están cargados en `dwh.fact_tickets` desde el full-load de
`data/synthetic/generate_data.py` del 29 de junio. Son dos datasets
distintos, generados por dos scripts distintos, en dos momentos distintos:

- `generate_data.py` → dataset completo (100k), pensado para cargar
  directo a Postgres (`dwh.fact_tickets` + dims + `audit.*`).
- `generate_ticket_samples.py` → muestra de 600 con texto real, pensada
  para alimentar `etl/extractors/` **sin** Postgres, útil para correr el
  DAG de punta a punta en local.

No confundir "el pipeline corrió hoy" con "hay datos nuevos en el DWH" —
hoy no se tocó `dwh.fact_tickets` en absoluto (ver §3).

## 2. Resultado real de la corrida de hoy, por etapa

De `data/staging/pipeline_monitor_history.json` (recalculado por
`refresh_aggregates` en ambas corridas, mismo resultado):

| etapa (staging) | registros |
|---|---|
| `raw_external.jsonl` | 450 |
| `raw_internal.jsonl` | 150 |
| `validated_tickets.jsonl` | 600 |
| `rejected_tickets.jsonl` | 0 |
| `sla_calculated.jsonl` | 600 |
| `reincidence_flagged.jsonl` | 600 |
| `ai_classification.jsonl` | 600 |
| `ai_sentiment.jsonl` | 600 |
| `ai_sla_risk.jsonl` | **109** |
| `dwh_snapshot.jsonl` | 600 |

`ai_sla_risk.jsonl` con 109 en vez de 600 **no es un bug**: `predict_breach_risk()`
(`ai/sla_predictor/sla_model.py:87-111`) solo puntúa tickets con status
`open`/`in_progress`/`pending` — no tiene sentido predecir incumplimiento de
algo que ya se resolvió o cerró. De los 600 tickets de la muestra, 109
estaban abiertos.

## 3. `load_to_dwh`: estado al momento de escribir esto vs. estado tras la prueba del 2026-07-04

### 3.1 Lo que pasó el 2026-07-03 (ambas corridas de esa fecha)

Log real de ambas corridas de ese día
(`logs/dag_id=cx_intelligence_pipeline/.../task_id=load_to_dwh/attempt=1.log`):

```
"DB_HOST no configurado o psycopg2 no disponible — 600 tickets quedaron en
staging/dwh_snapshot.jsonl en vez de dwh.fact_tickets"
[load_to_dwh] {'n_loaded': 600, 'loaded_to_postgres': False}
```

Razón: `.env` solo definía `AIRFLOW_UID`, sin `DB_HOST`, y el
`docker-compose.yaml` de este proyecto solo levantaba la Postgres interna
de metadatos de Airflow (`docker-compose.yaml:100-107`, DB
`airflow`/`airflow`) — ninguna Postgres para el DWH del CX platform
(`oxxo_cx_intelligence`) estaba conectada a esa red.

### 3.2 Qué se hizo el 2026-07-04 para probarlo con datos reales

Existe un contenedor `postgres-oxxo` (Postgres 16) que **no forma parte
del `docker-compose.yaml`** de este proyecto — es un contenedor aparte,
creado el 2026-07-02T20:13 UTC, detenido desde el 2026-07-03T03:09 UTC.
Al levantarlo y revisar adentro:

- Existe la base `oxxo_cx_intelligence` con los esquemas `dwh`, `audit`,
  `marts`, `staging` completos.
- `dwh.fact_tickets` tiene **100,000 filas**.
- `audit.pipeline_runs` tiene un único registro `run_mode='full-load'`,
  `triggered_by='generate_data.py'`, `finished_at = 2026-06-29 18:53:29 UTC`
  — la fecha coincide con el full-load del 29 de junio que se venía
  mencionando, aunque el contenedor Docker en sí se haya (re)creado el 2
  de julio (consistente con que el volumen/datos se restauraron desde ese
  full-load, no con que el full-load haya ocurrido el 2 de julio).

Pasos aplicados:
1. `docker network connect airflow-docker_default postgres-oxxo` — para
   que sea resoluble por nombre desde los contenedores de Airflow.
2. Se agregó a `.env`: `DB_HOST=postgres-oxxo`, `DB_PORT=5432`,
   `DB_NAME=oxxo_cx_intelligence`, `DB_USER=airflow`,
   `DB_PASSWORD=airflow`.
3. `docker-compose up -d` para recrear los contenedores de Airflow y que
   tomen el `.env` nuevo (se inyecta vía `env_file` en
   `docker-compose.yaml:54-55`).
4. Verificado con una query real ejecutada **desde el propio contenedor
   worker** (no solo "la task marcó success"):
   `SELECT count(*) FROM dwh.fact_tickets` → **100000**, conectividad
   confirmada.
5. Se disparó una corrida nueva del DAG
   (`manual__2026-07-04T03:11:24.473097+00:00`) para probar la carga de
   los 600 tickets de muestra contra esta Postgres real.

### 3.3 Resultado de esa corrida: `load_to_dwh` FALLÓ — bug real, no de configuración

Con `DB_HOST` ya apuntando a Postgres real, `load_to_dwh` dejó de caer al
fallback silencioso y **falló de verdad**, en el primer intento y en el
reintento, con el mismo error:

```
InvalidTextRepresentation: invalid input syntax for type integer: ""
LINE 3: ...ULL,NULL),('TKT-2026-0000489','internal',6,17,1,6,'',59,NULL...
```

Causa raíz confirmada: `etl/extractors/csv_internal_extractor.py:17` —
`INT_FIELDS = {"channel_key", "category_key", "priority", "agent_key",
"employee_key", "store_key"}` **no incluye `customer_key`**. Para tickets
internos (empleado↔empleado, sin cliente), la columna `customer_key` viene
vacía en el CSV (`data/samples/internal/internal_tickets.csv:117`, ticket
`TKT-2026-0000489`). `_coerce_row()` solo castea a `None` los campos
listados en `INT_FIELDS`; como `customer_key` no está ahí, el string vacío
`""` del CSV pasa intacto por todo el pipeline (JSON no valida tipos) y
solo revienta al intentar insertarlo en la columna `integer`
`dwh.fact_tickets.customer_key` en Postgres real.

**Este bug estaba oculto hasta hoy** porque siempre que faltaba `DB_HOST`
el pipeline caía al snapshot JSON local, que no tiene columnas tipadas y
nunca lo hubiera expuesto. No se corrige aquí — se deja documentado para
decidir el fix (candidato obvio: agregar `customer_key` a `INT_FIELDS`).

**Estado en ese momento**: la conectividad a la Postgres real
(`postgres-oxxo` / `oxxo_cx_intelligence`) estaba confirmada y funcionando,
pero la carga en sí fallaba antes de completar el INSERT — "la task marca
success" no aplicaba, de hecho ni siquiera llegó a completar sin error.
Esto se corrigió después (§3.4) y, al corregirlo, expuso un problema más
serio que el bug original (§3.5).

### 3.4 Fix del bug de `customer_key` y reintento, 2026-07-04

Se agregó `customer_key` a `INT_FIELDS` en
`etl/extractors/csv_internal_extractor.py:17` (antes: `{"channel_key",
"category_key", "priority", "agent_key", "employee_key", "store_key"}` —
faltaba `customer_key`, por eso el string vacío del CSV llegaba intacto en
vez de castearse a `None`). Se reinició el contenedor worker (los módulos
Python ya estaban importados en el proceso viejo) y se confirmó que carga
el fix: `INT_FIELDS` ya incluye `customer_key`.

Antes de reintentar, se confirmó el baseline con una query real:
`SELECT count(*) FROM dwh.fact_tickets` → **100000** (sin cambios respecto
a §3.2). Se disparó un run nuevo y limpio del DAG
(`manual__2026-07-04T03:27:21.083936+00:00`) — se esperó a que el run
atascado de §3.3 agotara sus reintentos y quedara en `failed` definitivo
(03:22:10 UTC) antes de disparar este, para no correr dos cargas en
paralelo sobre los mismos archivos de staging.

Resultado: **las 10 tasks del DAG terminaron en `success`, incluyendo
`load_to_dwh`.** Log real: `{'n_loaded': 600, 'loaded_to_postgres': True}`,
sin ningún error — el bug de `customer_key` está corregido y confirmado.

### 3.5 Incidente: la prueba sobrescribió 600 filas reales del full-load del 29 de junio

El criterio de éxito pedido era `load_to_dwh` en success **y** el
`COUNT(*)` subiendo en exactamente 600. Lo primero se cumplió; lo segundo
no:

```sql
SELECT count(*) FROM dwh.fact_tickets;  -- 100000, igual que antes del run
```

**El conteo no subió nada.** Investigando por qué: de los 600 `ticket_id`
de la muestra de hoy, **los 600 ya existían** en `dwh.fact_tickets` (rango
real de la tabla: `TKT-2024-0000001`..`TKT-2026-0099999`; confirmado con
`SELECT count(*) FROM dwh.fact_tickets WHERE ticket_id = ANY(...)` sobre
los 600 ids de la muestra → 600 coincidencias). El INSERT usa `ON CONFLICT
(ticket_id) DO UPDATE SET ...` (`etl/loaders/postgres_loader.py:74-77` en
ese momento), así que no se insertó ninguna fila nueva: **se hicieron 600
UPDATE sobre filas reales del dataset de 100k**, sobrescribiendo su
contenido (channel/category/priority/agent/customer/SLA/IA — todas las
columnas de `FACT_TICKETS_COLS` excepto `ticket_id`) con los valores de la
muestra sintética generada hoy.

**Causa raíz**: `gd.generate_tickets()` en `data/synthetic/generate_data.py:369`
arma el id así: `ticket_id = f"TKT-{2024 + (i % 3)}-{i+1:07d}"` — es
**puramente posicional sobre el índice del loop**, no depende del
`--seed`. Cualquier llamada a `generate_tickets(n, ...)`, con cualquier
seed, produce siempre los mismos primeros *n* `ticket_id` que cualquier
otra corrida del mismo generador — incluida la corrida de 100k del 29 de
junio. `generate_ticket_samples.py` reutiliza ese mismo generador para
crear la "muestra" de 600, así que sus ids **siempre iban a colisionar**
con el dataset real; no fue una casualidad del `seed=42` sino una
consecuencia estructural de compartir el generador de ids sin acotar el
rango.

**Búsqueda acotada de recuperación (máx. 10 min, sin reconstrucción manual
de valores) — sin resultado, contenido dado por perdido:**

1. **Volúmenes/contenedores Docker**: `docker volume inspect pgdata_oxxo`
   muestra `CreatedAt: 2026-06-29T16:39:18Z` — es el único volumen de esta
   base, creado el mismo día del full-load, ya mutado por el UPDATE de
   hoy. `docker ps -a` no muestra ningún otro contenedor Postgres parado
   de una sesión anterior relacionado con `oxxo`; los demás volúmenes
   (`crabago_postgres_data`, volúmenes anónimos, `n8n_data`) pertenecen a
   otros proyectos de Docker Compose sin relación con este. Revisado
   también `pg_wal` dentro de `postgres-oxxo`: `wal_level = replica`
   (default), sin `archive_command` configurado — solo quedan los
   segmentos WAL recientes que Postgres recicla, no un archivo continuo
   desde el 29 de junio. No hay base para un point-in-time-recovery.
2. **Dumps/backups/`.sql`/`.backup`**: búsqueda en el árbol de usuario de
   Windows por `*.dump`, `*.backup`, `*.sql`, `*.bak` — ningún resultado
   relacionado con `oxxo_cx_intelligence` o `fact_tickets`.
3. **`data/synthetic/` y `data/samples/`**: `data/synthetic/` solo tiene
   los scripts generadores (`generate_data.py` y afines), ningún output
   persistido del full-load de 100k. `data/samples/` solo tiene la
   muestra de 600 (la que causó el incidente), no una copia del dataset
   original. No existe localmente ningún registro de qué contenían esas
   600 filas antes de hoy.

**Resultado: las 600 filas reales sobrescritas se consideran perdidas de
forma permanente.** Sus `ticket_id` siguen existiendo en
`dwh.fact_tickets` (100,000 en total, sin cambio de conteo), pero el
contenido de esas 600 filas específicas ahora es el de la muestra
sintética de hoy, no el original del 29 de junio.

**Conclusión sobre el bug de `customer_key`**: el fix en sí (agregar
`customer_key` a `INT_FIELDS`) **está resuelto y confirmado** — el INSERT
ya no falla por `""` en una columna `integer`. Pero no se puede reportar
como un cierre limpio: al corregirlo y volver a probar contra Postgres
real, la prueba expuso que `generate_ticket_samples.py` y
`postgres_loader.py` combinados pueden sobrescribir datos reales por
colisión de `ticket_id`, y esta vez efectivamente lo hicieron — 600 filas
del full-load del 29 de junio quedaron perdidas. Ambas causas de fondo se
corrigieron después de detectar esto (ver §3.6), pero el daño a esas 600
filas ya está hecho y no es reversible.

### 3.6 Fixes aplicados tras el incidente

1. **`data/synthetic/generate_ticket_samples.py`** (`_normalize()`): el
   `ticket_id` de cada ticket de muestra ahora se remapea de `TKT-...` a
   `TEST-...` (`sample_ticket_id = t["ticket_id"].replace("TKT-", "TEST-",
   1)`) antes de escribirse a `data/samples/`. Con esto, ninguna muestra
   generada por este script puede volver a coincidir con un `ticket_id`
   real.

   **[RESUELTO 2026-07-04]** `data/samples/` se regeneró corriendo `python
   data/synthetic/generate_ticket_samples.py --n 600` (desde Python del
   host, `faker`/`psycopg2`/`numpy` disponibles ahí; el script mismo
   documenta que no debe correr dentro de los contenedores de Airflow).
   Verificado con query real contra `postgres-oxxo`:
   - 600 `ticket_id` en los archivos nuevos, los 600 distintos, los 600
     con prefijo `TEST-`.
   - `SELECT count(*) FROM dwh.fact_tickets WHERE ticket_id = ANY(...)`
     sobre esos 600 ids → **0 coincidencias** (vs. las 600/600 que
     coincidían con la muestra vieja en §3.5). `dwh.fact_tickets` sigue en
     100,000 filas, sin tocar.
   - Ya no hay riesgo de que una carga de esta muestra sobrescriba datos
     reales por colisión de id.
2. **`etl/loaders/postgres_loader.py`** (`_try_postgres_load`): el
   `INSERT ... ON CONFLICT DO UPDATE` ahora lleva `RETURNING (xmax = 0) AS
   inserted`, que distingue INSERT real de UPDATE por conflicto a nivel de
   Postgres. Si alguna fila resulta en UPDATE (`ticket_id` ya existía),
   se loggea con **WARNING** cuántas de las filas cargadas fueron INSERT
   nuevo vs. UPDATE de algo preexistente — para que una colisión como la
   de este incidente sea visible en el log la primera vez que pase, no
   silenciosa.

### 3.7 [RESUELTO 2026-07-04] `postgres-oxxo` formalizado en `docker-compose.yaml`

Hasta ahora `postgres-oxxo` era un contenedor standalone (creado con
`docker run`, sin labels de Compose) conectado a mano a la red del
proyecto con `docker network connect` (§3.2) — no sobrevivía un
`docker-compose down` / recreación del entorno desde cero. Se formalizó
como servicio del compose.

**Antes de tocar nada**: `docker inspect postgres-oxxo` para confirmar el
volumen real →
`{"Type":"volume","Name":"pgdata_oxxo","Source":"/var/lib/docker/volumes/pgdata_oxxo/_data","Destination":"/var/lib/postgresql/data",...}`.
Baseline confirmado con query real: `SELECT count(*) FROM
dwh.fact_tickets` → **100000**.

**Cambios en `docker-compose.yaml`**:
- Nuevo servicio `postgres-oxxo` (junto al servicio `postgres` existente),
  `container_name: postgres-oxxo`, mismas credenciales que ya tenía el
  contenedor (`POSTGRES_USER`/`POSTGRES_PASSWORD: airflow`), montando
  `pgdata_oxxo:/var/lib/postgresql/data`.
- En el bloque `volumes:` de nivel superior: `pgdata_oxxo:` declarado con
  **`external: true`** — Compose no lo crea ni lo gestiona, solo lo
  referencia. Esto es lo que garantiza que un futuro
  `docker-compose down -v` **no pueda borrarlo**: Compose nunca es dueño
  de su ciclo de vida. El nombre coincide carácter por carácter con el
  `Name` que reportó `docker inspect` arriba (`pgdata_oxxo`).
- Validado con `docker-compose config --quiet` (sintaxis correcta) antes
  de aplicar nada.

**Secuencia de aplicación** (sin `docker-compose down -v` en ningún
punto):
1. `docker stop postgres-oxxo` + `docker rm postgres-oxxo` — se removió
   el contenedor standalone viejo (sin labels de Compose, confirmado con
   `docker inspect ... Config.Labels` → `{}`) para liberar el nombre; el
   volumen `pgdata_oxxo` no se tocó, los datos viven ahí, no en el
   contenedor.
2. `docker-compose down` (sin `-v`) — bajó el stack de Airflow existente,
   sin remover volúmenes.
3. `docker-compose up -d` — recreó todo, incluyendo `postgres-oxxo` como
   servicio nativo del compose, sobre el mismo volumen `pgdata_oxxo`.

**Verificación después**: `postgres-oxxo` levantó `healthy`, con el mismo
mount (`docker inspect` post-recreación: mismo volumen `pgdata_oxxo` →
`/var/lib/postgresql/data`). Query real desde el worker:
`SELECT count(*) FROM dwh.fact_tickets` → **100000** — idéntico al
baseline de antes, sin cambios. `DB_HOST=postgres-oxxo` sigue resolviendo
correctamente (ahora vía DNS nativo de Compose por nombre de servicio, ya
no depende del `docker network connect` manual de §3.2).

### 3.8 Primera carga limpia de principio a fin — y el DAG ya la había hecho solo, sin que nadie la disparara a mano

Se pidió disparar el DAG de nuevo para probar la carga limpia
(`customer_key` corregido + ids `TEST-` sin colisión + `postgres-oxxo`
conectado vía compose), con baseline esperado de 100,000 antes y 100,600
después. **Al confirmar el baseline con una query real, ya estaba en
100,600, no en 100,000.**

Causa: el DAG `cx_intelligence_pipeline` nunca se pausó, y su schedule
(`0 6-23 * * *`, cada hora, `dags/cx_intelligence_pipeline.py:56`) siguió
corriendo solo durante todo el tiempo transcurrido entre sesiones — sin
que nadie lo disparara manualmente. `airflow dags list-runs
cx_intelligence_pipeline` mostró varias corridas `scheduled__` ya en
`success` para el 2026-07-04 antes de este mensaje. Revisando los logs de
`load_to_dwh` de cada una (usando el desglose INSERT/UPDATE del fix de
§3.6):

| run (`scheduled__...`) | resultado en `load_to_dwh` |
|---|---|
| `2026-07-04T18:00:00+00:00` | **`"600 filas insertadas como registros nuevos, 0 updates"`** — el INSERT limpio, `dwh.fact_tickets` pasó de 100,000 a 100,600 |
| `2026-07-04T06:00:00+00:00` | `"0 fueron INSERT nuevo y 600 fueron UPDATE"` |
| `2026-07-04T08:00:00+00:00` | `"0 fueron INSERT nuevo y 600 fueron UPDATE"` |
| `2026-07-04T09:00:00+00:00` | `"0 fueron INSERT nuevo y 600 fueron UPDATE"` |
| `2026-07-04T19:00:00+00:00` | `"0 fueron INSERT nuevo y 600 fueron UPDATE"` |

(Los timestamps de ejecución real de estas tasks no siguen el orden de
sus `run_id` — el scheduler procesó varias corridas atrasadas de forma
consecutiva tras el reinicio del stack en §3.7. No cambia la conclusión:
la de las 18:00 es, por su propio log, la única que insertó filas
nuevas.)

**Esto es exactamente la evidencia pedida — el DAG ya la produjo sola:**
- Carga limpia de principio a fin: `customer_key` corregido (§3.4), ids
  `TEST-` sin colisión (§3.6), `postgres-oxxo` conectado vía compose
  (§3.7) → `SELECT count(*) FROM dwh.fact_tickets`: **100,000 antes,
  100,600 después** (confirmado con query real, no solo "success" de la
  task).
- Las corridas repetidas posteriores (mismos 600 `ticket_id` `TEST-`, ya
  existentes) no duplicaron nada: `0 INSERT / 600 UPDATE` cada vez,
  `COUNT(*)` se mantiene en 100,600. El fix de `postgres_loader.py`
  (§3.6, punto 2) queda validado en la práctica, no solo en teoría.
- Confirmado de nuevo justo ahora con query real: `COUNT(*) = 100600`.

**Nota para futuras sesiones** (por qué se documenta esto aparte, no solo
el resultado): se asumió que "nada corrió" porque nadie disparó el DAG a
mano, y esa asunción era falsa — el cron horario nunca se pausó y siguió
cargando datos de forma autónoma entre sesiones. **Antes de asumir que el
estado de `dwh.fact_tickets` (o de cualquier tabla que el pipeline
toque) no cambió porque "no se disparó nada", verificar primero si el DAG
está pausado o no** (`airflow dags list` muestra la columna `is_paused`,
o `airflow dags list-runs <dag_id>` para ver qué corrió solo). Un
`COUNT(*)` real siempre es más confiable que la suposición de que el
tiempo entre sesiones no tuvo actividad.

**Acción tomada**: se pausó el DAG (`airflow dags pause
cx_intelligence_pipeline`) para que deje de correr solo cada hora
mientras se sigue validando el pipeline manualmente. Confirmado con
`airflow dags list` → `is_paused = True`. Para reactivarlo:
`airflow dags unpause cx_intelligence_pipeline`.

## 4. Métricas reales de los 3 modelos de IA (vs. lo que documenta el README)

Notas "honestas" ya presentes en el código (no son hallazgos nuevos, pero
se centralizan aquí porque el README que las contradice no está en este
repo — ver §6):

| Modelo | Métrica real | Métrica en README | Archivo |
|---|---|---|---|
| Clasificador de tickets | macro F1 = **0.7203** (holdout por plantilla, corpus ampliado 2026-07-06 — era 0.4334 con 147 plantillas, ver §4.2) | 87.4% | `ai/classifier/ticket_classifier.py:5-8` |
| Análisis de sentimiento | macro F1 = **0.9898** (real, TF-IDF+LogReg, no BERT/pysentimiento — corpus ampliado 2026-07-07, era 0.9515 con 147 plantillas, ver §4.4) | BERT/robertuito | `ai/sentiment/sentiment_analyzer.py:5-12` |
| Predictor de incumplimiento de SLA | AUC-ROC = **0.6475** (modelo desplegado 2026-07-07, ver §4.5 — no comparable dígito a dígito con el 0.5594 histórico de `causal_fix`, dataset sintético reconstruido) | 0.823 | `ai/sla_predictor/sla_model.py:5-8` |

El cambio de sentimiento (sklearn en vez de BERT) tiene una razón operativa
documentada: `huggingface.co` fuera del allowlist de egress del sandbox de
entrenamiento (403 confirmado) y `pysentimiento`/torch+CUDA sin espacio en
disco para instalar completo.

### 4.1 [HALLAZGO 2026-07-06] 0% de auto-clasificación real, no 98.1% — corpus semilla pasa de "mejora futura" a bloqueador

Al reconstruir `FASE_B_RESULTADOS.md` (§6, §7) a partir de
`ai/classifier/metrics_fase_b.json`, el campo `template_holdout.low_confidence_rate`
= **1.0**: el **100% de las predicciones de test** (holdout por
plantilla, n=528) cayeron por debajo de `CONFIDENCE_THRESHOLD = 0.75`
(`ai/classifier/ticket_classifier.py:21`), **sin importar si la
predicción fue correcta o no**.

**Consecuencia directa**: `classify_ticket_text()` marca
`needs_human_review = True` cuando `confidence < 0.75`
(`ticket_classifier.py:39-51`). Con el corpus semilla actual (147
plantillas / 20 categorías), eso significa que, bajo evaluación honesta,
**el clasificador no auto-clasificaría ningún ticket — 0%, no el
87.4%/98.1% que documentaba el README antes de esta sesión** (ver
corrección aplicada en README, sección Módulo 1 y tabla de Resultados
del POC).

No es un bug de umbral mal puesto: el umbral (0.75) es razonable para un
clasificador de producción; lo que falla es que el modelo, entrenado
sobre solo 147 plantillas, nunca alcanza esa confianza en texto que no
vio en entrenamiento. **Esto eleva la prioridad de ampliar el corpus
semilla**: ya no es una mejora deseable a futuro (no estaba ni siquiera
en el Roadmap de "Mejoras futuras" del README) — es la condición mínima
para que la promesa central de Fase B (clasificación automática sin
intervención manual) sea real y no solo teórica. Ver
`FASE_B_RESULTADOS.md` §3-4 para el detalle completo y las
recomendaciones (no medidas) de qué ampliar.

### 4.2 [RESUELTO PARCIALMENTE 2026-07-06] Corpus semilla ampliado 147→359 — F1 subió 66%, pero el problema de confianza casi no cambió

Siguiendo la recomendación de §4.1, se amplió `data/synthetic/seed_corpus_clientes.py`
y `seed_corpus_colaboradores.py` de 147 a **359 plantillas**, priorizando
las categorías con F1 real más bajo (más plantillas nuevas para
`beneficios_hr` y `sugerencia_general`, ambas en F1=0; menos para
`servicio_express`, ya en F1=0.958). Se reconstruyó
`data/synthetic/train_classifier.py` (no existía en el repo, ver §6) para
reentrenar con la misma metodología de holdout-por-plantilla, respaldando
antes el modelo y métricas anteriores
(`ai/classifier/models/ticket_classifier.joblib.bak`,
`ai/classifier/metrics_fase_b.json.bak`).

**Resultado medido, no asumido**:

| | Antes (147 plantillas) | Después (359 plantillas) |
|---|---|---|
| Macro F1 (holdout por plantilla) | 0.4334 | **0.7203** |
| Accuracy real | no medida entonces | **73.64%** |
| `low_confidence_rate` | 100% | **99.4%** (casi sin cambio) |

**El hallazgo importante no es que mejoró — es que la confianza no
mejoró con la exactitud.** Se añadió un análisis de calibración
(accuracy condicionada a si la predicción supera el umbral) para
entender por qué:

| | n (de 2,272 test) | Accuracy |
|---|---|---|
| Confianza ≥ 0.75 | 14 (0.6%) | **100%** |
| Confianza < 0.75 | 2,258 (99.4%) | **73.5%** |

El umbral de 0.75 **sí es confiable** (nunca falla cuando lo supera), pero
**casi nunca se supera** — con 20 categorías de vocabulario parcialmente
solapado, el softmax reparte probabilidad entre varias clases plausibles
incluso cuando acierta la correcta. Conclusión: la hipótesis de §4.1
("falta corpus") explicaba el F1 bajo, pero **no** explicaba el síntoma
que la motivó (0% de auto-clasificación) — esa parte requería recalibrar
la probabilidad del modelo, no más datos (ver resolución en §4.3).

**`tiempo_espera` en F1=0.0 — investigado, no es una regresión real**:
se sospechó inicialmente una regresión (0.826→0.0), pero al investigar:
(1) in-sample el modelo clasifica el 100% de sus propias 320 instancias
de entrenamiento de `tiempo_espera` correctamente, con features
correctas y sensatas (`fila`, `espera`, `tiempo`, `minutos`, `pico`) —
descarta vocabulario aplastado por otras categorías; (2) probando la
misma metodología con 5 semillas distintas, `tiempo_espera` da F1 entre
0.19 y 0.83 según qué 2-3 plantillas (de solo 13 totales) caigan en test
— la semilla 42 fue, para esta categoría, una mala racha del split, no
un efecto de la ampliación del corpus. Detalle completo en
`FASE_B_RESULTADOS.md` §2.1, incluyendo la implicación más amplia: el
macro F1 total también varía por semilla (0.704-0.766 en esa misma
prueba), así que 0.7203 es un punto dentro de un rango, no un valor fijo.

### 4.3 [RESUELTO 2026-07-06] Calibración aplicada — cobertura de auto-clasificación 0.6%→20.5% sin bajar el umbral

Siguiendo la recomendación de §4.2, se envolvió la `LogisticRegression`
con `CalibratedClassifierCV` (sigmoid/Platt, cv=5) en
`data/synthetic/train_classifier.py`, mismo train/test split, mismo
umbral de negocio (`CONFIDENCE_THRESHOLD = 0.75`, sin cambiar):

| | Sin calibrar | Calibrado |
|---|---|---|
| Macro F1 | 0.7203 | **0.7503** |
| `low_confidence_rate` (umbral 0.75) | 99.4% | **79.5%** |
| Cobertura de auto-clasificación | 0.6% (14 casos) | **20.5%** (465 casos) |
| Accuracy en predicciones "confiables" | 100% (n=14) | **95.7%** (n=465) |

**~34x más cobertura sin sacrificar precisión**, sin tocar el umbral de
negocio. `ai/classifier/ticket_classifier.py` no necesitó cambios de
código — el modelo calibrado sigue siendo un `Pipeline` con
`predict_proba`/`classes_` compatibles; probado end-to-end con
`classify_ticket_text()` sobre dos ejemplos reales, ambos clasificados
correctamente.

Se generó además un barrido de umbrales (0.30 a 0.90) documentado en
`FASE_B_RESULTADOS.md` §3.1 — por ejemplo, bajar el umbral a 0.50 daría
61.5% de cobertura con 90.9% de accuracy. **No se cambió el umbral**: es
un tradeoff de riesgo (cuánta auto-clasificación errónea aceptar) que
corresponde decidir a quien lleve el producto, no a esta sesión.

**README actualizado** con los números finales (F1 0.7503, accuracy
74.78%, cobertura 20.5%, el análisis de calibración) en las secciones
Módulo 1, tabla de Resultados del POC, diagrama de arquitectura, y
"Diagnóstico y lecciones del proceso".

### 4.4 [RESUELTO 2026-07-07] Sentiment Analyzer (Fase C) reentrenado — había quedado desactualizado por el trabajo de Fase B

Al mostrar `FASE_C_RESULTADOS.md` completo para revisión, se detectó que
sus números (F1 0.9515, n_train=4,120) seguían siendo del corpus original
de 147 plantillas — confirmado comparando fechas:
`sentiment_analyzer.joblib`/`metrics_fase_c.json` del 2026-07-02, pero
`seed_corpus_clientes.py`/`seed_corpus_colaboradores.py` (los mismos
archivos que usa este módulo, compartidos con Fase B) del 2026-07-06. El
modelo de sentimiento nunca se reentrenó tras la ampliación del corpus,
a diferencia del clasificador.

Se reconstruyó `data/synthetic/train_sentiment.py` (no existía, misma
metodología de holdout-por-plantilla que `train_classifier.py`, importando
sus helpers) y se reentrenó, respaldando antes el modelo/métricas
anteriores (`ai/sentiment/models/sentiment_analyzer.joblib.bak`,
`ai/sentiment/metrics_fase_c.json.bak`):

| | Antes (147 plantillas) | Después (359 plantillas) |
|---|---|---|
| Macro F1 (holdout por plantilla) | 0.9515 | **0.9898** |
| F1 `neutral` (el más débil) | 0.899 | **0.988** |

A diferencia de Fase B, **no hubo regresiones** — las tres clases
(negative/neutral/positive) mejoraron de forma consistente, sin ningún
caso como `tiempo_espera`. `ai/sentiment/sentiment_analyzer.py` no
necesitó cambios de código; probado end-to-end con `analyze_text()` sobre
3 ejemplos reales, los 3 correctos. README actualizado (Módulo 2,
diagrama de arquitectura) con F1 0.9898.

### 4.5 [RESUELTO 2026-07-07] SLA Predictor (Fase D) — el código del fix causal estaba perdido; features candidatas probadas y descartadas con evidencia

Al pedir atacar el SLA Predictor primero (de la lista de §7 anterior), se
encontró un hallazgo más serio que en Fase B/C: **no solo faltaba
`train_sla_model.py`** (mismo patrón ya visto) — `generate_times()` en
`data/synthetic/generate_data.py` **nunca tuvo guardado el parche causal**
que documentaba `FASE_D_RESULTADOS.md` (ronda `causal_fix`, AUC 0.5594).
Confirmado leyendo el código: sigue con el volado fijo ~74% sin relación
a ninguna feature (la lógica de la ronda `baseline`, AUC 0.4862) —
confirmado también con `grep` que no hay rastro de "hour_of_day",
"is_weekend" ni "causal_fix" en ese archivo. El AUC=0.5594 histórico es
un número real que se midió en su momento, pero el código que lo produjo
se perdió — no solo el script de entrenamiento, también el generador de
datos.

**Qué se hizo**: se reconstruyó `data/synthetic/train_sla_model.py` (no
existía) con un generador sintético propio (mismo patrón que
`train_classifier.py`/`train_sentiment.py` — no toca `generate_data.py`
ni Postgres), con una reconstrucción cualitativa razonable de la
estructura causal (hora pico, complejidad de categoría, canal, fin de
semana) — documentada explícitamente como reconstrucción, no como el
código original perdido.

**Se aprovechó la reconstrucción para responder, con evidencia, la
pregunta abierta de `FASE_D_RESULTADOS.md §5`**: ¿ayudarían las 3
features candidatas (carga del agente, historial de SLA por categoría,
longitud del mensaje)? Experimento controlado sobre el mismo dataset
causal — Modelo A (7 features originales) vs. Modelo B (A + 3
candidatas):

| Modelo | AUC-ROC |
|---|---|
| A — originales | 0.6475 |
| B — + 3 candidatas | 0.6492 |
| Delta | +0.0018 |

Verificado con 5 semillas (mismo criterio que la investigación de
`tiempo_espera` en §4.2): deltas `[-0.0033, +0.0054, +0.0001, +0.0018,
+0.0054]`, promedio **+0.0019** (std 0.0033) — **dentro de 1 desviación
estándar de cero**. Conclusión: las 3 features candidatas no ayudan de
forma distinguible del ruido, ni siquiera en un experimento donde se
construyeron a propósito con efecto causal real no nulo sobre la
etiqueta.

**Decisión de despliegue**: se desplegó el **Modelo A** (no el B) — B
habría requerido que `sla_model.py` calculara 3 features nuevas en
tiempo real (`row_num` en `predict_breach_probability()` está hardcodeado
a las 5 features numéricas originales; usar el bundle de B ahí lanza
`KeyError`), sin beneficio medible que lo justifique. Probado end-to-end
con `predict_breach_probability()` sobre un ticket de ejemplo — funciona
sin cambios de código. Modelo/métricas previos respaldados en
`ai/sla_predictor/models/sla_breach_predictor.joblib.bak` y
`ai/sla_predictor/metrics_fase_d.json.bak`.

**Nota de comparabilidad, importante**: el AUC=0.6475 del modelo
desplegado hoy **no se reporta como "mejoramos de 0.56 a 0.65"** — viene
de un dataset sintético reconstruido de forma independiente, no del
código original perdido. La comparación con evidencia real es la
interna (A vs. B, mismo dataset, mismo split), no la externa contra el
número histórico. README actualizado (Módulo 3, diagrama, tabla de
Resultados del POC, diagnóstico) con esta distinción explícita, y con el
bloque "Input" del Módulo 3 corregido — ya listaba "carga del agente" e
"historial de categoría" como si fueran inputs reales del modelo cuando
nunca lo fueron.

### 4.6 [RESUELTO 2026-07-07] `CONFIDENCE_THRESHOLD` bajado de 0.75 a 0.50 — decisión de producto tomada

Se pidió explícitamente bajar el umbral (la decisión que en §4.3 se dejó
pendiente a propósito). Se cambió `CONFIDENCE_THRESHOLD` en
`ai/classifier/ticket_classifier.py` y en `data/synthetic/train_classifier.py`,
y se reentrenó (mismo modelo/seed — determinista, los pesos no cambian;
lo que se recalcula son las métricas de calibración al nuevo punto de
operación):

| | Umbral 0.75 | Umbral 0.50 |
|---|---|---|
| Cobertura de auto-clasificación | 20.5% (465 casos) | **61.5%** (1,398 casos) |
| Accuracy en predicciones auto-clasificadas | 95.7% | **90.9%** |
| Accuracy en las que quedan para revisión humana | 69.4% (n=1,807) | 49.0% (n=874) |

Consistente con el barrido de umbrales ya documentado en
`FASE_B_RESULTADOS.md §3.1` antes de tomar la decisión (0.50 → 61.5%/90.9%,
exacto). Probado end-to-end con `classify_ticket_text()`: dos ejemplos
con confianza 0.67 y 0.73 que antes quedaban en revisión humana ahora se
auto-clasifican (ambos correctos); un tercero con confianza 0.47 sigue en
revisión humana, correctamente. README y `FASE_B_RESULTADOS.md`
actualizados (nueva §3.2) con los números del nuevo punto de operación.

## 5. Validación de calidad: no es Great Expectations

`etl/validation/expectations_suite.py:1-12` (docstring propio) es
explícito: implementa a mano las mismas reglas (not_null, rango,
unicidad, duplicados) que describiría una suite de Great Expectations,
**sin** la dependencia `great_expectations` instalada. `monitoring/pipeline_monitor.py:1-6`
tiene la misma nota respecto a un workflow de n8n del README que aquí se
reemplazó por Python plano. Si el README documenta GE como el stack de
validación, ese README no refleja el motor que corre hoy.

### 5.1 [RESUELTO 2026-07-06] El "11 de 12" era un número hardcodeado — ya se corrigió en el código

(Antes vivía en la sección de Pendiente como "identificar cuál check
falló" — queda aclarado por completo, no hay ningún check que identificar,
así que se documenta aquí como hallazgo cerrado.)

Ubicación exacta: `data/synthetic/generate_data.py`, función
`insert_pipeline_run`, **línea 775**:
```
773	            VALUES (%s,'full-load','success','generate_data.py',
774	                    %s,%s,0,%s,
775	                    12,11,1,
776	                    ARRAY['facebook','instagram','whatsapp','email','chat_web','interno'],
777	                    %s,%s,NOW())
```
`12,11,1` (dq_checks_total, dq_checks_passed, dq_checks_failed) está
escrito como literal fijo directamente en el SQL, junto a placeholders
`%s` dinámicos — no se calcula a partir de la lista `checks` que se
inserta después (líneas 782-806) en `audit.data_quality_log`. Las dos
tablas se llenan por separado, sin ninguna variable compartida entre
ellas: **es estructuralmente imposible que el resumen refleje los checks
reales**, porque nunca estuvieron conectados.

**Confirmado con la data real de la corrida del 29 de junio** (se
consultó `audit.data_quality_log` filtrado por el `pipeline_run_id` de ese
full-load): los 12 checks muestran `status='passed'`, `records_failed=0`
— los 12, sin excepción. `audit.pipeline_runs` para esa misma corrida
sigue diciendo `dq_checks_passed=11, dq_checks_failed=1`. Es una
contradicción directa entre el resumen y el detalle: en la corrida
específica que generó el 29 de junio, **cero checks fallaron según el
propio detalle**, pero el resumen dice que falló uno.

De los 12 checks, 11 tienen `failed=0` hardcodeado (líneas 782-789 y
791-795) y **uno solo** tiene conteo variable: `("dwh.fact_tickets",
"ai_confidence [0,1]", "range", n_tickets, random.randint(0, 5))`
(**línea 790**) — un número aleatorio entre 0 y 5 en cada corrida del
script, sin relación con los datos reales generados. En la corrida del 29
de junio ese aleatorio cayó en 0 (por eso el detalle muestra 12/12
pasados), pero el "1 failed" del resumen no depende de ese aleatorio en
absoluto — es fijo siempre.

¿Fue alguna vez un cálculo real que se quedó fijo, o siempre fue un
placeholder? Por estructura del código: **siempre fue un placeholder**. El
INSERT a `audit.pipeline_runs` (con el literal `12,11,1`) se ejecuta y
hace `commit` de forma completamente separada del bloque que arma e
inserta la lista `checks` en `audit.data_quality_log` — no hay ninguna
agregación (`sum(failed==0)`, etc.) en ningún punto de la función que
pudiera haber alimentado esos tres números. No hay rastro de que alguna
vez se haya derivado de un cálculo real.

Y de fondo: esto tampoco es — ni fue nunca — una validación de Great
Expectations. Es un log de calidad simulado dentro del generador de datos
sintéticos (`generate_data.py`), no la ejecución de una suite de GE
contra datos reales.

**Fix aplicado**: en `insert_pipeline_run()` (`data/synthetic/generate_data.py:764-800`),
la lista `checks` ahora se arma **antes** del `INSERT` a
`audit.pipeline_runs`, y `dq_checks_total`/`dq_checks_passed`/`dq_checks_failed`
se derivan de esa misma lista (`len(checks)`, y conteo de cuántos
`checks` tienen `failed > 0`) en vez del literal fijo `12,11,1`. Con esto,
el resumen de `audit.pipeline_runs` y el detalle de
`audit.data_quality_log` quedan estructuralmente conectados — ya no
pueden volver a contradecirse en una corrida futura, porque salen del
mismo dato.

**[RESUELTO 2026-07-06] Registro histórico también corregido**: se
confirmó primero con query real que `audit.data_quality_log` para
`run_id = fd4c7405-0ca7-4932-982e-31c508805e1e` (el full-load del 29 de
junio) tiene **12 filas, las 12 con `status='passed'`, 0 en cualquier
otro estado** — coincide exactamente con lo documentado arriba. Con esa
confirmación, se aplicó:

```sql
UPDATE audit.pipeline_runs
SET dq_checks_passed = 12, dq_checks_failed = 0
WHERE run_id = 'fd4c7405-0ca7-4932-982e-31c508805e1e';
-- UPDATE 1, verificado después: dq_checks_total=12, dq_checks_passed=12, dq_checks_failed=0
```

Ahora el resumen de `audit.pipeline_runs` y el detalle de
`audit.data_quality_log` son consistentes tanto para corridas futuras
(fix en código, arriba) como para este registro histórico específico. No
se tocó ninguna otra fila de `audit.pipeline_runs` ni ningún dato de
`dwh.fact_tickets`.

## 6. Documentos que el código referencia pero que no existen en este repo

Varios docstrings apuntan a documentos que no están presentes en el
checkout actual (`Get-ChildItem -Recurse *.md` no devolvía nada al momento
de escribir esto, salvo `ESTADO_REAL.md`):

- ~~`README.md`~~ — **[RESUELTO 2026-07-06]** el usuario tenía el contenido
  original guardado fuera de este checkout; se recuperó, se corrigió (ver
  §8.1) y ya existe en la raíz del proyecto. No se reconstruyó de cero ni
  se adivinó — es el texto original con las métricas y secciones
  corregidas contra este mismo documento.
- ~~`FASE_B_RESULTADOS.md`~~, ~~`FASE_C_RESULTADOS.md`~~, ~~`FASE_D_RESULTADOS.md`~~ —
  **[RESUELTO 2026-07-06]**. No aparecieron en ningún lado, pero al
  revisar `ai/{classifier,sentiment,sla_predictor}/` se encontró que cada
  módulo tiene un `metrics_fase_{b,c,d}.json` real, generado segundos
  antes que su `.joblib` correspondiente (mismo run de entrenamiento, ver
  timestamps) — con desglose por categoría/clase y, en el caso de Fase D,
  feature importance (SHAP) de ambas rondas (`baseline` y `causal_fix`).
  Estos JSON traían datos que el README daba por no medidos ("el
  desglose por categoría... no se han vuelto a medir bajo este esquema";
  "la lista de features más importantes... no se han vuelto a calcular
  bajo la ronda corregida") — en realidad **sí existían**, solo no se
  habían incorporado a ningún documento. Los tres `FASE_*_RESULTADOS.md`
  se escribieron a partir de esos JSON (no de memoria ni estimación) y ya
  existen en la raíz del proyecto. **Pendiente aparte, no resuelto aquí**:
  el README todavía dice que ese desglose "no se ha vuelto a medir" —
  technically desactualizado ahora que los FASE docs sí lo tienen; decidir
  si vale la pena actualizar esa frase del README o dejarla (no se tocó
  el README en este cambio, a propósito).

## 7. Pendiente

- **[x] Localizar o reconstruir los `FASE_{B,C,D}_RESULTADOS.md`** —
  **[RESUELTO 2026-07-06]**, ver §6: reconstruidos a partir de los
  `metrics_fase_{b,c,d}.json` reales encontrados en `ai/`. Queda abierto,
  sin decidir: si actualizar la frase del README que dice que ese
  desglose "no se ha vuelto a medir" (ya no es cierto, ver §6).

- **[x] Decidir qué hacer con el log de calidad simulado de
  `generate_data.py`** — **[RESUELTO 2026-07-06]**, ver §5.1: se eligió
  derivar `dq_checks_total/passed/failed` de la lista real de `checks` en
  vez de quitar el log o dejarlo documentado como limitación. Corregido
  en `insert_pipeline_run()` para corridas futuras, y también corregido el
  registro histórico del 29 de junio (`UPDATE` puntual, verificado
  12/12/0 tras confirmar el detalle real en `data_quality_log`).

- **[x] Verificar el estado real de Postgres/Docker tras el reinicio de
  la PC** — **[RESUELTO 2026-07-06]**, ver §8.3: todo consistente
  (100,600 filas, `pgdata_oxxo` intacto, `postgres-oxxo` healthy, DAG
  pausado). El riesgo de espacio en `C:` también se resolvió (vdisk
  movido a `D:`, ver §8.3).

- **[x] Ampliar el corpus semilla del clasificador (Fase B)** —
  **[RESUELTO 2026-07-06]**, ver §4.2: 147→359 plantillas, F1
  0.4334→0.7203. Abrió dos pendientes, ambos ya resueltos:
  - **[x] Recalibrar `CONFIDENCE_THRESHOLD`** — **[RESUELTO 2026-07-06,
    ampliado 2026-07-07]**: primero se calibró el modelo
    (`CalibratedClassifierCV`, §4.3) — cobertura 0.6%→20.5% al umbral
    original de 0.75. Después se pidió explícitamente bajar el umbral, y
    se bajó a 0.50 (§4.6) — cobertura 20.5%→61.5%, accuracy en esas
    predicciones 95.7%→90.9%. Ambas decisiones tomadas explícitamente, no
    unilateralmente.
  - **[x] Investigar la regresión de `tiempo_espera`** — **[RESUELTO
    2026-07-06]**: no era una regresión real, era varianza del split con
    solo 13 plantillas (F1 0.19-0.83 según semilla). Ver §4.2 y
    `FASE_B_RESULTADOS.md` §2.1.

- **[x] Reentrenar el Sentiment Analyzer (Fase C)** — **[RESUELTO
  2026-07-07]**, ver §4.4: había quedado desactualizado por el corpus
  ampliado de Fase B. F1 0.9515→0.9898, sin regresiones.

- **[x] Atacar el SLA Predictor (Fase D)** — **[RESUELTO 2026-07-07]**,
  ver §4.5: se encontró que el código del "fix causal" (no solo
  `train_sla_model.py`) también se había perdido. Se reconstruyó y se
  probaron con evidencia las 3 features candidatas de
  `FASE_D_RESULTADOS.md §5` (carga del agente, historial de SLA por
  categoría, longitud del mensaje) — no ayudaron (+0.0019 AUC promedio
  en 5 semillas, ruido). Se desplegó el modelo con las features
  originales. Candidatos sin probar que quedan documentados en
  `FASE_D_RESULTADOS.md §5` (interacciones explícitas entre features,
  más datos de entrenamiento, o reconsiderar si 0.82 fue nunca realista).

Cerrado y ya no listado aquí (ver detalle en su sección correspondiente,
no solo el título): el hardcodeo del "11 de 12" (§5.1), el bug de
`customer_key` (§3.4-3.6 — corregido, pero con un incidente de datos
irreversible como efecto colateral, no es un cierre "limpio"), la
regeneración de `data/samples/` con ids `TEST-` sin colisión (§3.6,
punto 1), la formalización de `postgres-oxxo` en `docker-compose.yaml`
sobre su volumen real `pgdata_oxxo` (§3.7), y la corrección completa de
`README.md` (§8.1).

## 8. Estado de hoy (2026-07-06): README corregido, Docker Desktop caído

### 8.1 `README.md` — corregido y consistente

El usuario proporcionó el contenido completo del README original (que no
vivía en este checkout, ver §6). Se reescribió con las correcciones de
Fase G, todas contra las cifras y hallazgos de este mismo
`ESTADO_REAL.md`:

- Classifier F1 real 0.4334 (no 87.4%), Sentiment F1 real 0.9515 (TF-IDF+
  LogReg, sustituto de BERT — no el modelo planeado), SLA Predictor AUC
  real 0.5594 (no 0.823) — en las secciones de Modelos de IA y en
  "Resultados del POC", no en una nota aparte.
- Tabla de "impacto operacional" (SLA 72%→91%, etc.) marcada
  explícitamente como simulación ilustrativa, no medida.
- Nueva sección "Diagnóstico y lecciones del proceso" con la fuga de datos
  por split ingenuo del clasificador, el log de auditoría hardcodeado
  (§5.1), el incidente de colisión de `ticket_id` (§3.5-3.6), y la
  lección del cron corriendo solo entre sesiones (§3.8).
- Tech Stack corregido a lo que realmente corre: `postgres:16` (no 15,
  unificado en badge/diagrama/quick start/árbol — no solo la tabla),
  `apache/airflow:3.2.2` (no 2.8), `scikit-learn 1.8` (no 1.4, confirmado
  por comentario en `requirements-ai.txt`), Great Expectations marcado
  explícitamente como no usado en los 3 lugares donde aparecía como si
  fuera real (diagrama del ETL, output de Quick Start, Roadmap Sprint 2),
  fila de SHAP eliminada (no hay `shap` en `requirements-ai.txt`).
- Sección "🧪 Tests" eliminada y referencias a `tests/`,
  `train_classifier.py`, `train_model.py`, `feature_engineering.py`
  quitadas del árbol de estructura — ninguno de esos archivos/carpetas
  existe en este repo. Roadmap Sprint 8 y las menciones a
  `.github/workflows/ci.yml` ("Tests en cada PR") ajustadas para no
  implicar una suite de tests que no existe.
- Revisado dos veces de punta a punta (una relectura manual completa tras
  la primera ronda de fixes, y una segunda tras los 3 ajustes finales) —
  sin `git` instalado en esta máquina, la verificación de consistencia se
  hizo releyendo el archivo completo en vez de con `git diff`.

**[NOTA 2026-07-06, corrección posterior]** El punto anterior sobre
`train_classifier.py` ya no aplica tal cual: ese mismo día, más tarde,
se creó `data/synthetic/train_classifier.py` de verdad (ver §4.2) para
reentrenar el clasificador. El árbol de estructura del README se
actualizó de nuevo para reflejarlo — ver §8.4 más abajo.

### 8.2 Docker Desktop dejó de responder

Cronología de esta sesión:
1. `docker ps` quedó colgado varios minutos sin responder (nunca completó).
2. Intentos de diagnóstico (`docker version`, `Glob`/`Grep` sobre archivos
   del proyecto) empezaron a fallar con `EUNKNOWN: unknown error,
   uv_spawn` — síntoma de que algo a nivel de spawning de procesos ya
   estaba comprometido, no solo Docker.
3. Un intento de escritura de archivo falló con `ENOSPC: no space left on
   device` — el disco se llenó. El usuario liberó espacio y las
   operaciones de archivo volvieron a funcionar con normalidad.
4. Docker Desktop se cerró y **no volvió a abrir**.
5. Se intentó `Restart-Service com.docker.service` — el servicio no
   existe en esta máquina (`Get-Service` con filtro "docker" no devuelve
   nada). Consistente con Docker Desktop corriendo sobre backend WSL2 en
   vez del servicio clásico de Windows.
6. Siguiente paso decidido por el usuario: **reinicio completo de la PC**.

### 8.3 [RESUELTO 2026-07-06] Verificado tras el reinicio — todo consistente, un riesgo abierto

Confirmado con comandos reales tras el reinicio de la PC, en orden, sin
asumir nada:

- **[x]** Docker Desktop responde (`docker version`, cliente y servidor
  4.78.0, sin colgarse).
- **[x]** `SELECT count(*) FROM dwh.fact_tickets` en `postgres-oxxo` /
  `oxxo_cx_intelligence` → **100,600**, sin cambio respecto a §3.8. Nota:
  la conexión requiere `-U airflow -d oxxo_cx_intelligence` (no
  `-U postgres`, ese rol no existe en este contenedor).
- **[x]** `pgdata_oxxo` sigue en `docker volume ls`, y `docker inspect
  postgres-oxxo` confirma el mismo mount
  (`/var/lib/docker/volumes/pgdata_oxxo/_data` →
  `/var/lib/postgresql/data`).
- **[x]** `postgres-oxxo` levantó `healthy` sobre ese mismo volumen (el
  stack ya estaba arriba tras el reinicio, no hizo falta `docker-compose
  up -d`).
- **[x]** `airflow dags list` → `cx_intelligence_pipeline` sigue
  `is_paused = True`.

**[RESUELTO 2026-07-06] Riesgo de espacio en C: cerrado — vdisk movido a D:**

Se movió el "Disk image location" de Docker Desktop de
`C:\Users\CRABAGO\AppData\Local\Docker\wsl` a `D:\DockerData` vía
Settings → Resources → Advanced (GUI, no vía WSL manual — esta versión
de Docker Desktop usa una sola distro WSL, `docker-desktop`, sin
`docker-desktop-data` separada, así que el disco de datos se maneja como
VHD adjunto, no como distro independiente).

**Primer intento fallido, diagnosticado antes de reintentar**: un primer
"Apply & Restart" no aplicó ningún cambio real — confirmado con evidencia
real, no solo asumido: ningún archivo bajo `%APPDATA%\Docker` cambió de
fecha, el vhdx viejo en `C:` siguió activo (fecha de modificación
posterior al intento), `D:\DockerData` quedó vacío, y `C:` incluso
empeoró (1.88 GB → 0.64 GB libres) por uso normal mientras tanto. Captura
de pantalla confirmó la causa: el campo "Disk image location" seguía
mostrando la ruta vieja y el botón Apply estaba deshabilitado — el
diálogo de "Browse" nunca había confirmado la nueva ruta la primera vez.

**Segundo intento, verificado con evidencia real tras Apply & Restart**:
- `D:\DockerData\DockerDesktopWSL\disk\docker_data.vhdx` (14.94 GB) y
  `...\main\ext4.vhdx` — confirmados en `D:`, con fecha de modificación
  del momento de la migración. La ruta vieja en `C:` ya no tiene ningún
  `.vhdx`.
- `C:` pasó de **0.64 GB a 15.64 GB libres**.
- Los 8 contenedores del stack volvieron solos, todos `healthy`, sin
  necesidad de `docker-compose up -d`.
- `pgdata_oxxo` — mismo volumen, mismo mount
  (`/var/lib/docker/volumes/pgdata_oxxo/_data` → `/var/lib/postgresql/data`).
- `SELECT count(*) FROM dwh.fact_tickets` → **100,600**, sin cambios.

Ya no es el sospechoso #1 para un futuro ENOSPC — `C:` tiene margen real
de nuevo, y el crecimiento futuro del vdisk ocurre en `D:` (722 GB
libres).

### 8.4 [RESUELTO 2026-07-06] Árbol de estructura del README actualizado con archivos nuevos y verificado contra el disco

El árbol de "Estructura del Proyecto" del README seguía siendo en gran
parte aspiracional (incluía `sql/`, `dashboards/`, `notebooks/`,
`ARCHITECTURE.md`, `DATA_MODEL.md`, `.github/workflows/`,
`requirements.txt`, `.env.example`, `ai/executive_summary/` —
ninguno existe en este checkout) y no reflejaba los archivos nuevos de
esta sesión (`FASE_{B,C,D}_RESULTADOS.md`, `train_classifier.py`,
`seed_corpus_clientes.py`, `seed_corpus_colaboradores.py`,
`text_generator.py`, `metrics_fase_{b,c,d}.json`).

Se reconstruyó el árbol completo a partir de `Get-ChildItem -Recurse`
real (no de memoria) y se reemplazó por completo, con una nota explícita
al inicio de la sección aclarando que los artefactos mencionados en otras
partes del README (dashboards, notebooks, SQL, docs de arquitectura,
tests, CI) no están en este repo — para no repetir la misma
inconsistencia que motivó las correcciones de §8.1.

### 8.5 [RESUELTO 2026-07-06] Quick Start, Tech Stack y Módulo 4 corregidos — última ronda de revisión final

Al pedir una revisión final completa del README, se releyó de punta a
punta (no solo las secciones ya tocadas) y aparecieron más comandos/rutas
que nunca existieron en este checkout, todos en "🚀 Quick Start":
`generate_external_tickets.py`/`generate_internal_tickets.py` (los reales
son `generate_data.py` y `generate_ticket_samples.py`),
`scripts/init_db.py`, `etl/pipeline.py`, `requirements.txt`
(el real es `requirements-ai.txt`), `.env.example` (el real es `.env`,
ya con las credenciales de `postgres-oxxo`), y
`ai/executive_summary/generator.py`.

**Hallazgo adicional, más serio que un typo de ruta**: se confirmó con
`grep -r "CREATE TABLE|CREATE SCHEMA"` sobre todo el repo — **cero
resultados**. No existe ningún DDL en este checkout para crear los
esquemas `dwh`/`audit`/`marts`/`staging` desde cero. `generate_data.py`
asume que el esquema ya existe; el volumen `pgdata_oxxo` que sí lo tiene
está declarado `external: true` en `docker-compose.yaml` (a propósito,
para que `down -v` no lo borre — ver §3.7), lo cual también significa que
Compose no lo crea. **Reproducir este proyecto en una máquina nueva sin
ese volumen no funcionaría con los comandos del Quick Start** — se
documentó esto explícitamente en el README en vez de ocultarlo detrás de
instrucciones que no funcionarían.

Se corrigió también: Tech Stack (Jupyter, Power BI Desktop, Claude API
marcados como "planeado, no implementado en este checkout" en vez de
listados sin nota), y Módulo 4 (Executive Summary Generator) marcado
explícitamente como no implementado — no tiene código en el repo, a
diferencia de los Módulos 1-3 que sí tienen modelos entrenados y métricas
reales.

### 8.6 [RESUELTO 2026-07-07] Árbol de estructura desactualizado otra vez — le faltaba `train_sentiment.py`

Al mostrar el README completo tras el reentrenamiento de Fase C (§4.4), el
árbol de "Estructura del Proyecto" (§8.4) ya no reflejaba el disco real:
no listaba `data/synthetic/train_sentiment.py` (creado en §4.4) ni la nota
de `.bak` en `ai/sentiment/metrics_fase_c.json`, y la fecha de
verificación del árbol seguía en 2026-07-06. Confirmado con
`Get-ChildItem` real sobre `data/synthetic/` y `ai/` antes de corregir
(mismo criterio que siempre: verificar contra disco, no asumir). Se
agregó `train_sentiment.py` al árbol, la anotación `.bak` en
`metrics_fase_c.json`, y se actualizó la fecha de verificación a
2026-07-07.

**Patrón a vigilar**: esta es la segunda vez que el árbol de estructura
queda desactualizado por un cambio en otra sección (primero por Fase B en
§8.4, ahora por Fase C) — cualquier archivo nuevo creado en sesiones
futuras debería revisarse también contra este árbol antes de dar por
cerrada la tarea.
