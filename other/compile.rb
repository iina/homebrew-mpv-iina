#!/usr/bin/env ruby

require "fileutils"
require "pathname"

include FileUtils::Verbose

$compile_deps = !$*.find_index("--no-deps")
$only_setup = $*.find_index("--setup-env")
$install_head = $*.find_index("--head")

$current_dir = "#{`pwd`.chomp}"
$homebrew_path = "#{`brew --repository`.chomp}/"

system "brew tap iina/mpv-iina"

def install(package, head: false)
  if head
    system "brew uninstall #{package}"
    system "brew install #{package} --HEAD"
  else
    system "brew reinstall #{package} --build-from-source"
  end
end

def fetch(package)
  system "brew fetch -f -s #{package}"
end

def livecheck(package)
  splitted = `brew livecheck rubberband`.split(/:|==>/).map { |x| x.strip }
  splitted[1] == splitted[2]
end

def setup_env
  system "brew update --auto-update"
  ENV["HOMEBREW_NO_AUTO_UPDATE"] = "1"
  ENV["HOMEBREW_NO_INSTALL_UPGRADE"] = "1"
  ENV["HOMEBREW_NO_INSTALL_CLEANUP"] = "1"
  ENV["HOMEBREW_NO_INSTALL_FROM_API"] = "1"
  FileUtils.cd $homebrew_path
end

# Begin compilation

begin
  setup_env
  return if $only_setup

  deps = "#{`brew deps mpv-iina -n`}".split("\n")
  total = deps.length + 1

  deps.each do |dep|
    fetch dep
  end
  fetch "mpv-iina"
  print "\n#{total} fetched\n"

  if $compile_deps
    print "#{total} packages to be compiled\n"

    deps.each do |dep|
      raise "brew livecheck failed for #{dep}" unless livecheck dep

      print "\nCompiling #{dep}\n"
      install dep
      total -= 1
      print "------------------------\n"
      print "#{dep} has been compiled\n"
      print "#{total} remained\n"
      print "------------------------\n"
    end
  end

  install "mpv-iina", head: $install_head

ensure
  reset
end
