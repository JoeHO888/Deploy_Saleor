#########################################################################################
# undeploy.sh
# Author:       Aaron K. Nall   http://github.com/thewhiterabbit
#########################################################################################
#!/bin/sh
set -e

print_status() {
    echo
    echo "## $1"
    echo
}

sudo systemctl stop saleor
wait
sudo ufw delete allow 9000
sudo ufw delete allow 8000
wait
#########################################################################################
# Get the actual user that logged in
#########################################################################################
UN="$(who am i | awk '{print $1}')"
if [[ "$UN" != "root" ]]; then
        HD="/home/$UN"
else
        HD="/root"
fi
cd $HD
#########################################################################################



#########################################################################################
# Get the operating system
#########################################################################################
IN=$(uname -a)
arrIN=(${IN// / })
IN2=${arrIN[3]}
arrIN2=(${IN2//-/ })
OS=${arrIN2[1]}
#########################################################################################



#########################################################################################
# Parse options
#########################################################################################
while [ -n "$1" ]; do # while loop starts
	case "$1" in
        -name)
            DEPLOYED_NAME="$2"
            shift
            ;;

        -host)
            HOST="$2"
            shift
            ;;

        -dashboard-uri)
            APP_MOUNT_URI="$2"
            shift
            ;;

        -static-url)
            STATIC_URL="$2"
            shift
            ;;

        -media-url)
            MEDIA_URL="$2"
            shift
            ;;
        
        # Gracefully remove database
        -g)
            if [ "$2" = "" ]; then
                GRD="yes"
                print_status "Graceful database removal selected."
            else
                GRD="$2"
            fi
            shift
            ;;

        *)
            echo "Option $1 is invalid."
            echo "Exiting"
            exit 1
            ;;
	esac
	shift
done
#########################################################################################



#########################################################################################
# Echo the detected operating system
#########################################################################################
print_status "$OS detected"
sleep 2
#########################################################################################



#########################################################################################
# Select/run Operating System specific commands
#########################################################################################
# Tested working on Ubuntu Server 20.04
# Needs testing on the distributions listed below:
#       Debian
#       Fedora CoreOS
#       Kubernetes
#       SUSE CaaS
print_status "Removing Saleor's core dependencies..."
sleep 1
case "$OS" in
    Debian)
        sudo apt-get --purge remove -y build-essential python3-dev python3-pip python3-cffi python3-venv gcc
        wait
        sudo apt-get --purge remove -y libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 libffi-dev shared-mime-info
        wait
        if [ "$GRD" != "yes" ]; then
            sudo apt-get --purge remove -y postgresql*
            wait
            if [ -d "/var/lib/postgresql" ]; then
                sudo rm -rf /var/lib/postgresql
            fi
            if [ -d "/var/log/postgresql" ]; then
                sudo rm -rf /var/log/postgresql
            fi
            if [ -d "/etc/postgresql" ]; then
                sudo rm -rf /etc/postgresql
            fi
            wait
        fi
        sudo apt autoremove -y
        ;;

    Fedora)
        ;;

    Kubernetes)
        ;;

    SUSE)
        ;;

    Ubuntu)
        sudo apt-get --purge remove -y build-essential python3-dev python3-pip python3-cffi python3-venv gcc
        wait
        sudo apt-get --purge remove -y libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 libffi-dev shared-mime-info
        wait
        if [ "$GRD" != "yes" ]; then
            sudo apt-get --purge remove -y postgresql*
            wait
            if [ -d "/var/lib/postgresql" ]; then
                sudo rm -rf /var/lib/postgresql
            fi
            if [ -d "/var/log/postgresql" ]; then
                sudo rm -rf /var/log/postgresql
            fi
            if [ -d "/etc/postgresql" ]; then
                sudo rm -rf /etc/postgresql
            fi
            wait
        fi
        sudo apt autoremove -y
        ;;

    *)
        # Unsupported distribution detected, exit
        echo "Unsupported Linix distribution detected."
        echo "Exiting"
        exit 1
        ;;
esac
#########################################################################################



#########################################################################################
# Tell the user what's happening
#########################################################################################
print_status "Finished purging core dependencies"
sleep 1
#########################################################################################



#########################################################################################
# Drop Saleor database and user - For future use
#########################################################################################
if [ "$GRD" = "yes" ]; then
    print_status "Removing the database and database user gracefully..."
    # Drop the role in the database and assign the generated password
    sudo -i -u postgres psql -c "DROP ROLE {pgsqluser};"
    wait
    # Drop the database for Saleor
    sudo -i -u postgres psql -c "DROP DATABASE {pgsqldbname};"
    wait
fi
#########################################################################################



#########################################################################################
# Tell the user what's happening
#########################################################################################
print_status "Finished removing database"
sleep 1
print_status "Removing the saleor service..."
sleep 2
#########################################################################################

# Disable
sudo systemctl disable saleor.service
# Reload the daemon
sudo systemctl daemon-reload

if [ -f "/etc/systemd/system/saleor.service" ]; then
    sudo rm /etc/systemd/system/saleor.service
fi

#########################################################################################
# Tell the user what's happening
#########################################################################################
print_status "Finished removing the saleor service"
sleep 1
print_status "Removing the saleor private key file..."
sleep 2
#########################################################################################

if [ -d "/etc/saleor" ]; then
    sudo rm -R /etc/saleor
fi
if [ -d "$HD/env/saleor" ]; then
    sudo rm -R $HD/env/saleor
fi
if [ -d "$HD/saleor" ]; then
    sudo rm -R $HD/saleor
fi
if [ -d "$HD/saleor-dashboard" ]; then
    sudo rm -R $HD/saleor-dashboard
fi
if [ -f "$HD/run/saleor.sock" ]; then
    sudo rm $HD/run/saleor.sock
fi
if [ -f "/etc/nginx/sites-enabled/saleor" ]; then
    sudo rm /etc/nginx/sites-enabled/saleor
fi
if [ -f "/etc/nginx/sites-available/saleor" ]; then
    sudo rm /etc/nginx/sites-available/saleor
fi
if [ -d "/var/www/api.domain.com" ]; then
    sudo rm -R /var/www/api.domain.com
    sudo rm -R /var/www/dashboard.domain.com
fi

print_status "Saleor has been undeployed!"