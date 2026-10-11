#!/usr/bin/env bash
# Personalizacao da extensao ReVanced: visionOS por padrao e credito na pagina de configuracoes.
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -s tools/revanced-cli.jar ]] || { echo 'Falta tools/revanced-cli.jar'; exit 1; }
[[ -s output/YouTube-Pessoal.apk ]] || { echo 'Falta output/YouTube-Pessoal.apk'; exit 1; }
[[ -s output/youtube-personal.keystore ]] || { echo 'Falta output/youtube-personal.keystore'; exit 1; }

mkdir -p tools output
if [[ ! -s tools/apktool.jar ]]; then
  curl --fail --location --retry 3 --silent --show-error \
    https://github.com/iBotPeaches/Apktool/releases/download/v3.0.3/apktool_3.0.3.jar \
    -o tools/apktool.jar
fi
echo 'dbf930b076c6b9be08d57c449cacefc3bdd6b71ebd59b3066fc0e1f5b14f9423  tools/apktool.jar' | sha256sum -c -

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp output/YouTube-Pessoal.apk "$tmp/original.apk"

python3 - "$tmp" <<'PY'
import sys,zipfile,pathlib
r=pathlib.Path(sys.argv[1])
with zipfile.ZipFile(r/'original.apk') as z,zipfile.ZipFile(r/'extension.apk','w') as dst:
  dst.writestr('AndroidManifest.xml',z.read('AndroidManifest.xml'))
  dst.writestr('classes.dex',z.read('classes5.dex'))
PY

java -Xmx3500m -jar tools/apktool.jar d -r -f -o "$tmp/extension" "$tmp/extension.apk" > "$tmp/dex-decode.log" 2>&1
python3 - "$tmp" <<'PY'
import sys,pathlib
r=pathlib.Path(sys.argv[1]);p=r/'extension/smali/app/revanced/extension/youtube/settings/Settings.smali'
s=p.read_text()
old='sget-object v4, Lapp/revanced/extension/shared/spoof/ClientType;->ANDROID_REEL_NO_AUTH:Lapp/revanced/extension/shared/spoof/ClientType;'
new='sget-object v4, Lapp/revanced/extension/shared/spoof/ClientType;->VISIONOS:Lapp/revanced/extension/shared/spoof/ClientType;'
if s.count(old)!=1:raise SystemExit('Versao de extensao mudou: default nao localizado')
p.write_text(s.replace(old,new))
PY
java -Xmx2500m -jar tools/apktool.jar b "$tmp/extension" -o "$tmp/extension-fixed.apk" > "$tmp/dex-build.log" 2>&1

java -Xmx4500m -jar tools/apktool.jar d -s --no-assets -f -o "$tmp/app" "$tmp/original.apk" > "$tmp/resources-decode.log" 2>&1
python3 - "$tmp" <<'PY'
import pathlib,sys,zipfile
r=pathlib.Path(sys.argv[1]);decoded=r/'app'
for name in ('revanced_prefs.xml','revanced_prefs_icons.xml','revanced_prefs_icons_bold.xml'):
  p=decoded/'res/xml'/name;s=p.read_text()
  needle='android:key="revanced_spoof_video_streams_client_type"'
  if s.count(needle)!=1:raise SystemExit('Preferencia de cliente nao localizada')
  s=s.replace(needle,'android:defaultValue="VISIONOS" '+needle)
  credit='    <Preference android:title="Desenvolvido por AllyzinSad" android:selectable="false" android:key="allyzinsad_developer_credit" />\n'
  if not s.rstrip().endswith('</PreferenceScreen>'):raise SystemExit('Estrutura de preferencias alterada')
  s=s.rsplit('</PreferenceScreen>',1)[0]+credit+'</PreferenceScreen>\n'
  p.write_text(s)
with zipfile.ZipFile(r/'original.apk') as z:
  for path in z.namelist():
    if path.startswith('assets/') and not path.endswith('/'):
      dest=decoded/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(z.read(path))
with zipfile.ZipFile(r/'extension-fixed.apk') as z:
  (decoded/'classes5.dex').write_bytes(z.read('classes.dex'))
PY

java -Xmx4500m -jar tools/apktool.jar b "$tmp/app" -o "$tmp/app-unsigned.apk" > "$tmp/resources-build.log" 2>&1
javac -cp tools/revanced-cli.jar -d "$tmp" scripts/SignAPK.java
java -Xmx2600m -cp "$tmp:tools/revanced-cli.jar" SignAPK \
  output/youtube-personal.keystore "$tmp/app-unsigned.apk" "$tmp/app-final.apk"
mv "$tmp/app-final.apk" output/YouTube-Pessoal.apk
sha256sum output/YouTube-Pessoal.apk > output/SHA256.txt
echo 'YouTube Pessoal v1.1: visionOS + credito AllyzinSad. Assinado e pronto.'
