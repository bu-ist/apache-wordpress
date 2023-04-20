### Proxy asset requests to S3

The contents of this subdirectory comprise an apache configuration that replaces the source location for wordpress assets from:

 Files stored in local`"/fs/"` directory mounts

to...

Objects stored in S3 bucket(s)

In this configuration, apache will proxy requests for assets to s3 as follows:

1. Use the [RewriteMap](https://httpd.apache.org/docs/2.4/mod/mod_rewrite.html#rewritemap) directive to delegate generating a proper signature required for an http request to s3 for the asset to a background process.
   The background process "listens" with a bash script that implements steps for v4 signature creation. See:
   - [Create a canonical request](https://docs.aws.amazon.com/general/latest/gr/create-signed-request.html#create-canonical-request)
   - [Sig V4 header-based authentication](https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html)
2. Once the signature is created, it is added as a header in the request as it is [proxied](https://httpd.apache.org/docs/2.4/mod/mod_proxy.html#proxypass) to an [s3 object lambda endpoint](https://docs.aws.amazon.com/AmazonS3/latest/userguide/transforming-objects.html).
   The [lambda function](https://docs.aws.amazon.com/AmazonS3/latest/userguide/olap-writing-lambda.html) will apply the proper security and asset manipulation as appropriate for the information presented in the request and its headers. 

