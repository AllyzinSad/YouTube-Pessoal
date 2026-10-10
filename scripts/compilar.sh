#!/usr/bin/env bash
# Gera a versao paralela do YouTube preservando a identidade visual original.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p output

[[ -s tools/revanced-cli.jar && -s tools/patches.rvp ]] || {
  echo "Ferramentas ausentes: execute scripts/preparar-ferramentas.sh primeiro." >&2
  exit 1
}
[[ -s input/youtube.apk ]] || {
  echo "Falta o APK completo original em input/youtube.apk." >&2
  exit 1
}
unzip -tqq input/youtube.apk >/dev/null || {
  echo "O arquivo de entrada nao e um APK/ZIP integro." >&2
  exit 1
}
unzip -Z -1 input/youtube.apk | grep -Fxq "AndroidManifest.xml" || {
  echo "Arquivo nao e um APK Android valido (AndroidManifest.xml ausente)." >&2
  exit 1
}

patches=(
  "GmsCore support"
  "Hide ads"
  "SponsorBlock"
  "Spoof video streams"
  "Remove background playback restrictions"
)
args=()
for patch in "${patches[@]}"; do
  if ! grep -Fq "$patch" output/patches-disponiveis.txt; then
    echo "Patch obrigatorio indisponivel: $patch" >&2
    exit 1
  fi
  args+=(-e "$patch")
done

echo "Patches: ${patches[*]}"
echo "Branding original preservado; nao selecionamos patches de alteracao de nome/icone."
java -jar tools/revanced-cli.jar patch \
  -bp tools/patches.rvp \
  --exclusive \
  "${args[@]}" \
  --keystore output/youtube-personal.keystore \
  --out output/YouTube-Pessoal.apk \
  --purge \
  input/youtube.apk

[[ -s output/YouTube-Pessoal.apk ]] || {
  echo "Falha: APK compilado nao foi gerado." >&2
  exit 1
}
[[ -s output/youtube-personal.keystore ]] || {
  echo "Falha: assinatura do APK nao encontrada." >&2
  exit 1
}
sha256sum output/YouTube-Pessoal.apk | tee output/SHA256.txt
