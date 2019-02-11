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

@remining = {}
@resolves = {}
@checked = {}

@count = 0
def parse_deps(package)
  @count += 1
  deps = "#{`brew deps #{package}`}".split("\n")
  # if we build harfbuzz before python, python will complain
  # "$MACOSX_DEPLOYMENT_TARGET mismatch"
  deps.append 'python' if package == 'harfbuzz'
  @remining[package] = deps.size
  deps.each do |dep|
    @resolves[dep] = [] if !@resolves.has_key? dep
    @resolves[dep].append package
  end
  @checked[package] = true
  deps.each do |dep|
    parse_deps(dep) if !@checked[dep]
  end
end

def install(package)
  system "brew reinstall #{package} -s"
end

parse_deps "mpv-iina"
print "Number of packages to be complied: #{@count}\n"

while @remining["mpv-iina"] != 0 do
  resolved = @remining.key(0)
  @remining.delete resolved
  install resolved
  @resolves[resolved].each do |package|
    @remining[package] -= 1
  end
end

install "mpv-iina"

system "git reset --hard HEAD"

