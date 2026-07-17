# Codex Weekly Limits

A small KDE Plasma 6 widget that shows Codex weekly usage as a progress bar.

It reads the weekly window from the locally authenticated Codex CLI and refreshes every five minutes. There are no settings.

## Requirements

- KDE Plasma 6
- Python 3
- An installed and signed-in Codex CLI

## Use

```sh
make check
make install
```

Then add **Codex Weekly Limits** from Plasma's widget picker.

For development, run `make dev`. Build a shareable package with `make package`.

Scaffolded from [kde-6-widget-starter](https://github.com/ruinivist/kde-6-widget-starter).
