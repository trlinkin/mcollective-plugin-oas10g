module MCollective
  module Agent
    class Oas10g<RPC::Agent

      action "container_status" do

        container_list = []
        err = ""
        status = run("/u03/devmidr2/opmn/bin/opmnctl status -noheaders -rsep ',' -fsep '|' -fmt %typ%prt%sta", :stdout => container_list, :stderr => err)

        records = container_list.first.split(',')
        containers = Hash.new

        records.map do |container|
          con = container.split('|')

          containers[con[1]] = {:type => con[0], :status => con[2]}
        end

        if request[:name]
          containers.select! do |container|
            container == request[:name]
          end
        end

        reply[:results] = containers

      end


    end
  end
end

