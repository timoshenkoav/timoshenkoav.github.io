---
layout: post
title:  "Sign multiple flavors with different keystores"
date:   2015-10-02 11:11:35
tags: 
- android 
- gradle
related_id: 2
redirect_from:
  - /2015/10/02/gradle-multi-flavors-signing.html
  - /2015/10/02/gradle-multi-flavors-signing/
---

One of my projects has a lot of flavors, and each flavor has different keystore to sign with. As a result it has very long build.gradle project file. As each flavor need defining separate singningConfig and defining flavor signing on release buildType

After reading couple of articles, i end up with this solution:

Create `signs.gradle` under project folder:

{%highlight scala%}
def fillDefaults(signingConfig) {
    signingConfig.storeFile = null
    signingConfig.storePassword = ''
    signingConfig.keyAlias = ''
    signingConfig.keyPassword = ''
}
def setupSigning(name) {
    def signingProperties = "${name}.info"
    def signingKeys = [
            storeFile    : { x -> file(x) },
            storePassword: { x -> x },
            keyAlias     : { x -> x },
            keyPassword  : { x -> x },
    ]
    // Find signing.properties in project root, or in $HOME/.gradle
    def f = ["${projectDir}/certs/${signingProperties}"].find { file(it).exists() }
    if (f) {
        println "Loading signing properties from ${f}"
        def props = new Properties()
        props.load(new FileInputStream(f))

        // For each property apply it to the release signing config
        signingKeys.any { k, fn ->
            if (!props.containsKey(k)) {
                println "Missing property ${k}"
                fillDefaults(android.signingConfigs[name])
                return true
            } else {
                android.signingConfigs[name][k] = fn(props[k]);
            }
            return
        }
        println android.signingConfigs[name]
    } else {
        println "Missing ${signingProperties} file"
        fillDefaults(android.signingConfigs[name])
    }
}
ext {
    setupSigning = this.&setupSigning
}
{%endhighlight%}

Apply it in project `build.gradle` in the beggining of the file

{%highlight scala%}
apply from: 'signs.gradle'
{%endhighlight%}

Add callbacks when `signingConfigs` and `productFlavors` is added:

{%highlight scala%}
android.signingConfigs.whenObjectAdded { signing ->
    setupSigning(signing.name)
}

android.productFlavors.whenObjectAdded { flavor ->
    flavor.signingConfig = android.signingConfigs[flavor.name]
}
{%endhighlight%}

The first will call our function with added signing name

The second will set `signingConfig` for flavor based on loaded config

Keystore information is stored in files named `<flavor_name>.info` under `certs` folder under project subfolder. The format of this file is often used to storing `signed.properties'

{%highlight ini%}
storeFile=certs/<filename>

storePassword=''

keyAlias=''

keyPassword=''

{%endhighlight%}

## Usage

Add flavor configuration

{%highlight scala%}
productFlavors {
	app1 {    
	    applicationId 'com.sample.app1'   
	}
}
{%endhighlight%}

Register signing config with the same name as flavor

{%highlight scala%}
signingConfigs {
	app1
}
{%endhighlight%}

Create `app1.info` file under `certs` directory with information about the keystore.

Build. Enjoy.


## ToDo

* Remove requirement to put `signingConfig` with flavor name. It should do this automatically when flavor is registered

## References

* {% include ga_link.html title="Squeezing your Gradle builds" url="http://saulmm.github.io/squeezing-gradle-builds" %}
* {% include ga_link.html title="Building Multiple Editions of an Android App with Gradle" url="http://blog.robustastudio.com/mobile-development/android/building-multiple-editions-of-android-app-gradle/" %}
* {% include ga_link.html title="HOW TO SIGN RELEASE APK WITH GRADLE" url="http://zserge.com/blog/android-signing.html" %}
