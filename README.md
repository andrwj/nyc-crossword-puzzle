# NYC Crossword Puzzle

![Menu](https://raw.githubusercontent.com/andrwj/nyc-crossword-puzzle/refs/heads/main/demo.png)
The goal is to download the NYC crossword puzzle as a PDF and have it automatically installed on your own e-Ink device. Currently, you can only download specific dates. Setting a time period and getting them all at once is a future update.

To download puzzles, you need to sign up for the service: https://www.nytimes.com/crosswords

I can't guarantee that it will work 100% on Linux and Windows environments. My development environment is macOS version 15.1.


## Usage
* First of all, Install the required packages.
* And Sign-in NYC service in your browser. Currently this script assumes you're using Chrome.
* And then select `Open Browser to Copy NYC Cookie value` from this script menu.
* When browser launchs, open Developer Tools
* type 'document.cookie' in your JavaScript console, do right-click on its value and select `Copy string contents` menu.
* Select `NYC Cookie value` from this script menu
* Ok, you can now download `Today's Puzzle`
* If you want to receive puzzles for a specific day, select `Set Tdoay` from this script menu.
* Downloading all puzzles in a given period is not yet implemented.





