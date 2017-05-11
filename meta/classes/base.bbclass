inherit utils

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
        bb.debug(1, "Unpacking: %s" % "\n".join(d.getVar('S').split()))
    except bb.fetch2.BBFetchException as e:
        bb.fatal(str(e))
}

addtask build after do_unpack
python base_do_build () {
    bb.debug(1, "Building")
}

EXPORT_FUNCTIONS do_fetch do_unpack do_build
