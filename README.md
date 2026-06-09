# UIUC Bus Plasmoid

A KDE Plasma desktop widget that displays live departures for [CUMTD](https://cumtd.com/) buses.

## Features

- **Live bus departures** — real-time arrival times pulled from the MTD API
- **Stop-specific** — configure any MTD stop ID to see its upcoming departures
- **Auto-refresh** — data refreshes automatically (configurable interval)
- **Data age indicator** — shows how recently the data was last updated
- **Color-coded route cards** — each bus route displayed in a Kirigami card with route number, destination, and countdown

## Requirements

- **KDE Plasma 6.0+**
- [MTD API key](https://mtd.dev/account/keys) — free registration required

## Installation

1. Download or clone this repository.
2. Copy the `ci.nw.plasmoids.uiucbus` directory to `~/.local/share/plasma/plasmoids/` (system-wide: `/usr/share/plasma/plasmoids/`).
3. Add the plasmoid to your Plasma desktop or dashboard via **Add Widgets → UIUC Bus**.
4. Right-click the widget → **Configure**, then enter:
   - **MTD Stop ID** — your desired stop code (e.g. `GWNMN`)
   - **MTD API Key** — from [mtd.dev/account/keys](https://mtd.dev/account/keys)

## Configuration

| Setting   | Description                | Example   |
|-----------|----------------------------|-----------|
| Stop ID   | MTD bus stop identifier    | `GWNMN`   |
| API Key   | Your personal MTD API key  | `abc123…` |

## How it works

1. The plasmoid queries the [mtd.dev](https://mtd.dev/) API for the configured stop's location details and live departures.
2. Results are rendered as scrollable Kirigami cards showing route number, name, destination (headsign), and expected arrival time.
3. A background timer auto-refreshes the data at a configurable interval.

## License

GPLv3

## Author

Nicholas Wang

## Bug Reports

[GitHub Issues](https://github.com/nicholascw/plasmoid-uiucbus/issues/new)
