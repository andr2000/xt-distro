BB_DEFAULT_TASK ?= "build"
CLASSOVERRIDE ?= "class-target"

XT_IMPORTS += "xtbuilder"
XT_IMPORTS[type] = "list"

def xt_import(d):
    import sys

    bbpath = d.getVar("BBPATH").split(":")
    sys.path[0:0] = [os.path.join(dir, "lib") for dir in bbpath]

    def inject(name, value):
        """Make a python object accessible from the metadata"""
        if hasattr(bb.utils, "_context"):
            bb.utils._context[name] = value
        else:
            __builtins__[name] = value

    import oe.data
    for toimport in oe.data.typed_value("XT_IMPORTS", d):
        imported = __import__(toimport)
        inject(toimport.split(".", 1)[0], imported)

    return ""

XT_IMPORTED := "${@xt_import(d)}"

def prune_suffix(var, suffixes, d):
    # See if var ends with any of the suffixes listed and
    # remove it if found
    for suffix in suffixes:
        if var.endswith(suffix):
            var = var.replace(suffix, "")

    prefix = d.getVar("MLPREFIX")
    if prefix and var.startswith(prefix):
        var = var.replace(prefix, "")

    return var

def base_prune_suffix(var, suffixes, d):
    return prune_suffix(var, suffixes, d)

def base_cpu_count():
    import multiprocessing
    return multiprocessing.cpu_count()

addtask fetch
do_fetch[dirs] = "${DL_DIR}"
do_fetch[vardeps] += "SRCREV"
python base_do_fetch() {
    src_uri = (d.getVar('SRC_URI') or "").split()
    if len(src_uri) == 0:
        return

    bb.debug(1, "Fetching: %s" % "\n".join(src_uri))
    try:
        fetcher = bb.fetch2.Fetch(src_uri, d)
        fetcher.download()
    except bb.fetch2.BBFetchException as e:
        bb.fatal(str(e))
}

addtask unpack after do_fetch
do_unpack[dirs] = "${WORKDIR}"

python () {
    if d.getVar('S') != d.getVar('WORKDIR'):
        d.setVarFlag('do_unpack', 'cleandirs', '${S}')
    else:
        d.setVarFlag('do_unpack', 'cleandirs', os.path.join('${S}', 'patches'))
}
python base_do_unpack() {
    src_uri = (d.getVar('SRC_URI') or "").split()
    if len(src_uri) == 0:
        return

    try:
        fetcher = bb.fetch2.Fetch(src_uri, d)
        bb.debug(1, "Unpacking: %s" % "\n".join(d.getVar('WORKDIR').split()))
        fetcher.unpack(d.getVar('WORKDIR'))
        bb.debug(1, "Unpacking S: %s" % "\n".join(d.getVar('S').split()))
    except bb.fetch2.BBFetchException as e:
        bb.fatal(str(e))
}

addtask build after do_unpack
python base_do_build () {
    build_system = (d.getVar('XT_BUILD_SYSTEM') or "yocto").split()

    try:
        import xtbuilder
        builder = xtbuilder.XTBuilder(build_system, d)
        builder.build(d.getVar('S'))
    except bb.fetch2.BBFetchException as e:
        bb.fatal(str(e))
}


EXPORT_FUNCTIONS do_build do_fetch do_unpack