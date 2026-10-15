#!/bin/bash
# needs md2html, gawk
set -e
SRC="$(cd "$(dirname "$0")" && pwd)"
S=$(dirname "$SRC")
V=$(date +%s)

rm -f "$S"/*.html
cp "$SRC/style.css" "$SRC/logo.png" "$SRC/mark.png" "$SRC/mark-bg.png" "$S/"
touch "$S/.nojekyll"

# md to page
page() {
  local md=$1 out=$2 tpl=${3:-template} title
  title=$(grep -m1 '^# ' "$md" | sed 's/^# //')
  title=${title:+$title - }Subverge
  md2html --github "$md" \
    | sed -E 's/href="([^":#]+)\.md/href="\1.html/g' \
    | gawk '
      match($0, /^<h([1-4])>(.*)<\/h[1-4]>$/, m) {
        id = tolower(m[2]); gsub(/<[^>]*>/, "", id); gsub(/&[a-z]+;/, "", id)
        gsub(/[^a-z0-9 _-]/, "", id); gsub(/ /, "-", id)
        print "<h" m[1] " id=\"" id "\">" m[2] "</h" m[1] ">"; next
      }
      { print }' > "$S/.body"
  awk -v t="$title" -v v="$V" -v b="$S/.body" '
    /@BODY@/ { while ((getline l < b) > 0) print l; next }
    { gsub(/@TITLE@/, t); gsub(/@VER@/, v); print }' "$SRC/$tpl.html" > "$S/$out"
}

for f in "$SRC"/*.md; do
  case ${f##*/} in
    index.md) page "$f" index.html home ;;
    *) page "$f" "$(basename "${f%.md}").html" ;;
  esac
done
# absolute paths
sed -i 's|<head>|<head>\n<base href="/">|' "$S/404.html"
rm -f "$S/.body"
echo "built $(ls "$S"/*.html | wc -l) pages"
