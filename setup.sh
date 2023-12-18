sudo apt-get update
sudo apt-get install -y build-essential python3-dev python3-pip python3-cffi python3.9-venv gcc
sudo apt-get install -y libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 libffi-dev shared-mime-info libpq-dev
sudo apt-get install -y nodejs npm postgresql postgresql-contrib nginx

#########################################################################################
# Set variables for the password, obfuscation string, and user/database names
#########################################################################################
# Append the database name for Saleor with the obfuscation string
PGSQLDBNAME="saleor"
# Append the database username for Saleor with the obfuscation string
PGSQLUSER="saleor"
# Generate a 128 byte password for the Saleor database user
# TODO: Add special characters once we know which ones won't crash the python script
PGSQLUSERPASS="saleor"
#########################################################################################

#########################################################################################
# Create a superuser for Saleor
#########################################################################################
# Create the role in the database and assign the generated password
sudo -i -u postgres psql -c "CREATE ROLE $PGSQLUSER PASSWORD '$PGSQLUSERPASS' SUPERUSER CREATEDB CREATEROLE INHERIT LOGIN;"
# Create the database for Saleor
sudo -i -u postgres psql -c "CREATE DATABASE $PGSQLDBNAME;"
# TODO - Secure the postgers user account
#########################################################################################