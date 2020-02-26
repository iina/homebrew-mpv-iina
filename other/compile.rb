#!/usr/bin/env ruby

require "fileutils"

include FileUtils::Verbose

compile_deps = !$*.find_index("--no-deps")

$homebrew_patch = "homebrew.patch"
$current_dir = "#{`pwd`.chomp}"
$homebrew_path = ""

# system "brew tap iina/mpv-iina"

def install(package)
  system "brew uninstall #{package} --ignore-dependencies"
  system "brew install #{package} --build-bottle"
end

def patch_python
  file_path = "#{`brew --prefix python`.chomp}/Frameworks/Python.framework/Versions/3.7/lib/python3.7/distutils/spawn.py"
  lines = File.readlines(file_path)
  lines.filter! { |line| !line.end_with?("raise DistutilsPlatformError(my_msg)\n") }
  File.open(file_path, 'w') { |file| file.write lines.join }
end

def setup_env
  ENV["HOMEBREW_NO_AUTO_UPDATE"] = "1"
  $homebrew_path = "#{`brew --prefix`.chomp}/Homebrew/"
  FileUtils.cd $homebrew_path
  system "git reset --hard HEAD"
  print "Applying Homebrew patch (MACOSX_DEPLOYMENT_TARGET)\n"
  system "git apply #{$current_dir}/#{$homebrew_patch}"
end

begin
  setup_env

  if compile_deps
    deps = "#{`brew deps mpv-iina -n`}".split("\n")
    print "#{deps.length + 1} packages to be complied\n"

    deps.each do |dep|
      install dep
      if dep == "python"
        patch_python
        system "brew postinstall python"
      end
    end
  end

  install "mpv-iina"

ensure
  FileUtils.cd $homebrew_path
  system "git reset --hard HEAD"
end
