#!/home/andrew/conda/envs/dj18/bin/python
import sys, os

# Add a custom Python path.
sys.path.insert(0, "/home/andrew/public_html/basesite")

# Switch to the directory of your project. (Optional.)
os.chdir("/home/andrew/public_html/basesite")

# Set the DJANGO_SETTINGS_MODULE environment variable.
os.environ['DJANGO_SETTINGS_MODULE'] = "basesite.settings"

from django.core.servers.fastcgi import runfastcgi
runfastcgi(method="threaded", daemonize="false")
