name 'Telstra Programmable Network Topology'
rs_ca_ver 20161221
short_description "![TPN Logo](https://demostaticimages.blob.core.windows.net/icons/tpn_icon.png =85x64)\n
Creates a Telstra Programmable Network Topology"

import "sys_log"
import "plugins/telstra_programmable_network"

###########
# Outputs #
###########

output "uuid" do
  label "UUID"
  category "Outputs"
  default_value @topology.uuid
end

output "status" do
  label "Status"
  category "Outputs"
  default_value @topology.status
end

resource "topology", type: "telstra_programmable_network.topology" do
  # name and description come from the standard Self Service inputs which
  # are put on the deployment
  name first(split(@@deployment.name, last(split(@@deployment.name, /^[^-]+/))))
  
  # description overwritten by the launch definition
  description "RightScale CAT created"
end

operation "launch" do
  label "Launch"
  definition "launch"
end

define launch(@topology) return @topology do
  # set the description as it is not available on the @@deployment in the
  # resource definition
  $topology_object = to_object(@topology)
  $topology_object["fields"]["description"] = @@execution.description
  @topology = $topology_object
  
  provision(@topology)
end