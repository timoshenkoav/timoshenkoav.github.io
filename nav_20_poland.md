---
layout: page
title: Poland
permalink: /poland/
show_in_navigation: true
---

<div class="home">  

  <ul class="post-list">    
  	{% assign items = site.poland | sort: 'date' | reverse %}
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
    {% endfor %}
  </ul>

  <p class="rss-subscribe">subscribe <a href="{{ "/feed.xml" | prepend: site.baseurl }}" target="_blank" class='subscribe'>via RSS</a></p>

</div>