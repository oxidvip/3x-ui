#!/bin/bash

red='\033[0;31m'
green='\033[0;36m'
yellow='\033[0;33m'
plain='\033[0m'

#Add some basic function here
function LOGD() {
    echo -e "${yellow}[DEG] $* ${plain}"
}

function LOGE() {
    echo -e "${red}[ERR] $* ${plain}"
}

function LOGI() {
    echo -e "${green}[INF] $* ${plain}"
}

# check root
[[ $EUID -ne 0 ]] && LOGE "ERROR: You must be root to run this script! \n" && exit 1

# Check OS and set release variable
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "Failed to check the system OS, please contact the author!" >&2
    exit 1
fi

echo "The OS release is: $release"

os_version=""
os_version=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)

if [[ "${release}" == "arch" ]]; then
    echo "Your OS is Arch Linux"
elif [[ "${release}" == "parch" ]]; then
    echo "Your OS is Parch linux"
elif [[ "${release}" == "manjaro" ]]; then
    echo "Your OS is Manjaro"
elif [[ "${release}" == "armbian" ]]; then
    echo "Your OS is Armbian"
elif [[ "${release}" == "opensuse-tumbleweed" ]]; then
    echo "Your OS is OpenSUSE Tumbleweed"
elif [[ "${release}" == "centos" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} Please use CentOS 8 or higher ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "ubuntu" ]]; then
    if [[ ${os_version} -lt 20 ]]; then
        echo -e "${red} Please use Ubuntu 20 or higher version!${plain}\n" && exit 1
    fi
elif [[ "${release}" == "fedora" ]]; then
    if [[ ${os_version} -lt 36 ]]; then
        echo -e "${red} Please use Fedora 36 or higher version!${plain}\n" && exit 1
    fi
elif [[ "${release}" == "debian" ]]; then
    if [[ ${os_version} -lt 11 ]]; then
        echo -e "${red} Please use Debian 11 or higher ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "almalinux" ]]; then
    if [[ ${os_version} -lt 9 ]]; then
        echo -e "${red} Please use AlmaLinux 9 or higher ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "rocky" ]]; then
    if [[ ${os_version} -lt 9 ]]; then
        echo -e "${red} Please use Rocky Linux 9 or higher ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "oracle" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} Please use Oracle Linux 8 or higher ${plain}\n" && exit 1
    fi
else
    echo -e "${red}Your operating system is not supported by this script.${plain}\n"
    echo "Please ensure you are using one of the following supported operating systems:"
    echo "- Ubuntu 20.04+"
    echo "- Debian 11+"
    echo "- CentOS 8+"
    echo "- Fedora 36+"
    echo "- Arch Linux"
    echo "- Parch Linux"
    echo "- Manjaro"
    echo "- Armbian"
    echo "- AlmaLinux 9+"
    echo "- Rocky Linux 9+"
    echo "- Oracle Linux 8+"
    echo "- OpenSUSE Tumbleweed"
    exit 1

fi

# Declare Variables
log_folder="${XUI_LOG_FOLDER:=/var/log}"
iplimit_log_path="${log_folder}/3xipl.log"
iplimit_banned_log_path="${log_folder}/3xipl-banned.log"
iplimit_directory="/etc/fail2ban"

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [Default $2]: " temp
        if [[ "${temp}" == "" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ "${temp}" == "y" || "${temp}" == "Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Restart the panel, Attention: Restarting the panel will also restart xray" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Press enter to return to the main menu: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/oxidvip/3x-ui/main/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    confirm "This function will forcefully reinstall the latest version, and the data will not be lost. Do you want to continue?" "y"
    if [[ $? != 0 ]]; then
        LOGE "Cancelled"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/oxidvip/3x-ui/main/install.sh)
    if [[ $? == 0 ]]; then
        LOGI "Update is complete, Panel has automatically restarted "
        exit 0
    fi
}

update_menu() {
    echo -e "${yellow}Updating Menu${plain}"
    confirm "This function will update the menu to the latest changes." "y"
    if [[ $? != 0 ]]; then
        LOGE "Cancelled"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/oxidvip/3x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    
    if [[ $? == 0 ]]; then
        echo -e "${green}Update successful. The panel has automatically restarted.${plain}"
        exit 0
    else
        echo -e "${red}Failed to update the menu.${plain}"
        return 1
    fi
}

# Function to handle the deletion of the script file
delete_script() {
    rm "$0" # Remove the script file itself
    exit 1
}

uninstall() {
    confirm "Are you sure you want to uninstall the panel? xray will also uninstalled!" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    
    if [ -d "$iplimit_directory" ]; then
    confirm "Fail2ban installed, Are you sure about remove it?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
        systemctl stop fail2ban
        systemctl disable fail2ban
        rm -rf /etc/fail2ban
        case "${release}" in
        ubuntu | debian | armbian)
            apt-get remove -y fail2ban
            apt-get purge -y fail2ban -y
            apt-get autoremove -y
            ;;
        centos | almalinux | rocky | oracle)
            yum remove fail2ban -y
            yum autoremove -y
            ;;
        fedora)
            dnf remove fail2ban -y
            dnf autoremove -y
            ;;
        arch | manjaro | parch)
            pacman -Rns --noconfirm fail2ban
            ;;
        esac
        systemctl daemon-reload
        systemctl stop x-ui
        systemctl disable x-ui
        rm /etc/systemd/system/x-ui.service -f
        systemctl daemon-reload
        systemctl reset-failed
        rm /etc/x-ui/ -rf
        rm /usr/local/x-ui/ -rf
    else
    if [ ! -d "$iplimit_directory" ]; then
        systemctl stop x-ui
        systemctl disable x-ui
        rm /etc/systemd/system/x-ui.service -f
        systemctl daemon-reload
        systemctl reset-failed
        rm /etc/x-ui/ -rf
        rm /usr/local/x-ui/ -rf
    fi
    fi
    
    echo ""
    echo -e "Uninstalled Successfully.\n"
    echo "If you need to install this panel again, you can use below command:"
    echo -e "${green}bash <(curl -Ls https://raw.githubusercontent.com/oxidvip/3x-ui/master/install.sh)${plain}"
    echo ""
    # Trap the SIGTERM signal
    trap delete_script SIGTERM
    delete_script
}

reset_user() {
    confirm "Are you sure to reset the username and password of the panel?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    read -rp "Please set the login username [default is a random username]: " config_account
    [[ -z $config_account ]] && config_account=$(date +%s%N | md5sum | cut -c 1-8)
    read -rp "Please set the login password [default is a random password]: " config_password
    [[ -z $config_password ]] && config_password=$(date +%s%N | md5sum | cut -c 1-8)
    /usr/local/x-ui/x-ui setting -username ${config_account} -password ${config_password} >/dev/null 2>&1
    /usr/local/x-ui/x-ui setting -remove_secret >/dev/null 2>&1
    echo -e "Panel login username has been reset to: ${green} ${config_account} ${plain}"
    echo -e "Panel login password has been reset to: ${green} ${config_password} ${plain}"
    echo -e "${yellow} Panel login secret token disabled ${plain}"
    echo -e "${green} Please use the new login username and password to access the X-UI panel. Also remember them! ${plain}"
    confirm_restart
}

gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
    echo "$random_string"
}

reset_webbasepath() {
    echo -e "${yellow}Resetting Web Base Path${plain}"
    
    read -rp "Are you sure you want to reset the web base path? (y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "${yellow}Operation canceled.${plain}"
        return
    fi

    config_webBasePath=$(gen_random_string 10)
    
    # Apply the new web base path setting
    /usr/local/x-ui/x-ui setting -webBasePath "${config_webBasePath}" >/dev/null 2>&1
    
    echo -e "Web base path has been reset to: ${green}${config_webBasePath}${plain}"
    echo -e "${green}Please use the new web base path to access the panel.${plain}"
    restart
}

reset_config() {
    confirm "Are you sure you want to reset all panel settings, Account data will not be lost, Username and password will not change" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -reset
    echo -e "All panel settings have been reset to default, Please restart the panel now, and use the default ${green}2053${plain} Port to Access the web Panel"
    confirm_restart
}

check_config() {
    local info=$(/usr/local/x-ui/x-ui setting -show true)
    if [[ $? != 0 ]]; then
        LOGE "get current settings error, please check logs"
        show_menu
        return
    fi
    LOGI "${info}"

    local existing_webBasePath=$(echo "$info" | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(echo "$info" | grep -Eo 'port: .+' | awk '{print $2}')
}

set_port() {
    echo && echo -n -e "Enter port number[1-65535]: " && read port
    if [[ -z "${port}" ]]; then
        LOGD "Cancelled"
        before_show_menu
    else
        /usr/local/x-ui/x-ui setting -port ${port}
        echo -e "The port is set, Please restart the panel now, and use the new port ${green}${port}${plain} to access web panel"
        confirm_restart
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        LOGI "Panel is running, No need to start again, If you need to restart, please select restart"
    else
        systemctl start x-ui
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            LOGI "x-ui Started Successfully"
        else
            LOGE "panel Failed to start, Probably because it takes longer than two seconds to start, Please check the log information later"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        LOGI "Panel stopped, No need to stop again!"
    else
        systemctl stop x-ui
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            LOGI "x-ui and xray stopped successfully"
        else
            LOGE "Panel stop failed, Probably because the stop time exceeds two seconds, Please check the log information later"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart x-ui
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        LOGI "x-ui and xray Restarted successfully"
    else
        LOGE "Panel restart failed, Probably because it takes longer than two seconds to start, Please check the log information later"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status x-ui -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable x-ui
    if [[ $? == 0 ]]; then
        LOGI "x-ui Set to boot automatically on startup successfully"
    else
        LOGE "x-ui Failed to set Autostart"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable x-ui
    if [[ $? == 0 ]]; then
        LOGI "x-ui Autostart Cancelled successfully"
    else
        LOGE "x-ui Failed to cancel autostart"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    echo -e "${green}\t1.${plain} Debug Logs"
    echo -e "${green}\t2.${plain} Clear All logs"
    echo -e "${green}\t0.${plain} Back to Main Menu"
    read -p "Choose an option: " choice
    case "$choice" in
    0)
        return
        ;;
    1)
        journalctl -u x-ui -e --no-pager -f -p debug
        if [[ $# == 0 ]]; then
        before_show_menu
        fi
        ;;
    2)
        sudo journalctl --rotate
        sudo journalctl --vacuum-time=1s
        echo "All Logs cleared."
        restart
        ;;
    *)
        echo "Invalid choice"
        ;;
    esac
}

show_banlog() {
    local system_log="/var/log/fail2ban.log"
    
    echo -e "${green}Checking ban logs...${plain}\n"
    
    if ! systemctl is-active --quiet fail2ban; then
        echo -e "${red}Fail2ban service is not running!${plain}\n"
        return 1
    fi
    if [[ -f "$system_log" ]]; then
        echo -e "${green}Recent system ban activities from fail2ban.log:${plain}"
        grep "3x-ipl" "$system_log" | grep -E "Ban|Unban" | tail -n 10 || echo -e "${yellow}No recent system ban activities found${plain}"
        echo ""
    fi
    if [[ -f "${iplimit_banned_log_path}" ]]; then
        echo -e "${green}3X-IPL ban log entries:${plain}"
        if [[ -s "${iplimit_banned_log_path}" ]]; then
            grep -v "INIT" "${iplimit_banned_log_path}" | tail -n 10 || echo -e "${yellow}No ban entries found${plain}"
        else
            echo -e "${yellow}Ban log file is empty${plain}"
        fi
    else
        echo -e "${red}Ban log file not found at: ${iplimit_banned_log_path}${plain}"
    fi

    echo -e "\n${green}Current jail status:${plain}"
    fail2ban-client status 3x-ipl || echo -e "${yellow}Unable to get jail status${plain}"
}

update_shell() {
    wget -O /usr/bin/x-ui -N --no-check-certificate https://github.com/oxidvip/3x-ui/raw/main/x-ui.sh
    if [[ $? != 0 ]]; then
        echo ""
        LOGE "Failed to download script, Please check whether the machine can connect Github"
        before_show_menu
    else
        chmod +x /usr/bin/x-ui
        LOGI "Upgrade script succeeded, Please rerun the script" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/x-ui.service ]]; then
        return 2
    fi
    temp=$(systemctl status x-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ "${temp}" == "running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled x-ui)
    if [[ "${temp}" == "enabled" ]]; then
        return 0
    else
        return 1
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        LOGE "Panel installed, Please do not reinstall"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        LOGE "Please install the panel first"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
    0)
        echo -e "Panel state: ${green}Running${plain}"
        show_enable_status
        ;;
    1)
        echo -e "Panel state: ${yellow}Not Running${plain}"
        show_enable_status
        ;;
    2)
        echo -e "Panel state: ${red}Not Installed${plain}"
        ;;
    esac
    show_xray_status
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Start automatically: ${green}Yes${plain}"
    else
        echo -e "Start automatically: ${red}No${plain}"
    fi
}

check_xray_status() {
    count=$(ps -ef | grep "xray-linux" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

show_xray_status() {
    check_xray_status
    if [[ $? == 0 ]]; then
        echo -e "xray state: ${green}Running${plain}"
    else
        echo -e "xray state: ${red}Not Running${plain}"
    fi
}

install_acme() {
    # Check if acme.sh is already installed
    if command -v ~/.acme.sh/acme.sh &>/dev/null; then
        LOGI "acme.sh is already installed."
        return 0
    fi
    LOGI "Installing acme.sh..."
    cd ~ || return 1 # Ensure you can change to the home directory
    curl -s https://get.acme.sh | sh
    if [ $? -ne 0 ]; then
        LOGE "Installation of acme.sh failed."
        return 1
    else
        LOGI "Installation of acme.sh succeeded."
    fi
    
    return 0
}

ssl_cert_issue_main() {
    echo -e "${green}\t1.${plain} Get SSL (Port:80)"
    echo -e "${green}\t2.${plain} Revoke"
    echo -e "${green}\t3.${plain} Force Renew"
    echo -e "${green}\t4.${plain} Show Existing Domains"
    echo -e "${green}\t5.${plain} Set Cert paths for the panel"
    echo -e "${green}\t0.${plain} Back to Main Menu"
    
    read -p "Choose an option: " choice
    case "$choice" in
    0)
        show_menu
        ;;
    1)
        ssl_cert_issue
        ssl_cert_issue_main
        ;;
    2)
        # Auto-detect existing domains for revoking
        local domains=$(find /root/cert/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
        if [ -z "$domains" ]; then
            echo "No certificates found to revoke."
        else
            echo "Existing domains:"
            echo "$domains"
            read -p "Please enter a domain from the list to revoke the certificate: " domain
            if echo "$domains" | grep -qw "$domain"; then
                ~/.acme.sh/acme.sh --revoke -d ${domain}
                LOGI "Certificate revoked for domain: $domain"
            else
                echo "Invalid domain entered."
            fi
        fi
        ssl_cert_issue_main
        ;;
    3)
        # Auto-detect existing domains for force renewal
        local domains=$(find /root/cert/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
        if [ -z "$domains" ]; then
            echo "No certificates found to renew."
        else
            echo "Existing domains:"
            echo "$domains"
            read -p "Please enter a domain from the list to renew the SSL certificate: " domain
            if echo "$domains" | grep -qw "$domain"; then
                ~/.acme.sh/acme.sh --renew -d ${domain} --force
                LOGI "Certificate forcefully renewed for domain: $domain"
            else
                echo "Invalid domain entered."
            fi
        fi
        ssl_cert_issue_main
        ;;
    4)
        # Show existing certificate paths for all domains
        local domains=$(find /root/cert/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
        if [ -z "$domains" ]; then
            echo "No certificates found."
        else
            echo "Existing domains and their paths:"
            for domain in $domains; do
                local cert_path="/root/cert/${domain}/fullchain.pem"
                local key_path="/root/cert/${domain}/privkey.pem"
                if [[ -f "${cert_path}" && -f "${key_path}" ]]; then
                    echo -e "Domain: ${domain}"
                    echo -e "\tCertificate Path: ${cert_path}"
                    echo -e "\tPrivate Key Path: ${key_path}"
                else
                    echo -e "Domain: ${domain} - Certificate or Key missing."
                fi
            done
        fi
        ssl_cert_issue_main
        ;;
    5)
        # Set Cert paths for the panel
        local domains=$(find /root/cert/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
        if [ -z "$domains" ]; then
            echo "No certificates found."
        else
            echo "Available domains:"
            echo "$domains"
            read -p "Please choose a domain to set the panel paths: " domain
            
            if echo "$domains" | grep -qw "$domain"; then
                local webCertFile="/root/cert/${domain}/fullchain.pem"
                local webKeyFile="/root/cert/${domain}/privkey.pem"
                
                if [[ -f "${webCertFile}" && -f "${webKeyFile}" ]]; then
                    /usr/local/x-ui/x-ui cert -webCert "$webCertFile"
                    /usr/local/x-ui/x-ui cert -webCertKey "$webKeyFile"
                    echo "Panel paths set for domain: $domain"
                    echo "  - Certificate File: $webCertFile"
                    echo "  - Private Key File: $webKeyFile"
                    restart
                else
                    echo "Certificate or private key not found for domain: $domain."
                fi
            else
                echo "Invalid domain entered."
            fi
        fi
        ssl_cert_issue_main
        ;;
        
    *)
        echo "Invalid choice"
        ;;
    esac
}

ssl_cert_issue() {
    # check for acme.sh first
    if ! command -v ~/.acme.sh/acme.sh &>/dev/null; then
        echo "acme.sh could not be found. we will install it"
        install_acme
        if [ $? -ne 0 ]; then
            LOGE "install acme failed, please check logs"
            exit 1
        fi
    fi
    
    # install socat second
    case "${release}" in
    ubuntu | debian | armbian)
        apt update && apt install socat -y
        ;;
    centos | almalinux | rocky | oracle)
        yum -y update && yum -y install socat
        ;;
    fedora)
        dnf -y update && dnf -y install socat
        ;;
    arch | manjaro | parch)
        pacman -Sy --noconfirm socat
        ;;
    *)
        echo -e "${red}Unsupported operating system. Please check the script and install the necessary packages manually.${plain}\n"
        exit 1
        ;;
    esac
    if [ $? -ne 0 ]; then
        LOGE "install socat failed, please check logs"
        exit 1
    else
        LOGI "install socat succeed..."
    fi

    # get the domain here, and we need to verify it
    local domain=""
    read -p "Please enter your domain name: " domain
    LOGD "Your domain is: ${domain}, checking it..."

    # check if there already exists a certificate
    local currentCert=$(~/.acme.sh/acme.sh --list | tail -1 | awk '{print $1}')
    if [ "${currentCert}" == "${domain}" ]; then
        local certInfo=$(~/.acme.sh/acme.sh --list)
        LOGE "System already has certificates for this domain, Can not issue again. Current certificate details:"
        LOGI "$certInfo"
        exit 1
    else
        LOGI "Your domain is ready for issuing certificates now..."
    fi

    # create a directory for the certificate
    certPath="/root/cert/${domain}"
    if [ ! -d "$certPath" ]; then
        mkdir -p "$certPath"
    else
        rm -rf "$certPath"
        mkdir -p "$certPath"
    fi
    
    # issue the certificate
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    ~/.acme.sh/acme.sh --issue -d ${domain} --listen-v6 --standalone --httpport 80
    if [ $? -ne 0 ]; then
        LOGE "Issuing certificate failed, please check logs."
        rm -rf ~/.acme.sh/${domain}
        exit 1
    else
        LOGE "Issuing certificate succeeded, installing certificates..."
    fi
    
    # install the certificate
    ~/.acme.sh/acme.sh --installcert -d ${domain} \
        --key-file /root/cert/${domain}/privkey.pem \
        --fullchain-file /root/cert/${domain}/fullchain.pem

    if [ $? -ne 0 ]; then
        LOGE "Installing certificate failed, exiting."
        rm -rf ~/.acme.sh/${domain}
        exit 1
    else
        LOGI "Installing certificate succeeded, enabling auto renew..."
    fi

    # enable auto-renew
    ~/.acme.sh/acme.sh --upgrade --auto-upgrade
    if [ $? -ne 0 ]; then
        LOGE "Auto renew failed, certificate details:"
        ls -lah cert/*
        chmod 755 $certPath/*
        exit 1
    else
        LOGI "Auto renew succeeded, certificate details:"
        ls -lah cert/*
        chmod 755 $certPath/*
    fi

    # Prompt user to set panel paths after successful certificate installation
    read -p "Would you like to set this certificate for the panel? (y/n): " setPanel
    if [[ "$setPanel" == "y" || "$setPanel" == "Y" ]]; then
        local webCertFile="/root/cert/${domain}/fullchain.pem"
        local webKeyFile="/root/cert/${domain}/privkey.pem"
        
        if [[ -f "$webCertFile" && -f "$webKeyFile" ]]; then
            /usr/local/x-ui/x-ui cert -webCert "$webCertFile"
            /usr/local/x-ui/x-ui cert -webCertKey "$webKeyFile"
            LOGI "Panel paths set for domain: $domain"
            LOGI "  - Certificate File: $webCertFile"
            LOGI "  - Private Key File: $webKeyFile"
            restart
        else
            LOGE "Error: Certificate or private key file not found for domain: $domain."
        fi
    else
        LOGI "Skipping panel path setting."
    fi
}

create_iplimit_jails() {
    # Use default bantime if not passed => 15 minutes
    local bantime="${1:-15}"

    # Uncomment 'allowipv6 = auto' in fail2ban.conf
    sed -i 's/#allowipv6 = auto/allowipv6 = auto/g' /etc/fail2ban/fail2ban.conf

    # On Debian 12+ fail2ban's default backend should be changed to systemd
    if [[  "${release}" == "debian" && ${os_version} -ge 12 ]]; then
        sed -i '0,/action =/s/backend = auto/backend = systemd/' /etc/fail2ban/jail.conf
    fi

    cat << EOF > /etc/fail2ban/jail.d/3x-ipl.conf
[3x-ipl]
enabled=true
backend=auto
filter=3x-ipl
action = %(known/action)s[name=%(__name__)s, protocol="%(protocol)s", chain="%(chain)s"]
logpath=${iplimit_log_path}
maxretry=2
findtime=32
bantime=${bantime}m
EOF

    cat << EOF > /etc/fail2ban/filter.d/3x-ipl.conf
[Definition]
datepattern = ^%%Y/%%m/%%d %%H:%%M:%%S
failregex   = \[LIMIT_IP\]\s*Email\s*=\s*<F-USER>.+</F-USER>\s*\|\|\s*SRC\s*=\s*<ADDR>
ignoreregex =
EOF

    cat << EOF > /etc/fail2ban/action.d/3x-ipl.conf
[INCLUDES]
before = iptables-common.conf

[Definition]
actionstart = <iptables> -N f2b-<name>
              <iptables> -A f2b-<name> -j <returntype>
              <iptables> -I <chain> -p <protocol> -j f2b-<name>

actionstop = <iptables> -D <chain> -p <protocol> -j f2b-<name>
             <actionflush>
             <iptables> -X f2b-<name>

actioncheck = <iptables> -n -L <chain> | grep -q 'f2b-<name>[ \t]'

actionban = <iptables> -I f2b-<name> 1 -s <ip> -j <blocktype>
            echo "\$(date +"%%Y/%%m/%%d %%H:%%M:%%S")   BAN   [Email] = <F-USER> [IP] = <ip> banned for <bantime> seconds." >> ${iplimit_banned_log_path}

actionunban = <iptables> -D f2b-<name> -s <ip> -j <blocktype>
              echo "\$(date +"%%Y/%%m/%%d %%H:%%M:%%S")   UNBAN   [Email] = <F-USER> [IP] = <ip> unbanned." >> ${iplimit_banned_log_path}

[Init]
# Use default settings from iptables-common.conf
# This will automatically handle both IPv4 and IPv6
name = default
protocol = tcp
chain = INPUT
EOF

    echo -e "${green}Ip Limit jail files created with a bantime of ${bantime} minutes.${plain}"
}

iplimit_remove_conflicts() {
    local jail_files=(
        /etc/fail2ban/jail.conf
        /etc/fail2ban/jail.local
    )

    for file in "${jail_files[@]}"; do
        # Check for [3x-ipl] config in jail file then remove it
        if test -f "${file}" && grep -qw '3x-ipl' ${file}; then
            sed -i "/\[3x-ipl\]/,/^$/d" ${file}
            echo -e "${yellow}Removing conflicts of [3x-ipl] in jail (${file})!${plain}\n"
        fi
    done
}

iplimit_main() {
    echo -e "\n${green}\t1.${plain} Install Fail2ban and configure IP Limit"
    echo -e "${green}\t2.${plain} Change Ban Duration"
    echo -e "${green}\t3.${plain} Unban Everyone"
    echo -e "${green}\t4.${plain} Ban Logs"
    echo -e "${green}\t5.${plain} Real-Time Logs"
    echo -e "${green}\t6.${plain} Service Status"
    echo -e "${green}\t7.${plain} Service Restart"
    echo -e "${green}\t8.${plain} Uninstall Fail2ban and IP Limit"
    echo -e "${green}\t0.${plain} Back to Main Menu"
    read -p "Choose an option: " choice
    case "$choice" in
    0)
        show_menu
        ;;
    1)
        confirm "Proceed with installation of Fail2ban & IP Limit?" "y"
        if [[ $? == 0 ]]; then
            install_iplimit
        else
            iplimit_main
        fi
        ;;
    2)
        read -rp "Please enter new Ban Duration in Minutes [default 30]: " NUM
        if [[ $NUM =~ ^[0-9]+$ ]]; then
            create_iplimit_jails ${NUM}
            systemctl restart fail2ban
        else
            echo -e "${red}${NUM} is not a number! Please, try again.${plain}"
        fi
        iplimit_main
        ;;
    3)
        confirm "Proceed with Unbanning everyone from IP Limit jail?" "y"
        if [[ $? == 0 ]]; then
            fail2ban-client reload --restart --unban 3x-ipl
            truncate -s 0 "${iplimit_banned_log_path}"
            echo -e "${green}All users Unbanned successfully.${plain}"
            iplimit_main
        else
            echo -e "${yellow}Cancelled.${plain}"
        fi
        iplimit_main
        ;;
    4)
        show_banlog
        iplimit_main
        ;;
    5)
        tail -f /var/log/fail2ban.log
        iplimit_main
        ;;
    6)
        service fail2ban status
        iplimit_main
        ;;
    7)
        systemctl restart fail2ban
        iplimit_main
        ;;
    8)
        remove_iplimit
        iplimit_main
        ;;
    *) echo "Invalid choice" ;;
    esac
}

install_iplimit() {
    if ! command -v fail2ban-client &>/dev/null; then
        echo -e "${green}Fail2ban is not installed. Installing now...!${plain}\n"

        # Check the OS and install necessary packages
        case "${release}" in
        ubuntu)
            if [[ "${os_version}" -ge 24 ]]; then
                apt update && apt install python3-pip -y
                python3 -m pip install pyasynchat --break-system-packages
            fi
            apt update && apt install fail2ban -y
            ;;
        debian | armbian)
            apt update && apt install fail2ban -y
            ;;
        centos | almalinux | rocky | oracle)
            yum update -y && yum install epel-release -y
            yum -y install fail2ban
            ;;
        fedora)
            dnf -y update && dnf -y install fail2ban
            ;;
        arch | manjaro | parch)
            pacman -Syu --noconfirm fail2ban
            ;;
        *)
            echo -e "${red}Unsupported operating system. Please check the script and install the necessary packages manually.${plain}\n"
            exit 1
            ;;
        esac

        if ! command -v fail2ban-client &>/dev/null; then
            echo -e "${red}Fail2ban installation failed.${plain}\n"
            exit 1
        fi

        echo -e "${green}Fail2ban installed successfully!${plain}\n"
    else
        echo -e "${yellow}Fail2ban is already installed.${plain}\n"
    fi

    echo -e "${green}Configuring IP Limit...${plain}\n"

    # make sure there's no conflict for jail files
    iplimit_remove_conflicts

    # Check if log file exists
    if ! test -f "${iplimit_banned_log_path}"; then
        touch ${iplimit_banned_log_path}
    fi

    # Check if service log file exists so fail2ban won't return error
    if ! test -f "${iplimit_log_path}"; then
        touch ${iplimit_log_path}
    fi

    # Create the iplimit jail files
    # we didn't pass the bantime here to use the default value
    create_iplimit_jails

    # Launching fail2ban
    if ! systemctl is-active --quiet fail2ban; then
        systemctl start fail2ban
        systemctl enable fail2ban
    else
        systemctl restart fail2ban
    fi
    systemctl enable fail2ban

    echo -e "${green}IP Limit installed and configured successfully!${plain}\n"
    before_show_menu
}

remove_iplimit() {
    echo -e "${green}\t1.${plain} Only remove IP Limit configurations"
    echo -e "${green}\t2.${plain} Uninstall Fail2ban and IP Limit"
    echo -e "${green}\t0.${plain} Abort"
    read -p "Choose an option: " num
    case "$num" in
    1)
        rm -f /etc/fail2ban/filter.d/3x-ipl.conf
        rm -f /etc/fail2ban/action.d/3x-ipl.conf
        rm -f /etc/fail2ban/jail.d/3x-ipl.conf
        systemctl restart fail2ban
        echo -e "${green}IP Limit removed successfully!${plain}\n"
        before_show_menu
        ;;
    2)
        rm -rf /etc/fail2ban
        systemctl stop fail2ban
        systemctl disable fail2ban
        case "${release}" in
        ubuntu | debian | armbian)
            apt-get remove -y fail2ban
            apt-get purge -y fail2ban -y
            apt-get autoremove -y
            ;;
        centos | almalinux | rocky | oracle)
            yum remove fail2ban -y
            yum autoremove -y
            ;;
        fedora)
            dnf remove fail2ban -y
            dnf autoremove -y
            ;;
        arch | manjaro | parch)
            pacman -Rns --noconfirm fail2ban
            ;;
        *)
            echo -e "${red}Unsupported operating system. Please uninstall Fail2ban manually.${plain}\n"
            exit 1
            ;;
        esac
        systemctl daemon-reload
        echo -e "${green}Fail2ban and IP Limit removed successfully!${plain}\n"
        before_show_menu
        ;;
    0)
        echo -e "${yellow}Cancelled.${plain}\n"
        iplimit_main
        ;;
    *)
        echo -e "${red}Invalid option. Please select a valid number.${plain}\n"
        remove_iplimit
        ;;
    esac
}

show_usage() {
    echo "x-ui control menu usages: "
    echo "------------------------------------------"
    echo -e "SUBCOMMANDS:"
    echo -e "x-ui              - Admin Management Script"
    echo -e "x-ui start        - Start"
    echo -e "x-ui stop         - Stop"
    echo -e "x-ui restart      - Restart"
    echo -e "x-ui status       - Current Status"
    echo -e "x-ui settings     - Current Settings"
    echo -e "x-ui enable       - Enable Autostart on OS Startup"
    echo -e "x-ui disable      - Disable Autostart on OS Startup"
    echo -e "x-ui log          - Check logs"
    echo -e "x-ui banlog       - Check Fail2ban ban logs"
    echo -e "x-ui update       - Update"
    echo -e "x-ui install      - Install"
    echo -e "x-ui uninstall    - Uninstall"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}3X-UI Panel Management Script${plain}
  ${green}0.${plain} Exit Script
————————————————
  ${green}1.${plain} Install
  ${green}2.${plain} Update
  ${green}3.${plain} Update Menu
  ${green}4.${plain} Uninstall
————————————————
  ${green}5.${plain} Reset Username & Password & Secret Token
  ${green}6.${plain} Reset Web Base Path
  ${green}7.${plain} Reset Settings
  ${green}8.${plain} Change Port
  ${green}9.${plain} View Current Settings
————————————————
  ${green}10.${plain} Start
  ${green}11.${plain} Stop
  ${green}12.${plain} Restart
  ${green}13.${plain} Check Status
  ${green}14.${plain} Logs Management
————————————————
  ${green}15.${plain} Enable Autostart
  ${green}16.${plain} Disable Autostart
————————————————
  ${green}17.${plain} SSL Certificate Management
  ${green}18.${plain} IP Limit Management
"
    show_status
    echo && read -p "Please enter your selection [0-18]: " num

    case "${num}" in
    0)
        exit 0
        ;;
    1)
        check_uninstall && install
        ;;
    2)
        check_install && update
        ;;
    3)
        check_install && update_menu
        ;;
    4)
        check_install && uninstall
        ;;
    5)
        check_install && reset_user
        ;;
    6)
        check_install && reset_webbasepath
        ;;
    7)
        check_install && reset_config
        ;;
    8)
        check_install && set_port
        ;;
    9)
        check_install && check_config
        ;;
    10)
        check_install && start
        ;;
    11)
        check_install && stop
        ;;
    12)
        check_install && restart
        ;;
    13)
        check_install && status
        ;;
    14)
        check_install && show_log
        ;;
    15)
        check_install && enable
        ;;
    16)
        check_install && disable
        ;;
    17)
        ssl_cert_issue_main
        ;;
    18)
        iplimit_main
        ;;
    *)
        LOGE "Please enter the correct number [0-18]"
        ;;
    esac
}

if [[ $# > 0 ]]; then
    case $1 in
    "start")
        check_install 0 && start 0
        ;;
    "stop")
        check_install 0 && stop 0
        ;;
    "restart")
        check_install 0 && restart 0
        ;;
    "status")
        check_install 0 && status 0
        ;;
    "settings")
        check_install 0 && check_config 0
        ;;
    "enable")
        check_install 0 && enable 0
        ;;
    "disable")
        check_install 0 && disable 0
        ;;
    "log")
        check_install 0 && show_log 0
        ;;
    "banlog")
        check_install 0 && show_banlog 0
        ;;
    "update")
        check_install 0 && update 0
        ;;
    "install")
        check_uninstall 0 && install 0
        ;;
    "uninstall")
        check_install 0 && uninstall 0
        ;;
    *) show_usage ;;
    esac
else
    show_menu
fi
