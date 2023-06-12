

# Custom aws-sigv4-proxy docker image

The aws-sigv4-proxy docker image currently requires a few customizations to accommodate the needs for signing s3 requests for assets for apache serving assets for wordpress from s3.

Specifically, there are two modifications needed:

1. The base image only recognizes requests that are made directly against the `"s3"` service.
   However, we make requests against the `"s3-object-lambda"` service.
   The relevant modification can be seen [here](https://github.com/bu-ist/aws-sigv4-proxy/commit/91847613371572968637e8c5b5079c60a5c80d4a),
   Currently there is a [pull request](https://github.com/awslabs/aws-sigv4-proxy/pull/138) to get this into the upstream repo.
2. A health check has been added to make this image more suitable to run in a load-balanced/clustered context.
   The modification details are [here](https://github.com/bu-ist/aws-sigv4-proxy/commit/a82dacf87f8dd2fe6a6d221369a981e4aec75f9c)

A new image with these modifications exists as a boston university public ecr repo.
Steps to update this repo with upstream changes are as follows:

1. Clone the custom repo:

   ```
   git clone https://github.com/bu-ist/aws-sigv4-proxy.git
   cd aws-sigv4-proxy/
   ```

2. Fetch any upstream changes:

   ```
   git remote add upstream https://github.com/awslabs/aws-sigv4-proxy.git
   git fetch upstream master
   ```

3. Rebase the custom master branch on whatever came down from the upstream repo:

   ```
   git rebase FETCH_HEAD
   ```

4. Build the new custom image:

   ```
   docker build -t public.ecr.aws/bostonuniversity-nonprod/aws-sigv4-proxy .
   ```

5. Push the new image to the public boston university elastic container registry:

   ```
   aws ecr-public get-login-password \
     --region us-east-1 | docker login \
       --username AWS \
       --password-stdin \
       public.ecr.aws/bostonuniversity-nonprod
       
   docker push public.ecr.aws/bostonuniversity-nonprod/aws-sigv4-proxy:latest
   ```

   