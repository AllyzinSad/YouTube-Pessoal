# YouTube Pessoal — Android (versão paralela)

Projeto pessoal de compilação do YouTube modificado com **ReVanced CLI 6**, preservando o nome, o ícone e a interface visual originais. O APK final é **outro pacote Android**, portanto não altera o YouTube pré-instalado.

## Recursos escolhidos para o APK
- **GmsCore support**: login Google em instalação sem root (exige instalação do GmsCore).
- **Hide ads**: controle de anúncios suportados pelo patch.
- **SponsorBlock**: pular trechos patrocinados sinalizados pela comunidade.
- **Spoof video streams**: compatibilidade de reprodução de vídeos.
- **Remove background playback restrictions**: reprodução em segundo plano.

Não selecionamos **Custom branding** nem patches visuais. Não há login embutido em nosso código: a autenticação usa o GmsCore separado, sem armazenar sua senha no GitHub.

## Primeiro APK compilado

Em **10/10/2026**, foi compilado a partir do APK original YouTube **20.40.45 (nodpi, universal, minSdk 28)**, usando o ReVanced CLI 6.0.0. Os **seis patches** escolhidos (incluindo `Video ads`) foram aplicados com sucesso. O APK resultante foi validado por `ApkVerifier`, que confirmou assinatura **APK Signature Scheme v3** sem erros.

- ID do pacote secundario: `app.revanced.android.youtube`.
- SHA-256 do APK: `55e8bcbbdd87d6563ea6796abdb8a46395718979c61aca66635ce64784ac1f28`.
- Certificado SHA-256: `c1be990b2776511c32f72b2ab3a1865fead41ec9dce2c238345c5d79ee7e2a06`.
- O APK e a keystore foram entregues **na conversa**, e **nao foram enviados ao GitHub publico**.
- O login Google, a interface e a estabilidade ainda precisam de teste em um celular Android fisico.
- A primeira compilacao do arquivo enviado foi feita em um ambiente de build separado, utilizando as ferramentas oficiais baixadas pelo GitHub Actions. Para reproduzir a compilacao dentro do proprio Actions, sera necessario disponibilizar o APK-base como descrito abaixo.

## Estado
- ✅ Scripts de build e seleção de patches enviados.
- ✅ Verificação automática do ReVanced a cada alteração no GitHub (push).
- ⏳ Compilação real precisa do **APK original completo** do YouTube em versão compatível.
- ⏳ Testes de instalação e login precisam de um celular físico.

## Versao-base recomendada neste build

O diagnostico de patches oficiais coletado em 10/10/2026 confirmou **YouTube 20.40.45** como versao compativel com os cinco recursos selecionados.

O APK **21.39.525** enviado para verificacao tem Android minimo 10 (API 29), arquitetura universal, mas **nao consta como compativel com esses patches**. Nao use versoes fora da lista: a etapa `scripts/validar-apk.py` falhara antecipadamente para proteger contra APKs defeituosos.

Para ter maior compatibilidade, use a variante **YouTube 20.40.45 (APK, nodpi, universal, Android 9.0+, NAO BUNDLE)**. Consulte a pagina [APKMirror - YouTube 20.40.45](https://www.apkmirror.com/apk/google-inc/youtube/youtube-20-40-45-release/youtube-20-40-45-2-android-apk-download/).

## GitHub Actions

1. Ao atualizar os scripts, o GitHub Actions executa a etapa de validação dos programas e patches, **sem APK original**.
2. Ao clicar em **Actions > YouTube pessoal - verificar e compilar > Run workflow**, ele tenta gerar o APK.
3. O APK-base deve ter o nome `youtube.apk` em uma release de tag `youtube-base` **OU** em um link direto confiável definido no secret `YOUTUBE_APK_URL`.
4. No fim, o workflow publica um arquivo de instalação na seção **Artifacts**, quando puder fazê-lo com segurança.

### Atenção ao repositório público
Não coloque `youtube.apk` ou dados de assinatura na árvore de código. Se a release estiver pública, **seus arquivos também ficam públicos**. Prefira um repositório privado para compilar e armazenar APK e keystore. Enquanto o repositório for público, a validação dos scripts pode ser executada independentemente do APK.

## Compilação enquanto o repositório estiver público

Para evitar expor a assinatura e o APK, configure o secret `YOUTUBE_BUILD_PASSWORD` nas configurações do GitHub Actions. O artefato final será criptografado (`.tar.gz.enc`). Para abrir no PC com OpenSSL:

```bash
openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 \\
  -in youtube-pessoal.tar.gz.enc \\
  -out youtube-pessoal.tar.gz \\
  -pass env:YOUTUBE_BUILD_PASSWORD
tar -xzf youtube-pessoal.tar.gz
```

Defina a variável `YOUTUBE_BUILD_PASSWORD` no computador para a mesma senha registrada no secret. Quando o repositório estiver privado, o workflow publica o APK e a assinatura diretamente (sem criptografia). Guarde a keystore para permitir atualizações futuras sem reinstalar o app.

## Requisitos técnicos
A versão-base precisa ser **APK completo (não APKS/APKM/XAPK)** compatível com os patches atuais, como indicado no [ReVanced Manager](https://revanced.app). A arquitetura 32/64-bit e o Android mínimo dependem do APK de origem. Android 8 e 2 GB RAM são metas de compatibilidade, não garantias.

## Login Google
Instale separadamente o [ReVanced GmsCore](https://github.com/ReVanced/GmsCore/releases), abrindo o pacote oficial no celular. Não forneça senhas, tokens de login ou cookies ao GitHub.

Em fevereiro de 2026, mudanças do Google causaram problemas de login; por isso usamos o patch GmsCore support atualizado. Se ocorrer um novo problema, normalmente é preciso atualizar tanto os patches quanto o GmsCore.

## Assinatura e atualizações
Uma instalação posterior só atualiza a primeira sem perda de dados se tiver o mesmo **identificador de pacote e assinatura**. O workflow armazena uma keystore no artefato de build **somente quando o repositório for privado**. Guarde o arquivo com segurança e configure `YOUTUBE_KEYSTORE_B64` antes dos próximos builds:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('youtube-personal.keystore')) | Set-Clipboard
```

Se usar uma chave nova, a atualização poderá exigir desinstalação antes da reinstalação.

## Solução de problemas
- **APK original ausente**: configure a release `youtube-base` com o asset `youtube.apk`, ou o secret `YOUTUBE_APK_URL`.
- **Patch incompatível**: use a versão de YouTube sugerida pelo ReVanced.
- **Login falha**: atualize ReVanced GmsCore e confira o patch GmsCore support.
- **Vídeo não carrega**: mantenha habilitado Spoof video streams.
- **Falha na instalação**: confirme o APK completo, arquitetura, assinatura e versão do Android.

Este é um mecanismo de modificação de um aplicativo de terceiros. Pode falhar após atualizações do YouTube, e o bloqueio de anúncios pode contrariar os termos de uso da plataforma.
