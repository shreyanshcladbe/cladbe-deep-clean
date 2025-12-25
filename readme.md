# cladbe-deep-clean

A portable deep-clean script for Flutter projects.

It:
- Finds the Flutter project root from any directory
- Cleans Flutter, Dart, and CocoaPods state
- Reinstalls dependencies deterministically
- Supports quiet and verbose modes
- Is safe to run via `curl | bash`

## Usage

```bash
curl -fsSL https://raw.githubusercontent.com/shreyanshcladbe/cladbe-deep-clean/main/script.sh | bash
