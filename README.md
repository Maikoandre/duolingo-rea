# Duolingo APK — decompilação

Alvo: `Duolingo.apk` — `com.duolingo` versão **6.102.4** (versionCode 2481), 164 MB, 18.111 entradas.

## O que está no repositório

| Caminho | Conteúdo |
|---|---|
| `sql/` | análise: schema real dos bancos SQLDelight, modelo de domínio reconstruído, ERD |
| `run_jadx.sh` | reprocesso por dex |
| `fetch-tools.sh` | baixa jadx 1.5.6 + apktool 3.0.3 |

## Saída local (não versionada)

Tudo abaixo é derivado do APK e fica fora do git (`.gitignore`):

| Caminho | Conteúdo |
|---|---|
| `decompiled/` | Código Java (jadx 1.5.6, 80.304 arquivos) |
| `apktool_out/` | `AndroidManifest.xml`, `res/`, `assets/`, `original/`, dex originais (apktool 3.0.3) |
| `dex/` | 11 dex extraídos (10 `classes*.dex` + `assets/audience_network.dex`) |
| `jadx_out/` | saída intermediária por dex |
| `tools/` | jadx 1.5.6 + apktool 3.0.3 |

## Fatos do pacote

- 10 dex principais, 93.716 classes, 430.186 métodos.
- `defpackage/` — 44.329 arquivos: código R8/obfuscado, sem nome de pacote original.
- `com/duolingo/` — 9.535 arquivos: módulos de app (achievements, ads, adventures, ai, alphabets, billing, chess, core, data, deeplinks, duoradio, ...).
- `com/google/` 11.878, `com/facebook/` 728, `androidx/` 657.
- Manifest: 489 activities, 17 services, 22 receivers, 12 providers.
- `assets/audience_network.dex` é SDK separado (Meta Audience Network), não faz parte do código do app.

## Reprocessar

```bash
./fetch-tools.sh          # baixa jadx + apktool
# coloque Duolingo.apk na raiz (não versionado)

# recursos + manifest (sem smali)
java -jar tools/apktool.jar d -s -f -o apktool_out Duolingo.apk

# dex por dex (o -jar abre a GUI e trava; usar a classe CLI)
./run_jadx.sh

# dex único
java -Xmx1600m -cp tools/jadx/lib/jadx-1.5.6-all.jar jadx.cli.JadxCLI \
  --no-res -d out dex/classes.dex
```

## Limites

- jadx reportou falhas por dex (2 a 156 métodos, ex. `StackOverflowError` em `app.rive`). Esses métodos saem com código parcial.
- Sem smali. Para patch/rebuild: `java -jar tools/apktool.jar d -f -o apktool_smali Duolingo.apk`.
- `--no-res` no jadx: recursos ficam só em `apktool_out/res`.

## Aviso

Este repositório não distribui o APK nem código descompilado do Duolingo. Contém apenas análise própria (schema, modelo, scripts). `Duolingo.apk`, `decompiled/`, `dex/` e `apktool_out/` são obra derivada de software proprietário e ficam fora do versionamento.
