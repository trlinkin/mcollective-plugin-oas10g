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

action :app_status, :description => "Retrieves current status of an OAS application" do
  input :name,
        :promt       => "Application Name",
        :description => "Name of the OAS Application to retrieve status for",
        :optional    => :true,
        :type        => :string,
        :validation  => '^[a-zA-Z\-_\d]+$',
        :maxlength   => 30

  input :container,
        :prompt      => "Container Name",
        :description => "Name of the OAS container to retrieve application statuses for",
        :optional    => false,
        :type        => :string,
        :validation  => '^[a-zA-Z\-_\d]+$',
        :maxlength   => 30

  output :results,
         :description => "Application Status Results as hash, empty if no results are found",
         :display_as  => "Application Status Results"
end

action "deploy", :description => "Deploys specified application" do

    input :ear_file,
        :prompt         => "EAR File",
        :description    => "EAR file to be deployed (include path)",
        :type           => :string,
        :validation     => '^[a-zA-Z\/.-_\d]+$',
        :optional       => false,
        :maxlength      => 30

    input :c_name,
        :prompt         =>  "Container Name",
        :description    =>  "OAS Name for the container",
        :type           =>  :string,
        :optional       =>  false,
        :validation     =>  '^[a-zA-Z\-_\d]+$',
        :maxlength      =>  30

    input :a_name,
        :prompt         =>  "Application Name",
        :description    =>  "OAS Name for the application",
        :type           =>  :string,
        :optional       =>  false,
        :validation     =>  '^[a-zA-Z\-_\d]+$',
        :maxlength      =>  30

    output :pid,
        :display_as     =>  "Process Identifier",
        :description    =>  "Process Identifier of deploy process"

    output :summary,
        :display_as     =>  "Status/Summary",
        :description    =>  "Status/Summary of Deploy task"
end

# This is Dan's UNDEPLOY action
action "undeploy", :description => "Undeploys specified application" do
    input :c_name,
        :prompt         =>  "Container Name",
        :description    =>  "OAS Name for the container",
        :type           =>  :string,
        :optional       =>  false,
        :validation     =>  '^[a-zA-Z\-_\d]+$',
        :maxlength      =>  30

    input :a_name,
        :prompt         =>  "Application Name",
        :description    =>  "OAS Name for the application",
        :type           =>  :string,
        :optional       =>  false,
        :validation     =>  '^[a-zA-Z\-_\d]+$',
        :maxlength      =>  30

    output :pid,
        :display_as     =>  "Process Identifier",
        :description    =>  "Process Identifier of undeploy process"

    output :summary,
        :display_as     =>  "Status/Summary",
        :description    =>  "Status/Summary of Undeploy task"
end

# This is Dan's CONTAINER_START action
action "container_start", :description => "Starts the specified container" do
    input :c_name,
        :prompt         =>  "Container Name",
        :description    =>  "OAS Name for the container",
        :type           =>  :string,
        :optional       =>  false,
        :validation     =>  '^[a-zA-Z\-_\d]+$',
        :maxlength      =>  30

    output :summary,
        :display_as     =>  "Status/Summary",
        :description    =>  "Status/Summary of Container Start task"
end

action "container_stop", :description => "Starts the specified container" do
    input :c_name,
        :prompt         =>  "Container Name",
        :description    =>  "OAS Name for the container",
        :type           =>  :string,
        :optional       =>  false,
        :validation     =>  '^[a-zA-Z\-_\d]+$',
        :maxlength      =>  30

    output :summary,
        :display_as     =>  "Status/Summary",
        :description    =>  "Status/Summary of Container Stop task"
end

# This is Dan's PIDCHECK action
action "pidcheck", :description => "Checks to see if the specified PID exists (if a process is running)" do
    input :pid,
        :prompt         =>  "Process Identifier",
        :description    =>  "Number that identifies a specific running process",
        :type           =>  :integer,
        :optional       =>  false

    output :status,
        :display_as     =>  "Status",
        :description    =>  "Whether a process with specified PID is running"

    output :status_b,
        :display_as     =>  "Boolean Status",
        :description    =>  "Status of PIDCHECK function in boolean form"
end
