---
layout: post
title:  "Deep android project structure"
date:   2016-04-23 20:30:00
tags: 
- android 
- gradle plugin
related_id: 11
meta_description: Android Gradle plugin
redirect_from:
  - /2016/04/23/android-gradle-flattener.html
  - /2016/04/23/android-gradle-flattener/
---

Inspired by <a href="https://medium.com/google-developer-experts/android-project-structure-alternative-way-29ce766682f0" class="ga-link" data-link-type="outbound" target='_blank'>Dmytro Danylyk</a> post about using sourceSets to have deep project structure in android, i've written small gradle plugin to automate this task.

To use it in you project add this to top level **build.gradle**

```

buildscript {
    repositories {
        ///...
        maven {
            url uri('http://maven.tunebrains.com/content/repositories/android/')
        }
    }
    dependencies {
        //...
        classpath group: 'com.tunebrains', name: 'sourcesetflattener',
                version: '0.0.1'
    }
}

```

Apply plugin in project level **build.gradle**

```

apply plugin: 'com.tunebrains.sourcesetflattener'

```

Specify root directory to store screen related resources

```
flattener{
    root 'res-screen'
}
```

Sync Project with gradle files, and it will load directory structure to source set automatically.

<img src="{{ site.url }}/assets/gradle_flattener/1461524521625.jpg"/>

Also works for multiple flavours.

<img src="{{ site.url }}/assets/gradle_flattener/1461524624236.jpg"/>

All source code available on {% include ga_link.html title="GitHub" url="https://github.com/timoshenkoav/SourceSetFlattener" %}

