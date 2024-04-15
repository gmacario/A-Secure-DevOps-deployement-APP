from uuid import uuid4
from django.db import models
from django.contrib.auth.models import User

# Create your models here.


class Upload(models.Model):
	user = models.ForeignKey(
		User,
		on_delete = models.PROTECT
	)

	file_name = models.UUIDField(
		default = uuid4
	)

	alias = models.CharField(max_length = 30)