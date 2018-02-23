name 'TPN Unattached Endpoints Policy'
rs_ca_ver 20161221
short_description "![TPN Logo](https://demostaticimages.blob.core.windows.net/icons/tpn_icon.png =85x64)\n
Telstra Programmable Network Policy which looks for unattached VNF Endpoints. 
The policy delivers a report via email and optionally deleted the VNFs."

import "sys_log"
import "plugins/telstra_programmable_network"

parameter "param_email" do
  category "Contact"
  label "Email addresses (separate with commas)"
  type "string"
end

parameter "param_action" do
  category "Endpoint"
  label "Endpoint Action"
  type "string"
  allowed_values "Report Only","Report and Delete"
  default "Report Only"
end

operation "launch" do
  label "Launch"
  definition "gen_launch"
end

define gen_launch() do
  #$deployment_str = @@deployment.description
  #call start_debugging()
  # $tops_str = to_json(to_object(@tops))
  
  #call sys_log.detail("@tops: " + to_json(to_object(@tops)))

  # get the customer uuid
  # @tops = telstra_programmable_network.topology.list()
  # $customer_uuid = to_object(@tops)["details"][1]["customer_uuid"]
  # call sys_log.detail("$customer_uuid: " + $customer_uuid)
  
  # run automated tests
  call unit_tests()


  
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

define unit_tests() do
  @topologies = telstra_programmable_network.topology.list()

  #####################
  # is_vnf test cases #
  #####################

  # Non-vnf endpoint: cfc3ff96-5557-4aa2-931b-8e6e11ba48d6
  @endpoint = telstra_programmable_network.endpoint.show(endpointuuid: "cfc3ff96-5557-4aa2-931b-8e6e11ba48d6")
  call endpoint_uuid(@endpoint) retrieve $endpoint_uuid
  call is_vnf(@endpoint) retrieve $is_vnf
  call sys_log.detail("Endpoint " + $endpoint_uuid + " is NOT a VNF. is_vnf returned " + to_s($is_vnf))
  assert logic_not($is_vnf)

  # VNF Endpoint: b8190e24-42af-4934-ae2a-619e3594d1d7
  @endpoint = telstra_programmable_network.endpoint.show(endpointuuid: "b8190e24-42af-4934-ae2a-619e3594d1d7")
  call endpoint_uuid(@endpoint) retrieve $endpoint_uuid
  call is_vnf(@endpoint) retrieve $is_vnf
  call sys_log.detail("Endpoint " + $endpoint_uuid + " is a VNF. is_vnf returned " + to_s($is_vnf))
  assert $is_vnf

  # Unattached VNF Endpoint: a7fe9533-f7ea-4e81-b07d-3a152f0907bb
  @endpoint = telstra_programmable_network.endpoint.show(endpointuuid: "a7fe9533-f7ea-4e81-b07d-3a152f0907bb")
  call endpoint_uuid(@endpoint) retrieve $endpoint_uuid
  call is_unattached(@topologies, @endpoint) retrieve $is_unattached
  call sys_log.detail("Endpoint " + $endpoint_uuid + " is_unattached returned " + to_s($is_unattached))
  assert $is_unattached
end

# loop through and log the details of all endpoints
define check_for_unattached_endpoints(@endpoints) do
  foreach @endpoint in @endpoints do
    call start_debugging()
    # we can't access some endpoints so need to catch the error caused by the
    # 4xx response
    sub on_error: error_endpoint(@endpoint) do
      @target_endpoint = @endpoint.show()
      call endpoint_uuid(@target_endpoint) retrieve $endpointuuid
      # $endpoint_str = to_s(to_object(@target_endpoint))
      # call sys_log.detail("$endpoint_str: " + $endpoint_str)
      
      call is_unattached(@target_endpoint) retrieve $is_unattached
      if $is_unattached
        # add to email report
        # optionally remove the endpoint
        call sys_log.detail("Endpoint " + $endpointuuid + " has unattached VNFs")
      end
    end
    call stop_debugging()
  end
end

define is_unattached(@topologies, @endpoint) return $is_unattached do
  call endpoint_uuid(@endpoint) retrieve $endpoint_uuid
  
  call is_vnf(@endpoint) retrieve $is_vnf
  call is_deployed(@endpoint) retrieve $is_deployed
  call no_vports_have_links(@endpoint) retrieve $no_vports_have_links
  call on_any_topologies(@topologies, @endpoint) retrieve $on_any_topologies

  $is_unattached = false
  if $is_vnf && $is_deployed && $no_vports_have_links
    $is_unattached = true
  end
end
 
# check if the given endpoint is a VNF
define is_vnf(@endpoint) return $is_vnf do
  $port = to_object(@endpoint)["details"][0]["port"][0]
  $port_keys = keys($port)
  $is_vnf = contains?($port_keys, ["vnf_status"])
end

define is_deployed(@endpoint) return $is_deployed do
  if to_object(@endpoint)["details"][0]["port"][0]["vnf_status"] == "deployed"
    $is_deployed = true
  else
    $is_deployed = false
  end
end

define no_vports_have_links(@endpoint) return $no_vports_have_links do
  $vports = to_object(@endpoint)["details"][0]["port"][0]["vport"]
  $no_vports_have_links = true
  foreach $vport in $vports do
    if $vport["linkuuid"] != ""
      $no_vports_have_links = false
    end
  end
end

define on_any_topologies(@topologies, @endpoint) return $on_any_topologies do
  # TODO call https://penapi.pacnetconnect.com/ttms/1.0.0/topology_tag/${taguuid}/objects
  $on_any_topologies = false
  for @topology in @topologies
    if to_object(@topology)["details"]
    $on_any_topologies = true
  end
end

define endpoint_uuid(@endpoint) return $endpointuuid do
  $port = to_object(@endpoint)["details"][0]["port"][0]
  $endpointuuid = $port["endpointuuid"]
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