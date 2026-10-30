# ERD — modelo de domínio Duolingo (reconstruído)

Reconstrução de design a partir das classes Kotlin do APK 6.102.4. **Não é** o schema real do app: o app não guarda domínio em SQLite (ver `model.md`).

Legenda de evidência:

- **E** = nome de coluna extraído do descritor `kotlinx.serialization` da classe real (nome JSON da API).
- **I** = inferido (nome não recuperado no dex: campos obfuscados ou hierarquia sealed).

```mermaid
erDiagram
    USER ||--o{ USER_COURSE : "cursos"
    USER ||--|| STREAK : "streak"
    USER ||--o{ XP_EVENT : "xp"
    USER ||--o{ USER_ACHIEVEMENT : "conquistas"
    USER ||--o| SUBSCRIPTION : "plus"
    USER ||--o{ SESSION : "sessoes"

    USER_COURSE ||--|| COURSE_PATH : "path"
    USER_COURSE ||--o{ PATH_SECTION : "secoes"

    PATH_SECTION ||--o{ PATH_UNIT : "unidades"
    PATH_UNIT ||--o{ PATH_LEVEL : "niveis"

    SESSION ||--o| SESSION_CONTEXT : "contexto"
    SESSION ||--o{ SESSION_CHALLENGE : "desafios"
    CHALLENGE ||--o{ SESSION_CHALLENGE : "usado em"

    ACHIEVEMENT ||--o{ USER_ACHIEVEMENT : "tiers"

    USER {
        text id PK
        text username
        text email
        text first_name
        text last_name
        text picture
        int creation_date
        text timezone
        text from_language
        text learning_language
        text current_course_id
        int total_xp
        int xp_goal
        int has_plus
        text subscriber_level
        int subscription_tenure
        text roles
        text raw_json
    }

    USER_COURSE {
        text id PK
        text user_id PK
        text subject
        int xp
        text from_language
        text learning_language
        text author_id
        text topic
        text alphabets_path_progress_key
    }

    COURSE_PATH {
        text user_id PK
        text course_id PK
        text active_path_section_id
        text status
        text path_details
        text score_metadata
    }

    PATH_SECTION {
        text id PK
        text course_id
        text user_id
        int section_index
        text title
        text subtitle
        text cefr
        int total_units
        int completed_units
        int total_levels
        text total_levels_per_unit
        text completed_levels_per_unit
        text first_unit_test_node
        text last_unit_review_node
        int section_starting_score
        int section_ending_score
    }

    PATH_UNIT {
        int id PK
        text section_id
        int unit_index
        text learning_unit_type
        text teaching_objective
        int total_spaced_repetition_sessions
        text guidebook
    }

    PATH_LEVEL {
        text id PK
        int unit_id
        int level_index
        text node_type
        text metadata
        text client_data
    }

    SESSION {
        text id PK
        text user_id
        text skill_id
        int level_index
        int level_session_index
        text session_type
        text from_language
        text learning_language
        int is_v2
        int beginner
        text explanation
        text metadata
        int started_at
        int completed_at
    }

    SESSION_CONTEXT {
        text session_id PK
        text context_type
        text focused_lexemes
        text example_sentences
        text grammar_description
        int num_kcs_covered
        real close_threshold
        real pass_threshold
        real perfect_threshold
    }

    SESSION_CHALLENGE {
        text session_id PK
        text challenge_id PK
        text bucket PK
        int ordinal
    }

    CHALLENGE {
        text id PK
        text type
        text prompt
        int correct
        int correct_index
        text correct_solutions
        text metadata
        text challenge_blob
        text grader
    }

    XP_EVENT {
        int id PK
        text user_id
        int time
        int xp
        text event_type
        text skill_id
    }

    STREAK {
        text user_id PK
        int length
        int start_timestamp
        int updated_timestamp
        text updated_time_zone
        int xp_goal
    }

    ACHIEVEMENT {
        text name PK
        int tier
        int count
        text tier_counts
        text rewards
        text unlock_timestamps
        int is_max_tier
    }

    USER_ACHIEVEMENT {
        text user_id PK
        text achievement_name PK
        int tier
        int unlocked_at
    }

    LEAGUE {
        text id PK
        text name
        int ordinal
    }

    SUBSCRIPTION {
        text user_id PK
        text product_id
        text currency
        text price
        int renewing
        int is_free_trial_period
        text period_length
        int expected_expiration_ms
        text renewer
        text vendor_purchase_id
    }
```

## Notas de modelagem

**Path.** A hierarquia real é `CoursePathInfo → sections → units → levels`, e cada nível é um nó (`PathLevelId` é só um wrapper de `String`; `PathLevelMetadata` é um `JsonElement` opaco). Por isso `path_level.metadata` e `client_data` são JSON: o app não tipa o conteúdo, então normalizar seria invenção.

**Desafios.** `Challenge` é uma sealed hierarchy com 181 campos possíveis no descritor. `type` é o discriminador (I). O resto fica em `challenge_blob` porque só um subconjunto se aplica a cada tipo.

**Sessão.** `SessionSurrogate` tem cinco listas de desafios (`challenges`, `adaptiveChallenges`, `postAdaptiveChallenges`, `mistakesReplacementChallenges`, `adaptiveInterleavedChallenges`). Uma tabela de junção com `bucket` cobre todas sem duplicar esquema.

**Streak.** `StreakData` tem 5 campos; o `streak` numérico do `User` é redundante e pode ser derivado de `streak.length`.

**Liga.** `League` é enum fixo de 10 tiers, não entidade persistida. O ranking semanal vem da API e não é cacheado em SQL — não há tabela de standings porque não há evidência de modelo local para ela.

**User.** 81 campos no descritor. Só os de uso local viraram coluna; os outros 60 ficam em `raw_json` para não inventar semântica.
