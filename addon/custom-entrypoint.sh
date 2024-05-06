#!/bin/bash

echo "127.0.0.1    cdk.example.com" >> /etc/hosts

# Start Tomcat in the background
/usr/local/tomcat/bin/startup.sh

# Sleep for a few seconds to ensure Tomcat starts
# sleep 20

# Wait until Tomcat starts
while ! nc -z localhost 18080; do   
  sleep 1 # wait for 1 second before check again
done

echo "Tomcat started."

# Place your script execution here
# Example: ./your-script.sh
cd /usr/local/tomcat/amster/
envsubst < install_am.amster.template > install_am.amster
./amster install_am.amster

# Copy the keystore and secrets to the right location
echo "Copying the keystore and secrets to the right location"

cd /usr/local/tomcat/am/tam/security
mv keystores keystores.bak
cp -rv /usr/local/tomcat/init/keystores .
cd ./secrets
mv default default.bak
cp -rv /usr/local/tomcat/init/secrets/default .

# Restarting Tomcat
/usr/local/tomcat/bin/shutdown.sh

# Wait until Tomcat stops
while nc -z localhost 18080; do
  sleep 1 # wait for 1 second before checking again
done

echo "Tomcat stopped."

/usr/local/tomcat/bin/startup.sh

# Wait until Tomcat starts again
while ! nc -z localhost 18080; do   
  sleep 1 # wait for 1 second before check again
done

echo "Tomcat restarted."

# Now, bring Tomcat to the foreground
# Tail the Catalina logs to keep the script running
tail -f /usr/local/tomcat/logs/catalina.out
