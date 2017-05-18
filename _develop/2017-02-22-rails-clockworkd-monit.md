---
layout: post
title:  Rails Clockworkd gem with capistrano and monit
date:   2017-02-22 14:31:18
tags: 
- monit
- capistrano
- clockworkd
- rails
related_id: 14
meta_description: Clockworkd with monit and capistrano
excerpt: Clockworkd with monit and capistrano
---

1. Add gem
  {%highlight ruby%}
  gem 'daemons'
  gem 'clockwork'
  {%endhighlight%}

{:start="2"}
2. Create **clock.rb**

{%highlight ruby%}
require 'clockwork'
require_relative './config/boot'
require_relative './config/environment'
module Clockwork

  every(1.minute, 'check:time') do

    #some logic to execute each minute

  end

end
{%endhighlight%}

{:start="3"}
3. Create task to control clockwork daemon. **lib/capistrano/tasks/clockworkd.rake**

{%highlight ruby%}

namespace :clockwork do
  desc 'Stop clockwork'
  task :stop do
    on roles(clockwork_roles) do
      if test("[ -d #{current_path} ]")
        within release_path do
          with rails_env: fetch(:rails_env) do
            begin
              if test("[ -d #{current_path} ]")
                execute :bundle, :exec, :clockworkd, :"stop -c #{current_path}/clock.rb --pid-dir=#{fetch(:clockwork_pid_file)}  -l #{fetch(:clockwork_log_file)} -d #{current_path} --log-dir=#{shared_path}/log"
              else
                true
              end
            rescue => ex
              puts ex.message
            end
          end
        end
      end
      true
    end
  end

  desc 'Start clockwork'
  task :start do
    on roles(clockwork_roles) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          if test("[ -d #{current_path} ]")
            execute :bundle, :exec, :clockworkd, :"start -c #{current_path}/clock.rb --pid-dir=#{fetch(:clockwork_pid_file)}  -l #{fetch(:clockwork_log_file)} -d #{current_path} --log-dir=#{shared_path}/log"
          else
            true
          end
        end
      end
    end
  end

  desc 'Restart clockwork'
  task :restart do
    on roles(clockwork_roles) do
      stop
      start
    end
  end

  def clockwork_roles
    fetch(:clockwork_roles, :app)
  end
end
{%endhighlight%}

{:start="4"}
4. Configure clockworkd options on deploy. **config/deploy/staging.rb**

{%highlight ruby%}
set :clockwork_roles, [:worker]
set :clockwork_log_file, "#{shared_path}/log/clockwork.log"
set :clockwork_pid_file, "#{shared_path}/pids"
{%endhighlight%}

{:start="5"}
5. Deploy and start clockwork

{%highlight ruby%}
bundle exec cap staging clockwork:start
{%endhighlight%}

{:start="6"}
6. Install monit
{%highlight bash%}
sudo apt-get install monit
{%endhighlight%}

{:start="7"}
7. Create clockwork service template. **config/deploy/templates/clockwork_init.erb**

{%highlight bash%}
#!/bin/bash

### BEGIN INIT INFO
# Provides: clockworkd
# Required-Start: $remote_fs $syslog
# Required-Stop: $remote_fs $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Manage clockworkd daemon
# Description: Start, stop, restart clockworkd daemon for a specific application.
### END INIT INFO
set -e

# Feel free to change any of the following variables for your app:
TIMEOUT=${TIMEOUT-60}
APP_ROOT=<%= current_path %>
PID=<%= fetch(:clockwork_pid_file) %>/clockworkd.clock.pid

# rvm
CMD_START="cd <%= current_path %>; RAILS_ENV=<%=fetch(:rails_env)%>  rvm <%= fetch(:rvm1_ruby_version) %> do bundle exec clockworkd start -c <%=current_path%>/clock.rb --pid-dir=<%=fetch(:clockwork_pid_file)%> -l <%=fetch(:clockwork_log_file)%> -d <%=current_path%> --log-dir=<%=shared_path%>/log"
CMD_STOP="cd <%= current_path %>; RAILS_ENV=<%=fetch(:rails_env)%> rvm <%= fetch(:rvm1_ruby_version) %> do bundle exec clockworkd stop -c <%=current_path%>/clock.rb --pid-dir=<%=fetch(:clockwork_pid_file)%> -l <%=fetch(:clockwork_log_file)%> -d <%=current_path%> --log-dir=<%=shared_path%>/log"

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
run "$CMD_START"
;;
stop)
run "$CMD_STOP"
;;
*)
echo >&2 "Usage: $0
<start|stop>"
exit 1
;;
esac

{%endhighlight%}

{:start="7"}
7. Create clockwork service tasks. **lib/capistrano/tasks/clockwork.rake**

{%highlight ruby%}
namespace :clockwork do
  task :setup do
    on roles(clockwork_roles) do |host|
      template 'clockwork_init.erb', '/tmp/clockworkd_init'
      execute :chmod, '+x', '/tmp/clockworkd_init'
      sudo :mv, "/tmp/clockworkd_init /etc/init.d/#{clockwork_service}"
      sudo "update-rc.d -f #{clockwork_service} defaults"
    end

  end
  %w[start stop restart].each do |command|
    desc "#{command} clockwork"
    task command do
      on roles(:app) do
        sudo "/etc/init.d/#{clockwork_service} #{command}"
      end
    end
  end
  def clockwork_roles
    fetch(:clockwork_roles, :app)
  end
  def clockwork_service
    "clockworkd_#{fetch(:application)}_#{fetch(:stage)}"
  end
end
{%endhighlight%}

{:start="8"}
8.  Template for monit controling clockwork daemon. **config/deploy/templates/monit_clockworkd.erb

{%highlight bash%}
check process <%="clockworkd_#{fetch(:application)}_#{fetch(:stage)}"%> with pidfile <%=fetch(:clockwork_pid_file)%>/clockworkd.clock.pid
  start program = "/etc/init.d/<%="clockworkd_#{fetch(:application)}_#{fetch(:stage)}"%> start" with timeout 60 seconds
  stop program  = "/etc/init.d/<%="clockworkd_#{fetch(:application)}_#{fetch(:stage)}"%> stop"
{%endhighlight%}

{:start="9"}
9. Monit tasks. **lib/capistrano/tasks/monit.rake**

{%highlight ruby%}

namespace :monit do
  task :setup_clockwork do
    on roles(clockwork_roles) do |host|
      template 'monit_clockwork.erb', '/tmp/monit_clockwork'
      sudo :mv, '/tmp/monit_clockwork', "/etc/monit/conf-available/clockworkd_#{fetch(:application)}_#{fetch(:stage)}"
    end
  end
  task :enable_clockwork do
    on roles(clockwork_roles) do |host|
      sudo :ln, '-s', "/etc/monit/conf-available/clockworkd_#{fetch(:application)}_#{fetch(:stage)}", "/etc/monit/conf-enabled/clockworkd_#{fetch(:application)}_#{fetch(:stage)}"
    end
  end
  %w[start stop restart reload].each do |command|
    desc "#{command} monit"
    task command do
      on roles(:app) do
        sudo "service monit #{command}"
      end
    end
  end
end
{%endhighlight%}