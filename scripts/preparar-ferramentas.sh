#!/usr/bin/env bash
# Prepara o ReVanced CLI e os patches oficiais e valida os recursos desejados.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p tools output

if ! command -v gh >/dev/null; then echo "GitHub CLI (gh) nao encontrado" >&2; exit 1; fi
if ! command -v java >/dev/null; then echo "Java nao encontrado" >&2; exit 1; fi
if [[ -z "${GH_TOKEN:-}" ]]; then echo "Variavel GH_TOKEN ausente" >&2; exit 1; fi

# ReVanced CLI 6 usa o formato RVP do Patcher 22.
gh release download v6.0.0 \
  --repo ReVanced/revanced-cli \
  --pattern '*-all.jar' \
  --dir tools --clobber

mapfile -t candidates < <(find tools -maxdepth 1 -name '*-all.jar' -type f)
[[ ${#candidates[@]} -eq 1 ]] || { echo "Esperado exatamente um JAR CLI" >&2; exit 1; }
mv -f "${candidates[0]}" tools/revanced-cli.jar

curl --fail --location --retry 3 --silent --show-error \
  'https://api.revanced.app/v5/patches.rvp' --output tools/patches.rvp
[[ -s tools/revanced-cli.jar && -s tools/patches.rvp ]]

java -jar tools/revanced-cli.jar list-patches --packages --versions -bp tools/patches.rvp \
  > output/patches-disponiveis.txt

required=(
  "GmsCore support"
  "Hide ads"
  "SponsorBlock"
  "Spoof video streams"
  "Remove background playback restrictions"
)
for patch in "${required[@]}"; do
  if ! grep -Fq "$patch" output/patches-disponiveis.txt; then
    echo "Patch necessario nao encontrado: $patch" >&2
    echo "As versoes e nomes de patches mudam; ajuste o projeto antes de compilar." >&2
    exit 1
  fi
done
echo "Ferramentas e cinco patches essenciais validados."
