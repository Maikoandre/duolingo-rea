-- Duolingo 6.102.4 — banco "math" (SQLDelight 2.x, schema v7)
-- Fonte: defpackage.nhm (classe obfuscada; getVersion() = 7)
--         create() = DDL abaixo; migrate() = cadeia 1..6
-- Usado por com.duolingo Math (DatabaseFile.MATH), queries em defpackage.hsk / hg / ank.
--
-- Guarda só o ponto de retomada da última sessão de Math incompleta, por usuário.

CREATE TABLE IF NOT EXISTS lastIncompleteSessionStart (
  user_id INTEGER NOT NULL,
  section_group_reference_id TEXT DEFAULT NULL,
  section_reference_id TEXT DEFAULT NULL,
  PRIMARY KEY(user_id)
);

CREATE INDEX IF NOT EXISTS index_math_last_incomplete_session_start_user_id
  ON lastIncompleteSessionStart (user_id);

-- Migrations (ordem exata do dex)
-- v1 -> v2: math_last_session_start += section_index_app_session;
--           cria math_last_incomplete_session_start (user_id, section_index_app_open)
-- v2 -> v3: renomeia math_last_session_start -> lastSessionStart
--           e math_last_incomplete_session_start -> lastIncompleteSessionStart;
--           recria indices; dropa room_master_table
-- v3 -> v4: lastIncompleteSessionStart += section_index_app_open_v2
-- v4 -> v5: lastIncompleteSessionStart += section_group_reference_id, section_reference_id
-- v5 -> v6: dropa lastSessionStart (tabela morta)
-- v6 -> v7: rebuild de lastIncompleteSessionStart mantendo só
--           (user_id, section_group_reference_id, section_reference_id);
--           section_index_app_open_v2 é descartada
