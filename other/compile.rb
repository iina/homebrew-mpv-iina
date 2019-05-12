#!/usr/bin/env ruby

require "fileutils"

include FileUtils::Verbose

homebrew_patch = "homebrew.patch"
current_dir = "#{`pwd`.chomp}"

system "brew tap iina/mpv-iina"

homebrew_path = "#{`brew --prefix`.chomp}/Homebrew/"
FileUtils.cd homebrew_path
system "git reset --hard HEAD"
print "Applying Homebrew patch (MACOSX_DEPLOYMENT_TARGET)\n"
system "git apply #{current_dir}/#{homebrew_patch}"

def install(package)
  system "brew reinstall #{package} -s"
end

deps = "#{`brew deps mpv-iina -n`}".split("\n")
print "#{deps.length + 1} packages to be complied\n"

deps.each do |dep|
  install dep
end

install "mpv-iina"

system "git reset --hard HEAD"
