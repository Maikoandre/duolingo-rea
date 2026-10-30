-- Duolingo 6.102.4 — banco "queued-requests" (SQLDelight 2.x, schema v4)
-- Fonte: com.duolingo.core.networking.persisted.data.db.networkingpersisted.QueuedRequestDatabaseImpl
--         (create-0iQ1-z0 = CREATE do v4; migrate-zeHU3Mk = 1→2→3→4)
-- DDL copiado literalmente das constantes do dex. Não reconstruído.
--
-- Fila de requisições HTTP persistida (offline-first). Grava request serializado,
-- corpo e estado; "Suspend" é a variante usada quando a fila está suspensa.

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS queuedRequest (
  id BLOB NOT NULL,
  request BLOB NOT NULL,
  request_body BLOB,
  time INTEGER NOT NULL,
  state TEXT NOT NULL,
  PRIMARY KEY(id)
);

CREATE TABLE IF NOT EXISTS queuedRequestUpdate (
  id BLOB NOT NULL,
  request_id BLOB NOT NULL,
  store TEXT NOT NULL,
  partition TEXT,
  PRIMARY KEY(id),
  FOREIGN KEY(request_id) REFERENCES queuedRequest(id) ON UPDATE RESTRICT ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS queuedRequestSuspend (
  id BLOB NOT NULL,
  request BLOB NOT NULL,
  request_body BLOB,
  time INTEGER NOT NULL,
  state TEXT NOT NULL,
  PRIMARY KEY(id)
);

CREATE TABLE IF NOT EXISTS queuedRequestUpdateSuspend (
  id BLOB NOT NULL,
  request_id BLOB NOT NULL,
  store TEXT NOT NULL,
  partition TEXT,
  PRIMARY KEY(id),
  FOREIGN KEY(request_id) REFERENCES queuedRequestSuspend(id) ON UPDATE RESTRICT ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS queuedRequestTracking (
  request_id BLOB NOT NULL,
  class_name TEXT NOT NULL,
  method_name TEXT NOT NULL,
  path TEXT NOT NULL,
  http_method TEXT NOT NULL,
  PRIMARY KEY(request_id)
);

CREATE TABLE IF NOT EXISTS queuedRequestTrackingSuspend (
  request_id BLOB NOT NULL,
  class_name TEXT NOT NULL,
  method_name TEXT NOT NULL,
  path TEXT NOT NULL,
  http_method TEXT NOT NULL,
  PRIMARY KEY(request_id)
);

CREATE INDEX IF NOT EXISTS index_queued_request_time ON queuedRequest (time);
CREATE INDEX IF NOT EXISTS index_queued_request_update_request_id ON queuedRequestUpdate (request_id);
CREATE INDEX IF NOT EXISTS index_queued_request_suspend_time ON queuedRequestSuspend (time);
CREATE INDEX IF NOT EXISTS index_queued_request_update_suspend_request_id ON queuedRequestUpdateSuspend (request_id);

-- Migrations (ordem exata do dex)
-- v1 -> v2: cria queued_request_tracking (request_id, class_name, method_name, path, http_method)
-- v2 -> v3: queued_request_update ganha nova forma (id, request_id, store, partition);
--           copia `update` -> store e `request` -> partition;
--           renomeia tabelas snake_case -> camelCase (queued_request -> queuedRequest, etc.);
--           recria indices; dropa room_master_table
-- v3 -> v4: cria queuedRequestSuspend + queuedRequestUpdateSuspend + indices
--           e queuedRequestTrackingSuspend
--
-- Sem FK de queuedRequestTracking -> queuedRequest: o tracking é independente.
