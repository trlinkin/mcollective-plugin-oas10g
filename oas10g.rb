module MCollective
  module Agent
    class Oas10g<RPC::Agent

      action "container_status" do

        container_list = String.new
        err = String.new
        status = run("/u03/devmidr2/opmn/bin/opmnctl status -noheaders -rsep ',' -fsep '|' -fmt %typ%prt%sta", :stdout => container_list, :stderr => err)

        if not status == 0
          fail!("Execution fail with error: #{err}")
        end

        records = container_list.split(',')
        containers = Hash.new

        records.map do |container|
          con = container.split('|')

          containers[con[1]] = {:type => con[0], :status => con[2]}
        end

        # TODO - We may need to sanitze the input data, as in to_upper it or something
        if request[:type]
          containers.select! do |name,data|
            data[:type] == request[:type]
          end
        end

        if request[:name]
          containers.select! do |name|
            name == request[:name]
          end
        end

        reply[:results] = containers
      end

      ###### Application Status Action
      action :app_status do

        options = "-co #{request[:container]}"
        if request[:application]
          options += " -a #{request[:application]}"
        end

        apps_raw = String.new
        err = String.new
        status = run("/u03/devmidr2/dcm/bin/dcmctl listApplications #{options}", :stdout => apps_raw, :stderr => err)

        if not status == 0
          fail!("Execution fail with error: #{err}")
        end


        apps = apps_raw.split(/^\d/)
        apps.reject!{ |x| x.to_s.empty? }

        apps.map! do |app|
          app.strip!
          name = app.split(/\n/).first
          name.strip
        end

        reply[:results]
      end

      ######## Application Deployment Action
      action "deploy" do

        # TODO - Check that file exists here
        # Initialize variables
        rd, wr = IO.pipe

        # Trying to expose the orphaned proc id the main process
        child = fork do
          # Close the read end since it will only write
          rd.close

          grandchild = fork do
            # Close write pipe since we don't need it, if not
            # the read in the main proc will block until this proc
            # is finished
            wr.close

            begin
              # Run our arbitrary shell commands
              #status = run("/bin/su - ora_ias -c \"/u03/devmidr2/dcm/bin/dcmctl deployApplication -file #{request[:ear_file]}  -a #{request[:a_name]} -co #{request[:c_name]}\"", :stdout => out, :stderr => err)
              exec("/bin/su - ora_ias -c \"/u03/devmidr2/dcm/bin/dcmctl deployApplication -file #{request[:ear_file]}  -a #{request[:a_name]} -co #{request[:c_name]}\"")
            rescue SystemCallError
              1
            end
          end

          # Detach the grandchild
          if grandchild
            Process.detach(grandchild)
          end

          # Write grandchild pid to pipe and close to end writing
          wr.write grandchild
          wr.close
        end

        # Detach the child
        if child
          Process.detach(child)
        end

        # Close the writing end
        wr.close

        # Read grandchild pid value from pipe and close reading end
        grandchild = rd.read
        rd.close

        # End forking stuff.  Double forking is officially over.

        if grandchild then
          reply[:pid] = grandchild
          reply[:summary] = "Application is being deployed.  Please wait."
        else
          reply[:summary] = "Application failed to be deployed.  Please check the nonexistent log files."
          fail!("Execution failed - deployment not started")
        end

      end

      # This is Dan's UNDEPLOY action
      # Input:  c_name (container name)
      #         a_name (application name)
      # Output: pid (process identifier)
      #         summary (status/summary)
      action "undeploy" do

        # Initialize variables
        rd, wr = IO.pipe

        # Trying to expose the orphaned proc id the main process
        child = fork do
          # Close the read end since it will only write
          rd.close

          grandchild = fork do
            # Close write pipe since we don't need it, if not
            # the read in the main proc will block until this proc
            # is finished
            wr.close

            begin
              # Run our arbitrary shell commands
              #status = run("/bin/su - ora_ias -c \"/u03/devmidr2/dcm/bin/dcmctl undeployApplication -a #{request[:a_name]} -co #{request[:c_name]}\"", :stdout => what, :stderr => err)
              exec("/bin/su - ora_ias -c \"/u03/devmidr2/dcm/bin/dcmctl undeployApplication -a #{request[:a_name]} -co #{request[:c_name]}\"")
            rescue SystemCallError
              puts "There was an error executing the command. Check the nonexistent log files."
            end
          end

          # Detach the grandchild
          if grandchild
            Process.detach(grandchild)
          end

          # Write grandchild pid to pipe and close to end writing
          wr.write grandchild
          wr.close

          # This first child still has the TTY of the parent, uncomment to see the
          # output show up after the main proc is done.
          #sleep 1
          #puts "The child of a child (you mean grandchild?) PID is #{grandchild}"

        end

        # Detach the child
        if child
          Process.detach(child)
        end

        # Close the writing end
        wr.close

        # Read grandchild pid value from pipe and close reading end
        grandchild = rd.read
        rd.close
        # End forking stuff.  Double forking is officially over.

        # Return grandchild's pid

        # Return summary
        if grandchild then
          reply[:pid] = grandchild
          reply[:summary] = "Application is being undeployed.  Please wait."
        else
          reply[:summary] = "Application failed to be undeployed.  Please check the nonexistent log files."
          fail!("Execution failed - deployment not started")
        end

      end

      # This is Dan's CONTAINER_START action
      # Input:  c_name (container name)
      # Output: summary (status/summary)
      action "container_start" do

        # Initialize variables
        err = ""
        out = ""

        # Consider making this a forking function as well since it hovers at the 1.5-2 minute runtime mark
        status = run("/bin/su - ora_ias -c \"/u03/devmidr2/opmn/bin/opmnctl startproc process-type=#{request[:c_name]}\"", :stdout => out, :stderr => err)

        # Return summary
        if status == 0 then
          reply[:summary] = "Container started successfully. Return code #{status}."
        elsif status == 150 then
          reply[:summary] = "Container is already running."
        else
          reply[:summary] = "Container failed to start with the following message(s): #{out} -- #{err} -- Return code #{status}."
        end

      end

      ################################## - Container Action
      action "container_stop" do

        # Initialize variables
        err = ""
        out = ""

        status = run("/bin/su - ora_ias -c \"/u03/devmidr2/opmn/bin/opmnctl stopproc process-type=#{request[:c_name]}\"", :stdout => out, :stderr => err)

        if status == 0 then
          reply[:summary] = "Container stopped successfully. Return code #{status}."
        elsif status == 150 then
          reply[:summary] = "Container was not running."
        else
          reply[:summary] = "Container failed to start with the following message(s): #{out} -- #{err} -- Return code #{status}."
        end

      end

      # This is Dan's PIDCHECK action
      # Input:  pid (process identifier)
      # Output: status (is it running?)
      action "pidcheck" do

        # Initialize variables
        pgid = 0

        begin
          pgid = Process.getpgid( request[:pid] )
          true
        rescue Errno::ESRCH
          puts "Methinks we have run into an error!  Check the nonexistent log files!"
          false
        end

        # Return status
        if pgid == 0 then
          reply[:status] = "Process is not running."
          reply[:status_b] = false
        else
          reply[:status] = "Process is still running."
          reply[:status_b] = true
        end
      end
    end
  end
end

