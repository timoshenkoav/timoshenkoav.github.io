---
layout: post
title:  "Block domains with vpn"
date:   2015-11-10 16:48:00
tags: android vpn
---


1. Create VpnService class

```
public class VpnConnectionBlocker extends VpnService {

}
```

2. Register it in AndroidManifest.xml

```
<service android:name=".VpnConnectionBlocker"
         android:permission="android.permission.BIND_VPN_SERVICE">
    <intent-filter>
        <action android:name="android.net.VpnService"/>
    </intent-filter>
</service>
```

3. Request VPN service to start

```
private static final int REQUEST_VPN = 0x10;
//...
startActivityForResult(VpnConnectionBlocker.prepare(MainActivity.this), REQUEST_VPN);
```

4. Handle user action and start VPN service

```
@Override
protected void onActivityResult(int requestCode, int resultCode, Intent data) {
    switch (requestCode){
        case REQUEST_VPN:
            if (resultCode == RESULT_OK) {
                startService(new Intent(MainActivity.this, VpnConnectionBlocker.class));
            }
            break;
    }
}
```

