---
layout: post
title:  "Encrypted API from android to rails"
date:   2015-10-02 17:54:00
tags: android rails
id: 1
---

Working on remote logging system for android, I faced up with Google require not to send user information to remote system, as this violates section 4.3 of the Developer Distribution Agreement.

To solve this we need to send the data to our server encrypted.

It's nice to encrypt it so even if someone sniff the traffic they will not be able to decrypt contents.

To provide such encryption we can use asymmetric algorithm like RSA, public key is stored inside the android application and used to encrypt the data sent to remote server, private key is stored on servicer side and used to decrypt the data.

But the problem with asymmetric algorithm is that generaly they can encrypt data length up to key size, so for RSA its 4096 bits, which is not good in our case, as our logs can be much longer.

Symmetric algorithms, like AES can encrypt practically unlimited ammount of data, but as the same key is used to encrypt and decrypt information, it's easy to stole data while transmissing to server if one has access to app code, which is true for Android applications. 

The often used solution is:

On Client Side:

* Generate random AES key ( e.g 256 bits long)
* Encrypt body with AES using generated key
* Encrypt key with RSA using stored public key
* Send encrypted key along with encrypted body

On Server Side

* Decrypt key with RSA private key to get plain AES key
* Decrypt body with plain AES key
* Handle the request

Lets start from the client side:

- Generate random AES key

```
public static final int AES_KEY_SIZE = 256 / 8;
public static String randomKey(int len) {
    Random generator = new Random();
    StringBuilder randomStringBuilder = new StringBuilder();
    int randomLength = len;
    char tempChar;
    for (int i = 0; i < randomLength; i++) {
        tempChar = (char) (generator.nextInt(96) + 32);
        randomStringBuilder.append(tempChar);
    }
    return randomStringBuilder.toString();
}
```


- Encrypt data with AES

```
public static byte[] AESEncrypt(final String plain, String pKey) throws NoSuchAlgorithmException, NoSuchPaddingException,
            InvalidKeyException, IllegalBlockSizeException, BadPaddingException, InvalidKeySpecException {

    SecretKeySpec skeySpec = new SecretKeySpec(pKey.getBytes(), "AES");
    Cipher cipher = Cipher.getInstance("AES");
    cipher.init(Cipher.ENCRYPT_MODE, skeySpec);
    byte[] encrypted = cipher.doFinal(plain.getBytes());
    return encrypted;
}
```

- Encrypt key using RSA

To generate RSA key-pair we can simply use great online service: [Generate Key Online](http://travistidwell.com/jsencrypt/demo/)

We can store public key either in assets/resources/plain string


To unify reading key we can use InputStream as source, so it can be FileInputStream, ByteArrayInputStream or any other source:

```
public static byte[] readKeyWrapped(InputStream pInputStream) throws IOException {
    String lStringKey = read(pInputStream);
    String lRawString = stripKeyHeaders(lStringKey);
    return base64(lRawString);
}
public static String stripKeyHeaders(String key) {
    StringBuilder strippedKey = new StringBuilder();
    String lines[] = key.split("\n");
    for (String line : lines) {
        if (!line.contains("PRIVATE KEY") && !line.contains("PUBLIC KEY") && !TextUtils.isEmpty(line.trim())) {
            strippedKey.append(line.trim());
        }
    }
    return strippedKey.toString().trim();
}
```

Using public key, we can encrypt data


```
public static byte[] RSAEncrypt(final byte[] plain, byte[] pKey) throws NoSuchPaddingException, NoSuchAlgorithmException, BadPaddingException, IllegalBlockSizeException, InvalidKeySpecException, InvalidKeyException {
    X509EncodedKeySpec spec = new X509EncodedKeySpec(pKey);
    KeyFactory kf = KeyFactory.getInstance("RSA");
    PublicKey publicKey = kf.generatePublic(spec);
    Cipher cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding");
    cipher.init(Cipher.ENCRYPT_MODE, publicKey);
    byte []encryptedBytes = cipher.doFinal(plain);
    return encryptedBytes;
}
```

Now we have everything encrypted and we can send data to our API. Body will be send as base64 request body, encrypted key - as request header.

```
byte[] lRSAKey = readKeyWrapped(getResources().openRawResource(R.raw.api_public));
String lAESKey =  randomKey(AES_KEY_SIZE);      
String lEncryptedKey = Base64.encode(RSAEncrypt(lAESKey, lAESKey), 0);
String lEncryptedBody = Base64.encode(AESEncrypt(body, lAESKey), 0);
post("http://api-domain.com", lEncryptedBody, lEncryptedKey);
```


To Be Continued...

