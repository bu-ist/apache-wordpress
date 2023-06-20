# Key Rotation

The s3 bucket that stores wordpress assets is originally cloud-formed along with an IAM user that has policies specific for access to this bucket. 
This user is created with an [access key](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) whose id and secret is stored in secrets manager. It is with these credentials that all http requests for bucket assets are signed. Per BU policy this access key needs to be rotated on a regular schedule.

The project timeline for bringing wordpress into the cloud will enter a phase where access to this bucket will be role-based, at which time, the need for these explicit credentials will drop off. Therefore, in the interim, manual key rotation can suffice over an automated solution. The manual steps are detailed here: 

### Perquisites:

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)
- User profile for role sufficient to perform all actions below.
  Example user: Shibboleth-InfraMgt/[you]@bu.edu
- Administrative access to wordpress host server.

### Steps:

1. Get the id of the users currently active key:

   ```
   username='wordpress-protected-s3-assets-jaydub-user'
   secretid="${username}/AccessKey"
   
   # Get the id of the users currently active key:
   keyId=$(aws iam list-access-keys \
     --user-name $username \
     --output text \
     --query 'AccessKeyMetadata[?Status==`Active`].AccessKeyId')
   ```

2. Temporarily save the current credentials:

   ```
   aws secretsmanager get-secret-value \
     --secret-id $secretId \
     --query '{SecretString:SecretString}' \
     --output text > credentials-old.json
   ```

3. Create a new key and capture the returned credentials:

   ```
   credentials=$(aws iam create-access-key --user-name $username)
   echo "$credentials" > credentials.json
   ```

4. Save the new credentials to secrets manager:

   ```
   aws secretsmanager put-secret-value \
     --secret-id $secredid \
     --secret-string "$credentials"
   ```

5. Deactivate or delete the original key:

   ```
   # Deactivate the original key:
   aws iam update-access-key \
     --user-name $username \
     --access-key-id $keyId \
     --status "Inactive"
      
   # Or...
   
   # Delete the original key:
   aws iam delete-access-key \
     --user-name $username \
     --access-key-id $keyId
   ```

6. Log in to the wordpress host server and update the credentials file:

   ```
   cd /etc/httpd/conf.d/s3proxy/
   vi credentials.sh
   # Replace the appropriate line items with their new values from the credentials.json file
   ```

7. Restart the docker proxy container:

   ```
   docker restart proxy
   ```

   

