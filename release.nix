{ lib, releases }:
let
  candidates = builtins.filter (
    r: lib.hasPrefix "launcher@" r.tag_name && !r.draft && !r.prerelease
  ) releases;
  sorted = builtins.sort (a: b: a.published_at > b.published_at) candidates;
  release =
    if sorted == [ ] then
      throw "No stable Horizon launcher release in the locked GitHub release feed"
    else
      builtins.head sorted;
  assets = builtins.filter (a: a.name == "horizon-launcher-linux-x86_64.tar.gz") release.assets;
  asset =
    if builtins.length assets != 1 then
      throw "Horizon ${release.tag_name}: expected one Linux x86_64 launcher archive"
    else
      builtins.head assets;
  digest = asset.digest or null;
in
{
  version = lib.removePrefix "launcher@" release.tag_name;
  url = asset.browser_download_url;
  sha256 =
    if builtins.isString digest && builtins.match "sha256:[0-9a-f]{64}" digest != null then
      lib.removePrefix "sha256:" digest
    else
      throw "Horizon ${release.tag_name}: archive has no valid SHA-256 digest";
}
