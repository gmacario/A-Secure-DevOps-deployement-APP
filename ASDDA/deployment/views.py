from uuid import (
	UUID, uuid4
)

from os import (
	remove, listdir, rmdir
)

from tarfile import open as TAR
from django.views.decorators.http import require_POST 
from django.contrib.auth.decorators import login_required

from django.shortcuts import (
	render, redirect
)

from django.http import (
	HttpRequest, HttpResponse
)

from .models import Upload
from .settings import OUTPUT_DIR
from . import api_s3


# Create your views here.


@login_required
def home(request: HttpRequest) -> HttpResponse:
	deployments = Upload.objects.filter(user = request.user)

	return render(
		request, 'deployment/home.html',
		context = {
			'deployments': deployments
		}
	)


@login_required
def messages(request: HttpRequest) -> HttpResponse:
	return render(
		request, 'deployment/messages.html',
	)


@require_POST
@login_required
def create_deployment(request: HttpRequest) -> HttpResponse:
	post_params = request.POST
	deployment_content = post_params['deployment']
	alias = post_params['alias']
	upload = Upload(user = request.user, alias = alias)
	api_s3.upload_2_bucket(deployment_content, upload.file_name)
	upload.save()

	return redirect('home')


@login_required
def get_deployment(request: HttpRequest, deployment: UUID) -> HttpResponse:
	upload = Upload.objects.filter(user = request.user, file_name = deployment).first()

	if not upload:
		return HttpResponse(
			'No IDOR here, but I respect your try ;)',
			status = 406
		)


	http = HttpResponse(
		api_s3.read_deployment(deployment),
		content_type = 'text/yaml'
	)

	http['Content-Disposition']  = f'attachment; filename="{upload.alias}.yaml"'

	return http


@login_required
def deploy(request: HttpRequest) -> HttpResponse:
	return render(
		request, 'deployment/troll.html'
	)


@require_POST
@login_required
def upload_tar_gz(request: HttpRequest) -> HttpResponse:
	file = request.FILES['tar_gz']

	def handle_uploaded_file(f: bytes):
		gzip_name = f'{OUTPUT_DIR}/{uuid4()}.tar.gz'

		with open(gzip_name, 'wb+') as destination:
			for chunk in f.chunks():
				destination.write(chunk)

		new_dir = uuid4()
		tmp_out = f'{OUTPUT_DIR}/{new_dir}/'

		with TAR(gzip_name, 'r:gz') as f:
			f.extractall(path = tmp_out)

		remove(gzip_name)

		for f in listdir(tmp_out):
			c_upload = Upload(user = request.user, alias = f.split('/')[-1])
			api_s3.upload_file_2_bucket(f'{tmp_out}{f}', c_upload.file_name)
			c_upload.save()
			remove(f'{tmp_out}{f}')

		rmdir(tmp_out)

	handle_uploaded_file(file)

	return redirect('home')