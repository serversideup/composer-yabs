# composer-yet-another-bench-script

A thin Composer-distributed wrapper around the upstream Yet-Another-Bench-Script (YABS).

This package does not modify YABS. It only vendors the upstream script and exposes a `yabs` binary in your PHP project's Composer `bin` directory for convenience.

- Upstream project: https://github.com/masonr/yet-another-bench-script
- Upstream site: https://yabs.sh

## Install

```bash
composer require --dev serversideup/yabs
```

## Usage

After install, Composer will expose the `yabs` executable at `vendor/bin/yabs`.

```bash
vendor/bin/yabs
```

All flags and behavior are implemented by the upstream script. See upstream docs for options like `-i` (skip iperf), `-r` (reduced iperf locations), `-j` (JSON), etc. Refer to:

- Upstream README: https://github.com/masonr/yet-another-bench-script#readme

## What this package is (and is not)

- This is simply a redistribution mechanism via Composer.
- No changes are made to the upstream YABS logic.
- The upstream script and binaries live under `src/` and retain their original license and notices.
- The small launcher in `bin/yabs` just executes `src/yabs.sh`.

## Licensing

- Upstream YABS is licensed under WTFPL; see `src/LICENSE` and `src/README.md` for details.
- This Composer wrapper is licensed under GPL-3.0-or-later (see `LICENSE`). It covers only the minimal wrapper files in this repository (e.g., `composer.json`, `bin/yabs`, and this README). The upstream code keeps its original license.

## Attribution

All credit for YABS goes to its author(s) and contributors: https://github.com/masonr/yet-another-bench-script

This package merely packages that work for Composer users.
