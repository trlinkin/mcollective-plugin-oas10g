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
        apps.reject!{&:empty?}

        apps.map! do |app|
          app.strip!
          name = app.split(/\n/).first
          name.strip
        end

        reply[:results]
      end
    end
  end
end

