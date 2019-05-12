#!/usr/bin/env ruby

require "fileutils"

include FileUtils::Verbose

compile_deps = ($*.first == "--compile-deps")

homebrew_patch = "homebrew.patch"
current_dir = "#{`pwd`.chomp}"

system "brew tap iina/mpv-iina"

def install(package)
  system "brew reinstall #{package} -s"
end

if compile_deps
  homebrew_path = "#{`brew --prefix`.chomp}/Homebrew/"
  FileUtils.cd homebrew_path
  system "git reset --hard HEAD"
  print "Applying Homebrew patch (MACOSX_DEPLOYMENT_TARGET)\n"
  system "git apply #{current_dir}/#{homebrew_patch}"
  deps = "#{`brew deps mpv-iina -n`}".split("\n")
  print "#{deps.length + 1} packages to be complied\n"

  deps.each do |dep|
    install dep
  end
end

install "mpv-iina"

at_exit {
  system "git reset --hard HEAD" if compile_deps
}
