name 'Telstra Programmable Network Test CAT'
rs_ca_ver 20161221
short_description "Telstra Programmable Network Test CAT"

import "sys_log"
import "plugins/telstra_programmable_network"

output "topologies" do
  label "Topologies"
  category "Outputs"
  default_value $tops_str
end

output "my_topology" do
  label "My Topology"
  category "Outputs"
  default_value $my_top_str
end

output "deployment" do
  label "Deployment"
  category "Outputs"
  default_value $deployment_str
end

operation "launch" do
  label "Launch"
  definition "gen_launch"
  output_mappings do {
      $topologies => $tops_str,
      $my_topology => $my_top_str,
      $deployment => $deployment_str
  } end
end

define gen_launch() return @tops, @my_top, @endpoints, $endpoints_str, $endpoint_str, $my_top_str, $tops_str do
  #$deployment_str = @@deployment.description
  #call start_debugging()
  # $tops_str = to_json(to_object(@tops))
  
  #call sys_log.detail("@tops: " + to_json(to_object(@tops)))

  # get the customer uuid
  @tops = telstra_programmable_network.topology.list()
  $customer_uuid = to_object(@tops)["details"][1]["customer_uuid"]
  call sys_log.detail("$customer_uuid: " + $customer_uuid)
  
  #@endpoint = telstra_programmable_network.endpoint.show(uuid: "cfc3ff96-5557-4aa2-931b-8e6e11ba48d6")

  # get all the endpoints for this customer
  @endpoints = telstra_programmable_network.endpoint.list(customer_uuid: $customer_uuid)
  $endpoints_str = to_json(to_object(@endpoints))
  call sys_log.detail("$endpoints_str: " + $endpoints_str)
  
  
  
  # sub task_label: "retrieving all endpoints' ports", on_error: skip do
  #   @port = @endpoints.port
  # end
  # call stop_debugging()
  # $port_str = to_json(to_object(@port))
  # call sys_log.detail("$port_str: " + $port_str)

  # iterate through the endpoints and log the details
  foreach @endpoint in @endpoints do
    call start_debugging()
    $endpoint_str = to_s(to_object(@endpoint))
    call stop_debugging()
    call sys_log.detail("$endpoint_str: " + $endpoint_str)
  end
  
  # @endpoints = telstra_programmable_network.endpoint.list(customer_uuid: $customer_uuid)  
  # $endpoints_str = to_json(to_object(@endpoints))

  # @endpoint = telstra_programmable_network.endpoint.show(uuid: "8f85450f-e5ca-4341-8406-6305abfc2ce5")
  
  # call stop_debugging()
  # call start_debugging()
  # Don't iterate on the resources as this takes ages. Perhaps it is doing an
  # additional API call for each one?
  # $tops = to_object(@tops)
  # 
  # foreach $top in $tops do
  #   $tops_str = $tops_str + $top["name"] + ", " + $top["status"] + ", " + $top["uuid"] + "\n"
  # end
  # call stop_debugging()

  # call start_debugging()
  # @my_top = telstra_programmable_network.topology.show(uuid: "9a8ee002-e05f-4a83-af92-013a36d7bb26")
  # call stop_debugging()

  # call start_debugging()
  # #$my_top_str = to_json(to_object(@my_top))
  # $my_top = to_object(@my_top)
  # $my_top_str = $my_top["details"][0]["name"] + "{ status: " + $my_top["details"][0]["status"] + ", uuid: " + $my_top["details"][0]["uuid"] + " }"
  # call stop_debugging()
end

# define error_endpoint do
#   $_error_behavior = "skip"
# end

define start_debugging() do
  if $$debugging == false || logic_and($$debugging != false, $$debugging != true)
    initiate_debug_report()
    $$debugging = true
  end
end

define stop_debugging() do
  if $$debugging == true
    $debug_report = complete_debug_report()
    call sys_log.detail($debug_report)
    $$debugging = false
  end
end