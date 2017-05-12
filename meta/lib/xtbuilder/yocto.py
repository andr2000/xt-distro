import bb
from   xtbuilder import BuildSystem

class YoctoBuilder(BuildSystem):

    def supports(self, build_system, d):
        bb.debug(1, 'check ' + build_system)
        return build_system == 'yocto'

    def build(self, d):
        bb.debug(1, 'Using Yocto builder')