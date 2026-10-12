#!/usr/bin/env python3
"""Corrige o versionCode do YouTube 20.40.45 para atualização in-place sem perda de dados.

Preserva o pacote, assinatura (é feita em seguida), recursos e arquivos dex.
Aumenta a versão para que instaladores de Android reconheçam uma atualização.
"""
from pathlib import Path
import struct
import sys
import zipfile

SOURCE = Path(sys.argv[1])
DESTINATION = Path(sys.argv[2])
OLD_VERSION_CODE = 1557278144
NEW_VERSION_CODE = 1557278145

with zipfile.ZipFile(SOURCE) as source_zip, zipfile.ZipFile(DESTINATION, "w") as output_zip:
    for entry in source_zip.infolist():
        data = source_zip.read(entry)
        if entry.filename == "AndroidManifest.xml":
            old = struct.pack("<I", OLD_VERSION_CODE)
            if data.count(old) != 1:
                raise ValueError("versionCode inesperado; confira a base do APK antes de alterar")
            offset = data.index(old)
            if data[offset-4:offset] != b"\x08\x00\x00\x10":
                raise ValueError("O versionCode não é um atributo binário INT válido")
            data = data[:offset] + struct.pack("<I", NEW_VERSION_CODE) + data[offset+4:]
        output_zip.writestr(entry, data)

print(f"versionCode atualizado de {OLD_VERSION_CODE} para {NEW_VERSION_CODE}.")
