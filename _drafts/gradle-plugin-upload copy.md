---
layout: post
title:  "Android Gradle plugin sample"
date:   2016-01-11 13:40:00
tags: android gradle plugin
meta_description: Android Gradle plugin
---

Plugin will upload apk to distribution system after building release artifact.

### Create Project

Create plugin project in IntelliJ IDEA. Go to **File**->**New**->**Project**.

Select Gradle and add Groovy Framework

<img src="{{ site.url }}/assets/gradle_plugin_upload/new_project.jpg"/>

Name your plugin:

<img src="{{ site.url }}/assets/gradle_plugin_upload/plugin_name.jpg"/>

Select gradle settings:

<img src="{{ site.url }}/assets/gradle_plugin_upload/gradle_settings.jpg"/>

And save your plugin:

<img src="{{ site.url }}/assets/gradle_plugin_upload/plugin_save.jpg"/>

### Add Groovy dependency

Change **build.gradle**

```
group 'com.tunebrains.beta'
version '1.0-SNAPSHOT'

task wrapper(type: Wrapper) {
  gradleVersion = '2.2'
  distributionUrl = "https://services.gradle.org/distributions/gradle-$gradleVersion-bin.zip"
}

apply plugin: 'java'
apply plugin: 'groovy'

sourceCompatibility = 1.7

repositories {
    mavenCentral()
}

dependencies {
    compile 'org.codehaus.groovy:groovy-all:2.3.11'

    compile gradleApi()
    compile localGroovy()
    compile 'com.android.tools.build:gradle:0.14.0'
}

```

### Configure plugin and deploy to local folder

Create folder structure

Project Root
<span>
<br>
<span style="margin-left: 10px;">
- src
</span>
<br>
<span style="margin-left: 20px;">- main</span>
<br>
<span style="margin-left: 40px;">
- groovy
</span>
<br>
<span style="margin-left: 40px;">
- resources
</span>
<br>
<span style="margin-left: 60px;">
- META-INF
</span>
<br>
<span style="margin-left: 80px;">
- gradle-plugins			
</span>		
<br>
</span>

Create plugin description file under **gradle-plugins** folder

**File Name:** *com.tunebrains.beta-gradle-beta-upload.properties*

```
implementation-class=com.tunebrains.beta.gradle.UploadApkPlugin
```

Create groovy class **com.tunebrains.beta.gradle.UploadApkPlugin**

{%highlight groovy%}
package com.tunebrains.beta.gradle

import org.gradle.api.Plugin
import org.gradle.api.Project

class UploadApkPlugin implements Plugin<Project> {
    @Override
    void apply(Project pProject) {

    }
}

{%endhighlight%}

Apply maven plugin to **build.gradle**

```
apply plugin: 'maven'
```

Specify folder to deploy plugin

```
uploadArchives {
    repositories {
        mavenDeployer {
            repository(url: "file:///Users/alex/Projects/Tutorials/repo")
        }
    }
}
```

Execute gradle tast to upload archive. Refresh gradle task if required.

<img src="{{ site.url }}/assets/gradle_plugin_upload/upload_archive.jpg"/>


### Apply plugin in your Android project.

In top level **build.gradle**

```
buildscript {
    repositories {
        //...
        maven {
            url uri('file:///Users/alex/Projects/Tutorials/repo')
        }
    }
    dependencies {
        
        classpath group: 'com.tunebrains.beta', name: 'releaseupload',
                version: '1.0-SNAPSHOT'
    }
}

```

In app level **build.gradle**

Apply plugin:

```
apply plugin: 'com.tunebrains.beta-release-upload'
```

Its time for write some code.

We will add custom tasks **betaDebug** and **betaRelease** to upload debug and release apks.

{%highlight groovy%}
pProject.configure(pProject) {
    def hasProp = pProject.hasProperty("android")
    if (hasProp) {
        tasks.whenTaskAdded { task ->
            pProject.("android").applicationVariants.all { variant ->
                def expectingTask = "package${variant.name.capitalize()}".toString()
                if (expectingTask.equals(task.name)) {
                    def variantName = variant.name

                    def newTaskName = "beta${variantName.capitalize()}"
                    pProject.task(newTaskName) << {
                        //write task code
                    }
                }
            }
        }
    }

}
{%endhighlight%}

To perform multipart post add apache dependencies to **build.gradle**

```
compile 'org.apache.httpcomponents:httpmime:4.+'
compile 'commons-io:commons-io:2.+'
compile 'org.apache.commons:commons-compress:1.+'
```

To get resulting apk for upload we can use task field

{%highlight groovy%}
String apkFilename = task.outputFile.toString()
{%endhighlight%}