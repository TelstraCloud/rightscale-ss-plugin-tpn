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
  call start_debugging()
  @top = telstra_programmable_network.topology.show("uuid": "eee39575-1b2a-4dab-9732-200ac8a6f86c")
  call stop_debugging()
  call sys_log.detail("@top: " + to_s(to_object(@top)))
  call start_debugging()
  @top_objects = @top.objects()
  call stop_debugging()
  call sys_log.detail("@top.objects(): " + to_s(to_object(@top_objects)))

  #@top_objects = @top.objects()
  # @topology_objects = telstra_programmable_network.topology_objects.show("uuid": "eee39575-1b2a-4dab-9732-200ac8a6f86c")
  # call stop_debugging()
  #@top_objects = telstra_programmable_network.topology.objects("uuid": "eee39575-1b2a-4dab-9732-200ac8a6f86c")
  # call sys_log.detail("@top_objects: " + to_s(to_object(@top_objects)))

  # get the customer uuid
  # @tops = telstra_programmable_network.topology.list()
  # $customer_uuid = to_object(@tops)["details"][1]["customer_uuid"]
  # call sys_log.detail("$customer_uuid: " + $customer_uuid)
  
  # retrieve a specific endpoint
  # @endpoint = telstra_programmable_network.endpoint.show(endpointuuid: "4e3c449f-b548-4bcc-8410-35ba2255a1af")
  # call is_vnf(@endpoint)
  
  # get all the endpoints for this customer
  # @endpoints = telstra_programmable_network.endpoint.list(customer_uuid: $customer_uuid)
  # call sys_log.detail("@endpoints: " + to_s(to_object(@endpoints)))
  # call list_endpoints(@endpoints)

  ##### TODO clean up below ######

  # iterate through the endpoints and log the details

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

# check if the given endpoint is a VNF
define is_vnf(@endpoint) do
  #call sys_log.detail("$endpoint_str: " + to_s(to_object(@endpoint)))
  $port = to_object(@endpoint)["details"][0]["port"][0]
  $endpointuuid = $port["endpointuuid"]
  $vporttype = $port["vport"][0]["vporttype"]
  
  if $vporttype == "vnf"
    call sys_log.detail("endpoint " + $endpointuuid + " is a VNF!")
  else
    call sys_log.detail("endpoint " + $endpointuuid + " is not a VNF")
  end

end

# loop through and log the details of all endpoints
define list_endpoints(@endpoints) do
  foreach @endpoint in @endpoints do
    call start_debugging()
    # we can't access some endpoints so need to catch the error caused by the
    # 4xx response
    sub on_error: error_endpoint(@endpoint) do
      @target_endpoint = @endpoint.show()
      $endpoint_str = to_s(to_object(@target_endpoint))
      call sys_log.detail("$endpoint_str: " + $endpoint_str)      
    end
    call stop_debugging()
  end
end

# some endpoints return 4xx responses so we need to catch that when looping
# through all
define error_endpoint(@endpoint) do
  $endpoint_str = to_s(to_object(@endpoint))
  call sys_log.detail("ERROR: $endpoint_str: " + $endpoint_str)
  $_error_behavior = "skip"
end

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