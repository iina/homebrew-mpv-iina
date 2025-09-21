# Last check with upstream: 042325cd385225e055e2ccf676abe0072cd38dcb <ffmpeg: update 6.0_2 bottle>
# https://github.com/Homebrew/homebrew-core/blob/master/Formula/f/ffmpeg.rb

class FfmpegIina < Formula
  desc "Play, record, convert, and stream audio and video"
  homepage "https://ffmpeg.org/"
  url "https://ffmpeg.org/releases/ffmpeg-8.0.tar.xz"
  sha256 "b2751fccb6cc4c77708113cd78b561059b6fa904b24162fa0be2d60273d27b8e"
  head "https://github.com/FFmpeg/FFmpeg.git", branch: "master"

  keg_only <<EOS
it is intended to only be used for building IINA.
This formula is not recommended for daily use and has no binaraies (ffmpeg, ffplay etc.)
EOS

  depends_on "pkgconf" => :build
  depends_on "dav1d"
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "frei0r"
  depends_on "gnutls"
  depends_on "harfbuzz"
  depends_on "libass"
  depends_on "libbluray"
  depends_on "libsoxr"
  depends_on "libssh"
  depends_on "libvidstab"
  depends_on "rubberband"
  depends_on "snappy"
  depends_on "speex"
  # depends_on "tesseract"
  depends_on "xz"
  depends_on "zeromq"
  depends_on "zimg"
  depends_on "jpeg-xl" # for JPEG-XL format screenshot
  depends_on "webp" # for webp format screenshot
  depends_on "rav1e" # for AVIF format screenshot, #4579
  depends_on "libbs2b" # see #5149

  on_intel do
    depends_on "nasm" => :build
  end

  uses_from_macos "bzip2"
  uses_from_macos "libxml2"
  uses_from_macos "zlib"

  def install

    args = %W[
      --prefix=#{prefix}
      --enable-shared
      --enable-pthreads
      --enable-version3
      --host-cflags=#{ENV.cflags}
      --host-ldflags=#{ENV.ldflags}
      --enable-ffplay
      --enable-gnutls
      --enable-harfbuzz
      --enable-gpl
      --enable-libbluray
      --enable-libdav1d
      --enable-librav1
      --enable-librubberband
      --enable-libsnappy
      --enable-libssh
      --disable-libtesseract
      --enable-libvidstab
      --enable-libxml2
      --enable-libfontconfig
      --enable-libfreetype
      --enable-frei0r
      --enable-libass
      --enable-libspeex
      --enable-libsoxr
      --enable-videotoolbox
      --enable-audiotoolbox
      --enable-libzmq
      --enable-libzimg
      --enable-libwebp
      --enable-libjxl
      --enable-libbs2b
      --disable-libjack
      --disable-indev=jack
      --disable-programs
    ]


    args << "--enable-neon" if Hardware::CPU.arm?
    args << "--cc=#{ENV.cc}" if Hardware::CPU.intel?

    system "./configure", *args
    system "make", "install"

  end

  test do
    # Create an example mp4 file
    mp4out = testpath/"video.mp4"
    system bin/"ffmpeg", "-filter_complex", "testsrc=rate=1:duration=1", mp4out
    assert_path_exists mp4out
  end
end
