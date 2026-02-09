# Welcome
## Everything is already configured to contain the data within it's own folder. That way it is easy to configure the service or for making backups. Please review the docker compose file to see if changes are needed.

### Create a User if you need to by:

sudo adduser newuser

usermod -aG sudo newuser

### Please be sure install docker first.

curl -sSL https://get.docker.com | sh

sudo usermod -aG docker $USER

### If you want to use docker compose, navigate to the folder for the service you want to install.
<table><tr><td>cd foldername/</td></tr></table>

###  Then type command below to install or start docker image
Prior to installing, please make sure to check the docker compose file that everything is correct by typing *nano docker-compose.yml*
<table><tr><td>docker compose up -d</td></tr></table>

###  type command below to stop docker image
<table><tr><td>docker compose down</td></tr></table>

###  type command below to update docker image
<table><tr><td>docker compose pull</td></tr></table>
