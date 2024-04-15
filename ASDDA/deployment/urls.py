from django.urls import path
from . import views

urlpatterns = [
    path(
		'home/', views.home,
		name = 'home'
	),
	path(
		'create_deployment/', views.create_deployment,
		name = 'create_deployment'
	),
	path(
		'get_deployment/<uuid:deployment>', views.get_deployment,
		name = 'get_deployment'
	),
	path(
		'deploy/', views.deploy,
		name = 'deploy'
	),
	path(
		'index/', views.home,
		name = 'index'
	),
	path(
		'upload_tar_gz/', views.upload_tar_gz,
		name = 'upload_tar_gz'
	),
	path(
		'messages', views.messages,
		name = 'messages'
	)
]