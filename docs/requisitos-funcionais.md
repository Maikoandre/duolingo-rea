# Requisitos funcionais de alto nível — Duolingo Android 6.102.4

Documento derivado do APK `com.duolingo` 6.102.4 (versionCode 2481) por engenharia reversa: manifest decodificado, inventário de pacotes, enums e modelos de dados. Não é a especificação oficial — é o comportamento que o binário declara.

**Escala do app:** 62 módulos em `com.duolingo/`, 76 em `feature/`, 88 em `core/`, 79 em `data/`, 489 activities, 113 tipos de desafio, 54 idiomas, 18.111 entradas no pacote.

Convenção de evidência: cada requisito cita o pacote ou classe que o comprova. Itens marcados **(inferido)** não têm nome explícito no dex.

---

## 1. Conta e autenticação

- **RF-01** Criar conta por e-mail, Google ou Facebook; login por telefone/SMS.
  *Evidência:* `signuplogin/`, `core/account/`, `User.googleId`, `facebookId`, `phoneNumber`, `requiresSsoLogin`. Sem evidência de Apple Sign-In no dex.
- **RF-02** Suportar login social vinculado e desvinculado da mesma conta.
  *Evidência:* `hasGoogleId`, `hasFacebookId`, `deanonymizedSpeechShareEnabled`, `PersistentCookieStore`.
- **RF-03** Manter sessão autenticada entre execuções, com cookies persistidos.
  *Evidência:* `core/networking/PersistentCookieStore`, `core/integrity/`.
- **RF-04** Excluir conta e limpar dados locais.
  *Evidência:* `core/cleanup/`, `settings/`.
- **RF-05** Aplicar papéis e permissões de conta (ex.: moderador, aluno de escola).
  *Evidência:* `User.roles`, `shouldPreventMonetizationForSchoolsUser`.

## 2. Onboarding e escolha de curso

- **RF-06** Perguntar idioma de origem, idioma de destino e motivo do aprendizado.
  *Evidência:* `onboarding/`, `User.motivation`, `data/user/UserMotivation`.
- **RF-07** Permitir pular o onboarding e adiar o cadastro completo.
  *Evidência:* `delaysignup/`, `signuplogin/`.
- **RF-08** Exibir trilha de idiomas disponíveis e permitir trocar de curso ativo.
  *Evidência:* `core/language/Language` (54 valores), `User.currentCourseId`, `data/course/`.

## 3. Sessão de aprendizado

- **RF-09** Executar uma sessão de lição composta por uma sequência de desafios.
  *Evidência:* `core/session/Session`, `SessionSurrogate` (26 campos), `session/`.
- **RF-10** Suportar 113 tipos de desafio, incluindo tradução, escuta, fala, ditado, lacunas, correspondência, diálogo, flashcards, traçado de caracteres, matemática e xadrez.
  *Evidência:* `core/challenges/ChallengeType` (113 constantes).
- **RF-11** Corrigir respostas localmente e classificar erro próximo / aceitável / errado por limiares.
  *Evidência:* `SessionContext.closeThreshold`, `passThreshold`, `perfectThreshold`, `core/challenges/grading/`.
- **RF-12** Explicar respostas erradas com conteúdo vindo do servidor.
  *Evidência:* `explanations/`, `core/challenges/explanations/`, `ExplanationElementModel`.
- **RF-13** Adaptar a dificuldade durante a sessão e intercalar desafios de reforço.
  *Evidência:* `SessionSurrogate.adaptiveChallenges`, `postAdaptiveChallenges`, `adaptiveInterleavedChallenges`, `mistakesReplacementChallenges`.
- **RF-14** Reproduzir áudio, sintetizar fala e gravar microfone.
  *Evidência:* `core/audio/`, `speechrecognition/`, `opuscodec/`, permissão `RECORD_AUDIO`.
- **RF-15** Encerrar a sessão com resumo, XP, acertos e recompensas.
  *Evidência:* `sessionend/`, `feature/sessionend`, `core/session/XpEvent`.

## 4. Trilha de progressão (path)

- **RF-16** Organizar o conteúdo em curso → seção → unidade → nível.
  *Evidência:* `CoursePathInfo`, `CoursePathSectionSummaryRemote` (19 campos), `RemotePathUnitData`, `PathLevelId`.
- **RF-17** Exibir estado de conclusão por seção, unidade e nível, com contadores.
  *Evidência:* `completedUnits`, `totalUnits`, `completedLevelsPerUnit`, `totalLevelsPerUnit`.
- **RF-18** Aplicar testes de unidade e revisões de unidade no fim de cada bloco.
  *Evidência:* `firstUnitTestNode`, `lastUnitReviewNode`, `PathLevelClientData.UnitTest`, `UnitReview`.
- **RF-19** Desbloquear nós sequencialmente e destacar o próximo nó disponível.
  *Evidência:* `UserPositionToNode`, `PathLevelClientData.AlphabetGate`.
- **RF-20** Oferecer abas alternativas de conteúdo por curso (ex.: seção, histórias, prática).
  *Evidência:* `pathTabsSummary`, `feature/coursetabs`.

## 5. Modalidades de prática

- **RF-21** Praticar revisão espaçada de itens já vistos.
  *Evidência:* `spacedRepetitionSession`, `totalSpacedRepetitionSessions`.
- **RF-22** Praticar erros recentes e lições específicas sob demanda.
  *Evidência:* `mistakesReplacementChallenges`, `SessionTypeInfo` (tipos de sessão de prática).
- **RF-23** Consumir histórias interativas com diálogo e escolhas.
  *Evidência:* `stories/`, `data/stories/`, `GenericStorySession`.
- **RF-24** Ouvir DuoRadio com sessões de escuta guiada.
  *Evidência:* `duoradio/`, `core/duoradio/`, `DuoRadioSummary`.
- **RF-25** Jogar aventuras narrativas com personagens e cenários próprios.
  *Evidência:* `adventures/`, `adventureslib/data/Episode`, `Environment`.
- **RF-26** Conversar por roleplay e videochamada com IA.
  *Evidência:* `feature/roleplay`, `videocall/`, `SessionTypeInfo.VideoCall`, `core/ai/`.
- **RF-27** Aprender matemática com trilha, desafios e calculadora próprios.
  *Evidência:* `math/`, `androidmath/`, `mathcalculator/`, `mathgrade/`, `MATH_*` (20 tipos).
- **RF-28** Aprender música com teclado, partitura e exercícios de percepção.
  *Evidência:* `music/`, `core/music/`, `instrumenttab`, `musicLessonSession`.
- **RF-29** Jogar xadrez com puzzles, partidas e revisão de jogo.
  *Evidência:* `chess/`, `CHESS_*`, `PathLevelClientData.Chess.GameReview`.
- **RF-30** Aprender alfabetos não latinos com traçado de caracteres.
  *Evidência:* `alphabets/`, `CHARACTER_TRACE*`, `AlphabetCourse` (20 campos).

## 6. Progresso, metas e streak

- **RF-31** Acumular XP por evento e totalizar por usuário e por curso.
  *Evidência:* `XpEvent{time, xp, eventType, skillId}`, `User.totalXp`, `CourseProgressSummary.xp`.
- **RF-32** Definir meta diária de XP e acompanhar seu cumprimento.
  *Evidência:* `User.xpGoal`, `goals/`, `streakGoal`.
- **RF-33** Manter streak diário com data de início, atualização, fuso e congelamentos.
  *Evidência:* `StreakData{length, startTimestamp, updatedTimestamp, updatedTimeZone, xpGoal}`, `streak/`, `feature/streakfreeze`.
- **RF-34** Recuperar streak perdido e celebrar marcos de streak.
  *Evidência:* `resurrection/`, `feature/streakincreased`, `streakjackpot`, `streaksociety`.
- **RF-35** Conceder conquistas com tiers, contadores e datas de desbloqueio.
  *Evidência:* `Achievement{name, tier, count, tierCounts, rewards, unlockTimestamps}`, `achievements/`.
- **RF-36** Exibir calendário de streak e retrospectiva anual.
  *Evidência:* `feature/streakcalendar`, `feature/yearinreview`.

## 7. Social e competição

- **RF-37** Adicionar amigos, seguir usuários e ver feed de atividades.
  *Evidência:* `data/friends/`, `feed/`, `followsuggestions/`.
- **RF-38** Competir em ligas semanais com ranking e promoção/rebaixamento.
  *Evidência:* `leagues/`, `core/leagues/League` (10 tiers: bronze a diamond), `LeaderboardType`.
- **RF-39** Manter streak de amizade e missões cooperativas.
  *Evidência:* `friendStreak/`, `friendsquest/`, `FriendsQuestToFriendStreakConversion`.
- **RF-40** Enviar e receber mensagens e reações no app.
  *Evidência:* `messages/`, `LeaguesReactionVia`, `HomeMessageBottomSheet`.
- **RF-41** Compartilhar progresso e convidar amigos por link.
  *Evidência:* `share/`, `referral/`, `User.inviteURL`.

## 8. Economia interna

- **RF-42** Gerenciar gemas, itens e inventário do usuário.
  *Evidência:* `shop/`, `core/shop/`, `User.shopItems`, `GemsConfig`, `data/shop/InventoryItem`.
- **RF-43** Vender itens: congelamento de streak, boosts de XP, baús, roupas de mascote.
  *Evidência:* `tieredchest/`, `xpboost/`, `avatar/`, `InventoryItem`.
- **RF-44** Limitar consumo por energia e permitir recarga por tempo, gemas ou vídeo.
  *Evidência:* `energy/`, `core/energy/EnergyConfig`, `MsneGemRechargeCopyCondition`.
- **RF-45** Distribuir recompensas em pacotes configuráveis pelo servidor.
  *Evidência:* `core/rewards/RewardBundle`, `User.rewardBundles`, `data/shop/CurrencyAndItemRewardBundleOptions`.

## 9. Assinatura e monetização

- **RF-46** Oferecer planos pagos (Super/Max) com compra e renovação via Google Play.
  *Evidência:* `plus/`, `core/billing/`, `SubscriptionInfo{productId, price, renewing, expectedExpirationMs}`, `SubscriptionRenewalSource{ANDROID, APPLE, WEB, PREPAID, NONE}`, permissão `BILLING`.
- **RF-47** Suportar teste grátis, período de renovação e histórico de assinatura.
  *Evidência:* `isFreeTrialPeriod`, `periodLength`, `subscriptionTenure`, `subscriberLevel`.
- **RF-48** Oferecer plano familiar com membros e convites.
  *Evidência:* `familyplan/`, `FamilyPlanInfo`, `family_plan_add_member`.
- **RF-49** Exibir anúncios para usuários gratuitos, com decisão vinda do backend.
  *Evidência:* `ads/`, `BackendInterstitialAdDecisionRequest`, `LessonAdFragment`, `hasPlus`.
- **RF-50** Usar mediação de anúncios com múltiplas redes.
  *Evidência:* SDKs presentes no dex: Google AdMob, Meta Audience Network, Unity Ads, IronSource, Pangle/ByteDance, Moloco.
- **RF-51** Aplicar descontos e promoções contextuais.
  *Evidência:* `promocode/`, `plusDiscounts`, `PlusDiscount`, `feature/promo`.

## 10. Escolas

- **RF-52** Entrar em turma escolar por código e participar de atividades de classe.
  *Evidência:* `schools/SchoolsClassroom`, `joinedClassroomIds`, `observedClassroomIds`, `classroomLeaderboardsEnabled`.
- **RF-53** Desativar monetização e anúncios para contas escolares.
  *Evidência:* `shouldPreventMonetizationForSchoolsUser`.

## 11. Notificações

- **RF-54** Registrar dispositivo para push e receber notificações segmentadas.
  *Evidência:* `notifications/`, `DeviceRegistrationRepository`, `com.google.android.c2dm.permission.RECEIVE`.
- **RF-55** Permitir controle granular de tipos de push (streak, ligas, promoções, família, amigos).
  *Evidência:* `User.pushStreakFreezeUsed`, `pushLeaderboards`, `pushPromotion`, `pushFamilyPlanNudge`, `pushFriendStreakNudge`.
- **RF-56** Agendar lembretes locais com alarme exato e ícone de badge.
  *Evidência:* permissões `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `READ_APP_BADGE`.
- **RF-57** Oferecer notificações em tela cheia e por e-mail.
  *Evidência:* `USE_FULL_SCREEN_INTENT`, `NotificationDisplayStyle`, `User.emailStreakFreezeUsed`.

## 12. Offline

- **RF-58** Enfileirar requisições HTTP feitas sem rede e reenviá-las ao reconectar.
  *Evidência:* banco `queued-requests` v4 (`sql/queued_requests.sql`), `QueuedRequestsStore`.
- **RF-59** Pré-baixar sessões e recursos para uso offline, com expiração.
  *Evidência:* `core/offline/OfflineManifest` (28 dias / 1 dia), `PrefetchedPathSessionKey`.
- **RF-60** Retomar a última sessão de Math interrompida.
  *Evidência:* banco `math` v7 (`sql/math.sql`).

## 13. Personalização e experimentos

- **RF-61** Aplicar experimentos e feature flags definidos pelo servidor.
  *Evidência:* `core/experiments/` (dezenas de `*Experiments`), `AttemptedTreatmentsDataSource`.
- **RF-62** Personalizar avatar, tema e ícone do app.
  *Evidência:* `avatar/`, `feature/avatar`, `feature/appicon`, `CharacterTheme`.
- **RF-63** Ajustar configurações de conta, privacidade, som, vibração e acessibilidade.
  *Evidência:* `settings/`, `PrivacySetting`, `feature/haptics`, `data/settings/`.

## 14. Plataforma e integração

- **RF-64** Abrir telas por deep link (`duolingo://`, https) e receber retorno de OAuth.
  *Evidência:* schemes `duolingo`, `duolingo-linkedin-android`, `fbconnect`, `core/deeplink/`, `deeplinks/`.
- **RF-65** Integrar com calendário e contatos do dispositivo.
  *Evidência:* permissões `READ_CALENDAR`/`WRITE_CALENDAR`, `READ_CONTACTS`, `contactsync/`.
- **RF-66** Autenticar por biometria para proteger a conta.
  *Evidência:* permissões `USE_BIOMETRIC`/`USE_FINGERPRINT`.
- **RF-67** Detectar captura de tela e aplicar política de conteúdo.
  *Evidência:* permissão `DETECT_SCREEN_CAPTURE`, `shakeToReportEnabled`.
- **RF-68** Reportar conteúdo impróprio e enviar feedback.
  *Evidência:* `report/`, `feedback/`.
- **RF-69** Localizar interface e conteúdo em dezenas de idiomas.
  *Evidência:* `core/localization/`, `feature/localization/livestrings`, 54 valores em `Language`.
- **RF-70** Medir atribuição, analytics e erros com SDKs de terceiros.
  *Evidência:* `core/adjust/`, Amplitude (`user-properties.db`), Firebase, `com/apm/insight`.

---

## Fora do escopo deste documento

- Requisitos não funcionais (desempenho, disponibilidade, segurança) não foram levantados aqui.
- Regras de negócio do servidor: o app só declara o contrato, não a lógica. Limiares, preços e conteúdo vêm da API.
- Itens marcados **(inferido)** carecem de nome explícito no dex e vêm de estrutura de pacote ou de SDK presente.

## Rastreabilidade

| Grupo | Onde verificar |
|---|---|
| Manifest, permissões, deep links | `apktool_out/AndroidManifest.xml` |
| Modelos de rede e enums | `decompiled/com/duolingo/data/`, `core/` |
| Desafios e correção | `core/challenges/` |
| Bancos locais | `sql/queued_requests.sql`, `sql/math.sql`, `sql/model.md` |
| Modelo de domínio | `sql/domain_model.sql`, `sql/domain_erd.md` |
