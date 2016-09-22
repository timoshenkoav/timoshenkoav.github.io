---
layout: post
title:  "Read custom attributes from activity"
date:   2016-01-04 18:52:00
tags: 
- android
related_id: 7
redirect_from:
  - /2016/01/04/read-custom-attributes-from-activity.html
  - /2016/01/04/read-custom-attributes-from-activity/
---

Its quite small article about reading custom attributes from theme in Activity code. 

First we need to define our custom attribute.

{%highlight xml%}
<attr name="TitleText" format="reference|string"/>
{%endhighlight%}

Apply this attribute to Activity's theme

{%highlight xml%}
<style name="AppTheme" parent="Theme.AppCompat.Light.DarkActionBar">        
	<item name="TitleText">@string/app_name</item>
</style>
{%endhighlight%}

Read this attribute in activity and set TextView text.

{%highlight java%}
TextView text = (TextView) findViewById(R.id.text);
TypedValue lTypedText = new TypedValue();

getTheme().resolveAttribute(R.attr.TitleText, lTypedText, true);
//check if we have value set
if (lTypedText.resourceId != 0) {
    String title = getResources().getString(lTypedText.resourceId);
    text.setText(title);
}
{%endhighlight%}

Full source code for this article is available on {% include ga_link.html title="GitHub" url="https://github.com/timoshenkoav/ActivityAttributes" %} 