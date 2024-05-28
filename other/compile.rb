#!/usr/bin/env ruby

require "fileutils"
require "pathname"

include FileUtils::Verbose

$compile_deps = !$*.find_index("--no-deps")
$only_setup = $*.find_index("--setup-env")
$install_head = $*.find_index("--head")

arch = %x[arch].chomp
$homebrew_patch = if arch == "arm64"
                    "homebrew_arm.patch"
                  else
                    "homebrew_x86.patch"
                  end
$current_dir = "#{`pwd`.chomp}"
$homebrew_path = "#{`brew --repository`.chomp}/"

# system "brew tap iina/mpv-iina"

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

class FormulaPatcher
  def initialize(lib)
    @file_path = `brew edit --print-path #{lib}`.strip
  end

  def remove_line(ln)
    lines = Pathname(@file_path).readlines
    lines.filter! { |line| !line.strip.end_with?(ln) }
    File.open(@file_path, 'w') { |file| file.write lines.join }
  end

  def append_after_line(ln, &block)
    new_ln = block.call
    lines = Pathname(@file_path).readlines
    arg_line = lines.index { |l| l.strip.end_with?(ln) }
    lines.insert(arg_line + 1, new_ln + "\n")
    File.open(@file_path, 'w') { |file| file.write lines.join }
  end
end

def patch_formula(*libs, &block)
  libs.each do |lib|
    patcher = FormulaPatcher.new(lib)
    block.call(patcher)
    p "Patched #{lib}"
  end
end

def livecheck(package)
  splitted = `brew livecheck rubberband`.split(/:|==>/).map { |x| x.strip }
  splitted[1] == splitted[2]
end

def setup_rb(package)
  system "sd 'def install' 'def install\n\tENV[\"CFLAGS\"] = \"-mmacosx-version-min=10.15\"\n\tENV[\"LDFLAGS\"] = \"-mmacosx-version-min=10.15\"\n\tENV[\"CXXFLAGS\"] = \"-mmacosx-version-min=10.15\"\n' $(brew edit --print-path #{package})"
end

def setup_env
  system "brew update --auto-update"
  ENV["HOMEBREW_NO_AUTO_UPDATE"] = "1"
  ENV["HOMEBREW_NO_INSTALL_UPGRADE"] = "1"
  ENV["HOMEBREW_NO_INSTALL_CLEANUP"] = "1"
  ENV["HOMEBREW_NO_INSTALL_FROM_API"] = "1"
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

# Begin compilation

begin
  setup_env
  return if $only_setup

  patch_formula 'luajit' do |p|
    p.remove_line 'ENV["MACOSX_DEPLOYMENT_TARGET"] = MacOS.version'
  end

  # Patch formulas to set deployment target to be 10.15
  if arch != "arm64"
    patch_formula 'libpng', 'luajit', 'glib' do |p|
      p.append_after_line 'def install' do
        %q(
          ENV["CFLAGS"] = "-mmacosx-version-min=10.15"
          ENV["LDFLAGS"] = "-mmacosx-version-min=10.15"
          ENV["CXXFLAGS"] = "-mmacosx-version-min=10.15"
        )
      end
    end

    patch_formula 'rubberband' do |p|
      p.append_after_line 'args = ["-Dresampler=libsamplerate"]' do
        'args << "-Dcpp_args=-mmacosx-version-min=10.15"'
      end
    end

    patch_formula 'jpeg-xl' do |p|
      p.append_after_line 'system "cmake", "-S", ".", "-B", "build",' do
        %q(
          "-DCMAKE_CXX_FLAGS=-mmacosx-version-min=10.15",
          "-DCMAKE_CXX_FLAGS='-O2 -fno-sized-deallocation'",
        )
      end
    end
  end

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
