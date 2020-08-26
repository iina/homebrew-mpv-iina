#!/usr/bin/env ruby

require "fileutils"

include FileUtils::Verbose

$compile_deps = !$*.find_index("--no-deps")
$only_setup = $*.find_index("--setup-env")

$homebrew_patch = "homebrew.patch"
$current_dir = "#{`pwd`.chomp}"
$homebrew_path = "#{`brew --prefix`.chomp}/Homebrew/"

# system "brew tap iina/mpv-iina"

def install(package)
  system "brew uninstall #{package} --ignore-dependencies"
  system "brew install #{package} --build-bottle"
  system "brew postinstall #{package}"
end

def setup_env
  ENV["HOMEBREW_NO_AUTO_UPDATE"] = "1"
  FileUtils.cd $homebrew_path
  system "git reset --hard HEAD"
  print "Applying Homebrew patch (MACOSX_DEPLOYMENT_TARGET)\n"
  system "git apply #{$current_dir}/#{$homebrew_patch}"
end

def reset
  return if $only_setup
  FileUtils.cd $homebrew_path
  system "git reset --hard HEAD"
end

begin
  setup_env
  return if $only_setup

  if $compile_deps
    deps = "#{`brew deps mpv-iina -n`}".split("\n")
    print "#{deps.length + 1} packages to be compiled\n"

    deps.each do |dep|
      print "\nCompiling #{dep}\n"
      install dep
      print "------------------------\n"
      print "#{dep} has been compiled\n"
      print "------------------------\n"
    end
  end

  install "mpv-iina"

ensure
  reset
end
