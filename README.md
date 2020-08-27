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
You do not have to use this script in most cases. The libraries that IINA ships are compiled by `other/compile.rb`. Although this script actually runs homebrew command to compile the dependencies and libraries that IINA needs, unlike the libraries you get by installing mpv (or mpv-iina) using homebrew directly, this script:

- Compile all IINA dependencies with `MACOSX_DEPLOTMENT_TARGET=10.11` to be compatible with OS X 10.11. This is done by patching homebrew (see `other/homebrew.patch`) before compiling and disable homebrew auto update.
- Add `--build-bottle` option to homebrew when compiling to keep compatibility for some older architecture. See https://github.com/iina/iina/issues/1660 .

- Patch Python before compiling harfbuzz to prevent Python from throwing errors complaining `$MACOSX_DEPLOYMENT_TARGET mismatch`. See https://stackoverflow.com/a/13315980 .

**Important** This script automatically reverts changes to homebrew before exiting, but does not restore Python to its original state. Please reinstall Python from homebrew after running this script if you want to use a clean Python.
