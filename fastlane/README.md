fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios checkmeta

```sh
[bundle exec] fastlane ios checkmeta
```

Validate localized App Store metadata exists for all launch locales

### ios upmeta

```sh
[bundle exec] fastlane ios upmeta
```

Upload App Store metadata only

### ios uppic

```sh
[bundle exec] fastlane ios uppic
```

Upload localized App Store screenshots only

### ios build_release

```sh
[bundle exec] fastlane ios build_release
```

Build an App Store Connect archive

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
