---
layout: post
title:  "Android Gradle plugin sample"
date:   2016-01-27 17:04:00
tags: android gradle plugin
meta_description: Android Gradle plugin
---

Plugin will upload apk to distribution system after building release artifact.

### Create Project

In the gradle folder, copy **samples**->**customPlugin**->**plugin** to your work directory. Gradle distribution can be downloaded {% include ga_link.html title="here" url="http://gradle.org/gradle-download/" %}

### build.gradle

Change build.gradle to this strusture

```
apply plugin: 'groovy'

dependencies {
    compile gradleApi()
    compile localGroovy()

    compile 'com.android.tools.build:gradle:0.14.0'
}

apply plugin: 'maven'

repositories {
    mavenCentral()
}

dependencies {
    testCompile 'junit:junit:4.12'
}

group = 'com.tunebrains.beta'
version = '1.0-SNAPSHOT'


```

### Configure plugin and deploy to local folder

Rename and change plugin description file under **src**->**main**->**resources**->**META-INF**->**gradle-plugins** folder

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

Now we need to post our resulting apk to server endpoint.

{%highlight groovy%}
private Object uploadApk(Project project, String apkFilename, String mappingFilename) {
    String serverEndpoint = "http://localhost:3000"
    String url = "${serverEndpoint}/api/v3/uploads.json"
    MultipartEntity entity = buildEntity(apkFilename, mappingFilename)
    String via = ""

    return post(url, entity, via)
}
private MultipartEntity buildEntity(String apkFilename, String mappingFilename) {
    MultipartEntity entity = new MultipartEntity()
    entity.addPart('upload[data_file_name]', new FileBody(new File(apkFilename)))
    return entity
}
private Object post(String url, MultipartEntity entity, String via) {
    DefaultHttpClient httpClient = buildHttpClient()
    HttpPost post = new HttpPost(url)
    post.setEntity(entity)
    HttpResponse response = httpClient.execute(post)

    String json = EntityUtils.toString(response.getEntity())
    def parser = new JsonSlurper()
    def parsed = parser.parseText(json)

    return parsed
}
private DefaultHttpClient buildHttpClient() {
    DefaultHttpClient httpClient = new DefaultHttpClient()
    return httpClient
}
{%endhighlight%} 

In result of evecution *uploadApk* we got the resulting json object of parsed server response. And can for example print to console url where you can find the build.

Enjoy!