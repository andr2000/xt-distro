import bb
import logging

logger = logging.getLogger("xen-troops.builder")

class XTBuilder(object):
    def __init__(self, build_system, d):
        if len(build_system) == 0:
            build_system = d.getVar("XT_BUILD_SYSTEM").split()
        self.build_system = build_system
        self.d = d

    def build(self, src=None):
        bb.debug(1, 'Building at ' + src)
