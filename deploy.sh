#########################################################################################
# deploy-saleor.sh
# Author:       Aaron K. Nall   http://github.com/thewhiterabbit
#########################################################################################
#!/bin/sh
set -e

#########################################################################################
# Get the actual user that logged in
#########################################################################################
UN="$(whoami | awk '{print $1}')"
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
OS="Ubuntu"
#########################################################################################

#########################################################################################
# Generate a secret key file
#########################################################################################
# Does the key file directory exiet?
if [ ! -d "/etc/saleor" ]; then
        sudo mkdir /etc/saleor
else
        # Does the key file exist?
        if [ -f "/etc/saleor/api_sk" ]; then
                # Yes, remove it.
                sudo rm /etc/saleor/api_sk
        fi
fi
# Create randomized 2049 byte key file
echo $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 2048| head -n 1) | sudo dd status=none of=/etc/saleor/api_sk
#########################################################################################


#########################################################################################
# Collect input from the user to assign required installation parameters
#########################################################################################
echo "Please provide details for your Saleor API instillation..."
echo ""

HOST="api.domain.com"
ADMIN_EMAIL="admin@domain.com"
ADMIN_PASS="password"
STATIC_URL="/static/"
MEDIA_URL="/media/" 
PGDBHOST="localhost"
DBPORT="5432"
GQL_PORT="9000"
API_PORT="8000"
APIURI="graphql"
VERSION="main"

SAME_HOST="no"
APP_HOST="dashboard.domain.com"
APP_MOUNT_URI="app.domain.com"

#########################################################################################
# Open the selected ports for the API and APP
#########################################################################################
# Open GraphQL port
sudo ufw allow $GQL_PORT
# Open API port
sudo ufw allow $API_PORT
#########################################################################################

#########################################################################################
# Create virtual environment directory
if [ ! -d "$HD/env" ]; then
        sudo -u $UN mkdir $HD/env
        wait
fi
# Does an old virtual environment for Saleor exist?
if [ ! -d "$HD/env/saleor" ]; then
        # Create a new virtual environment for Saleor
        sudo -u $UN python3.9 -m venv $HD/env/saleor
        wait
fi
#########################################################################################



#########################################################################################
# Clone the Saleor Git repository
#########################################################################################
# Make sure we're in the user's home directory
cd $HD
# Does the Saleor Dashboard already exist?
if [ -d "$HD/saleor" ]; then
        # Remove /saleor directory
        sudo rm -R $HD/saleor
        wait
fi
#
echo "Cloning Saleor from github..."
echo ""
# Check if the -v (version) option was used
if [ "$vOPT" = "true" ]; then
        # Get the Mirumee repo
        sudo -u $UN git clone https://github.com/JoeHO888/saleor.git
else
        # Was a repo specified?
        if [ "$REPO" = "mirumee" ]; then
                # Get the Mirumee repo
                sudo -u $UN git clone https://github.com/JoeHO888/saleor.git
        else
                # Get the Mirumee repo
                sudo -u $UN git clone https://github.com/JoeHO888/saleor.git

                ###### For possible later use ######
                # Get the forked repo from thewhiterabbit
                #git clone https://github.com/mirumee/saleor.git
                ###### For possible later use ######
        fi
fi
wait
# Make sure we're in the project root directory for Saleor
cd $HD/saleor
wait
# Was the -v (version) option used?
if [ "vOPT" = "true" ] || [ "$VERSION" != "" ]; then
        # Checkout the specified version
        sudo -u $UN git checkout main
        wait
fi
#sudo -u $UN cp $HD/django/saleor/asgi.py $HD/saleor/saleor/
#sudo -u $UN cp $HD/django/saleor/wsgi.py $HD/saleor/saleor/
#sudo -u $UN cp $HD/saleor/saleor/wsgi/__init__.py $HD/saleor/saleor/wsgi.py
if [ ! -d "$HD/run" ]; then
        sudo -u $UN mkdir $HD/run
else
        if [ -f "$HD/run/saleor.sock" ]; then
                sudo rm $HD/run/saleor.sock
        fi
fi
#########################################################################################




#########################################################################################
# Tell the user what's happening
#########################################################################################
echo "Github cloning complete"
echo ""
sleep 2
#########################################################################################

#########################################################################################
# Replace any parameter slugs in the template files with real paramaters & write them to
# the production files
#########################################################################################
# Replace the settings.py with the production version
# if [ -f "$HD/saleor/saleor/settings.py" ]; then
#         sudo rm $HD/saleor/saleor/settings.py
# fi
# sudo cp $HD/Deploy_Saleor/resources/saleor/3.0.0-settings.py $HD/saleor/saleor/settings.py
# Replace the populatedb.py file with the production version
# if [ -f "$HD/saleor/saleor/core/management/commands/populatedb.py" ]; then
#         sudo rm $HD/saleor/saleor/core/management/commands/populatedb.py
# fi
# sudo cp $HD/Deploy_Saleor/resources/saleor/3.0.0-populatedb.py $HD/saleor/saleor/core/management/commands/populatedb.py
# Replace the test_core.py file with the production version
#if [ -f "$HD/saleor/saleor/core/tests/test_core.py" ]; then
#        sudo rm $HD/saleor/saleor/core/tests/test_core.py
#fi
#sudo cp $HD/Deploy_Saleor/resources/saleor/test_core.py $HD/saleor/saleor/core/tests/
# wait
# Does an old saleor.service file exist?
if [ -f "/etc/systemd/system/saleor.service" ]; then
        # Remove the old service file
        sudo rm /etc/systemd/system/saleor.service
fi
###### This following section is for future use and will be modified to allow an alternative repo clone ######
# Was the -v (version) option used or Mirumee repo specified?
if [ "vOPT" = "true" ] || [ "$REPO" = "mirumee" ]; then
        # Create the saleor service file
        sed "s/{un}/$UN/
                  s|{hd}|$HD|g" $HD/Deploy_Saleor/resources/saleor/template.service  | sudo dd status=none of=/etc/systemd/system/saleor.service 
        wait
        # Does an old server block exist?
        if [ -f "/etc/nginx/sites-available/saleor" ]; then
                # Remove the old service file
                sudo rm /etc/nginx/sites-available/saleor
        fi
        # Create the saleor server block
        sed "s|{hd}|$HD|g
                  s/{host}/$HOST/g
                  s|{static}|$STATIC_URL|g
                  s|{media}|$MEDIA_URL|g" $HD/Deploy_Saleor/resources/saleor/server_block | sudo dd status=none of=/etc/nginx/sites-available/saleor
        wait
        sudo rm -rf /etc/nginx/sites-enabled/saleor
        sudo ln -s /etc/nginx/sites-available/saleor /etc/nginx/sites-enabled/        
else
        # Create the new service file
        sed "s/{un}/$UN/
                  s|{hd}|$HD|g" $HD/Deploy_Saleor/resources/saleor/template.service  | sudo dd status=none of=/etc/systemd/system/saleor.service 
        wait
        # Does an old server block exist?
        if [ -f "/etc/nginx/sites-available/saleor" ]; then
                # Remove the old service file
                sudo rm /etc/nginx/sites-available/saleor
        fi
        # Create the new server block
        sed "s|{hd}|$HD|g
                  s/{api_host}/$API_HOST/
                  s/{host}/$HOST/g
                  s|{static}|$STATIC_URL|g
                  s|{media}|$MEDIA_URL|g
                  s/{api_port}/$API_PORT/" $HD/Deploy_Saleor/resources/saleor/server_block | sudo dd status=none of=/etc/nginx/sites-available/saleor
        wait
        sudo rm -rf /etc/nginx/sites-enabled/saleor        
        sudo ln -s /etc/nginx/sites-available/saleor /etc/nginx/sites-enabled/
fi
# Create the production uwsgi initialization file
sed "s|{hd}|$HD|g
          s/{un}/$UN/" $HD/Deploy_Saleor/resources/saleor/template.uwsgi | sudo dd status=none of=$HD/saleor/saleor/wsgi/prod.ini
if [ -d "/var/www/$HOST" ]; then
        sudo rm -R /var/www/$HOST
        wait
fi
# Create the host directory in /var/www/
sudo mkdir /var/www/$HOST
wait
# Create the media directory
sudo mkdir /var/www/$HOST$MEDIA_URL
# Static directory will be moved into /var/www/$HOST/ after collectstatic is performed
#########################################################################################

#########################################################################################
# Tell the user what's happening
echo "Preparaing SSL"
echo ""
#########################################################################################

#########################################################################################
sudo rm -rf /etc/nginx/ssl
sudo mkdir /etc/nginx/ssl
sudo cp $HD/Deploy_Saleor/domain.com.crt /etc/nginx/ssl
sudo cp $HD/Deploy_Saleor/domain.com.key /etc/nginx/ssl
#########################################################################################

#########################################################################################
# Tell the user what's happening
echo "Creating production deployment packages for Saleor API & GraphQL..."
echo ""
#########################################################################################

#########################################################################################
# Setup the environment variables for Saleor API
#########################################################################################
# Build the database URL
DB_URL="postgres://$PGSQLUSER:$PGSQLUSERPASS@$PGDBHOST:$DBPORT/$PGSQLDBNAME"
EMAIL_URL="smtp://$EMAIL:$EMAIL_PW@$EMAIL_HOST:/?ssl=True"
API_HOST=$(hostname -i);
# Build the chosts and ahosts lists
C_HOSTS="$HOST,$API_HOST,localhost,127.0.0.1"
A_HOSTS="$HOST,$API_HOST,localhost,127.0.0.1"
QL_ORIGINS="$HOST,$API_HOST,localhost,127.0.0.1"
# Write the production .env file from template.env
sed "s|{dburl}|$DB_URL|
          s|{emailurl}|$EMAIL_URL|
          s/{chosts}/$C_HOSTS/
          s/{ahosts}/$A_HOSTS/
          s/{host}/$HOST/g
          s|{static}|$STATIC_URL|g
          s|{media}|$MEDIA_URL|g
          s/{adminemail}/$ADMIN_EMAIL/
          s/{gqlorigins}/$QL_ORIGINS/" $HD/Deploy_Saleor/resources/saleor/template.env > $HD/saleor/.env
wait
#########################################################################################

#########################################################################################
# Copy the uwsgi_params file to /saleor/uwsgi_params
#########################################################################################
sudo cp $HD/Deploy_Saleor/resources/saleor/uwsgi_params $HD/saleor/uwsgi_params
#########################################################################################

#########################################################################################
# Install Saleor for production
#########################################################################################
# Does an old virtual environment vassals for Saleor exist?
if [ -d "$HD/env/saleor/vassals" ]; then
        sudo rm -R $HD/env/saleor/vassals
        wait
fi
# Create vassals directory in virtual environment
sudo -u $UN mkdir $HD/env/saleor/vassals
wait
# Simlink to the prod.ini
sudo ln -s $HD/saleor/saleor/wsgi/prod.ini $HD/env/saleor/vassals
wait

# Activate the virtual environment
source $HD/env/saleor/bin/activate
# Make sure pip is upgraded
python3 -m pip install --upgrade pip
wait
# Install Django
pip3 install Django
wait
# Create a Temporary directory to generate some fil es we need
#sudo -u $UN mkdir $HD/django
#cd django
# Create the project folder
#sudo -u $UN django-admin.py startproject saleor
# Install uwsgi
pip3 install uwsgi
wait
# Install poetry
pip3 install poetry==1.7.0
wait
# Install the project requirements
poetry install --no-root
wait
# Install the decoupler for .env file
pip3 install python-decouple
wait
# Set any secret Environment Variables
export ADMIN_PASS="$ADMIN_PASS"
# Install the project
source $HD/.nvm/nvm.sh
nvm use v16.20.2
npm install
wait
# Run an audit to fix any vulnerabilities
#sudo -u $UN npm audit fix
#wait
# Establish the database
python3 manage.py migrate
wait
python3 manage.py populatedb --createsuperuser
wait
# Collect the static elemants
python3 manage.py collectstatic
wait
# Build the schema
npm run build-schema
wait
# Exit the virtual environment here? _#_
deactivate
# Set ownership of the app directory to $UN:www-data
sudo chown -R $UN:www-data $HD/saleor
wait
# Run the uwsgi socket and create it for the first time
#sudo uwsgi --ini $HD/saleor/saleor/wsgi/uwsgi.ini --uid www-data --gid www-data --pidfile $HD/saleortemp.pid
#sleep 5
# Stop the uwsgi processes
#uwsgi --stop $HD/saleortemp.pid
# Move static files to /var/www/$HOST
sudo mv $HD/saleor/static /var/www/${HOST}${STATIC_URL}
sudo chown -R www-data:www-data /var/www/$HOST
#sudo chmod -R 776 /var/www/$HOST
#########################################################################################



#########################################################################################
# Tell the user what's happening
#########################################################################################
echo ""
echo "Finished creating production deployment packages for Saleor API & GraphQL"
echo ""
#########################################################################################



#########################################################################################
# Call the dashboard deployment script - Disabled until debugged
#########################################################################################
. $HD/Deploy_Saleor/deploy-dashboard.sh
#########################################################################################


#########################################################################################
# Enable the Saleor service
#########################################################################################
# Enable
sudo systemctl enable saleor.service
# Reload the daemon
sudo systemctl daemon-reload
# Start the service
sudo systemctl restart saleor.service
#########################################################################################



#########################################################################################
# Tell the user what's happening
echo "Creating undeploy.sh for undeployment scenario..."
#########################################################################################
if [ "$SAME_HOST" = "no" ]; then
        sed "s|{rm_app_host}|sudo rm -R /var/www/$APP_HOST|g
             s|{host}|$HOST|
             s|{gql_port}|$GQL_PORT|
             s|{api_port}|$API_PORT|" $HD/Deploy_Saleor/template.undeploy > $HD/Deploy_Saleor/undeploy.sh
        wait
else
        BLANK=""
        sed "s|{rm_app_host}|$BLANK|g
             s|{host}|$HOST|
             s|{gql_port}|$GQL_PORT|
             s|{api_port}|$API_PORT|" $HD/Deploy_Saleor/template.undeploy > $HD/Deploy_Saleor/undeploy.sh
        wait
fi
#########################################################################################



#########################################################################################
# Tell the user what's happening
#########################################################################################
echo "I think we're done here."
echo "Test the installation."
#########################################################################################
