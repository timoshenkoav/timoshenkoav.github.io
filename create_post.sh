NOW=$(date +"%Y-%m-%d")
TIME=$(date +"%Y-%m-%d %H:%M:%S")
title="$2"
timestamp=$(date +%s)
fname=${title// /-}
fname_lower=$(echo "$fname" | awk '{print tolower($0)}')
f="_$1/$NOW-$fname_lower.md"
touch $f
cat > $f <<- EOM
---
layout: post
title:  $title
date:   $TIME
tags: 
related_id: $timestamp
meta_description: 
---
EOM

