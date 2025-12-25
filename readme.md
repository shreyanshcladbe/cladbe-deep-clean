# cladbe-deep-clean

A portable deep-clean script for Flutter projects.

It: - Finds the Flutter project root from any directory - Cleans
Flutter, Dart, and CocoaPods state - Reinstalls dependencies using
`pod install --repo-update` - Shows animated spinners and progress bars
by default - Supports verbose and quiet execution modes - Is safe to run
via `curl | bash`

## Usage

``` bash
curl -fsSL https://raw.githubusercontent.com/shreyanshcladbe/cladbe-deep-clean/main/script.sh | bash
```

### Verbose mode (step-by-step output)

``` bash
curl -fsSL https://raw.githubusercontent.com/shreyanshcladbe/cladbe-deep-clean/main/script.sh | bash -s -- -v
```

### Quiet mode (minimal output, CI-friendly)

``` bash
curl -fsSL https://raw.githubusercontent.com/shreyanshcladbe/cladbe-deep-clean/main/script.sh | bash -s -- -q
```
