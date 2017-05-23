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
                base_update_conf_value ${local_conf} SSTATE_DIR ${SSTATE_DIR}
        fi
        if [ -n ${IMAGE_ROOTFS} ] ; then
                base_update_conf_value ${local_conf} IMAGE_ROOTFS ${IMAGE_ROOTFS}/${PN}
        fi
        if [ -n ${DEPLOY_DIR} ] ; then
                base_update_conf_value ${local_conf} DEPLOY_DIR ${DEPLOY_DIR}/${PN}
        fi
        if [ -n ${XT_SHARED_ROOTFS_DIR} ] ; then
                base_update_conf_value ${local_conf} XT_SHARED_ROOTFS_DIR ${XT_SHARED_ROOTFS_DIR}
        fi
        base_update_conf_value ${local_conf} INHERIT buildhistory "+"
        base_update_conf_value ${local_conf} BUILDHISTORY_COMMIT 1
    fi
}

build_yocto_add_bblayer() {
    cd ${S}

    source poky/oe-init-build-env && bitbake-layers add-layer ${S}/${XT_BBLAYER}
}

build_yocto_bbappend_kernel_provider() {
    cd ${S}

    source poky/oe-init-build-env
    provider=`bitbake virtual/kernel -e | grep "^[^\#]*PREFERRED_PROVIDER_virtual/kernel" | grep -oP '"[^"]*"'`
    path=`eval bitbake-layers show-recipes -f ${provider} | grep -E '\.bb$' | head -1`
    filename=`echo $(basename "$path") | sed -E 's/_.*/_%.bbappend/g'`
    mkdir -p "${S}/${XT_QUIRCK_KERNEL_DEPLOY_RECIPE_DIR}"
    bbappend_fname="${S}/${XT_QUIRCK_KERNEL_DEPLOY_RECIPE_DIR}/${filename}"
    echo "DEPLOYDIR=\"${XT_SHARED_ROOTFS_DIR}/boot/${XT_QUIRCK_KERNEL_DEPLOY_IMAGE_DIR}\"" > "${bbappend_fname}"
    echo "MODULE_TARBALL_DEPLOY=\"0\"" >> "${bbappend_fname}"
}

python build_yocto_do_kernel_deploy_bbappend_generate() {
    shared_deploy_dir = d.getVar("XT_SHARED_ROOTFS_DIR") or ""
    if not shared_deploy_dir:
        return
    kernel_recipe_path = d.getVar("XT_QUIRCK_KERNEL_DEPLOY_RECIPE_DIR") or ""
    if not kernel_recipe_path:
        return
    bb.build.exec_func('build_yocto_bbappend_kernel_provider', d)
}

build_yocto_kernel_import_generate() {
    cd ${S}

    mkdir -p "${S}/${XT_QUIRCK_KERNEL_IMPORT_RECIPE_DIR}"
    bb_fname="${S}/${XT_QUIRCK_KERNEL_IMPORT_RECIPE_DIR}/import-kernels.bb"
    #echo "DEPLOYDIR=\"${XT_SHARED_ROOTFS_DIR}/boot/${XT_QUIRCK_KERNEL_DEPLOY_IMAGE_DIR}\"" > "${bb_fname}"
    #echo "MODULE_TARBALL_DEPLOY=\"0\"" >> "${bbappend_fname}"
    echo \
    "dfsdfsdfs
     sdfsdfsdfsd" \
    > "${bb_fname}"
}

python build_yocto_do_kernel_import_generate() {
    shared_deploy_dir = d.getVar("XT_SHARED_ROOTFS_DIR") or ""
    if not shared_deploy_dir:
        return
    kernel_recipe_path = d.getVar("XT_QUIRCK_KERNEL_IMPORT_RECIPE_DIR") or ""
    if not kernel_recipe_path:
        return
    bb.build.exec_func('build_yocto_kernel_import_generate', d)
}

addtask configure after do_unpack
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

addtask compile after do_configure
do_compile() {
    cd ${S}
    source poky/oe-init-build-env && bitbake ${XT_BB_IMAGE_TARGET}
}

addtask build after do_compile
do_build() {
    :
}

EXPORT_FUNCTIONS do_kernel_deploy_bbappend_generate do_kernel_import_generate