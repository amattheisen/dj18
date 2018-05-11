#!/home/andrew/conda/envs/dj18/bin/python

from flup.server.fcgi import WSGIServer
def app(environ, start_response):
    start_response('200 OK', [('Content-Type', 'text/plain')])
    return ['Hello World!\n']

if __name__ == '__main__':
    WSGIServer(app).run()
