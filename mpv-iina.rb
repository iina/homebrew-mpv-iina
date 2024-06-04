# Last check with upstream: 03fb1acf8d1c5417b8079eb68b2104a1296bc665
# https://github.com/Homebrew/homebrew-core/blob/master/Formula/m/mpv.rb

class MpvIina < Formula
desc "Media player based on MPlayer and mplayer2"
  homepage "https://mpv.io"
  url "https://github.com/mpv-player/mpv/archive/refs/tags/v0.38.0.tar.gz"
  sha256 "86d9ef40b6058732f67b46d0bbda24a074fae860b3eaae05bab3145041303066"
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
  depends_on "libplacebo"
  depends_on "little-cms2"
  depends_on "luajit"
  depends_on "libbluray"
  depends_on "libsamplerate"
  depends_on "vulkan-loader"
  depends_on "zimg"
 # depends_on "molten-vk"

  uses_from_macos "zlib"

  depends_on "mujs"
  depends_on "uchardet"
  # depends_on "vapoursynth"
  depends_on "yt-dlp"

  stable do
    # patch :DATA

    patch do
      url "https://raw.githubusercontent.com/iina/homebrew-mpv-iina/master/other/13348.patch"
      sha256 "f73b5e68ea31d69beb3163b2a19801e9aeb730196483f002622a8184df53eaa9"
    end

    patch do
      url "https://raw.githubusercontent.com/iina/homebrew-mpv-iina/master/other/14092.patch"
      sha256 "5f67187ec7474cece4a0aabb9c7f484d4553c1782e61c6e708600c97eaac863f"
    end

    patch do
      url "https://raw.githubusercontent.com/iina/homebrew-mpv-iina/master/other/14229.patch"
      sha256 "aa5cbc43a8fb6ac8cf89560ab02924602971e80a9a42ec3d72bcebfa7deb0e0e"
    end
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

      -Dmanpage-build=disabled

      -Dswift-build=disabled
      -Dmacos-cocoa-cb=disabled
      -Dmacos-media-player=disabled
      -Dmacos-touchbar=disabled
      -Davfoundation=disabled

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
diff --git a/version.sh b/version.sh
index 2cfc384b5c..6a2c049bfe 100755
--- a/version.sh
+++ b/version.sh
@@ -34,7 +34,7 @@ fi
 # or from "git describe" output
 git_revision=$(cat snapshot_version 2> /dev/null)
 test "$git_revision" || test ! -e .git || git_revision="$(git describe \
-    --match "v[0-9]*" --always --tags --dirty | sed 's/^v//')"
+    --match "v[0-9]*" --always --tags | sed 's/^v//')"
 version="$git_revision"
 
 # other tarballs extract the version number from the VERSION file
diff --git a/waftools/detections/compiler_swift.py b/waftools/detections/compiler_swift.py
index cf55149291..9efef4c4d9 100644
--- a/waftools/detections/compiler_swift.py
+++ b/waftools/detections/compiler_swift.py
@@ -24,13 +24,13 @@ def __add_swift_flags(ctx):
 def __add_swift_library_linking_flags(ctx, swift_library):
     ctx.env.append_value('LINKFLAGS', [
         '-L%s' % swift_library,
-        '-Xlinker', '-force_load_swift_libs', '-lc++',
+        '-lc++',
     ])
 
 def __find_swift_library(ctx):
     swift_library_paths = [
-        'Toolchains/XcodeDefault.xctoolchain/usr/lib/swift_static/macosx',
-        'usr/lib/swift_static/macosx'
+        'Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx',
+        'usr/lib/swift/macosx'
     ]
     dev_path = __run(['xcode-select', '-p'])[1:]
 
