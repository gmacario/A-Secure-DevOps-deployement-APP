from uuid import UUID
from boto3 import client


__BUCKET = 'a-super-ultra-secure-company-asdda-deployments'
s3_client = client('s3')


def upload_2_bucket(content: str, key: UUID):
	s3_client.put_object(
		Body = content,
		Bucket = __BUCKET,
		Key = f'{key}'
	)


def upload_file_2_bucket(fn: str, key: UUID):
	s3_client.upload_file(fn, __BUCKET, f'{key}')


def read_deployment(key: UUID):
	resp = s3_client.get_object(
		Bucket = __BUCKET,
		Key = f'{key}'
	)

	return resp['Body'].read().decode()