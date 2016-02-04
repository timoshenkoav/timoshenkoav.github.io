---
layout: post
title:  "Load app hi-res icon"
date:   2016-02-04 22:00:00
tags: android icon
meta_description: Load hi-res icon for app
---

Short snippet how to load hi-res icon of the app by its package name.

By default when you request some app icon from **PackageManager** you get icon for device density, which is pretty obvious.

{%highlight java%}
public static Drawable loadAppIcon(Context pContext, String packageName){
    try {
        PackageManager packageManager = pContext.getPackageManager();
        ApplicationInfo applicationInfo = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA);
        return applicationInfo.loadIcon(packageManager);
    } catch (PackageManager.NameNotFoundException e) {

    }
    return null;
}

{% endhighlight%}

But if you want to display this icon larger then it is (46dp) you need to load higher resolution version of icon to prevent pixilisation.

If your min sdk is >= 15 you can use this code:

{%highlight java%}
try {
    PackageManager packageManager = pContext.getPackageManager();
    ApplicationInfo applicationInfo = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA);
    if (applicationInfo.icon!=0){
        Resources lResources = packageManager.getResourcesForApplication(applicationInfo);
        return lResources.getDrawableForDensity(applicationInfo.icon, DisplayMetrics.DENSITY_XXXHIGH);
    }
    return applicationInfo.loadIcon(packageManager);
} catch (PackageManager.NameNotFoundException e) {

}
{% endhighlight%}

Enjoy!