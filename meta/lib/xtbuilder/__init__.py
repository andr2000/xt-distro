import bb

methods = []

class BuildSystem(object):
    def supports(self, build_system, d):
        return 0

    def build(self, d):
        return

class XTBuilder(object):
    def __init__(self, build_system, d):
        if len(build_system) == 0:
            build_system = d.getVar("XT_BUILD_SYSTEM").split()
        self.build_system = build_system
        self.d = d
        self.method = None

        for m in methods:
            if m.supports(self, build_system):
                self.method = m
                break

        if not self.method:
            raise Exception('Build system is not supported: ' + str(build_system))

    def build(self, src=None):
        bb.debug(1, 'Building at ' + src)
        self.method.build(src)

from . import yocto

# all the build systems we support
methods.append(yocto.YoctoBuilder())