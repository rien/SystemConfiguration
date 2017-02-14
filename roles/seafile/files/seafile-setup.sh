#!/bin/bash
set -eo pipefail

# Arguments needed:
#TOPDIR
#DEFAULT_CONF_DIR
#SEAFILE_DATA_DIR
#DEST_SETTINGS_PY
#SQLSEAFILEPW
#SQLROOTPW
#IP_OR_DOMAIN
#SEAFILE_ADMIN
#SEAFILE_ADMIN_PW
#PYTHON

cd $TOPDIR

mkdir -p ${DEFAULT_CONF_DIR}

# -------------------------------------------
# Create ccnet, seafile, seahub conf using setup script
# -------------------------------------------

./setup-seafile-mysql.sh auto -u seafile -w ${SQLSEAFILEPW} -r ${SQLROOTPW}

# Fix service url
eval "sed -i 's/^SERVICE_URL.*/SERVICE_URL = https:\/\/${IP_OR_DOMAIN}/' ${DEFAULT_CONF_DIR}/ccnet.conf"

# -------------------------------------------
# Configure Seafile WebDAV Server(SeafDAV)
# -------------------------------------------
sed -i 's/enabled = .*/enabled = true/' ${DEFAULT_CONF_DIR}/seafdav.conf
sed -i 's/fastcgi = .*/fastcgi = true/' ${DEFAULT_CONF_DIR}/seafdav.conf
sed -i 's/share_name = .*/share_name = \/seafdav/' ${DEFAULT_CONF_DIR}/seafdav.conf

# -------------------------------------------
# Backup check_init_admin.py befor applying changes
# -------------------------------------------
cp ${INSTALLPATH}/check_init_admin.py ${INSTALLPATH}/check_init_admin.py.backup


# -------------------------------------------
# Set admin credentials in check_init_admin.py
# -------------------------------------------
eval "sed -i 's/= ask_admin_email()/= \"${SEAFILE_ADMIN}\"/' ${INSTALLPATH}/check_init_admin.py"
eval "sed -i 's/= ask_admin_password()/= \"${SEAFILE_ADMIN_PW}\"/' ${INSTALLPATH}/check_init_admin.py"

# -------------------------------------------
# Start and stop Seafile eco system. This generates the initial admin user.
# -------------------------------------------
${INSTALLPATH}/seafile.sh start
${INSTALLPATH}/seahub.sh start
sleep 2
${INSTALLPATH}/seahub.sh stop
sleep 1
${INSTALLPATH}/seafile.sh stop


# -------------------------------------------
# Restore original check_init_admin.py
# -------------------------------------------
mv ${INSTALLPATH}/check_init_admin.py.backup ${INSTALLPATH}/check_init_admin.py

if ${IS_PRO}; then
    PRO_PY=${INSTALLPATH}/pro/pro.py
    $PYTHON ${PRO_PY} setup --mysql --mysql_host=127.0.0.1 --mysql_port=3306 --mysql_user=seafile --mysql_password=${SQLSEAFILEPW} --mysql_db=seahub_db
    sed -i 's/enabled = false/enabled = true/' ${TOPDIR}/conf/seafevents.conf
fi
