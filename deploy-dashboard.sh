#########################################################################################
echo ""
echo "Creating production deployment packages for Saleor Dashboard..."
echo ""
#########################################################################################


#########################################################################################
# Clone the git and setup the environment variables for Saleor API & Dashboard install
#########################################################################################
# Make sure we're in the user's home directory
cd $HD
# Clone the Saleor Dashboard Git repository
if [ -d "$HD/saleor-dashboard" ]; then
        sudo rm -R $HD/saleor-dashboard
fi
sudo -u $UN git clone https://github.com/JoeHO888/saleor-dashboard.git
wait
# Build the API URL
API_URL="https://$HOST/$APIURI/"
# Write the production .env file from template.env
sed "s|{api_url}|$API_URL|" $HD/Deploy_Saleor/resources/saleor-dashboard/template.env | sudo dd status=none of=$HD/saleor-dashboard/.env
#########################################################################################



#########################################################################################
# Build Saleor Dashboard for production
#########################################################################################
# Make sure we're in the project root directory
cd saleor-dashboard
# Was the -v (version) option used?
if [ "vOPT" = "true" ] || [ "$VERSION" != "" ]; then
        sudo -u $UN git checkout main
else
        sudo -u $UN git checkout main
fi
wait
# Install dependancies
npm i
wait
npm install husky -g
wait
npm run build
wait
#########################################################################################

#########################################################################################
# Setup the nginx block and move the static build files
#########################################################################################
echo "Moving static files for the Dashboard..."
echo ""

sudo rm -rf /var/www/$APP_HOST
sudo mv $HD/saleor-dashboard/build/dashboard /var/www/$APP_HOST
# Make an empry variable
DASHBOARD_LOCATION=""
# Clean the saleor server block
sudo sed -i "s#{dl}#$DASHBOARD_LOCATION#" /etc/nginx/sites-available/saleor
# Create the saleor-dashboard server block
sed "s|{hd}|$HD|g
        s/{app_mount_uri}/$APP_MOUNT_URI/g
        s/{host}/$APP_HOST/g" $HD/Deploy_Saleor/resources/saleor-dashboard/server_block | sudo dd status=none of=/etc/nginx/sites-available/saleor-dashboard
wait
sudo chown -R www-data /var/www/$APP_HOST
echo "Enabling server block and Restarting nginx..."
sudo rm -rf /etc/nginx/sites-enabled/saleor-dashboard
sudo ln -s /etc/nginx/sites-available/saleor-dashboard /etc/nginx/sites-enabled/
sudo systemctl restart nginx
#########################################################################################
