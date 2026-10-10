#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p output

mapfile -t CLI_FILES < <(find tools -maxdepth 1 -type f -name '*-all.jar' | sort)
mapfile -t PATCH_FILES < <(find tools -maxdepth 1 -type f -name '*.rvp' | sort)
[[ ${#CLI_FILES[@]} -eq 1 ]] || { echo 'ReVanced CLI ausente ou duplicado' >&2; exit 1; }
[[ ${#PATCH_FILES[@]} -eq 1 ]] || { echo 'Bundle de patches ausente ou duplicado' >&2; exit 1; }
[[ -s input/youtube.apk ]] || { echo 'Falta input/youtube.apk' >&2; exit 1; }

CLI="${CLI_FILES[0]}"
PATCHES="${PATCH_FILES[0]}"
java -jar "$CLI" list-patches --packages --versions -bp "$PATCHES" > output/patches-disponiveis.txt

# Selecionar apenas os recursos solicitados. Nunca aplicar branding.
required=('GmsCore support' 'Hide ads' 'SponsorBlock' 'Remove background playback restrictions')
optional=('Video ads' 'Spoof video streams')
args=()
for patch in "${required[@]}"; do
  if ! grep -Fq "$patch" output/patches-disponiveis.txt; then
    echo "ERRO: patch essencial ausente: $patch. Consulte patches-disponiveis.txt no log." >&2
    exit 1
  fi
  args+=(-e "$patch")
done
for patch in "${optional[@]}"; do
  if grep -Fq "$patch" output/patches-disponiveis.txt; then
    args+=(-e "$patch")
  fi
done

echo "Patches escolhidos: ${args[*]}"
java -jar "$CLI" patch \
  -bp "$PATCHES" \
  --exclusive \
  "${args[@]}" \
  --keystore output/youtube-personal.keystore \
  --out output/YouTube-Pessoal.apk \
  --purge \
  input/youtube.apk
