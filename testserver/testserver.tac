import logging
from os.path import dirname, join, abspath
from pyamf.remoting.gateway.twisted import TwistedGateway
from twisted.web import static, server
from twisted.internet import reactor
from twisted.application import service, internet

PORT = 8080

logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s %(levelname)-5.5s [%(name)s] %(message)s")


class Service1(object):

    def hello(self):
        return "Hello!"

    def echo(self, data):
        return data;

    def add(self, a, b):
        return a + b

    def raiseError():
        raise Error("Bang!")

services = {"Service1": Service1}
amf = TwistedGateway(
    services, logger=logging, expose_request=False, debug=True)

baseDir = dirname(dirname(abspath(__file__)))
path = join(baseDir, "bin")
root = static.File(path)
root.putChild("amf", amf)

application = service.Application("test service")
svr = internet.TCPServer(PORT, server.Site(root))
svr.setServiceParent(application)
