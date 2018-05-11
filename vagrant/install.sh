#!/usr/bin/bash
# Description: Vagrant django1.8 install script for Centos7 to mimic bluehost shared hosting
echo Creating user.
# ==========================
useradd -m -pwaasup andrew
# disable vagrant user
usermod -L vagrant
mv /home/vagrant/bashrc /home/andrew/.bashrc
chown andrew:andrew /home/andrew/.bashrc

echo Enabling andrew sudo.
# ==========================
echo "%andrew ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/andrew

echo Enabling passwordless login.
# =========================================
su - andrew -c "mkdir -m 700 /home/andrew/.ssh"
mv /home/vagrant/host_id_rsa.pub /home/andrew/.ssh/authorized_keys
chmod 700 /home/andrew/.ssh/authorized_keys
chown andrew:andrew /home/andrew/.ssh/authorized_keys

if [ -f /vagrant/id_rsa ] && [ -f /vagrant/id_rsa.pub ] ; then
    echo "Adding canned RSA keys (for github.com)."
    # =============================================
    mv /vagrant/id_rsa /home/andrew/.ssh/id_rsa
    mv /vagrant/id_rsa.pub /home/andrew/.ssh/id_rsa.pub
    chmod 700 /home/andrew/.ssh/id_rsa*
    chown andrew:andrew /home/andrew/.ssh/id_rsa*
else
    echo Creating RSA keys.
    # =====================
    su - andrew -c 'ssh-keygen -f ~/.ssh/id_rsa -q -N ""'
fi

echo Installing YUM packages.
# ===========================
yum --enablerepo=updates clean metadata
yum install -y -q $(cat /home/vagrant/requirements.yum)

echo Configuring VIM.
# ===================
mv /home/vagrant/.vimrc /home/andrew/
mv /home/vagrant/.vim /home/andrew/
chown -R andrew:andrew /home/andrew/.vim
chown andrew:andrew /home/andrew/.vimrc

echo Configuring git.
# ===================
mv /home/vagrant/.gitconfig /home/andrew/
chown andrew:andrew /home/andrew/.gitconfig

echo Configuring screen.
# ======================
# NOTE: (screen installed by default).
mv /home/vagrant/screenrc /home/andrew/.screenrc
chown andrew:andrew /home/andrew/.screenrc

echo Installing miniconda and python3.
# ====================================
su - andrew -c 'wget -nv https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh'
su - andrew -c 'bash ~/miniconda.sh -b -p /home/andrew/conda'
su - andrew -c '/home/andrew/conda/bin/conda create -y -q --prefix /home/andrew/conda/envs/dj18 python=3.6'

echo Installing pip packages.
# ===========================
mv /home/vagrant/requirements.pip /home/andrew
chown andrew:andrew /home/andrew/requirements.pip
su - andrew -c 'source /home/andrew/conda/bin/activate dj18 && pip install -q -r /home/andrew/requirements.pip'

echo Configuring and enabling Apache2 http server.
# ================================================
yum -y -q install httpd httpd-devel mod_fcgid gcc policycoreutils-python
mv /vagrant/dj18_httpd.conf /etc/httpd/conf.d/dj18_httpd.conf
mkdir /home/andrew/public_html
mv /home/vagrant/htaccess /home/andrew/public_html/.htaccess
mv /home/vagrant/basesite.fcgi /home/andrew/public_html
mv /home/vagrant/app.py /home/andrew/public_html
chown -R andrew:andrew /home/andrew/public_html
usermod -a -G andrew apache  # add group andrew to user apache
chmod g+rx /home/andrew
chmod g+rx /home/andrew/public_html

echo Placating selinux before starting httpd.
# ===========================================
# see https://www.serverlab.ca/tutorials/linux/web-servers-linux/configuring-selinux-policies-for-apache-web-servers/
# and https://blog.tinned-software.net/apache-document-root-in-users-home-directory-with-selinux/
# and https://wiki.centos.org/HowTos/SELinux#head-faa96b3fdd922004cdb988c1989e56191c257c01
#setenforce permissive  # uncomment this if having selinux issues then use `sudo audit2allow -a -m httpd` and `sudo audit2allow -a -M httpd` to generate a new httpd.pp file
restorecon -Rv /etc/httpd/conf.d/
semanage fcontext -a -t httpd_sys_rw_content_t "/home/andrew/conda/envs/dj18(/.*)?"
restorecon -R /home/andrew/conda/envs/dj18
semanage fcontext -a -t httpd_sys_rw_content_t "/home/andrew/public_html(/.*)?"
restorecon -Rv /home/andrew/public_html/
setsebool -P httpd_enable_homedirs true
setsebool -P httpd_unified true
setsebool -P httpd_tmp_exec true
setsebool -P httpd_read_user_content true
semodule -i /vagrant/httpd.pp

echo Starting httpd.
# ==================
systemctl enable httpd
systemctl start httpd

echo "Creating a new Django project.  Creating a placeholder for an additional site.  Adding secret files;)"
# ==========================================================================================================
# see https://simpleisbetterthancomplex.com/2015/11/30/starting-a-new-django-18-project.html
su - andrew -c "cd /home/andrew/public_html && /home/andrew/conda/envs/dj18/bin/django-admin startproject basesite"
su - andrew -c "mkdir /home/andrew/public_html/other_cool_site"
su - andrew -c "echo 'supersecrets' > /home/andrew/public_html/other_cool_site/secrets.txt"
su - andrew -c "cp /home/andrew/public_html/app.py /home/andrew/public_html/other_cool_site/app.py"
