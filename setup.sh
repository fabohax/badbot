function check_installed_pip() {
   ${PYTHON} -m pip > /dev/null
   if [ $? -ne 0 ]; then
        echo "pip not found (called as '${PYTHON} -m pip'). Please make sure that pip is available for ${PYTHON}."
        exit 1
   fi
}

# Check which python version is installed
function check_installed_python() {
    if [ -n "${VIRTUAL_ENV}" ]; then
        echo "Please deactivate your virtual environment before running setup.sh."
        echo "You can do this by running 'deactivate'."
        exit 2
    fi

    which python3.8
    if [ $? -eq 0 ]; then
        echo "using Python 3.8"
        PYTHON=python3.8
        check_installed_pip
        return
    fi

    which python3.7
    if [ $? -eq 0 ]; then
        echo "using Python 3.7"
        PYTHON=python3.7
        check_installed_pip
        return
    fi

    which python3.6
    if [ $? -eq 0 ]; then
        echo "using Python 3.6"
        PYTHON=python3.6
        check_installed_pip
        return
   fi

   if [ -z ${PYTHON} ]; then
        echo "No usable python found. Please make sure to have python3.6 or python3.7 installed"
        exit 1
   fi
}

function updateenv() {
    echo "-------------------------"
    echo "Updating virtual environment"
    echo "-------------------------"
    if [ ! -f .env/bin/activate ]; then
        echo "Something went wrong, no virtual environment found."
        exit 1
    fi
    source .env/bin/activate
    echo "pip install in-progress. Please wait..."
    ${PYTHON} -m pip install --upgrade pip
    read -p "Do you want to install dependencies for dev [y/N]? "
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        ${PYTHON} -m pip install --upgrade -r requirements-dev.txt
    else
        ${PYTHON} -m pip install --upgrade -r requirements.txt
        echo "Dev dependencies ignored."
    fi

    ${PYTHON} -m pip install -e .
    echo "pip install completed"
    echo
}

# Install tab lib
function install_talib() {
    if [ -f /usr/local/lib/libta_lib.a ]; then
        echo "ta-lib already installed, skipping"
        return
    fi

    cd build_helpers
    tar zxvf ta-lib-0.4.0-src.tar.gz
    cd ta-lib
    sed -i.bak "s|0.00000001|0.000000000000000001 |g" src/ta_func/ta_utility.h
    ./configure --prefix=/usr/local
    make
    sudo make install
    if [ -x "$(command -v apt-get)" ]; then
        echo "Updating library path using ldconfig"
        sudo ldconfig
    fi
    cd .. && rm -rf ./ta-lib/
    cd ..
}

# Install bot Debian_ubuntu
function install_debian() {
    sudo apt-get update
    sudo apt-get install -y build-essential autoconf libtool pkg-config make wget git
    install_talib
}

# Upgrade the bot
function update() {
    git pull
    updateenv
}

# Reset Develop or Stable branch
function reset() {
    echo "----------------------------"
    echo "Reseting branch and virtual env"
    echo "----------------------------"

    if [ "1" == $(git branch -vv |grep -cE "\* develop|\* stable") ]
    then

        read -p "Reset git branch? (This will remove all changes you made!) [y/N]? "
        if [[ $REPLY =~ ^[Yy]$ ]]; then

            git fetch -a

            if [ "1" == $(git branch -vv |grep -c "* develop") ]
            then
                echo "- Hard resetting of 'develop' branch."
                git reset --hard origin/develop
            elif [ "1" == $(git branch -vv |grep -c "* stable") ]
            then
                echo "- Hard resetting of 'stable' branch."
                git reset --hard origin/stable
            fi
        fi
    else
        echo "Reset ignored because you are not on 'stable' or 'develop'."
    fi

    if [ -d ".env" ]; then
        echo "- Delete your previous virtual env"
        rm -rf .env
    fi
    echo
    ${PYTHON} -m venv .env
    if [ $? -ne 0 ]; then
        echo "Could not create virtual environment. Leaving now"
        exit 1
    fi
    updateenv
}

function config_generator() {

    echo "Starting to generate config.json"
    echo
    echo "Generating General configuration"
    echo "-------------------------"
    default_max_trades=3
    read -p "Max open trades: (Default: $default_max_trades) " max_trades
    max_trades=${max_trades:-$default_max_trades}

    default_stake_amount=0.05
    read -p "Stake amount: (Default: $default_stake_amount) " stake_amount
    stake_amount=${stake_amount:-$default_stake_amount}

    default_stake_currency="BTC"
    read -p "Stake currency: (Default: $default_stake_currency) " stake_currency
    stake_currency=${stake_currency:-$default_stake_currency}

    default_fiat_currency="USD"
    read -p "Fiat currency: (Default: $default_fiat_currency) " fiat_currency
    fiat_currency=${fiat_currency:-$default_fiat_currency}

    echo
    echo "Generating exchange config "
    echo "------------------------"
    read -p "Exchange API key: " api_key
    read -p "Exchange API Secret: " api_secret

    echo
    echo "Generating Telegram config"
    echo "-------------------------"
    read -p "Telegram Token: " token
    read -p "Telegram Chat_id: " chat_id

    sed -e "s/\"max_open_trades\": 3,/\"max_open_trades\": $max_trades,/g" \
        -e "s/\"stake_amount\": 0.05,/\"stake_amount\": $stake_amount,/g" \
        -e "s/\"stake_currency\": \"BTC\",/\"stake_currency\": \"$stake_currency\",/g" \
        -e "s/\"fiat_display_currency\": \"USD\",/\"fiat_display_currency\": \"$fiat_currency\",/g" \
        -e "s/\"your_exchange_key\"/\"$api_key\"/g" \
        -e "s/\"your_exchange_secret\"/\"$api_secret\"/g" \
        -e "s/\"your_telegram_token\"/\"$token\"/g" \
        -e "s/\"your_telegram_chat_id\"/\"$chat_id\"/g" \
        -e "s/\"dry_run\": false,/\"dry_run\": true,/g" config.json.example > config.json

}

function config() {

    echo "-------------------------"
    echo "Please use 'bitbot new-config -c config.json' to generate a new configuration file."
    echo "-------------------------"
}

function install() {
    echo "-------------------------"
    echo "Installing mandatory dependencies"
    echo "-------------------------"

    if [ "$(uname -s)" == "Darwin" ]
    then
        echo "macOS detected. Setup for this system in-progress"
        install_macos
    elif [ -x "$(command -v apt-get)" ]
    then
        echo "Debian/Ubuntu detected. Setup for this system in-progress"
        install_debian
    else
        echo "This script does not support your OS."
        echo "If you have Python3.6 or Python3.7, pip, virtualenv, ta-lib you can continue."
        echo "Wait 10 seconds to continue the next install steps or use ctrl+c to interrupt this shell."
        sleep 10
    fi
    echo
    reset
    config
    echo "-------------------------"
    echo "Run the bot!"
    echo "-------------------------"
    echo "You can now use the bot by executing 'source .env/bin/activate; bitbot <subcommand>'."
    echo "You can see the list of available bot subcommands by executing 'source .env/bin/activate; bitbot --help'."
    echo "You verify that bitbot is installed successfully by running 'source .env/bin/activate; bitbot --version'."
}


# Verify if 3.6 or 3.7 is installed
check_installed_python

case $* in
--install|-i)
install
;;
--config|-c)
config
;;
--update|-u)
update
;;
--reset|-r)
reset
;;
*)
help
;;
esac
exit 0
