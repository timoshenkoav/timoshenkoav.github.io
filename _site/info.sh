ls -1 | grep .jpg | while read line
do
w=$(identify -format '%w' $line)
h=$(identify -format '%h' $line)
echo - url: $line
echo "  width: $w"
echo "  height: $h"
done