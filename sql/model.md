# Modelagem de dados — Duolingo 6.102.4 (Android)

## Como isto foi obtido

1. Varredura de `decompiled/` por literais `CREATE TABLE` / `CREATE INDEX` / `ALTER TABLE`.
2. Identificação dos bancos pelo enum `com.duolingo.core.persistence.relational.DatabaseFile`, que lista todo arquivo de banco que o app abre.
3. Leitura das classes de schema SQLDelight 2.x: `create()` traz o DDL do esquema atual, `migrate()` traz a cadeia de versões.

Resultado: **339 literais DDL** no APK, dos quais **49 são do Duolingo** (2 bancos). O resto é SDK de terceiro.

Não há Room no código do app (`RoomDatabase` só aparece dentro de bibliotecas). Não há SQLCipher.

## Bancos que o app abre

Enum `DatabaseFile` — 12 entradas:

| Nome do arquivo | Dono | Schema recuperado |
|---|---|---|
| `queued-requests` | Duolingo | **sim, v4** → `sql/queued_requests.sql` |
| `math` | Duolingo | **sim, v7** → `sql/math.sql` |
| `offline_manifest.db` | Duolingo | parcial, v6 (ver abaixo) |
| `mvvm-example`, `mvvm-example-backend` | Duolingo (provável código de exemplo) | nenhum DDL no dex |
| `com.google.android.datatransport.events` | Firebase DataTransport | sim (6 tabelas) |
| `google_app_measurement_local.db` | Google Analytics | sim |
| `exoplayer_internal.db` | media3 | sim |
| `event-log-messages` | Firebase | sim |
| `log-messages` | Firebase | sim |
| `pending-updates` | Firestore | sim (`pendingUpdateEntry`) |
| `service-mapping` | Firebase | sim (`serviceMapping`) |

Bancos de terceiros fora do enum (não abertos pela camada relacional do app): WorkManager (`androidx.work`), Amplitude (`user-properties.db`), Moloco (`events`), Pangle/bytedance (`ttopensdk.db`, `ttadlog.db`, `pag_monitor.db`), IronSource (`supersonic_sdk.db`), AppsFlyer/apm.

## Banco `queued-requests` (v4)

Fila HTTP persistida, usada pelo `NetworkingPersistedModule` (`com.duolingo.core.networking.persisted`).

| Tabela | Papel | Entidade |
|---|---|---|
| `queuedRequest` | requisição pendente: `request` BLOB serializado, `request_body` BLOB, `time`, `state` | `QueuedRequest` |
| `queuedRequestUpdate` | updates parciais presos a uma requisição (`store`, `partition`) | `QueuedRequestUpdate` |
| `queuedRequestSuspend` | mesma coisa quando a fila está suspensa | `QueuedRequestSuspend` |
| `queuedRequestUpdateSuspend` | updates da fila suspensa | `QueuedRequestUpdateSuspend` |
| `queuedRequestTracking` | metadado de origem: `class_name`, `method_name`, `path`, `http_method` | `QueuedRequestTracking` |
| `queuedRequestTrackingSuspend` | idem, fila suspensa | `QueuedRequestTrackingSuspend` |

- `state` é `enum State { QUEUED, EXECUTING }`, gravado como TEXT.
- `id`/`request_id` são `UUID`, gravados como BLOB por `ColumnAdaptersKt.getUuidAdapter()`.
- `request_body` usa `getBodyAdapter()` (bytes + content-type).
- FK real: `queuedRequestUpdate.request_id → queuedRequest.id`, `ON DELETE CASCADE`. Sem FK em tracking.
- Consumo típico: `SELECT ... FROM queuedRequest ORDER BY time ASC LIMIT 1` (pega o mais antigo), `UPDATE ... SET state = ?`.

## Banco `math` (v7)

Guarda apenas o ponto de retomada da última sessão de Math incompleta, por usuário (`user_id` como PK).

Tabela única: `lastIncompleteSessionStart(user_id, section_group_reference_id, section_reference_id)`.
`lastSessionStart` existiu até a v5 e foi dropada na v6.

## Banco `offline_manifest.db` (v6) — vestigial

O schema (`defpackage.uhm`, obfuscado e mesclado com o schema do Firestore no mesmo arquivo) declara versão 6 e o `create()` dessa variante **não emite nenhum `CREATE TABLE`**.

O que sobrou no dex: `DROP TABLE` / `DELETE FROM` das tabelas antigas de cache de sessão — `lessonSession`, `levelReviewSession`, `lexemePracticeSession`, `spacedRepetitionSession`, `unitReviewSession`, `storiesSession`, `mathLessonSession`, `musicLessonSession`, `duoRadioSession`, `sessionMetadata`, `rawResource` e outras.

O conteúdo do "manifest" hoje é o objeto `com.duolingo.core.offline.OfflineManifest` (data class Kotlin serializada por Moshi), não tabelas. Conclusão: o banco existe para limpar esquema antigo; não é fonte de modelagem útil.

## O que não é SQL

Estado principal do app não está em banco relacional:

- 1.357 arquivos em `com/duolingo` usam `kotlinx.serialization` (payloads e estado serializado em arquivo/preferências).
- Só 8 arquivos usam `SharedPreferences`.
- Nenhum uso de protobuf em `com/duolingo`.
- Progresso, streak, path, ligas vêm da API e ficam em cache serializado, não em tabelas.

## Modelo de domínio reconstruído

O app não tem esse schema. Para ter um, foi feita engenharia reversa de *design* a partir das classes Kotlin:

- `domain_model.sql` — DDL de 16 tabelas (user, curso, path, sessão, desafio, xp, streak, conquistas, liga, assinatura).
- `domain_erd.md` — diagrama Mermaid + notas de modelagem.

Nomes de coluna vêm dos descritores `kotlinx.serialization` (nomes JSON reais da API). Tipos e cardinalidades vêm das classes. Nomes de tabela, PK/FK e normalização são proposta, não extração.

## Limites

- `defpackage.*` é código ofuscado por R8; nomes de classes não são os originais. Nomes de tabela/coluna sobrevivem como string e são confiáveis.
- O DDL acima é literal do dex para os bancos `queued-requests` e `math`. O `offline_manifest` é inferência a partir das migrations.
- Sem dados de runtime: não há `.db` extraído de dispositivo, então não há confirmação de esquema em uso, volume de linhas ou dados reais.
- jadx falhou em alguns métodos (ver `README.md`); nenhuma falha caiu nas classes de schema dos dois bancos recuperados.
