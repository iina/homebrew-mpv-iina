# Last check with upstream: 03fb1acf8d1c5417b8079eb68b2104a1296bc665
# https://github.com/Homebrew/homebrew-core/blob/master/Formula/m/mpv.rb

class MpvIina < Formula
desc "Media player based on MPlayer and mplayer2"
  homepage "https://mpv.io"
  head "https://github.com/iina/mpv.git", :branch => "iina-release/1.5.0"

  keg_only "it is intended to only be used for building IINA. This formula is not recommended for daily use"

  depends_on "docutils" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]
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
  depends_on "mujs"
  depends_on "uchardet"
  # depends_on "vapoursynth"
  depends_on "yt-dlp"

  uses_from_macos "zlib"

  on_ventura :or_older do
    depends_on "lld" => :build
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

    # Work around https://github.com/mpv-player/mpv/issues/15591
    # This bug happens running classic ld, which is the default
    # prior to Xcode 15 and we enable it in the superenv prior to
    # Xcode 15.3 when using -dead_strip_dylibs (default for meson).
    if OS.mac? && MacOS.version <= :ventura
      ENV.append "LDFLAGS", "-fuse-ld=lld"
      ENV.O1 # -Os is not supported for lld and we don't have ENV.O2
    end

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

      -Dmacos-touchbar=disabled
      -Dmacos-media-player=disabled
      -Dmacos-cocoa-cb=disabled

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
    # Make sure `pkgconf` can parse `mpv.pc` after the `inreplace`.
    system "pkgconf", "--print-errors", "mpv"
  end
end
