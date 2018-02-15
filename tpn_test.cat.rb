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

define gen_launch() return @tops, @my_top, $my_top_str, $tops_str, $deployment_str do
  $deployment_str = @@deployment.description
  call start_debugging()
  @tops = telstra_programmable_network.topology.list()
  call stop_debugging()

  call start_debugging()
  # Don't iterate on the resources as this takes ages. Perhaps it is doing an
  # additional API call for each one?
  $tops = to_object(@tops)
  $tops_str = to_json($tops)
  # foreach $top in $tops do
  #   $tops_str = $tops_str + $top["name"] + ", " + $top["status"] + ", " + $top["uuid"] + "\n"
  # end
  call stop_debugging()

  # call start_debugging()
  # @my_top = telstra_programmable_network.topology.show(uuid: "9a8ee002-e05f-4a83-af92-013a36d7bb26")
  # call stop_debugging()

  # call start_debugging()
  # #$my_top_str = to_json(to_object(@my_top))
  # $my_top = to_object(@my_top)
  # $my_top_str = $my_top["details"][0]["name"] + "{ status: " + $my_top["details"][0]["status"] + ", uuid: " + $my_top["details"][0]["uuid"] + " }"
  # call stop_debugging()
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