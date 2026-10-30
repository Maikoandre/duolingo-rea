-- Duolingo 6.102.4 — modelo de domínio reconstruído
--
-- ATENÇÃO: este schema NÃO existe no APK. O app não usa banco relacional para
-- domínio (só fila HTTP + ponteiro de Math, ver model.md).
--
-- Isto é engenharia reversa de DESIGN: os nomes de coluna vêm dos descritores
-- kotlinx.serialization das classes reais (nomes JSON da API), os tipos e as
-- cardinalidades vêm das classes Kotlin. Nomes de tabela e escolha de PK/FK são
-- proposta minha. Campos marcados "inferido" não têm nome recuperado no dex.
--
-- Fonte por tabela:
--   user              com.duolingo.data.user.User            (81 campos JSON)
--   user_course       com.duolingo.data.course.CourseProgressSummary (8)
--   course_path       com.duolingo.data.path.common.CoursePathInfo (14)
--   path_section      ...CoursePathSectionSummaryRemote (19)
--   path_unit         ...RemotePathUnitData (6) + CoursePathSectionData (3)
--   path_level        com.duolingo.data.home.path.PathLevelId / PathLevelMetadata
--   session           com.duolingo.core.session.SessionSurrogate (26)
--   session_context   ...SessionContextSurrogate (8)
--   challenge         com.duolingo.core.challenges.ChallengeSurrogate (181)
--   xp_event          com.duolingo.core.session.XpEvent (4)
--   streak            com.duolingo.data.streak.StreakData (5)
--   achievement       com.duolingo.data.achievements.Achievement (8)
--   user_achievement  ...AchievementsState (1) + Achievement.unlockTimestamps
--   league            com.duolingo.core.leagues.League (enum, 10 tiers)
--   subscription      com.duolingo.data.plus.SubscriptionInfo (10)

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------- usuário

CREATE TABLE user (
  id                  TEXT PRIMARY KEY,          -- UserId
  username            TEXT NOT NULL,
  email               TEXT,
  first_name          TEXT,
  last_name           TEXT,
  picture             TEXT,
  creation_date       INTEGER,                   -- epoch ms
  timezone            TEXT,                      -- ex. "America/Sao_Paulo"
  from_language       TEXT,                      -- Language (código)
  learning_language   TEXT,
  current_course_id   TEXT,                      -- ref lógica: user_course(user_id, id)
  total_xp            INTEGER NOT NULL DEFAULT 0,
  xp_goal             INTEGER,                   -- meta diária
  has_plus            INTEGER NOT NULL DEFAULT 0,
  subscriber_level    TEXT,
  subscription_tenure INTEGER,
  roles               TEXT,                      -- JSON array
  tracking_properties TEXT,                      -- JSON
  -- demais 60 campos do User ficam no blob abaixo em vez de virar coluna
  raw_json            TEXT
);

CREATE INDEX index_user_username ON user (username);

-- ---------------------------------------------------------------- curso

CREATE TABLE user_course (
  id                          TEXT NOT NULL,     -- CourseId
  user_id                     TEXT NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  subject                     TEXT NOT NULL,     -- LANGUAGE | MATH | MUSIC | CHESS
  xp                          INTEGER NOT NULL DEFAULT 0,
  from_language               TEXT NOT NULL,
  learning_language           TEXT NOT NULL,
  author_id                   TEXT,
  topic                       TEXT,
  alphabets_path_progress_key TEXT,
  PRIMARY KEY (user_id, id)
);

CREATE INDEX index_user_course_learning ON user_course (user_id, learning_language);

CREATE TABLE course_path (
  course_id                TEXT NOT NULL,
  user_id                  TEXT NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  active_path_section_id   TEXT REFERENCES path_section(id),
  status                   TEXT NOT NULL,        -- CourseStatus
  path_details             TEXT,                 -- JSON (PathDetails)
  path_experiments         TEXT,                 -- JSON
  global_practice_metadata TEXT,                 -- JSON
  score_metadata           TEXT,                 -- JSON (CourseScoreMetadata)
  PRIMARY KEY (user_id, course_id),
  FOREIGN KEY (user_id, course_id) REFERENCES user_course(user_id, id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------- path

CREATE TABLE path_section (
  id                        TEXT PRIMARY KEY,    -- CoursePathSectionSummaryRemote.id
  course_id                 TEXT NOT NULL,
  user_id                   TEXT NOT NULL,
  section_index             INTEGER NOT NULL,
  title                     TEXT,
  subtitle                  TEXT,
  summary                   TEXT,
  example_sentence          TEXT,
  header_image              TEXT,
  reference_id              TEXT,
  debug_name                TEXT,
  cefr                      TEXT,
  total_units               INTEGER NOT NULL DEFAULT 0,
  completed_units           INTEGER NOT NULL DEFAULT 0,
  total_levels              INTEGER NOT NULL DEFAULT 0,
  total_levels_per_unit     TEXT,                -- JSON array
  completed_levels_per_unit TEXT,                -- JSON array
  first_unit_test_node      TEXT,
  last_unit_review_node     TEXT,
  section_starting_score    INTEGER,
  section_ending_score      INTEGER,
  FOREIGN KEY (user_id, course_id) REFERENCES course_path(user_id, course_id) ON DELETE CASCADE
);

CREATE INDEX index_path_section_course ON path_section (user_id, course_id, section_index);

CREATE TABLE path_unit (
  id                              INTEGER PRIMARY KEY,
  section_id                      TEXT NOT NULL REFERENCES path_section(id) ON DELETE CASCADE,
  unit_index                      INTEGER NOT NULL,   -- PathUnitIndex
  learning_unit_type              TEXT,               -- LearningUnitType
  teaching_objective             TEXT,
  total_spaced_repetition_sessions INTEGER NOT NULL DEFAULT 0,
  guidebook                       TEXT,               -- JSON (Guidebook)
  UNIQUE (section_id, unit_index)
);

CREATE TABLE path_level (
  id           TEXT PRIMARY KEY,   -- PathLevelId.value
  unit_id      INTEGER NOT NULL REFERENCES path_unit(id) ON DELETE CASCADE,
  level_index  INTEGER NOT NULL,   -- posição dentro da unidade (inferido)
  node_type    TEXT,               -- discriminator da sealed hierarchy (inferido)
  metadata     TEXT,               -- JSON (PathLevelMetadata é JsonElement opaco)
  client_data  TEXT                -- JSON (PathLevelClientData.*)
);

CREATE INDEX index_path_level_unit ON path_level (unit_id, level_index);

-- ---------------------------------------------------------------- sessão

CREATE TABLE session (
  id                       TEXT PRIMARY KEY,     -- SessionSurrogate.id
  user_id                  TEXT NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  course_id                TEXT,                 -- inferido a partir de from/learningLanguage
  skill_id                 TEXT,
  level_index              INTEGER,
  level_session_index      INTEGER,
  session_type             TEXT,                 -- SessionTypeInfo / replacedSessionType
  from_language            TEXT,
  learning_language        TEXT,
  is_v2                    INTEGER NOT NULL DEFAULT 0,
  beginner                 INTEGER NOT NULL DEFAULT 0,
  explanation              TEXT,
  challenge_time_taken_cutoff INTEGER,
  show_best_translation_in_grading_ribbon INTEGER,
  disable_hints_override   INTEGER,
  disable_cant_listen_override INTEGER,
  metadata                 TEXT,                 -- JSON
  tracking_properties      TEXT,                 -- JSON
  feedback_properties      TEXT,                 -- JSON
  debug_properties         TEXT,                 -- JSON
  started_at               INTEGER,
  completed_at             INTEGER
);

CREATE INDEX index_session_user ON session (user_id, started_at);

CREATE TABLE session_context (
  session_id        TEXT PRIMARY KEY REFERENCES session(id) ON DELETE CASCADE,
  context_type      TEXT,
  focused_lexemes   TEXT,     -- JSON array
  example_sentences TEXT,     -- JSON array
  grammar_description TEXT,
  num_kcs_covered   INTEGER,
  close_threshold   REAL,
  pass_threshold    REAL,
  perfect_threshold REAL
);

-- bucket = de qual lista da sessão o desafio veio:
-- challenges | adaptiveChallenges | postAdaptiveChallenges |
-- mistakesReplacementChallenges | adaptiveInterleavedChallenges
CREATE TABLE session_challenge (
  session_id   TEXT NOT NULL REFERENCES session(id) ON DELETE CASCADE,
  challenge_id TEXT NOT NULL REFERENCES challenge(id) ON DELETE CASCADE,
  bucket       TEXT NOT NULL DEFAULT 'challenges',
  ordinal      INTEGER NOT NULL,
  PRIMARY KEY (session_id, bucket, ordinal)
);

CREATE TABLE challenge (
  id            TEXT PRIMARY KEY,   -- ChallengeSurrogate.id
  type          TEXT NOT NULL,      -- discriminador do sealed Challenge (inferido)
  prompt        TEXT,
  correct       INTEGER,            -- boolean
  correct_index INTEGER,
  correct_solutions TEXT,           -- JSON
  metadata      TEXT,               -- JSON
  challenge_blob TEXT,              -- JSON
  grader        TEXT
);

-- ---------------------------------------------------------------- progresso

CREATE TABLE xp_event (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id    TEXT NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  time       INTEGER NOT NULL,
  xp         INTEGER NOT NULL,
  event_type TEXT NOT NULL,
  skill_id   TEXT
);

CREATE INDEX index_xp_event_user_time ON xp_event (user_id, time);

CREATE TABLE streak (
  user_id            TEXT PRIMARY KEY REFERENCES user(id) ON DELETE CASCADE,
  length             INTEGER NOT NULL DEFAULT 0,
  start_timestamp    INTEGER,
  updated_timestamp  INTEGER,
  updated_time_zone  TEXT,
  xp_goal            INTEGER
);

-- ---------------------------------------------------------------- gamificação

CREATE TABLE achievement (
  name              TEXT PRIMARY KEY,
  tier              INTEGER NOT NULL DEFAULT 0,
  count             INTEGER NOT NULL DEFAULT 0,
  tier_counts       TEXT,      -- JSON
  rewards           TEXT,      -- JSON
  unlock_timestamps TEXT,      -- JSON
  is_max_tier       INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE user_achievement (
  user_id          TEXT NOT NULL REFERENCES user(id) ON DELETE CASCADE,
  achievement_name TEXT NOT NULL REFERENCES achievement(name) ON DELETE CASCADE,
  tier             INTEGER NOT NULL,
  unlocked_at      INTEGER,
  PRIMARY KEY (user_id, achievement_name)
);

-- Lookup fixo: League é enum no código, não entidade do usuário.
CREATE TABLE league (
  id       TEXT PRIMARY KEY,   -- bronze, silver, gold, sapphire, ruby,
  name     TEXT NOT NULL,      -- emerald, amethyst, pearl, obsidian, diamond
  ordinal  INTEGER NOT NULL
);

INSERT INTO league (id, name, ordinal) VALUES
  ('bronze',   'Bronze League',   0),
  ('silver',   'Silver League',   1),
  ('gold',     'Gold League',     2),
  ('sapphire', 'Sapphire League', 3),
  ('ruby',     'Ruby League',     4),
  ('emerald',  'Emerald League',  5),
  ('amethyst', 'Amethyst League', 6),
  ('pearl',    'Pearl League',    7),
  ('obsidian', 'Obsidian League', 8),
  ('diamond',  'Diamond League',  9);

CREATE TABLE subscription (
  user_id                 TEXT PRIMARY KEY REFERENCES user(id) ON DELETE CASCADE,
  product_id              TEXT NOT NULL,
  currency                TEXT,
  price                   TEXT,
  renewing                INTEGER NOT NULL DEFAULT 0,
  is_free_trial_period    INTEGER NOT NULL DEFAULT 0,
  period_length           TEXT,
  expected_expiration_ms  INTEGER,
  renewer                 TEXT,
  vendor_purchase_id      TEXT
);
