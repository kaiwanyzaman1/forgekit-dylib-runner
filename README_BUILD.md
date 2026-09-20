# KaiwanLicense

This is a Theos iOS tweak project. The source is not a standalone macOS
dynamic library; it must be compiled with an iPhoneOS SDK and Theos.

## Build on macOS with Theos

```sh
export THEOS="$HOME/theos"
make clean
make package FINALPACKAGE=1
```

The compiled library will be under `.theos/obj/` and the packaged tweak will
be under `packages/`. For eSign injection, use the generated
`KaiwanLicense.dylib` that matches the target architecture.

This version keeps the overlay window alive and assigns it to the active
`UIWindowScene`, which fixes the common “dylib injected but the license UI is
not visible” issue on iOS 13 and newer. The source contains only the license
overlay; it does not contain a separate in-app menu.

## Build on GitHub Actions

Upload this folder as a GitHub repository. The included workflow runs on a
macOS runner, installs Theos and the iOS SDK, and publishes
`KaiwanLicense.dylib` as a workflow artifact. Open the repository's
**Actions** tab, select **Build KaiwanLicense dylib**, and run it manually if
you do not want builds on every push.