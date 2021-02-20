#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

mkdir -p /var/log/nginx/

yum -y install libpng12 libpng12.so.0

rm -fr /srv/iform/app/*

# provision app code
wget "https://iform-dst.s3.amazonaws.com/iform-master.zip" -O ~/iform.zip
unzip ~/iform.zip -d ./iform-tmp
mv ./iform-tmp/*/* /srv/iform/app/

# provision RDS TLS CA
wget ${rds_ca_2019_location} -O ${local_ca_2019_location}

chown -R ec2-user:ec2-user /srv/iform/app/
rm -fr ./iform-tmp ./iform.zip

pushd /srv/iform/app
/home/ec2-user/.rbenv/shims/bundle install --without development test
popd

cat <<EOF >/srv/iform/app/.env
export IGNORE_STRIPE=1
export DEBUG=0

export APP_HOST="${app_host}"

export SPP_LOG_FILE="${spp_log_file}"

export SMTP_ADDRESS="${smtp_address}"
export SMTP_PORT="${smtp_port}"
export SMTP_PASSWORD="${smtp_password}"
export SMTP_USERNAME="${smtp_username}"

export FROM_EMAIL="${from_email}"

export SECRET_KEY_BASE="${secret_key_base}"
export STRIPE_KEY="${stripe_key}"
export SECRET_TOKEN="${secret_token}"

export DB_HOST="${rds_endpoint}"
export DB_USERNAME="${rds_username}"
export DB_PORT=${rds_port}
export DB_PASSWORD="${rds_password}"
export DB_DATABASE="${rds_database}"

export DATALAKE_MOUNT_POINT="${datalake_mount_point}"

export DEVISE_SECRET_KEY="${devise_secret_key}"

export LOCAL_CA_2019_LOCATION="${local_ca_2019_location}"

EOF

cat <<EOF >/tmp/script.rb

unless Company.all.any?
  school = Company.create!(subdomain: "${subdomain}", title: "${school_title}", email: "${from_email}", phone: "${school_phone}", secret_phrase: "${school_secret_phrase}")
  admin = Admin.create!(first_name: "Admin", last_name: "User", email: "${from_email}", password: "${admin_password}", password_confirmation: "${admin_password}")
  school.generate_config!
  admin.companies << school
end

EOF

mkdir -p /opt/aws/amazon-cloudwatch-agent/bin

yum -y install amazon-cloudwatch-agent

cat <<EOF >/opt/aws/amazon-cloudwatch-agent/bin/config.json
{
     "agent": {
         "run_as_user": "root"
     },
     "logs": {
         "logs_collected": {
             "files": {
                 "collect_list": [
                     {
                         "file_path": "${spp_log_file}",
                         "log_group_name": "iForm-Application-Logs",
                         "log_stream_name": "{instance_id}"
                     }
                 ]
             }
         }
     }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s

/bin/systemctl status amazon-cloudwatch-agent.service

# create a directory to mount our efs volume to
mkdir -p /mnt/efs
# mount the efs volume
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_dns_name}:/ /mnt/efs
# create fstab entry to ensure automount on reboots
su -c "echo '${efs_dns_name}:/ /mnt/efs nfs4 defaults,vers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0' >> /etc/fstab"

# provision iForm user data as ec2-user
cd /srv/iform/app
export PATH=/home/ec2-user/.rbenv/shims:/home/ec2-user/.rbenv/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/home/ec2-user/.local/bin:/home/ec2-user/bin
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bundle exec rails r /tmp/script.rb

systemctl restart nginx
systemctl restart puma
