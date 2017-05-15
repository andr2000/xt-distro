# HACK: oe-init-build-env cannot be run directly as Yocto uses /bin/sh
# which by default is dash on Ububntu which is a problem for
# oe-init-build-env script. Use bash directly

addtask configure after do_unpack
do_configure () {
    local local_conf="${S}/build/conf/local.conf"

    cd ${S}
    /bin/bash -x -c "source poky/oe-init-build-env"
    if [ -e ${XT_BB_LAYERS_FILE} ] ; then
        cp ${XT_BB_LAYERS_FILE} ${S}/build/conf/bblayers.conf
    fi
    if [ -e ${XT_BB_LOCAL_CONF_FILE} ] ; then
        cp ${XT_BB_LOCAL_CONF_FILE} ${local_conf}
    fi
    # update local.conf so inner build uses our folders
    if [ -e ${local_conf} ] ; then
        if [ -n ${DL_DIR} ] ; then
                base_update_conf_value ${local_conf} DL_DIR ${DL_DIR}
        fi
        if [ -n ${SSTATE_DIR} ] ; then
                base_update_conf_value ${local_conf} SSTATE_DIR ${SSTATE_DIR}
        fi
        if [ -n ${IMAGE_ROOTFS} ] ; then
                base_update_conf_value ${local_conf} IMAGE_ROOTFS ${IMAGE_ROOTFS}/${PN}
        fi
        if [ -n ${DEPLOY_DIR} ] ; then
                base_update_conf_value ${local_conf} DEPLOY_DIR ${DEPLOY_DIR}/${PN}
        fi
        base_update_conf_value ${local_conf} INHERIT buildhistory "+"
        base_update_conf_value ${local_conf} BUILDHISTORY_COMMIT 1
    fi
}

addtask compile after do_configure
do_compile () {
    cd ${S}
    /bin/bash -x -c "source poky/oe-init-build-env && bitbake ${XT_BB_IMAGE_TARGET}"
}

addtask build after do_compile
do_build () {
    :
}
