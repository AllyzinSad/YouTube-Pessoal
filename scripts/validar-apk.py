#!/usr/bin/env python3
"""Valida APK-base e cada patch oficial antes de tentar compilar."""
import argparse, re, struct, sys, zipfile

REQUIRED = ("GmsCore support", "Hide ads", "SponsorBlock", "Spoof video streams", "Remove background playback restrictions")

def parse_manifest(b):
    u16=lambda i: struct.unpack_from("<H",b,i)[0]
    u32=lambda i: struct.unpack_from("<I",b,i)[0]
    def len8(i):
        x=b[i]; return ((((x&127)<<8)|b[i+1]),i+2) if x&128 else (x,i+1)
    def len16(i):
        x=u16(i);return ((((x&32767)<<16)|u16(i+2)),i+4) if x&32768 else (x,i+2)
    if u16(0)!=3: raise ValueError("Manifest nao e XML binario Android")
    strs=[]; props={};pos=8
    while pos<len(b):
        t,hs,sz=struct.unpack_from("<HHI",b,pos)
        if sz<hs or sz<8 or pos+sz>len(b): raise ValueError("Manifest invalido")
        if t==1:
            n,flags,start=u32(pos+8),u32(pos+16),u32(pos+20)
            for j in range(n):
                p=pos+start+u32(pos+hs+4*j)
                if flags&256:
                    _,p=len8(p); ln,p=len8(p); val=b[p:p+ln].decode("utf8")
                else:
                    ln,p=len16(p);val=b[p:p+ln*2].decode("utf-16le")
                strs.append(val)
        if t==0x102 and strs and strs[u32(pos+20)] in ("manifest","uses-sdk"):
            start,n=u16(pos+24),u16(pos+28)
            for j in range(n):
                p=pos+16+start+20*j
                key=strs[u32(p+4)];raw=u32(p+8);kind=b[p+15];value=u32(p+16)
                if key in ("package","versionName","minSdkVersion","targetSdkVersion"):
                    props[key]=strs[raw] if raw!=0xffffffff else strs[value] if kind==3 else value
        pos+=sz
    return props

def supports(output, name, version):
    for block in re.split(r"(?m)^Index:\s+\d+\s*$",output):
        if not re.search(r"(?m)^Name:\s+"+re.escape(name)+r"\s*$",block):continue
        for match in re.finditer(r"(?m)^\s*Package name:\s*com\.google\.android\.youtube\s*$",block):
            sec=re.split(r"(?m)^\s*Package name:",block[match.end():])[0]
            if re.search(r"(?m)^\s*"+re.escape(version)+r"\s*$",sec):return True
    return False

def main():
    ap=argparse.ArgumentParser();ap.add_argument("apk");ap.add_argument("--patches",required=True);a=ap.parse_args()
    try:
        with zipfile.ZipFile(a.apk) as z:
            bad=z.testzip()
            if bad:raise ValueError(f"APK corrompido: {bad}")
            manifest=parse_manifest(z.read("AndroidManifest.xml"))
            arch=sorted({p.split("/")[1] for p in z.namelist() if p.startswith("lib/")})
        pkg,vers=manifest.get("package"),manifest.get("versionName")
        print(f"APK: {pkg} {vers}, Android minimo API {manifest.get('minSdkVersion')}, arquiteturas: {arch}")
        if pkg!="com.google.android.youtube" or not vers:raise ValueError("APK nao reconhecido como YouTube")
        with open(a.patches,encoding="utf8") as f: listing=f.read()
        unsupported=[patch for patch in REQUIRED if not supports(listing,patch,vers)]
        if unsupported:raise ValueError(f"Versao {vers} incompativel com: {', '.join(unsupported)}. Testar uma versao recomendada, como 20.40.45.")
        print(f"OK: {vers} compativel com os cinco patches.")
    except (ValueError,KeyError,zipfile.BadZipFile) as e:
        print(f"ERRO: {e}",file=sys.stderr);sys.exit(1)
if __name__=="__main__":main()
