---
layout: post
title:  Rails+Ember-cli Capistrano deploy
date:   2017-02-06 14:31:18
tags: 
- ember
- rails
related_id: 13
meta_description: Deploy rails + ember app with capistano
excerpt: Deploy rails + ember app with capistano
---

I. Server Setup

1. Create deployer account on server

{%highlight bash%}
adduser deployer
{%endhighlight%}

{:start="2"}
2. Add user to sudo group

{%highlight bash%}
gpasswd -a deployer sudo
{%endhighlight%}

{:start="3"}
3. Add ability to execute sudo without password

{%highlight bash%}
visudo
{%endhighlight%}

Add and save

{%highlight bash%}
deployer ALL=(ALL) NOPASSWD: ALL
{%endhighlight%}

{:start="4"}
4.  Add Public Key Authentication (On local machine)

{%highlight bash%}
ssh-copy-id -i PATH_TO_KEY deployer@SERVER_IP
{%endhighlight%}

{:start="5"}
5. Disable password based ssh login

{%highlight bash%}
nano /etc/ssh/sshd_config
{%endhighlight%}

Update following lines

{%highlight ruby%}
ChallengeResponseAuthentication no
PasswordAuthentication no
UsePAM no
{%endhighlight%}

Restart sshd daemon
{%highlight bash%}
service sshd restart
{%endhighlight%}

{:start="6"}
6. Create dirs

{%highlight bash%}
mkdir /www
chown deployer:deployer /www
{%endhighlight%}


II. Deploy config

{:start="1"}
1. Install gems

{%highlight ruby%}
group :development do
  gem 'capistrano', '~> 3.4.0'
  gem 'capistrano-rails'
  gem 'capistrano-bundler'
  gem 'capistrano-deploytags'
  gem 'rvm1-capistrano3', require: false
  gem 'capistrano-nginx-unicorn', github: 'timoshenkoav/capistrano-nginx-unicorn'
end
{%endhighlight%}

{%highlight bash%}
bundle install
bundle exec cap install
{%endhighlight%}

{:start="2"}
2. Configure deploy.rb

{%highlight ruby%}
lock '3.4.0'

set :application, 'APPLICATION_NAME'
set :repo_url, 'APPLICATION_GIT_URL'

set :branch, 'master'

set :deploy_to, "/var/www/#{fetch(:application)}"

set :scm, :git

set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/application.yml')

set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/uploads', 'stats')

set :rvm1_type, :user
set :rvm1_alias_name, "#{fetch(:application)}"
set :rvm1_ruby, 'RUBY_VERSION'
set :rvm1_ruby_version, "#{fetch(:rvm1_ruby)}@#{fetch(:rvm1_alias_name)}"

set :keep_releases, 2
namespace :setup do
  task :create_env do
    on roles(:all) do |host|
      execute :mkdir, '-p', "#{shared_path}/config"
      ask(:env_file, 'File to get env')
      upload! fetch(:env_file), "#{shared_path}/config/application.yml"
    end

  end
  task :create_db do
    on roles(:all) do |host|
      execute :mkdir, '-p', "#{shared_path}/config"
      ask(:env_file, 'File to get database.yml')
      upload! fetch(:env_file), "#{shared_path}/config/database.yml"
    end
  end
  task :create_secrets do
    on roles(:all) do |host|
      execute :mkdir, '-p', "#{shared_path}/config"
      ask(:env_file, 'File to get secrets.yml')
      upload! fetch(:env_file), "#{shared_path}/config/secrets.yml"
    end
  end
end

namespace :app do
  task :update_rvm_key do
    on roles(:all) do
      execute :gpg, '--keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3'
    end

  end
end
before 'rvm1:install:rvm', 'app:update_rvm_key'
{%endhighlight%}


  2.1 Configure Capfile

{%highlight ruby%}
require 'capistrano/setup'

require 'capistrano/deploy'
require 'rvm1/capistrano3'

require 'capistrano/nginx_unicorn'
require 'capistrano/bundler'
require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'
require 'capistrano/monit'
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
{%endhighlight%}

{:start="3"}
3. Configure config/deploy/production.rb
{%highlight ruby%}
role :app, %w(SERVER_IP)
role :web, %w(SERVER_IP)
role :db, %w(SERVER_IP)
role :worker, %w(SERVER_IP)

set :rails_env, 'production'

set :ssh_options, {
    user: 'deployer',
    keys: %w(PATH_TO_USER_KEY),
    forward_agent: true,
    auth_methods: %w(publickey)
}

#NGINX
set :templates_path, 'config/deploy/templates'
set :nginx_config_name, 'NGINX_CONFIG_FILE_NAME'
set :nginx_server_name, 'NGINX_SERVER_NAME'
set :nginx_pid, '/run/nginx.pid'

set :nginx_config_path, '/etc/nginx/sites-available'

set :unicorn_workers, 2
set :unicorn_user, 'deployer'
set :unicorn_log, "#{shared_path}/log/unicorn.log"
set :unicorn_config, "#{shared_path}/config/unicorn.rb"
set :unicorn_pid, "#{current_path}/tmp/pids/unicorn.pid"
set :unicorn_sock, "#{shared_path}/tmp/sockets/unicorn.sock"

{%endhighlight%}

{:start="4"}
4. Configure server templates

  4.1 deploy/templates/unicorn.rb.erb

{%highlight ruby%}
working_directory "<%= current_path %>"
pid "<%= fetch(:unicorn_pid) %>"
stderr_path "<%= fetch(:unicorn_log) %>"
stdout_path "<%= fetch(:unicorn_log) %>"

listen "<%= fetch(:unicorn_sock) %>"
worker_processes <%= fetch(:unicorn_workers) %>
timeout 600

preload_app true

before_exec do |server|
  ENV["BUNDLE_GEMFILE"] = "<%= current_path %>/Gemfile"
end

before_fork do |server, worker|
  # Disconnect since the database connection will not carry over
  if defined? ActiveRecord::Base
    ActiveRecord::Base.connection.disconnect!
  end

  # Quit the old unicorn process
  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end

  if defined?(Resque)
    Resque.redis.quit
  end

  sleep 1
end

after_fork do |server, worker|
  # Start up the database connection again in the worker
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
  end

  if defined?(Resque)
    Resque.redis = 'localhost:6379'
  end
end

{%endhighlight%}

  4.2 deploy/templates/unicorn_init.rb
{%highlight ruby%}
#!/bin/bash
### BEGIN INIT INFO
# Provides: unicorn
# Required-Start: $remote_fs $syslog
# Required-Stop: $remote_fs $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Manage unicorn server
# Description: Start, stop, restart unicorn server for a specific application.
### END INIT INFO
set -e

# Feel free to change any of the following variables for your app:
TIMEOUT=${TIMEOUT-60}
APP_ROOT=<%= current_path %>
PID=<%= fetch(:unicorn_pid) %>

# rvm
CMD="cd <%= current_path %>; rvm <%= fetch(:rvm1_ruby_version) %> do bundle exec unicorn -D -c <%= fetch(:unicorn_config) %> -E <%= fetch(:rails_env) %>"

AS_USER=<%= fetch(:unicorn_user) %>
set -u

OLD_PIN="$PID.oldbin"

sig () {
test -s "$PID" && kill -$1 `cat $PID`
}

oldsig () {
test -s $OLD_PIN && kill -$1 `cat $OLD_PIN`
}

run () {
if [ "$(id -un)" = "$AS_USER" ]; then
eval $1
else
su -c "$1" - $AS_USER
fi
}

case "$1" in
start)
sig 0 && echo >&2 "Already running" && exit 0
run "$CMD"
;;
stop)
sig QUIT && exit 0
echo >&2 "Not running"
;;
force-stop)
sig TERM && exit 0
echo >&2 "Not running"
;;
restart|reload)
sig USR2 && echo reloaded OK && exit 0
echo >&2 "Couldn't reload, starting '$CMD' instead"
run "$CMD"
;;
upgrade)
if sig USR2 && sleep 2 && sig 0 && oldsig QUIT
then
n=$TIMEOUT
while test -s $OLD_PIN && test $n -ge 0
do
printf '.' && sleep 1 && n=$(( $n - 1 ))
done
echo

if test $n -lt 0 && test -s $OLD_PIN
then
echo >&2 "$OLD_PIN still exists after $TIMEOUT seconds"
exit 1
fi
exit 0
fi
echo >&2 "Couldn't upgrade, starting '$CMD' instead"
run "$CMD"
;;
reopen-logs)
sig USR1
;;
*)
echo >&2 "Usage: $0
<start|stop|restart|upgrade|force-stop|reopen-logs>"
exit 1
;;
esac
{%endhighlight%}

  4.3 deploy/templates/nginx_conf.erb

{%highlight bash%}
upstream unicorn_<%= fetch(:nginx_config_name) %> {
server unix:<%= fetch(:unicorn_sock) %> fail_timeout=0;
}


server {

listen 80;

client_max_body_size 4G;
keepalive_timeout 10;

error_page 500 502 504 /500.html;
error_page 503 @503;

server_name <%= fetch(:nginx_server_name) %>;
root <%= current_path %>/public;
try_files $uri/index.html $uri @unicorn_<%= fetch(:nginx_config_name) %>;

gzip              on;
gzip_http_version 1.0;
gzip_disable      "MSIE [1-6]\.(?!.*SV1)";
gzip_buffers 4 16k;
gzip_comp_level 2;
gzip_min_length 0;
gzip_types text/plain text/css application/x-javascript text/xml application/xml application/xml+rss text/javascript application/json;
gzip_proxied any;

location @unicorn_<%= fetch(:nginx_config_name) %> {
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header Host $http_host;
proxy_redirect off;
add_header Access-Control-Allow-Origin *;
proxy_pass http://unicorn_<%= fetch(:nginx_config_name) %>;
# limit_req zone=one;
access_log <%= shared_path %>/log/nginx.access.log;
error_log <%= shared_path %>/log/nginx.error.log;
}

location ^~ /assets/ {
gzip_static on;
expires max;
add_header Cache-Control public;
add_header Access-Control-Allow-Origin *;
}

location = /50x.html {
root html;
}

location = /404.html {
root html;
}

location @503 {
error_page 405 = /system/maintenance.html;
if (-f $document_root/system/maintenance.html) {
rewrite ^(.*)$ /system/maintenance.html break;
}
rewrite ^(.*)$ /503.html break;
}

if ($request_method !~ ^(GET|HEAD|PUT|POST|DELETE|OPTIONS|PATCH)$ ){
return 405;
}

if (-f $document_root/system/maintenance.html) {
return 503;
}

}


{%endhighlight%}

{:start="5"}
5. Deploy setup

  5.1 Install RVM and ruby

{%highlight bash%}
 bundle exec cap production rvm1:install:rvm
 bundle exec cap production rvm1:install:ruby
{%endhighlight%}

  5.2 Create gemset

Edit file lib/capistrano/tasks/create_gemset.rake

{%highlight ruby%}
namespace :gemset do
  desc "Create an gemset for the given"
  task :create do
    on roles(fetch(:rvm1_roles, :all)) do
      within fetch(:release_path) do
        execute "#{fetch(:rvm1_auto_script_path)}/rvm-auto.sh",
                "rvm", "ruby-#{fetch(:rvm1_ruby)}",'do','rvm','gemset','create',
          fetch(:rvm1_alias_name)
      end
    end
  end
  before :create, 'deploy:updating'
  before :create, 'rvm1:hook'
end
{%endhighlight%}

{%highlight bash%}
 bundle exec cap production gemset:create
{%endhighlight%}

  5.3 Create alias

{%highlight bash%}
 bundle exec cap production rvm1:alias:create
{%endhighlight%}

  5.4 Install Bundler

Edit file lib/capistrano/tasks/install_bundle.rake

{%highlight ruby%}
namespace :bundle do
  desc "Create an gemset for the given"
  task :install do
    on roles(fetch(:rvm1_roles, :all)) do
      within release_path do
        execute "#{fetch(:rvm1_auto_script_path)}/rvm-auto.sh",fetch(:rvm1_ruby_version), "gem", "install", "bundler"
      end
    end
  end
  before :install, 'deploy:updating'
  before :install, 'rvm1:hook'
end
{%endhighlight%}

{%highlight bash%}
 bundle exec cap production bundle:install
{%endhighlight%}

  5.5 Push config and env

{%highlight bash%}
 bundle exec cap production setup:create_env
 bundle exec cap production setup:create_db
 bundle exec cap production setup:create_secrets
{%endhighlight%}

  5.6 Edit copied application.yml, database.yml and secrets.yml for on server

{:start="6"}
6. Install nginx and postgres

{%highlight bash%}
apt-get install nginx postgresql postgresql-contrib libpq-dev
{%endhighlight%}

{:start="7"}
7. Create postgres user

{%highlight bash%}
sudo -u postgres createuser -s appname
sudo -u postgres psql
\password appname
CREATE DATABASE DB_NAME owner appname;
\q
{%endhighlight%}

{:start="8"}
8. Deploy nginx and capistrano configuration

{%highlight bash%}
bundle exec cap production nginx:setup
bundle exec cap production unicorn:setup_initializer
bundle exec cap production unicorn:setup_app_config
{%endhighlight%}

{:start="9"}
9. Install requirements for ember

{%highlight bash%}
apt-get install nodejs nodejs-legacy npm
npm install -g bower
{%endhighlight%}

{:start="10"}
10. Deploy
{%highlight bash%}
bundle exec cap production deploy
{%endhighlight%}

{:start="11"}
11. Start
{%highlight bash%}
bundle exec cap production unicorn:start
{%endhighlight%}


{%highlight ruby%}

{%endhighlight%}


