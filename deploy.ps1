# Builds the game and publishes it to GitHub Pages. The gh-pages branch is replaced by a single
# fresh commit each time, so 40 MB engine builds never pile up in the repository's history.
& "$PSScriptRoot\build.ps1"
$site = "$PSScriptRoot\build\web"
$origin = git -C $PSScriptRoot remote get-url origin
# Without this, Pages runs the files through Jekyll first
New-Item -ItemType File -Force "$site\.nojekyll" | Out-Null
Remove-Item -Recurse -Force "$site\.git" -ErrorAction SilentlyContinue
git -C $site init --quiet --initial-branch gh-pages
git -C $site add --all
git -C $site commit --quiet --message "Publish build"
git -C $site push --force --quiet $origin gh-pages
