---
layout: post
title: Using KMS in the shell
categories: aws
---

## Purpose
Some notes on using AWS KMS from the shell


### Create an AWS [customer master key](http://docs.aws.amazon.com/cli/latest/reference/kms/create-key.html) if you do not already have one
```
key_id=$(aws kms create-key | jq -r .KeyMetadata.KeyId)
aws kms create-alias --alias-name alias/my-test-key --target-key-id $key_id
```


### Policy
- You should use policy to restrict access to the key
- In this sample I presume you have access to the key


### Script with encrypt\decrypt and some test functions

```bash
#!/bin/bash
# This assumes you have configured the AWS region and credentials, if not it will fail
# We do not set errexit or pipefail as the environment sourcing this should configure this
# Can use set -o to check

kms-decrypt()
{
	context=$1
	cipher=$2
	region=${3:-$AWS_REGION}

	aws kms decrypt --ciphertext-blob fileb://<(echo $cipher | base64 --decode) --region $region --output text --query Plaintext | base64 --decode
}

kms-encrypt()
{
	key=$1
	context=$2
	plain=$3
	region=${4:-$AWS_REGION}

	aws kms encrypt --key-id alias/${key} --plaintext "$plain" --region $region --output text --query CiphertextBlob
}

# Tests
assert()
{
	# If you have set errexit this will fail and exit immediately, should test with set +o errexit
	eval "$1"
	[[ $? -eq 0 ]] && echo -e "\e[32m${FUNCNAME[1]}: ${1} passed\e[0m" || echo -e "\e[31m ${FUNCNAME[1]}: ${1} failed\e[0m"
}

test-kms-roundtrip-with-no-context()
{
	key=my-test-key
	context=
	original_data='eykjsgh$^%46546112--dff09865-END'

	cipher=$(kms-encrypt $key "$context" "$original_data")
	plain=$(kms-decrypt "$context" "$cipher")

	assert "[ '$original_data' == '$plain' ]"
}

test-kms-roundtrip-with-context()
{
	key=my-test-key
	context='k1=v1,k2=v2'
	original_data='eykjsgh$^%46546112--dff09865-OTHER-END.'

	cipher=$(kms-encrypt $key "$context" "$original_data")
	plain=$(kms-decrypt "$context" "$cipher")

	assert "[ '$original_data' == '$plain' ]"
}
```
