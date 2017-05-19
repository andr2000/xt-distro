# HACK: oe-init-build-env cannot be run directly as Yocto uses /bin/sh
# which by default is dash on Ububntu which is a problem for
# oe-init-build-env script. Use bash directly

bash_run_configure () {
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

bash_add_bblayer () {
    cd ${S}

    source poky/oe-init-build-env && bitbake-layers add-layer ${S}/${XT_BBLAYER}
}

bash_get_kernel_provider_fname () {
    cd ${S}

    source poky/oe-init-build-env &&
    provider=`bitbake virtual/kernel -e | grep "^[^\#]*PREFERRED_PROVIDER_virtual/kernel" | grep -oP '"[^"]*"'` &&
    provider_fname=`eval bitbake-layers show-recipes -f ${provider} | grep -E '\.bb$' | head -1` &&
    XT_KERNEL_RECIPE_FILE=$(basename "$provider_fname") &&
    export XT_KERNEL_RECIPE_FILE
}

def generate_kernel_deploy_bbappend(d):
    import os

    shared_deploy_dir = d.getVar("XT_SHARED_ROOTFS_DIR") or ""
    if not shared_deploy_dir:
        return
    kernel_recipe_path = d.getVar("XT_QUIRCK_KERNEL_DEPLOY_RECIPE_PATH") or ""
    if not kernel_recipe_path:
        return
    if not os.path.exists(shared_deploy_dir):
        os.makedirs(shared_deploy_dir)
    if not os.path.exists(kernel_recipe_path):
        os.makedirs(kernel_recipe_path)
    bb.build.exec_func("bash_get_kernel_provider_fname", d)
    recipe_fname = d.getVar('XT_KERNEL_RECIPE_FILE') or ""

addtask configure after do_unpack
python do_configure() {
    bb.build.exec_func("bash_run_configure", d)
    # add layers to bblayers.conf
    layers = (d.getVar("XT_QUIRCK_BB_ADD_LAYER") or "").split()
    if layers:
        for layer in layers:
            bb.debug(1, "Adding to bblayers.conf: " + str(layer.split()))
            d.setVar('XT_BBLAYER', str(layer))
            bb.build.exec_func("bash_add_bblayer", d)
}

addtask compile after do_configure
do_compile () {
    cd ${S}
    source poky/oe-init-build-env && bitbake ${XT_BB_IMAGE_TARGET}
}

addtask build after do_compile
do_build () {
    :
}
