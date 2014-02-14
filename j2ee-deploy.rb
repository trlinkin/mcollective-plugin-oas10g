#!/opt/puppet/bin/ruby

require 'mcollective'
require 'set'

include MCollective::RPC

container = ''
application = ''
ear_location =''

failed_nodes = Array.new
ready_nodes = Array.new

oas = rpcclient('oas10g')

# Create filters for the nodes we will run against
#oas.class_filter 'role::oas::eq_app' ### Sample class name for class the manages EQ
#oas.fact_filter 'org_env', 'dev'
#oas.fact_filter 'org_site', 'fake_place'
#oas.fact_filter 'osfamily', 'SunOS'

# Run Container Stop Action

puts "Running contains stop actions..."
stop_results = oas.container_stop(:c_name => container)

stop_results.each do |result|
  if result[:statuscode] == 0
    ready_nodes << result[:sender]
  else
    failed_nodes << result[:sender]
  end
end

# Reset Filtering and apply custom group based on 'ready_nodes'

oas.reset_filter
oas.discover(:nodes => ready_nodes)

# Run the undeploy actions
puts "Running undeploy actions..."
undeploy_results = oas.undeploy(:c_name => container, :a_name => application)
undeploy_results = Set.new(undeploy_results)

undeploy_results.each do |result|
  unless result[:statuscode] == 0
    undeploy_results.delete(result)
    failed_nodes << result[:sender]
    ready_nodes.delete(result[:sender])
  end
end

until undeploy_results.empty?
  # lets give it all time to bake a little
  print '.'
  sleep 10

  undeploy_results.each do |result|
    oas.reset_filter
    oas.discover(:nodes => result[:sender])

    undeploy_status = oas.pidcheck(:pid => result[:pid])

    if undeploy_status.first
      unless undeploy_status.first[:status_b]
        undeploy_results.delete(result)
      end
    end
  end
end
print "\n"

# Check overall Application Status - Remove failures

oas.reset_filter
oas.discover(:nodes => ready_nodes)

app_status_results = oas.app_status(:name => application, :container => container)

app_status_results.each do |result|
  unless result[:results].empty?
    failed_nodes << result[:sender]
    ready_nodes.delete(result[:sender])
  end
end

# Deploy application to ready nodes

oas.reset_filter
oas.discover(:nodes => ready_nodes)

# Run the Deploy actions
 puts "Deploying Application..."
deploy_results = oas.deploy(:c_name => container, :a_name => application, :ear_file => ear_file)
deploy_results = Set.new(deploy_results)

deploy_results.each do |result|
  unless result[:statuscode] == 0
    deploy_results.delete(result)
    failed_nodes << result[:sender]
    ready_nodes.delete(result[:sender])
  end
end
puts "Entering wait loop for deployment tracking..."
until deploy_results.empty?
  # lets give it all time to bake a little
  print '.'
  sleep 10

  deploy_results.each do |result|
    oas.reset_filter
    oas.discover(:nodes => result[:sender])

    deploy_status = oas.pidcheck(:pid => result[:pid])

    if deploy_status.first
      unless deploy_status.first[:status_b]
        deploy_results.delete(result)
      end
    end
  end
end
print "\n"

# Check overall Application Status - Remove failures
puts "Checking to see if application was installed..."
oas.reset_filter
oas.discover(:nodes => ready_nodes)

app_status_results = oas.app_status(:name => application, :container => container)

app_status_results.each do |result|
  unless result[:results]
    failed_nodes << result[:sender]
    ready_nodes.delete(result[:sender])
  end
end

# Run Container Start

puts "Starting Containers\n"
oas.reset_filter
oas.discover(:nodes => ready_nodes)

start_results = oas.container_start(:c_name => container)
puts "--- All Containers should be started\n\n"

start_results.each do |result|
  unless result[:statuscode] == 0
    ready_nodes.delete(result[:sender])
    failed_nodes << result[:sender]
    puts "Failed Container Start Node: #{result[:sender]}\n"
  end
end


############# Final Tally
#
#

puts "Nodes Sucessful :\n#{ready_nodes.join("\n")}"
puts "###############################################"
puts "Failed Nodes :\n#{failed_nodes.join("\n")}"

