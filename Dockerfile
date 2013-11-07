FROM ubuntu

ENV DEBIAN_FRONTEND noninteractive

RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -s /bin/true /sbin/initctl

RUN apt-get update; apt-get -y install lsb-release software-properties-common

# Add Sources
RUN add-apt-repository -y ppa:git-core/ppa;\
  echo deb http://us.archive.ubuntu.com/ubuntu/ $(lsb_release -cs) universe multiverse >> /etc/apt/sources.list;\
  echo deb http://us.archive.ubuntu.com/ubuntu/ $(lsb_release -cs)-updates main restricted universe >> /etc/apt/sources.list;\
  echo deb http://security.ubuntu.com/ubuntu $(lsb_release -cs)-security main restricted universe >> /etc/apt/sources.list

# Run upgrades
RUN  echo udev hold | dpkg --set-selections;\
  echo initscripts hold | dpkg --set-selections;\
  echo upstart hold | dpkg --set-selections;\
  apt-get update;\
  apt-get -y upgrade

# Install dependencies
RUN apt-get install -y build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libreadline-dev libncurses5-dev libffi-dev curl git-core openssh-server redis-server checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev logrotate libpq-dev sudo git 

# Install Ruby
RUN mkdir /tmp/ruby;\
  cd /tmp/ruby;\
  curl ftp://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p247.tar.gz | tar xz;\
  cd ruby-2.0.0-p247;\
  chmod +x configure;\
  ./configure;\
  make;\
  make install;\
  gem install bundler --no-ri --no-rdoc

# Create Git user
RUN adduser --disabled-login --gecos 'GitLab' git

# Install GitLab Shell
RUN cd /home/git;\
  su git -c "git clone https://github.com/gitlabhq/gitlab-shell.git";\
  cd gitlab-shell;\
  su git -c "git checkout v1.7.4";\
  su git -c "cp config.yml.example config.yml";\
  sed -i -e 's/localhost/127.0.0.1:8080/g' config.yml;\
  su git -c "./bin/install"

# Install GitLab
RUN cd /home/git;\
  su git -c "git clone https://github.com/gitlabhq/gitlabhq.git gitlab";\
  cd /home/git/gitlab;\
  su git -c "git checkout 6-2-stable"

# Misc configuration stuff
RUN cd /home/git/gitlab;\
  chown -R git tmp/;\
  chown -R git log/;\
  chmod -R u+rwX log/;\
  chmod -R u+rwX tmp/;\
  su git -c "mkdir /home/git/gitlab-satellites";\
  su git -c "mkdir tmp/pids/";\
  su git -c "mkdir tmp/sockets/";\
  chmod -R u+rwX tmp/pids/;\
  chmod -R u+rwX tmp/sockets/;\
  su git -c "mkdir public/uploads";\
  chmod -R u+rwX public/uploads;\
  su git -c "cp config/unicorn.rb.example config/unicorn.rb";\
  su git -c "cp config/initializers/rack_attack.rb.example config/initializers/rack_attack.rb";\
  su git -c 'sed -ie "s/# config.middleware.use Rack::Attack/config.middleware.use Rack::Attack/" config/application.rb';\
  su git -c "git config --global user.name 'GitLab'";\
  su git -c "git config --global user.email 'gitlab@localhost'";\
  su git -c "git config --global core.autocrlf input"

RUN cd /home/git/gitlab;\
  gem install charlock_holmes --version '0.6.9.4';\
  su git -c "bundle install --deployment --without development test mysql aws"

# Install init scripts
RUN cd /home/git/gitlab;\
  cp lib/support/init.d/gitlab /etc/init.d/gitlab;\
  chmod +x /etc/init.d/gitlab;\
  update-rc.d gitlab defaults 21

RUN cd /home/git/gitlab;\
  cp lib/support/logrotate/gitlab /etc/logrotate.d/gitlab

EXPOSE 8080
EXPOSE 22

ADD . /srv/gitlab

RUN chmod +x /srv/gitlab/start.sh;\
  chmod +x /srv/gitlab/firstrun.sh

CMD ["/srv/gitlab/start.sh"]
