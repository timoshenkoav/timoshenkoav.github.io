---
layout: post
title:  "Track outbound links to GA on jekyll"
date:   2015-11-13 22:25:00
tags: GA jekyll
---


1. Add jQuery to your jekyll blog if its not there yet. I am adding it to **_includes/head.html**

{%highlight xml%}
<script src="//code.jquery.com/jquery-1.11.3.min.js"></script>
<script src="//code.jquery.com/jquery-migrate-1.2.1.min.js"></script>
{%endhighlight%}

2. Create additional include where we will make our magick. I did this in **_includes/google__analytics.html**. 

{%highlight javascript%}
$(document).ready(function(){
	$('.ga-link').on('click', function(){
		if (typeof(ga)!=="undefined"){
			ga('send',{
				hitType: 'event',
				eventCategory: 'click',
				eventAction: 'outbound',
				eventLabel: $(this).attr('href')
			});	  		
	  	}
	});
)};	
{%endhighlight%}

File with this code is included in *default.html* 

{%highlight liquid%}
{% raw %}{% include google_analytics.html %} {%endraw%}
{%endhighlight%}

3.  Add **class='ga-link'** to all links you want to track to google analytics.

{%highlight xml%}
<a href="https://github.com/{{ site.github_username }}" class='ga-link' target='_blank'>
{%endhighlight%}

I`ve created such include to help generate links tracked:

{%highlight xml%}
<a href="{{ include.url }}" class="ga-link" target='_blank'>{{ include.title }}</a>
{%endhighlight%}

Now if i want to have such link i can use:

{%highlight liquid%}
{% raw %}
{% include ga_link.html 
	title="GitHub" 
	url="https://github.com" 
%}
{%endraw%}
{%endhighlight%}

