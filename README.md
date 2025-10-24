# battinfo

A command-line tool to display detailed battery information, including health/degradation, status, and other relevant metrics.

## Features

*   Displays battery manufacturer, model, and technology.
*   Shows current charge capacity and status.
*   Calculates and displays battery degradation percentage.
*   Provides voltage, current, power, and temperature readings (if available).
*   Includes a simple ASCII art battery graph.
*   Uses color-coded output for better readability.

## Installation

To install `battinfo`:

1.  Clone the GitHub repository:
    ```bash
    git clone https://github.com/viztini/battinfo.git
    ```
2.  Change into the project directory:
    ```bash
    cd battinfo
    ```
3.  Run the installation script:
    ```bash
    ./install.sh
    ```

This script will:

1.  Copy the `battinfo` script to `~/.local/bin/`.
2.  Make the `battinfo` script executable.

## Usage

After installation, you can run `battinfo` from any terminal:

```bash
battinfo
```

## Customization

The script automatically detects the first available battery (e.g., BAT0, BAT1). If you have multiple batteries or a non-standard setup, you might need to adjust the `BATTERY_PATH` variable within the `battinfo` script.

## Contributing

Feel free to contribute to this project by submitting pull requests or opening issues.
