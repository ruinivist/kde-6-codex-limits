# Codex Limits

A small KDE Plasma 6 widget that shows Codex five-hour and weekly usage limits.

It reads the limits from the locally authenticated Codex CLI and refreshes every 30 seconds. There are no settings.

## Requirements

- KDE Plasma 6
- Python 3
- An installed and signed-in Codex CLI

## Use

```sh
make check
make install
```

Then add **Codex Limits** from Plasma's widget picker.

For development, run `make dev`. Build a shareable package with `make package`.

Scaffolded from [kde-6-widget-starter](https://github.com/ruinivist/kde-6-widget-starter).

OpenAI and ChatGPT are trademarks of OpenAI.
