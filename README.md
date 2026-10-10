# YouTube Pessoal — build Android via GitHub Actions

Este projeto prepara um **APK secundário modificado do YouTube para uso pessoal**. Não contém o aplicativo original, APKs prontos, contas Google ou credenciais.

## Recursos planejados
- Nome, ícone e interface originais (não selecionamos patches de branding).
- Instalação em paralelo ao YouTube de fábrica usando o patch de suporte ao GmsCore.
- Bloqueio de anúncios, SponsorBlock e reprodução em segundo plano.
- Login Google através do **ReVanced GmsCore** instalado separadamente.
- A compatibilidade real depende da versão-base e do pacote de patches; 32-bit, Android antigo e 2 GB RAM não são garantidos.

## Antes de executar
**IMPORTANTE:** o workflow recusa compilar em repositórios **públicos**, para não expor o APK proprietário e a sua chave de assinatura.

1. Abra `Settings > General > Danger Zone > Change repository visibility` e altere para **Private**.
2. Obtenha uma versão **APK completo** do YouTube legalmente acessível a você, compatível com a versão dos patches do ReVanced. Não use APKM/APKS/XAPK ou APKs de procedência duvidosa.
3. Renomeie o arquivo para `youtube.apk`.
4. No repositório privado, acesse `Releases > Draft a new release`; use a tag **youtube-base**, anexe `youtube.apk` como asset e publique essa release. **Não envie o APK como arquivo de código.**
5. Vá em `Actions > YouTube pessoal - compilar APK > Run workflow`.
6. Após execução bem-sucedida, baixe o artefato `YouTube-Pessoal-APK-e-assinatura`, disponível por **1 dia**. Ele contém o APK, checksum e uma chave de assinatura pessoal.

**Não compartilhe o artefato inteiro**: a keystore é uma chave privada.

## Atualizações sem perder os dados
Após o primeiro build, salve `youtube-personal.keystore` em local seguro. Para builds seguintes, codifique em base64 e configure em `Settings > Secrets and variables > Actions` como `YOUTUBE_KEYSTORE_B64`.

PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('youtube-personal.keystore')) | Set-Clipboard
```

Sem manter a mesma assinatura, uma atualização poderá exigir desinstalação prévia do aplicativo.

## Login Google
Instale o ReVanced GmsCore oficial separadamente em:
https://github.com/ReVanced/GmsCore/releases

O login depende do GmsCore, patches e Google; **não é garantido** em todos os aparelhos nem em todas as versões. Não envie sua senha ou dados pessoais para este repositório.

## Diagnóstico
- **Release not found:** falta a tag exata `youtube-base` com o asset `youtube.apk`.
- **Patch incompatível:** use a versão de YouTube sugerida pelo ReVanced Manager.
- **Patch ausente:** os patches podem mudar de nome; revise os logs e ajuste `scripts/compilar.sh`.
- **Falha do login:** confira o GmsCore e a aplicação de `GmsCore support`.
- **APK não instala:** confirme assinatura, Android mínimo, formato e arquitetura.

O GitHub Actions só realiza a compilação; a instalação e o teste precisam ser feitos em aparelho real. O projeto não cria uma versão oficial do YouTube e seu uso pode contrariar termos de serviço.
