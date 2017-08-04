---
layout: default
title: Develop
permalink: /develop/
show_in_navigation: true
---

<div class="home">  

  <ul class="post-list">    
  	{% assign items = site.develop | sort: 'date' | reverse %}
    {% assign random = site.time | date: "%s%N" | modulo: items.size %}
    {% assign i = 0 %}
    {% for post in items %}
      <li>
        <span class="post-meta">{{ post.date | date: "%b %-d, %Y" }}</span>

        <h2>
          <a class="post-link" href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>
        </h2>
        <div class="excerpt">
          {{post.excerpt}}
        </div>
      </li>
      {%if random == i %}
        {% include infeed_ads.html %}                            
      {%endif%}
      {%assign i = i+1%}
    {% endfor %}
  </ul>

  <p class="rss-subscribe">subscribe <a href="{{ "/feed.xml" | prepend: site.baseurl }}" target="_blank" class='subscribe'>via RSS</a></p>

</div>
