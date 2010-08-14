require 'config/environment'

set :application, "errbit"
set :repository,  "http://github.com/jdpace/errbit.git"

set :scm, :git
set :scm_verbose, true
set(:current_branch) { `git branch`.match(/\* (\S+)\s/m)[1] || raise("Couldn't determine current branch") }
set :branch, defer { current_branch }

set :user, :deploy
set :use_sudo, false
set :ssh_options,      { :forward_agent => true }
default_run_options[:pty] = true

set :deploy_to, "/var/www/apps/#{application}"
set :deploy_via, :remote_cache
set :copy_cache, true
set :copy_exclude, [".git"]
set :copy_compression, :bz2

role :web, Errbit::Config.host
role :app, Errbit::Config.host
role :db,  Errbit::Config.host, :primary => true

after 'deploy:update_code', 'bundler:install'

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

namespace :bundler do
  task :symlink_vendor, :roles => :app, :except => { :no_release => true } do
    shared_gems = File.join(shared_path,'vendor','bundler_gems')
    release_gems = "#{latest_release}/vendor/"
    run("mkdir -p #{shared_gems} && ln -nfs #{shared_gems} #{release_gems}")
  end
  
  task :install, :rolse => :app do
    bundler.symlink_vendor
    run("cd #{release_path} && bundle install vendor/bundler_gems --without development test")
  end
end