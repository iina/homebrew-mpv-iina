# mpv homebrew tap for IINA

This repo contains custom mpv and ffmpeg homebrew tap for IINA.

### mpv-iina.rb
- Depends on ffmpeg-iina instead of ffmpeg
- Does not depend on vapoursynth
- Removes swift supoport

### ffmpeg-iina.rb
- Removed all encoding libraries
- Removed some of the decoding libraries which ffmpeg can natively decode

### other/compile.rb
You do not have to use this script in most cases. The libraries that IINA ships are compiled by `other/compile.rb`. All the dependencies of mpv-iina (and mpv-iina itself) is installed to the standard homebrew dirs. Each library is installed via
```bash
brew reinstall {package name} --build-from-source
```

Note that this script no longer inject `MACOSX_DEPLOYMENT_TARGET` to the env of homebrew during compile time. All libraries are targeted to the compiling system. So, in order to support a lower version of macOS, please run this script on that specific version of macOS. This script was tested on macOS 10.15 (x86) and macOS 12 (arm).

