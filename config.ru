#!/usr/bin/env ruby

# Try to load vendor-ed rhosync, otherwise load the gem
begin
  require 'vendor/rhosync/lib/rhosync/server'
  require 'vendor/rhosync/lib/rhosync/console/server'
rescue LoadError
  require 'rhosync/server'
  require 'rhosync/console/server'
end

# By default, turn on the resque web console
require 'resque/server'

ROOT_PATH = File.expand_path(File.dirname(__FILE__))

# Rhosync server flags
Rhosync::Server.disable :run
Rhosync::Server.disable :clean_trace
Rhosync::Server.enable  :raise_errors
Rhosync::Server.set     :secret,      '8a1da4ea1254231f35dedd847fddf3828b5e91df34acf4b9cadbd7ca90159fdbd59c5bede80eb3104031ed3e0bc97e837866f81b686202a4c54c507cef36a482'
Rhosync::Server.set     :root,        ROOT_PATH
Rhosync::Server.use     Rack::Static, :urls => ["/data"], :root => Rhosync::Server.root

# Load our rhosync application
require 'application'

# Setup the url map
run Rack::URLMap.new \
	"/"         => Rhosync::Server.new,
	"/resque"   => Resque::Server.new, # If you don't want resque frontend, disable it here
	"/console"  => RhosyncConsole::Server.new # If you don't want rhosync frontend, disable it here