# Use the official Tomcat base image
FROM tomcat:9-jdk11

# Install unzip
RUN apt-get update && apt-get install -y unzip gettext-base netcat

# Remove the default web applications
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy your ForgeRock AM WAR file into the webapps directory
COPY AM-7.4.0.war /usr/local/tomcat/webapps/openam.war

# Optional: If you need to modify the server.xml or other config files
RUN rm -rf /usr/local/tomcat/conf/server.xml
COPY conf/server.xml /usr/local/tomcat/conf/

RUN mkdir /usr/local/tomcat/cert
COPY cert/truststore /usr/local/tomcat/cert/

COPY conf/setenv.sh /usr/local/tomcat/bin/
RUN chmod +x /usr/local/tomcat/bin/*.sh

# Copy Amster.zip into the working directory and unzip it
COPY Amster-7.4.0.zip /usr/local/tomcat/
RUN unzip /usr/local/tomcat/Amster-7.4.0.zip
RUN rm /usr/local/tomcat/Amster-7.4.0.zip
COPY install_am.amster.template /usr/local/tomcat/amster/

# Copy init folder used for post installation
COPY init /usr/local/tomcat/init

# Expose the port Tomcat will run on
EXPOSE 18080

COPY custom-entrypoint.sh /usr/local/tomcat/bin/custom-entrypoint.sh
RUN chmod +x /usr/local/tomcat/bin/custom-entrypoint.sh

ENTRYPOINT ["/usr/local/tomcat/bin/custom-entrypoint.sh"]
