# Building the docker images

##### 1. Download the relevant files

- wso2sp-4.0.0.zip 
- jdk-8u*-linux-x64.tar.gz (Any JDK 8u* version)
- mysql-connector-java-5*-bin.jar (Any mysql connector 5* version)

Add the above files to `sp/files` location.

- create a folder called `kafka-osgi` under `sp/files` and drop the OSGified kafka client libs (https://docs.wso2.com/display/SP400/Supporting+Different+Transports#SupportingDifferentTransports-KafkatransportKafka)

##### 2. Install few tools

- Install `bc` - `sudo apt-get install bc`

##### 3. Enable docker experimental features

- Edit /etc/default/docker and add `--experimental=true` flag to DOCKER_OPTS variable.

##### 2. Build docker images

Run build.sh
```
./build.sh
```
