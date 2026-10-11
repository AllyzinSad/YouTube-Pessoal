import java.io.*;
import java.security.*;
import java.security.cert.*;
import java.util.*;
import com.android.apksig.*;
import org.bouncycastle.jce.provider.BouncyCastleProvider;

/** Reassina com a keystore BKS do próprio ReVanced CLI, preservando a assinatura. */
public class SignAPK {
 public static void main(String[] args) throws Exception {
  Security.addProvider(new BouncyCastleProvider());
  KeyStore ks=KeyStore.getInstance("BKS","BC");
  try(FileInputStream in=new FileInputStream(args[0])){ ks.load(in,new char[0]); }
  String alias=ks.aliases().nextElement();
  PrivateKey key=(PrivateKey)ks.getKey(alias,new char[0]);
  if(key==null)throw new Exception("Chave privada ausente");
  X509Certificate cert=(X509Certificate)ks.getCertificate(alias);
  ApkSigner.SignerConfig cfg=new ApkSigner.SignerConfig.Builder(alias,key,Arrays.asList(cert)).build();
  ApkSigner signer=new ApkSigner.Builder(Arrays.asList(cfg))
     .setInputApk(new File(args[1])).setOutputApk(new File(args[2]))
     .setV1SigningEnabled(true).setV2SigningEnabled(true).setV3SigningEnabled(true)
     .setMinSdkVersion(28).build();
  signer.sign();
  ApkVerifier.Result checked=new ApkVerifier.Builder(new File(args[2])).setMinCheckedPlatformVersion(28).build().verify();
  if(!checked.isVerified() || !checked.isVerifiedUsingV3Scheme())
     throw new Exception("Falha na assinatura APK v3: "+checked.getErrors());
  byte[] certSha=MessageDigest.getInstance("SHA-256").digest(cert.getEncoded());
  StringBuilder hex=new StringBuilder();for(byte b:certSha)hex.append(String.format("%02x",b));
  System.out.println("Assinatura v3 verificada. Certificado SHA256: "+hex);
 }
}
