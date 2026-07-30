#!/usr/bin/env bash
# Generate a simple download index for the `app` branch artifacts.
# Links use GitHub raw URLs so browsers download files instead of opening blob pages.
set -euo pipefail

repo="${1:?repository owner/name required, e.g. fossasia/pslab-app}"
outdir="${2:-.}"
raw_base="https://github.com/${repo}/raw/app"
outfile="${outdir%/}/index.html"

{
  cat <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>PSLab App Downloads</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; max-width: 720px; margin: 48px auto; padding: 0 20px; line-height: 1.5; color: #24292f; }
    h1 { margin-bottom: 8px; }
    p { color: #57606a; }
    ul { list-style: none; padding: 0; }
    li { display: flex; justify-content: space-between; align-items: center; gap: 12px; padding: 12px 0; border-top: 1px solid #d0d7de; }
    a { color: #fff; background: #cf2b27; text-decoration: none; padding: 8px 14px; border-radius: 8px; font-weight: 600; white-space: nowrap; }
    .name { font-weight: 600; word-break: break-all; }
  </style>
</head>
<body>
  <h1>PSLab App Downloads</h1>
  <p>Development builds from the <code>app</code> branch. Each link starts a direct file download.</p>
  <ul>
EOF

  shopt -s nullglob
  for file in "$outdir"/*; do
    [ -f "$file" ] || continue
    base=$(basename "$file")
    [ "$base" = "index.html" ] && continue
    case "$base" in
      *.apk|*.aab|*.ipa|*.exe|*.deb|*.rpm|*.dmg|*.zip) ;;
      *) continue ;;
    esac
    escaped_name=$(printf '%s' "$base" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')
    encoded_name=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$base")
    printf '    <li><span class="name">%s</span><a href="%s/%s" download>Download</a></li>\n' \
      "$escaped_name" "$raw_base" "$encoded_name"
  done

  cat <<'EOF'
  </ul>
</body>
</html>
EOF
} > "$outfile"

echo "Wrote $outfile"
