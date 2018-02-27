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
  definition "launch"
end

define launch() do
  # used to collect errors such as endpoints that cannot be read
  $$errors = []
  
  # run automated tests
  # call unit_tests()

  call build_topologies_cache() retrieve $topologies, $all_topology_objects

  call check_for_unattached_endpoints($topologies, $all_topology_objects)
  
  # log any endpoints that the script was not authorized to view
  call sys_log.detail("ERRORS: " + to_s($$errors))
end

define unit_tests() do

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

  #########################
  # unattached test cases #
  #########################

  # Unattached VNF Endpoint: a7fe9533-f7ea-4e81-b07d-3a152f0907bb
  @endpoint = telstra_programmable_network.endpoint.show(endpointuuid: "a7fe9533-f7ea-4e81-b07d-3a152f0907bb")
  call endpoint_uuid(@endpoint) retrieve $endpoint_uuid
  call is_unattached($topologies, $all_topology_objects, @endpoint) retrieve $is_unattached
  call sys_log.detail("Endpoint " + $endpoint_uuid + " is unattached. is_unattached returned " + to_s($is_unattached))
  assert $is_unattached

  # Attached VNF Endpoint: b8190e24-42af-4934-ae2a-619e3594d1d7
  @endpoint = telstra_programmable_network.endpoint.show(endpointuuid: "b8190e24-42af-4934-ae2a-619e3594d1d7")
  call endpoint_uuid(@endpoint) retrieve $endpoint_uuid
  call is_unattached($topologies, $all_topology_objects, @endpoint) retrieve $is_unattached
  call sys_log.detail("Endpoint " + $endpoint_uuid + " is attached. is_unattached returned " + to_s($is_unattached))
  assert logic_not($is_unattached)

  #############################################
  # check_for_unattached_endpoints test cases #
  #############################################

  call check_for_unattached_endpoints($topologies, $all_topology_objects)
end

# loop through and log the details of all endpoints
define check_for_unattached_endpoints($topologies, $all_topology_objects) do
  # get the customer uuid
  $customer_uuid = $topologies["details"][0]["customer_uuid"]

  call sys_log.detail("$customer_uuid: " + $customer_uuid)
  @endpoints = telstra_programmable_network.endpoint.list(customer_uuid: $customer_uuid)
  
  call sys_log.detail("check_for_unattached_endpoints: Checking " +
    to_s(size(@endpoints)) + " endpoints for unattached VNFs")

  $unattached_endpoints = []
  foreach @endpoint in @endpoints do
    # we can't access some endpoints so need to catch the error caused by the
    # 4xx response
    sub on_error: error_endpoint(@endpoint) do
      @target_endpoint = @endpoint.show(endpointuuid: @endpoint.uuid)
      call endpoint_uuid(@target_endpoint) retrieve $endpointuuid
      call is_unattached($topologies, $all_topology_objects, @target_endpoint) retrieve $is_unattached
      if $is_unattached
        # add to email report
        # optionally remove the endpoint
        call sys_log.detail("check_for_unattached_endpoints: Endpoint " +
          $endpointuuid + " is an unattached VNF")
          $unattached_endpoints << to_object(@target_endpoint)
      end
    end
  end

  call sys_log.detail("check_for_unattached_endpoints: Completed checking " +
    to_s(size(@endpoints)) + " endpoints. " + to_s(size($unattached_endpoints)) +
    " were unattached VNFs")
  call sys_log.detail("check_for_unattached_endpoints: $unattached_endpoints " +
    to_s($unattached_endpoints))

end

# returns true if the given @endpoint is an unattached VNF
define is_unattached($topologies, $all_topology_objects, @endpoint) return $is_unattached do
  call endpoint_uuid(@endpoint) retrieve $endpoint_uuid
  
  call is_vnf(@endpoint) retrieve $is_vnf
  call is_deployed(@endpoint) retrieve $is_deployed
  call no_vports_have_links(@endpoint) retrieve $no_vports_have_links
  call on_any_topologies($topologies, $all_topology_objects, @endpoint) retrieve $on_any_topologies

  $is_unattached = false
  if $is_vnf && $is_deployed && $no_vports_have_links && logic_not($on_any_topologies)
    $is_unattached = true
  end
end
 
# returns true if the given endpoint is a VNF
define is_vnf(@endpoint) return $is_vnf do
  $port = to_object(@endpoint)["details"][0]["port"][0]
  $port_keys = keys($port)
  $is_vnf = contains?($port_keys, ["vnf_status"])
end

# returns true if the @endpoint is deployed
define is_deployed(@endpoint) return $is_deployed do
  if to_object(@endpoint)["details"][0]["port"][0]["vnf_status"] == "deployed"
    $is_deployed = true
  else
    $is_deployed = false
  end
end

# returns true if the given @endpoint has no vports with links
define no_vports_have_links(@endpoint) return $no_vports_have_links do
  $vports = to_object(@endpoint)["details"][0]["port"][0]["vport"]
  $no_vports_have_links = true
  foreach $vport in $vports do
    if $vport["linkuuid"] != ""
      $no_vports_have_links = false
    end
  end
end

# builds a cache of all the topology data so it doesn't need to be retrieved
# for each endpoint that is checked
define build_topologies_cache() return $topologies, $all_topology_objects do
  @topologies = telstra_programmable_network.topology.list()

  call sys_log.detail("build_topologies_cache: Retrieved " + to_s(size(@topologies)) +
    " topologies. Starting to retrieve all " + to_s(size(@topologies)) +
    " topology objects")

  # the following line is useful for testing as it avoids caching all topologies
  # @topologies = @topologies[0..1]
  $topologies = to_object(@topologies)
  $all_topology_objects = {}
  foreach $topology in $topologies["details"] do
    $topology_uuid = $topology["uuid"]
    @topology_objects = telstra_programmable_network.topology_objects.show("uuid": $topology_uuid)
    $all_topology_objects[$topology_uuid] = to_object(@topology_objects)
  end

  call sys_log.detail("build_topologies_cache: Completed retrieving " +
    to_s(size($all_topology_objects)) + " topology objects")
end

# returns true if @endpoint is used on any topologies
# $topologies, $all_topology_objects are the cached topology data data 
define on_any_topologies($topologies, $all_topology_objects, @endpoint) return $on_any_topologies do
  call endpoint_uuid(@endpoint) retrieve $endpoint_uuid
  $on_any_topologies = false
  foreach $topology in $topologies["details"] do
    $topology_uuid = $topology["uuid"]
    $topology_objects = $all_topology_objects[$topology_uuid]
    foreach $target_endpoint in $topology_objects["details"][0]["endpoints"] do
      $target_endpoint_uuid = $target_endpoint["endpoint_uuid"]
      #call sys_log.detail("$endpoint_uuid: " + $endpoint_uuid + " @topology: " + $topology_uuid + " $target_endpoint_uuid: " + $target_endpoint_uuid)
      if $endpoint_uuid == $target_endpoint_uuid
        $on_any_topologies = true
        # TODO should break out of the loop here
      end
    end
  end
end

# returns the endpoint_uuid for the given endpoint
define endpoint_uuid(@endpoint) return $endpointuuid do
  $port = to_object(@endpoint)["details"][0]["port"][0]
  $endpointuuid = $port["endpointuuid"]
end

# some endpoints return 4xx responses so we need to catch that when looping
# through all
define error_endpoint(@endpoint) do
  endpoint_uuid(@endpoint) retrieve $endpointuuid
  $$errors << "ERROR: Can't access Endpoint: " + $endpointuuid
  $_error_behavior = "skip"
end

# debugging tools

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