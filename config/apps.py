from django.contrib.admin.apps import AdminConfig


class DoccanoAdminConfig(AdminConfig):
    default_site = 'config.admin.DoccanoAdminSite'