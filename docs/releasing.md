# Releasing

## Pre-release Checklist

1. Update `lib/vietnam_qr_pay/version.rb`
2. Update `CHANGELOG.md`
3. If upstream bank data changed, run `ruby script/generate_catalog.rb`
4. Run `bundle exec rake test`
5. Run `bundle exec rake build`

Current target release in this repository: `0.1.1`

## Local Build

```bash
bundle exec rake build
```

The built gem will be written to:

```text
pkg/vietnam_qr_pay-<version>.gem
```

## Publish to RubyGems

```bash
gem push pkg/vietnam_qr_pay-<version>.gem
```

For the current repo state:

```bash
gem push pkg/vietnam_qr_pay-0.1.1.gem
```

## Makefile Shortcut

The repository `Makefile` avoids hardcoding the gem filename in the publish target.

Relevant lines:

```make
VERSION := $(shell ruby -e 'require_relative "lib/vietnam_qr_pay/version"; puts VietnamQrPay::VERSION')
GEM_FILE := pkg/vietnam_qr_pay-$(VERSION).gem
```

How this works:

- `$(shell ...)` runs a shell command from `make`
- that Ruby command reads `lib/vietnam_qr_pay/version.rb`
- `VERSION` becomes the current gem version, for example `0.1.1`
- `GEM_FILE` then becomes `pkg/vietnam_qr_pay-0.1.1.gem`

So this target:

```make
publish: build
	gem push $(GEM_FILE)
```

expands at runtime to:

```bash
gem push pkg/vietnam_qr_pay-0.1.1.gem
```

That means after bumping the version in `lib/vietnam_qr_pay/version.rb`, `make publish` automatically targets the new artifact name without needing a Makefile edit.

## RubyGems Metadata

The gemspec already includes:

- homepage
- source code URL
- bug tracker URL
- changelog URL
- MFA requirement

Review those links before each release if the repository or branch layout changes.
