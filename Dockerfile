FROM ubuntu:trusty
MAINTAINER Takahiro Shizuki <shizu@futuregadget.com>

ENV HOST_HOME $HOME
ENV CLIENT_HOME /root


# set package repository mirror
RUN sed -i.bak -e "s%http://archive.ubuntu.com/ubuntu/%http://ftp.iij.ad.jp/pub/linux/ubuntu/archive/%g" /etc/apt/sources.list
RUN apt-get update -o Acquire::ForceIPv4=true

# fundamental
RUN apt-get install -y p7zip bzip2 curl man nkf ntp psmisc software-properties-common tmux unzip vim wget
RUN apt-get clean

# developmemt relations
RUN apt-get install -y cmake exuberant-ctags git make tig
RUN apt-get clean

# git latest
RUN add-apt-repository -y ppa:git-core/ppa
RUN apt-get update -o Acquire::ForceIPv4=true
RUN apt-get install -y git

# x window relations
RUN apt-get -y install insserv sysv-rc-conf python-appindicator xterm xfce4-terminal leafpad vim-gtk
RUN apt-get clean


# ansible2
RUN apt-get -y install python-dev python-pip
RUN pip install ansible markupsafe
RUN mkdir -p $CLIENT_HOME/ansible
RUN bash -c 'echo 127.0.0.1 ansible_connection=local > $CLIENT_HOME/ansible/localhost'



# Option, User Environment

# japanese packages
RUN wget -t 1 -q https://www.ubuntulinux.jp/ubuntu-ja-archive-keyring.gpg -O- | apt-key add -
RUN wget -t 1 -q https://www.ubuntulinux.jp/ubuntu-jp-ppa-keyring.gpg -O- | apt-key add -
RUN wget -t 1 https://www.ubuntulinux.jp/sources.list.d/wily.list -O /etc/apt/sources.list.d/ubuntu-ja.list
RUN apt-get update -o Acquire::ForceIPv4=true
RUN apt-get -y install language-pack-ja-base language-pack-ja fonts-ipafont-gothic dbus-x11
RUN apt-get -y install ibus-skk
RUN apt-get -y install skkdic skkdic-cdb skkdic-extra skksearch skktools
RUN update-locale LANG=ja_JP.UTF-8 LANGUAGE=ja_JP:ja
RUN apt-get clean

ENV LANG ja_JP.UTF-8
ENV LC_ALL ja_JP.UTF-8
ENV LC_CTYPE ja_JP.UTF-8

ENV GTK_IM_MODULE ibus
ENV QT_IM_MODULE ibus
ENV XMODIFIERS @im=ibus
RUN echo "ibus-daemon -drx" >> $CLIENT_HOME/.bashrc


# diff merge
WORKDIR $CLIENT_HOME/src
RUN wget -t 1 http://download-us.sourcegear.com/DiffMerge/4.2.0/diffmerge_4.2.0.697.stable_amd64.deb
RUN dpkg -i diffmerge_4.2.0.697.stable_amd64.deb


# nvm and node.js
ENV NODE_VERSION v4.2.6
RUN git clone https://github.com/creationix/nvm.git $CLIENT_HOME/.nvm
RUN echo "if [[ -s $CLIENT_HOME/.nvm/nvm.sh ]] ; then source $CLIENT_HOME/.nvm/nvm.sh ; fi" >> $CLIENT_HOME/.bashrc
RUN bash -c 'source $CLIENT_HOME/.nvm/nvm.sh && nvm install $NODE_VERSION && nvm use $NODE_VERSION && nvm alias default $NODE_VERSION && ln -s $CLIENT_HOME/.nvm/versions/node/$NODE_VERSION/bin/node /usr/bin/node && ln -s $CLIENT_HOME/.nvm/versions/node/$NODE_VERSION/bin/npm /usr/bin/npm'

## install npm packages
RUN npm -g --ignore-scripts install spawn-sync
RUN npm -g --unsafe-perm install node-sass
RUN npm -g install less
RUN npm -g install stylus
RUN npm -g install eslint


# Set Env
ENV SHELL /bin/bash
RUN mkdir $CLIENT_HOME/.ssh
RUN chmod 600 $CLIENT_HOME/.ssh
RUN git config --global push.default simple

# Set Timezone
RUN cp /usr/share/zoneinfo/Japan /etc/localtime

# OpenGL env
env LIBGL_ALWAYS_INDIRECT 1
#env DRI_PRIME 1


# Install SBCL from the tarball binaries.
RUN wget -t 1 http://prdownloads.sourceforge.net/sbcl/sbcl-1.3.1-x86-64-linux-binary.tar.bz2	 -O $CLIENT_HOME/src/sbcl.tar.bz2 \
&&    mkdir $CLIENT_HOME/src/sbcl_src \
&&    tar jxvf $CLIENT_HOME/src/sbcl.tar.bz2 --strip-components=1 -C $CLIENT_HOME/src/sbcl_src/ \
&&    cd $CLIENT_HOME/src/sbcl_src \
&&    sh install.sh \
&&    cd $CLIENT_HOME/src/ \
&&    rm -rf $CLIENT_HOME/src/sbcl_src/

RUN mkdir $CLIENT_HOME/src/sbcl
WORKDIR $CLIENT_HOME/src/sbcl
ADD install.lisp install.lisp
RUN wget -t 1 http://beta.quicklisp.org/quicklisp.lisp
RUN sbcl --non-interactive --load $CLIENT_HOME/src/sbcl/install.lisp


# options
# .bashrc
RUN bash -c 'echo alias ls=\"ls --color\" >> $CLIENT_HOME/.bashrc'


# git config
ENV GIT_USER_NAME "Takahiro Shizuki"
ENV GIT_USER_EMAIL "shizu@futuregadget.com"
RUN git config --global user.name $GIT_USER_NAME
RUN git config --global user.email $GIT_USER_EMAIL


# docker run
ENV DISPLAY 192.168.99.1:0
ADD terminalrc $CLIENT_HOME/.config/xfce4/terminal/
WORKDIR /opt/src
ADD ansible /opt/src/ansible
#RUN ansible-playbook -v --extra-vars "taskname=packages_option" ansible/playbook.yml
RUN ansible-playbook -v --extra-vars "taskname=ricty_diminished-font" ansible/playbook.yml
WORKDIR $CLIENT_HOME
CMD xfce4-terminal --tab --command "bash -c 'cd /mnt/dockerfile_root; ./run_ansible.sh; read'"
