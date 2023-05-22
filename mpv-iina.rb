# Last check with upstream: 356dc6f78059f1706bc8c6c44545c262dca43c3e
# https://github.com/Homebrew/homebrew-core/blob/master/Formula/mpv.rb

class MpvIina < Formula
  desc "Media player based on MPlayer and mplayer2"
  homepage "https://mpv.io"
  url "https://github.com/mpv-player/mpv/archive/v0.35.1.tar.gz"
  sha256 "41df981b7b84e33a2ef4478aaf81d6f4f5c8b9cd2c0d337ac142fc20b387d1a9"
  head "https://github.com/mpv-player/mpv.git"

  keg_only "it is intended to only be used for building IINA. This formula is not recommended for daily use"

  depends_on "docutils" => :build
  depends_on "meson" => :build
  depends_on "pkg-config" => [:build, :test]
  depends_on xcode: :build

  depends_on "ffmpeg-iina"
  depends_on "jpeg-turbo"
  depends_on "libarchive"
  depends_on "libass"
  depends_on "little-cms2"
  depends_on "luajit"
  depends_on "libbluray"

  depends_on "mujs"
  depends_on "uchardet"
  # depends_on "vapoursynth"
  depends_on "yt-dlp"

  # Fix ytdl issue. Remove after next mpv release.
  patch :DATA

  # Fix charset conversion issue. Remove after next mpv release.
  patch do 
    url "https://gist.githubusercontent.com/lhc70000/ab2aa7c8728ad18367082e7f0a9ad059/raw/8a8da66707de7bc12b689d60591ce0621d57e3ba/charset_conv.diff"
    sha256 "30315e3d5ba962201516ff7c4420bcb2b6d664c0c1caba1b570369624ecc7748"
  end

  # Fix mpv not allowing sleep. Remove after these are resolved:
  # PR https://github.com/mpv-player/mpv/pull/11667
  # issue https://github.com/mpv-player/mpv/issues/11617
  patch do 
    url "https://gist.githubusercontent.com/lhc70000/ab2aa7c8728ad18367082e7f0a9ad059/raw/eceb7b620a763677c0a5ef2b07e10fa26f95a943/coreaudio_allow_sleep.patch"
    sha256 "c7f179331ddae45b119803b0556a2b05c5f7a314ebdb8696a7db65c3ebbd0c0e"
  end

  def install
    # LANG is unset by default on macOS and causes issues when calling getlocale
    # or getdefaultlocale in docutils. Force the default c/posix locale since
    # that's good enough for building the manpage.
    ENV["LC_ALL"] = "C"

    # force meson find ninja from homebrew
    ENV["NINJA"] = Formula["ninja"].opt_bin/"ninja"

    # libarchive is keg-only
    ENV.prepend_path "PKG_CONFIG_PATH", Formula["libarchive"].opt_lib/"pkgconfig"

    args = %W[
      -Dhtml-build=disabled
      -Djavascript=enabled
      -Dlibmpv=true
      -Dlua=luajit
      -Dlibarchive=enabled
      -Duchardet=enabled

      -Dlibbluray=enabled
      -Dcplayer=false

      -Dswift-build=disabled
      -Dmacos-cocoa-cb=disabled
      -Dmacos-media-player=disabled
      -Dmacos-touchbar=disabled
      -Dmanpage-build=disabled

      --sysconfdir=#{pkgetc}
      --datadir=#{pkgshare}
    ]

    system "meson", "setup", "build", *args, *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"

    # `pkg-config --libs mpv` includes libarchive, but that package is
    # keg-only so it needs to look for the pkgconfig file in libarchive's opt
    # path.
    libarchive = Formula["libarchive"].opt_prefix
    inreplace lib/"pkgconfig/mpv.pc" do |s|
     s.gsub!(/^Requires\.private:(.*)\blibarchive\b(.*?)(,.*)?$/,
             "Requires.private:\\1#{libarchive}/lib/pkgconfig/libarchive.pc\\3")
    end

  end

  test do
    system bin/"mpv", "--ao=null", test_fixtures("test.wav")
    # Make sure `pkg-config` can parse `mpv.pc` after the `inreplace`.
    system "pkg-config", "mpv"
  end
end

__END__
diff --git a/player/lua/ytdl_hook.lua b/player/lua/ytdl_hook.lua
index f40579ad36..77f7446ed2 100644
--- a/player/lua/ytdl_hook.lua
+++ b/player/lua/ytdl_hook.lua
@@ -47,6 +47,7 @@ local tag_list = {
     -- (default --display-tags does not include this name)
     ["description"]     = "ytdl_description",
     -- "title" is handled by force-media-title
+    -- tags don't work with all_formats=yes
 }

 local safe_protos = Set {
@@ -90,17 +91,18 @@ local function map_codec_to_mpv(codec)
 end

 local function platform_is_windows()
-    return package.config:sub(1,1) == "\\"
+    return mp.get_property_native("platform") == "windows"
 end

 local function exec(args)
     msg.debug("Running: " .. table.concat(args, " "))

-    local ret = mp.command_native({name = "subprocess",
-                                   args = args,
-                                   capture_stdout = true,
-                                   capture_stderr = true})
-    return ret.status, ret.stdout, ret, ret.killed_by_us
+    return mp.command_native({
+        name = "subprocess",
+        args = args,
+        capture_stdout = true,
+        capture_stderr = true,
+    })
 end

 -- return true if it was explicitly set on the command line
@@ -295,7 +297,7 @@ local function edl_track_joined(fragments, protocol, is_live, base)
         local args = ""

         -- assume MP4 DASH initialization segment
-        if not fragments[1].duration then
+        if not fragments[1].duration and #fragments > 1 then
             msg.debug("Using init segment")
             args = args .. ",init=" .. edl_escape(join_url(base, fragments[1]))
             offset = 2
@@ -307,7 +309,7 @@ local function edl_track_joined(fragments, protocol, is_live, base)
         -- if not available in all, give up.
         for i = offset, #fragments do
             if not fragments[i].duration then
-                msg.error("EDL doesn't support fragments" ..
+                msg.verbose("EDL doesn't support fragments " ..
                          "without duration with MP4 DASH")
                 return nil
             end
@@ -421,6 +423,7 @@ local function formats_to_edl(json, formats, use_all_formats)
             track.protocol, json.is_live,
             track.fragment_base_url)
         if not edl_track and not url_is_safe(track.url) then
+            msg.error("No safe URL or supported fragmented stream available")
             return nil
         end

@@ -628,7 +631,9 @@ local function add_single_video(json)

     mp.set_property("stream-open-filename", streamurl:gsub("^data:", "data://", 1))

-    mp.set_property("file-local-options/force-media-title", json.title)
+    if mp.get_property("force-media-title", "") == "" then
+        mp.set_property("file-local-options/force-media-title", json.title)
+    end

     -- set hls-bitrate for dash track selection
     if max_bitrate > 0 and
@@ -805,9 +810,9 @@ function run_ytdl_hook(url)
     table.insert(command, "--")
     table.insert(command, url)

-    local es, json, result, aborted
+    local result
     if ytdl.searched then
-        es, json, result, aborted = exec(command)
+        result = exec(command)
     else
         local separator = platform_is_windows() and ";" or ":"
         if o.ytdl_path:match("[^" .. separator .. "]") then
@@ -825,12 +830,12 @@ function run_ytdl_hook(url)
                 msg.verbose("Found youtube-dl at: " .. ytdl_cmd)
                 ytdl.path = ytdl_cmd
                 command[1] = ytdl.path
-                es, json, result, aborted = exec(command)
+                result = exec(command)
                 break
             else
                 msg.verbose("No youtube-dl found with path " .. path .. exesuf .. " in config directories")
                 command[1] = path
-                es, json, result, aborted = exec(command)
+                result = exec(command)
                 if result.error_string == "init" then
                     msg.verbose("youtube-dl with path " .. path .. exesuf .. " not found in PATH or not enough permissions")
                 else
@@ -844,20 +849,21 @@ function run_ytdl_hook(url)
         ytdl.searched = true
     end

-    if aborted then
+    if result.killed_by_us then
         return
     end

+    local json = result.stdout
     local parse_err = nil

-    if (es ~= 0) or (json == "") then
+    if result.status ~= 0 or json == "" then
         json = nil
     elseif json then
         json, parse_err = utils.parse_json(json)
     end

     if (json == nil) then
-        msg.verbose("status:", es)
+        msg.verbose("status:", result.status)
         msg.verbose("reason:", result.error_string)
         msg.verbose("stdout:", result.stdout)
         msg.verbose("stderr:", result.stderr)
@@ -870,10 +876,8 @@ function run_ytdl_hook(url)
             err = err .. "not found or not enough permissions"
         elseif parse_err then
             err = err .. "failed to parse JSON data: " .. parse_err
-        elseif not result.killed_by_us then
-            err = err .. "unexpected error occurred"
         else
-            err = string.format("%s returned '%d'", err, es)
+            err = err .. "unexpected error occurred"
         end
         msg.error(err)
         if parse_err or string.find(ytdl_err, "yt%-dl%.org/bug") then
@@ -925,7 +929,7 @@ function run_ytdl_hook(url)
             set_http_headers(json.entries[1].http_headers)

             mp.set_property("stream-open-filename", playlist)
-            if not (json.title == nil) then
+            if json.title and mp.get_property("force-media-title", "") == "" then
                 mp.set_property("file-local-options/force-media-title",
                     json.title)
             end
