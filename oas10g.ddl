metadata :name        => "OAS 10gR2 Application Control",
         :description => "Agent to control and deploy Oracle Application Server 10g Applications",
         :author      => "FDA",
         :version     => "1.0",
         :license     => "None",
         :url         => "None",
         :timeout     => 60

action "container_status", :description => "Retrieves current status of OAS container" do
  input :type,
        :prompt      => "Container Type",
        :description => "OAS Type for the container",
        :type        => :list,
        :optional    => true,
        :list        => ['oc4j']

   input :name,
        :prompt      => "Container Name",
        :description => "OAS Name for the container",
        :type        => :string,
        :validation  => '^[a-zA-Z\-_\d]+$',
        :optional    => true,
        :maxlength   => 30

   output :results,
        :description => "Statuses of found containers",
        :display_as  => "Container Results"

end

