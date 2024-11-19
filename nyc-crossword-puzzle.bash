#!/usr/bin/env bash
# @author A.J <andrwj@gmail.com>
# @date 2024-11-20
# @version 1.0.0

function clean_up {
  rc=${1:-0}

  dialog --clear
  trap - INT
  rm -f "$RC"

  echo
  echo "If your Ctrl-C doesn't work, run 'reset' command"
  echo
  exit 0
}

function open_folder_or_show_file_list {
  # open current folder if using macOS, otherwise list up contents.
  if [[ $is_macOS -eq 0 ]] && [[ $rc -eq 0 ]]; then
    open .
  else
    ls -la
  fi
}

function open_chrome_with_devtools {
  if [[ $is_macOS -eq 0 ]]; then
    open -a "Google Chrome" "$PDF_URL" --args --auto-open-devtools-for-tabs
  elif [[ $is_linux -eq 0 ]]; then
    gogole-chrome "$PDF_URL" --auto-open-devtools-for-tabs
  else
    start chrome "$PDF_URL" --auto-open-devtools-for-tabs
  fi
}

function install_necessary_packages_on_macOS {
  if [[ has_dialog -ne 0 ]]; then
    brew install dialog
  fi
  if [[ has_curl -ne 0 ]]; then
    brew install curl
  fi
}

function validate_requirements {
  if ! command -v dialog &>/dev/null; then
    echo "Error: could not found utility 'dialog'"
    echo "To install it, run the following:"
    echo "Ubuntu/Debian: sudo apt-get install dialog"
    echo "CentOS/RHEL: sudo yum install dialog"
    echo "macOS: brew install dialog"
    clean_up 1
  fi

  if ! command -v curl &>/dev/null; then
    echo "Error: could not found utility 'curl'"
    echo "To install it, run the following:"
    echo "Ubuntu/Debian: sudo apt-get install curl"
    echo "CentOS/RHEL: sudo yum install curl"
    echo "macOS: brew install curl"
    clean_up 1
  fi
}

function get_nyc_cookie_value {
  dialog --backtitle "$DIALOG_BACK_TITLE" --msgbox "Continue if you already copied Cookie value from Browser" 5 65
  "$COPY_CMD" | tr -d '\r' | tr -d '\n' >"$COOKIE_FILE"
  declare -i cookie_size
  cookie_size=$(wc -c <"$COOKIE_FILE" | tr -d ' ')
  if [[ "$cookie_size" -gt "2048" ]]; then
    dialog --backtitle "$DIALOG_BACK_TITLE" --msgbox "NYC COOKIE value has been set" 5 60
  else
    dialog --backtitle "$DIALOG_BACK_TITLE" --msgbox "Error: Invalid Cookie Value." 5 60
  fi
}

function get_puzzle_for_today {
  if [[ ! -e $COOKIE_FILE ]] || [[ -z $COOKIE_FILE ]]; then
    dialog --backtitle "$DIALOG_BACK_TITLE" --msgbox "Please set NYC COOKIE value first" 5 60
  else
    curl -s -L \
      -H "Referer: $REFERER_URL" \
      -H "Cookie: $(cat "$COOKIE_FILE")" \
      -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36" \
      --progress-bar \
      "$PDF_URL" \
      -o "$PDF_NAME"
    is_valid_type=$(
      file "$PDF_NAME" | grep 'PDF' >/dev/null
      echo $?
    )
    if [ "$is_valid_type" -ne 0 ]; then
      dialog --backtitle "$DIALOG_BACK_TITLE" --msgbox "Error: Invalid Document Type" 5 60
    else
      open_folder_or_show_file_list
    fi
  fi
}

function get_month_abbr {
  local month=${1}
  local Months=()
  Months+=("" "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
  echo -n "${Months[$month]}"
}

function set_today {
  current_day=$(date +%-d)   # 날짜 (1-31)
  current_month=$(date +%-m) # 월 (1-12)
  current_year=$(date +%Y)   # 년도 (4자리)

  today=$(LC_TIME=en_US.UTF-8 dialog --stdout --calendar "Select Date:" 0 0 $current_day $current_month $current_year)
  if [[ $? -eq 0 ]]; then
    day="${today%%/*}"
    temp="${today#*/}"
    month="${temp%%/*}"
    year="${today##*/}"
    short_year=${year:2}
    month_abbr=$(get_month_abbr "$month")
    today="${month_abbr}.${day}, ${year}"

    TODAY="${year}/${month}/${day}"
    PDF_NAME="${month_abbr}${day}${short_year}.pdf" # i.e: Nov1924
    REFERER_URL="${BASE_URL}/crosswords/game/daily/$TODAY"
    PDF_URL="${BASE_URL}/svc/crosswords/v2/puzzle/print/${PDF_NAME}"

    dialog --backtitle "$DIALOG_BACK_TITLE" --msgbox "You've set today's date to ${month_abbr}.$day ${year}" 5 50
  fi
}

# end of define functions
############################################################################

declare -i is_macOS
is_macOS=$(
  uname -s | grep 'Darwin' >/dev/null
  echo $?
)
declare -i is_linux
is_linux=$(
  uname -s | grep 'Linux' >/dev/null
  echo $?
)
declare -i has_dialog
has_dialog=$(
  command -v dialog &>/dev/null
  echo $?
)
declare -i has_curl
has_curl=$(
  command -v curl &>/dev/null
  echo $?
)
declare -s today
today=$(LC_TIME=en_US.UTF-8 date +"%b.%d, %Y")

if [[ "$is_macOS" -eq "0" ]]; then
  COPY_CMD="pbpaste"
else
  COPY_CMD="xclip -o"
fi

# temporary file to hold return code
RC="/tmp/rc.$$"
COOKIE_FILE="${HOME}/.nyc-cookie"

# set handler for signals
trap clean_up SIGHUP SIGINT SIGTERM

TODAY=$(LC_TIME=en_US.UTF-8 date +"%Y/%m/%d")
PDF_NAME="$(LC_TIME=en_US.UTF-8 date +'%b%d%y').pdf" # i.e: Nov1924
BASE_URL="https://www.nytimes.com"
REFERER_URL="${BASE_URL}/crosswords/game/daily/$TODAY"
PDF_URL="${BASE_URL}/svc/crosswords/v2/puzzle/print/${PDF_NAME}"
DIALOG_BACK_TITLE="7NYT Crossword Puzzle Downloader"

############################################################################
# START HERE
############################################################################

# check 'dialog', 'curl' utility is available or die.
validate_requirements

function main {
  while true; do
    cookie_status=$(if [[ -e "${COOKIE_FILE}" ]]; then echo "(ok)"; else echo "(N/A)"; fi)
    package_status=$(if [[ $has_dialog -eq 0 ]] && [[ $has_curl -eq 0 ]]; then echo "(ok)"; else echo "(missing)"; fi)
    command=()
    command+=("0" "Quit")
    command+=("1" "Install necessary packages $package_status")
    command+=("2" "Open Browser to Copy NYC Cookie value")
    command+=("3" "Set NYC Cookie value $cookie_status")
    command+=("4" "Clear NYC Cookie")
    command+=("5" "Download Today's Puzzle")
    command+=("6" "Download All Puzzles of This Month")
    command+=("7" "Download Puzzles within period")
    command+=("8" "Set Today (${today})")
    command+=("9" "Set Start Date of Period")
    command+=("10" "Set End Date of Period")
    command+=("11" "Open current folder")

    selected_cmd=$(dialog --backtitle "$DIALOG_BACK_TITLE" --no-cancel --stdout --title "Download NYT Crossword Puzzle" --menu "Choose a command to perform action on:" 20 80 5 "${command[@]}")
    exit_status=$?

    if [ $exit_status -eq 0 ]; then
      case $selected_cmd in
      0)
        clean_up
        ;;
      1)
        os=$(uname -s)
        has_dialog=$(
          command -v dialog &>/dev/null
          echo $?
        )
        has_curl=$(
          command -v curl &>/dev/null
          echo $?
        )
        if [[ has_dialog -eq 0 ]] && [[ has_curl -eq 0 ]]; then
          dialog --backtitle "$DIALOG_BACK_TITLE" --msgbox "You have all the necessary packages installed." 5 60
          if [[ "$os" == "Darwin" ]]; then
            install_necessary_packages_on_macOS
          else
            dialog --backtitle "$DIALOG_BACK_TITLE" --msgbox "Not implemented yet" 5 60
          fi
        fi
        ;;
      2)
        dialog --backtitle "$DIALOG_BACK_TITLE" --msgbox "When your browser launches, open Developer Tools.\n\nIn the JavaScript Console tab, type 'document.cookie' and press Enter to display the cookie value.\n\n
Right-click on the value and select 'copy string contents'" 10 70
        open_chrome_with_devtools
        ;;
      3)
        get_nyc_cookie_value
        ;;
      4)
        export NYC_COOKIE=''
        rm -f "$COOKIE_FILE"
        ;;
      5)
        get_puzzle_for_today
        ;;
      8)
        set_today
        ;;
      11)
        open_folder_or_show_file_list
        ;;
      *)
        dialog --backtitle "$DIALOG_BACK_TITLE" --msgbox "Not implemented yet" 5 60
        ;;
      esac
    fi
  done
}

main

clean_up
