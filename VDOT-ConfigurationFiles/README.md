# VDOT Configuration Files

This folder contains a reviewed snapshot migrated from the
[Virtual Desktop Optimization Tool configuration files](https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/tree/main/2009/ConfigurationFiles).

The files are hosted in this repository so that image customization does not apply SYSTEM-level registry and service changes based directly on mutable content from a third-party GitHub repository. This migration addresses [Bug 63518981: Supply-chain: SYSTEM-level registry/service modification driven by unpinned 3rd-party GitHub content](https://microsoft.visualstudio.com/OS/_workitems/edit/63518981).

## Upstream Updates

Maintainers must subscribe to or watch the upstream [Virtual Desktop Optimization Tool repository](https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool) for changes to its `2009/ConfigurationFiles` directory.

Do not synchronize upstream changes automatically. When upstream configuration changes are detected:

1. Review the upstream diff and its impact on Azure Virtual Desktop images.
2. Validate all registry, service, scheduled task, policy, and default-association changes.
3. Decide explicitly whether each change should be migrated into this folder.
4. Test the updated files with the corresponding image customization flow before merging.

Files in this folder are intentionally updated only after human review.