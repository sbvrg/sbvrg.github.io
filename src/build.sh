#!/bin/bash
# needs md2html, gawk
set -e
SRC="$(cd "$(dirname "$0")" && pwd)"
S=$(dirname "$SRC")
V=$(date +%s)
D=$(date -u +%Y-%m-%d)

rm -f "$S"/*.html
cp "$SRC/style.css" "$SRC/logo.png" "$SRC/mark.png" "$SRC/mark-light.png" "$SRC/mark-bg.png" "$SRC/mark-footer.png" "$SRC/banner.jpg" "$S/"
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
  awk -v t="$title" -v v="$V" -v d="$D" -v b="$S/.body" -v h="$SRC/header.html" -v f="$SRC/footer.html" '
    function inc(p,  l) { while ((getline l < p) > 0) sub_print(l); close(p) }
    function sub_print(l) { gsub(/@TITLE@/, t, l); gsub(/@VER@/, v, l); gsub(/@DATE@/, d, l); print l }
    /@BODY@/ { while ((getline l < b) > 0) print l; close(b); next }
    /@HEADER@/ { inc(h); next }
    /@FOOTER@/ { inc(f); next }
    { sub_print($0) }' "$SRC/$tpl.html" > "$S/$out"
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
