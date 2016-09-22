---
layout: post
title:  "Android UsageStatsManager sample"
date:   2015-10-20 17:41:00
tags: 
- android
related_id: 3
meta_description: Sample of using UsageStatsManager on Android API >= 21
redirect_from:
  - /2015/10/20/usage-stats-manager-sample.html
  - /2015/10/20/usage-stats-manager-sample/
---

Google has deprecated the function "getRecentTasks" of "ActivityManager" class. Now all it does is to get the list of apps that the current app has opened. But if you are writing app that "locks" access to specific apps with password or any other protection methods, you still need to be able to get top most activity/package to react accordingly to user changing current app and for example show your overlay.

Google introduces UsageStatsManager in api 21, which can replace "getRecentTasks" for new versions.

I've created sample project demonstrating how to use this api.

First of all you need to declare permission in AndroidManifest.xml

```

<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"
                     tools:ignore="ProtectedPermissions"/>

```

Adding  

```
tools:ignoe="ProtectedPermissions"

```

will disable warning that permission is system level and will not be granted to third-party apps. However, declaring the permission implies intention to use the API and the user of the device can grant permission through the Settings application.

So we need to check if our app was granted this permission

```

private boolean hasPermission() {
    AppOpsManager appOps = (AppOpsManager)
                getSystemService(Context.APP_OPS_SERVICE);
    int mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(), getPackageName());
    return mode == AppOpsManager.MODE_ALLOWED;
}

```

and if no, ask user to enable it

```
startActivityForResult(
    new Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS), 
        MY_PERMISSIONS_REQUEST_PACKAGE_USAGE_STATS);
```

We are launching settings activity to allow app to get usage stats, its not android M default way to deal with permissions, we need to check result in onActivityResult

```
@Override
protected void onActivityResult(int requestCode, int resultCode, Intent data) {
    switch (requestCode){
        case MY_PERMISSIONS_REQUEST_PACKAGE_USAGE_STATS:
            if (hasPermission()){
                getStats();
            }else{
                requestPermission();
            }
            break;
    }
}
```

In this sample if user did not grant permission we will ask again while permission is not granted. In real application, its better to tell user why do we need this permission and turn off functionality if permission was not granted.

After the permission was eventually granted, we can query information about last active packages

```

UsageStatsManager lUsageStatsManager = 
    (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
List<UsageStats> lUsageStatsList = 
    lUsageStatsManager.queryUsageStats(
        UsageStatsManager.INTERVAL_DAILY, 
        System.currentTimeMillis()- TimeUnit.DAYS.toMillis(1),
        System.currentTimeMillis()+ TimeUnit.DAYS.toMillis(1));

```


There are a lot of methods in UsageStatsManager, that can be usefull for your app. Checkout {% include ga_link.html title="official documentation" url="https://developer.android.com/reference/android/app/usage/UsageStatsManager.html" %}

Full source code for this article is available on {% include ga_link.html title="GitHub" url="https://github.com/timoshenkoav/USMSample" %} 


