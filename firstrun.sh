#!/bin/bash

psqlpass=PASSWORD
psqlhost=localhost
psqlport=port

# === Do not modify anything in this section ===

# Regenerate the SSH host key
/bin/rm /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server

# Copy over config files
cp /srv/gitlab/config/gitlab.yml /home/git/gitlab/config/gitlab.yml

cp /srv/gitlab/config/database.yml /home/git/gitlab/config/database.yml
chown git:git /home/git/gitlab/config/database.yml && chmod o-rwx /home/git/gitlab/config/database.yml
sed -i -e "s/PASSWORD/$psqlpass/g" /home/git/gitlab/config/database.yml
sed -i -e "s/HOSTNAME/$psqlhost/g" /home/git/gitlab/config/database.yml
sed -i -e "s/PORT/$psqlport/g" /home/git/gitlab/config/database.yml

# Link data directories to /srv/gitlab/data
rm -R /home/git/gitlab/tmp && ln -s /srv/gitlab/data/tmp /home/git/gitlab/tmp && chown -R git /srv/gitlab/data/tmp/ && chmod -R u+rwX  /srv/gitlab/data/tmp/
rm -R /home/git/.ssh && ln -s /srv/gitlab/data/ssh /home/git/.ssh && chown -R git:git /srv/gitlab/data/ssh && chmod -R 0700 /srv/gitlab/data/ssh && chmod 0700 /home/git/.ssh
chown -R git:git /srv/gitlab/data/gitlab-satellites
chown -R git:git /srv/gitlab/data/repositories && chmod -R ug+rwX,o-rwx /srv/gitlab/data/repositories && chmod -R ug-s /srv/gitlab/data/repositories/
find /srv/gitlab/data/repositories/ -type d -print0 | xargs -0 chmod g+s

# Change repo path in gitlab-shell config
sed -i -e 's/\/home\/git\/repositories/\/srv\/gitlab\/data\/repositories/g' /home/git/gitlab-shell/config.yml

# ==============================================
# === Delete this section if restoring data from previous build ===

#cd /home/git/gitlab
#su git -c "bundle exec rake gitlab:setup force=yes RAILS_ENV=production"
#sleep 5
#su git -c "bundle exec rake db:seed_fu RAILS_ENV=production"

# ================================================================

# Manually create /var/run/sshd
mkdir /var/run/sshd

# Delete firstrun script
rm /srv/gitlab/firstrun.sh
