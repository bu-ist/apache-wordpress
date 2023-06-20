# Proxy asset requests to S3

The contents of this subdirectory comprise an apache configuration that replaces the source location for wordpress assets from files stored in local`"/fs/"` directory mounts objects stored in S3 bucket(s).
The implementation of this is in two parts:

1. The [https://github.com/awslabs/aws-sigv4-proxy]() repository is pulled to provide a docker build context to create an image containers can be run from to sign http requests to object lambda access points, send them, and return the response.
   The docker container runs as a background process and is available to the apache httpd server on localhost.
2. A modified apache configuration that recognizes specific request URI patterns that indicate assets and proxies them to the docker container for retrieval from s3.

### Prerequisites:

- The [AWS command line interface](https://aws.amazon.com/cli/)
- Docker
- Git

### Steps:

1. Log into the WordPress server.

2. If needed, update the docker image within our registry.
   See [build-image readme file](./build-image.md) for an explanation and steps
   
3. Pull this repository:

   ```
   cd /tmp
   git clone https://github.com/bu-ist/apache-wordpress.git
   cd apache-wordpress
   git checkout olap
   ```

4. Copy the s3proxy subdirectory to the WordPress config directory:

   ```
   cp -r /tmp/apache-wordpress/conf.d/s3proxy /etc/httpd/conf.d
   ```

5. Add an import for the s3proxy.conf file to the main wordpress.conf file:

   ```
   sed -i -re  's|(Include conf.d/shib.conf)|\1\n\nInclude conf.d/s3proxy/s3proxy.conf|' /etc/httpd/conf.d/wordpress.conf
   ```

6. Update the `conf.d/s3proxy/credentials.sh` file.
   The docker container will sign http requests using the credentials of an IAM principal that has the privileges to access the object lambda access point. This principals credentials should be locatable in secrets manager.
   Update the following 2 entries: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
   *NOTE: Other values in this file have defaults - modify these as appropriate.*
   *CUSTOM_IMAGE is used indicate what the docker container runs against if not the default value. Typically done if the go code that is part of the https://github.com/awslabs/aws-sigv4-proxy needs to be modified and we run a custom variant image from our own repository until such time (maybe never) the upstream authors accept a pull request for our modification*
   
7. Run the docker container:

   ```
   cd /etc/httpd/conf.d/s3proxy
   sh docker.sh run
   ```

8. Test the container:
   Curl to an olap endpoint via the container.
   Provide the object key, followed by a site to send in an header for the olap lambda function.

   ```
   sh docker.sh curl \
     'admissions/files/2018/09/cuba-abroad-banner-compressed-1000x600.jpg' \
     'jaydub-bulb.cms-devl.bu.edu'
   ```




### Key Rotation:

See [rotate-keys readme file](./rotate-keys.md)
