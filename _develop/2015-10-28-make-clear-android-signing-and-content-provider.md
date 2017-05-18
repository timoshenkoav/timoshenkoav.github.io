---
layout: post
title:  "Signing android app for secure content provider"
date:   2015-10-28 13:17:35
tags: 
- android 
- keystore
related_id: 4
redirect_from:
  - /2015/10/28/make-clear-android-signing-and-content-provider.html
  - /2015/10/28/make-clear-android-signing-and-content-provider/
---

Always was curious how to manage android keystore sertificates for multiple apps, either generate separate keystore file each time, or just use multiple alias in the same keystore.

Now its time to make it clear.

To make it clear, i've created sample app with multiple flavours. Each flavour can be installed on device, and they does not run in the same process, so fingerprint of keystored should be different, can we do this using aliases? Lets check. To make sure everything works, i'll use secured content provider based on signature level verification

Flavors config:

{%highlight scala%}
productFlavors {
    flavor2 {
        applicationId 'com.tunebrains.keystoresample2'
        versionName '10'
    }
    flavor1 {
        applicationId 'com.tunebrains.keystoresample1'
        versionName '10'
    }
}
{%endhighlight%}

Generate our keystore with multiple aliases:

```
keytool -genkey -v -keystore release_key.keystore -alias flavor1 -keyalg RSA -keysize 2048 -validity 10000
```

Add another alias to the keystore

```
keytool -genkey -v -keystore release_key.keystore -alias flavor2 -keyalg RSA -keysize 2048 -validity 10000
```

Configure two signing configs:

{%highlight scala%}
signingConfigs {
    Flavor1 {
        storeFile file("release_key.keystore")
        storePassword "password"
        keyAlias "flavor1"
        keyPassword "password1"
    }
    Flavor2 {
        storeFile file("release_key.keystore")
        storePassword "password"
        keyAlias "flavor2"
        keyPassword "password2"
    }
}
{%endhighlight%}

Configure release signing for both flavors:

{%highlight scala%}
productFlavors {
    flavor1 {
        applicationId 'com.tunebrains.keystoresample1'
        versionName '10'        
        signingConfig signingConfigs.Flavor1
    }
    flavor2 {
        applicationId 'com.tunebrains.keystoresample2'
        versionName '10'        
        signingConfig signingConfigs.Flavor2
    }
}
{%endhighlight%}

Each flavor has its own content provider, which is secured by signature level permission

{%highlight xml%}
<permission android:name="${applicationId}.permission"
                android:protectionLevel="signature"/>
<provider
    android:exported="true"
    android:authorities="${applicationId}.provider"
    android:name=".ContentProviderSecured"
    android:permission="${applicationId}.permission">
</provider>
{%endhighlight%}

Code for content provider is quite simple, it just return empty **MatrixCursor**

{%highlight java%}
public Cursor query(Uri uri, String[] projection, String selection, String[] selectionArgs, String sortOrder) {
    MatrixCursor lMatrixCursor = new MatrixCursor(new String[]{"key"});    
    return lMatrixCursor;
}
{%endhighlight%}

Flavor2 will try to get access to Flavor1 content provider

{%highlight java%}
Cursor c = null;
try {
    c = getContentResolver().query(Uri.parse("content://" + "com.tunebrains.keystoresample1" + "/query"), null, null, null, null);
    Log.d("Result", "" + c.getCount());
}catch (Exception e){
    Log.d("Result", "Cannot access provider");
}finally {
    if (c!=null){
        c.close();
    }
}
{%endhighlight%}

Now its time to install both apps, and check if Flavor2 does NOT have access to Flavor1 data. And its true, everything works well as expected. To get access to Flavor1 data from Flavor2 we need to sign it with **Flavor2** signingConfig.

Code is available on {% include ga_link.html title="GitHub" url="https://github.com/timoshenkoav/KeystoreSample" %} 





