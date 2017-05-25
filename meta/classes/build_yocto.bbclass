build_yocto_configure() {
    local local_conf="${S}/build/conf/local.conf"

    cd ${S}
    source poky/oe-init-build-env
    if [ -f "${S}/${XT_BB_LAYERS_FILE}" ] ; then
        cp "${S}/${XT_BB_LAYERS_FILE}" "${S}/build/conf/bblayers.conf"
    fi
    if [ -f "${S}/${XT_BB_LOCAL_CONF_FILE}" ] ; then
        cp "${S}/${XT_BB_LOCAL_CONF_FILE}" "${local_conf}"
    fi
    # update local.conf so inner build uses our folders
    if [ -f ${local_conf} ] ; then
        if [ -n ${DL_DIR} ] ; then
                base_update_conf_value ${local_conf} DL_DIR ${DL_DIR}
        fi
        if [ -n ${SSTATE_DIR} ] ; then
                base_update_conf_value ${local_conf} SSTATE_DIR ${SSTATE_DIR}/${PN}
        fi
        if [ -n ${IMAGE_ROOTFS} ] ; then
                base_update_conf_value ${local_conf} IMAGE_ROOTFS ${IMAGE_ROOTFS}/${PN}
        fi
        if [ -n ${DEPLOY_DIR} ] ; then
                base_update_conf_value ${local_conf} DEPLOY_DIR ${DEPLOY_DIR}/${PN}
        fi
        if [ -n ${LOG_DIR} ] ; then
                base_update_conf_value ${local_conf} LOG_DIR ${LOG_DIR}/${PN}
        fi
        if [ -n ${XT_SHARED_ROOTFS_DIR} ] ; then
                base_update_conf_value ${local_conf} XT_SHARED_ROOTFS_DIR ${XT_SHARED_ROOTFS_DIR}
        fi
        if [ -n ${XT_SSTATE_CACHE_MIRROR_DIR} ] ; then
                base_update_conf_value ${local_conf} XT_SSTATE_CACHE_MIRROR_DIR ${XT_SSTATE_CACHE_MIRROR_DIR}
        fi
        base_update_conf_value ${local_conf} INHERIT buildhistory "+"
        base_update_conf_value ${local_conf} BUILDHISTORY_COMMIT 1
    fi
}

build_yocto_add_bblayer() {
    cd ${S}

    source poky/oe-init-build-env && bitbake-layers add-layer ${S}/${XT_BBLAYER}
}

python do_configure() {
    bb.build.exec_func("build_yocto_configure", d)
    # add layers to bblayers.conf
    layers = (d.getVar("XT_QUIRCK_BB_ADD_LAYER") or "").split()
    if layers:
        for layer in layers:
            bb.debug(1, "Adding to bblayers.conf: " + str(layer.split()))
            d.setVar('XT_BBLAYER', str(layer))
            bb.build.exec_func("build_yocto_add_bblayer", d)
}

do_compile() {
    cd ${S}
    source poky/oe-init-build-env
    bitbake ${XT_BB_IMAGE_TARGET}
}

do_populate_sdk() {
    if [ -n ${XT_POPULATE_SDK} ] ; then
        cd ${S}
        source poky/oe-init-build-env && bitbake ${XT_BB_IMAGE_TARGET} -c populate_sdk
    fi
}

do_collect_build_history() {
    cd ${S}
    BUILDHISTORY_DIR=${DEPLOY_DIR}/${PN}/buildhistory
    install -d ${BUILDHISTORY_DIR}
    source poky/oe-init-build-env
    buildhistory-collect-srcrevs -a > ${BUILDHISTORY_DIR}/build-versions.inc
}

do_populate_sstate_cache() {
    if [ -n ${XT_SSTATE_CACHE_MIRROR_DIR} ] ; then
        install -d ${XT_SSTATE_CACHE_MIRROR_DIR}
        cp -rf ${SSTATE_DIR} ${XT_SSTATE_CACHE_MIRROR_DIR}
    fi
}

do_build() {
    :
}
