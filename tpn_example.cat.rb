name 'Telstra Programmable Network Topology'
rs_ca_ver 20161221
short_description "Creates a Telstra Programmable Network Topology"

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
  
  # FIXME getting the description from the deployment isn't working...
  description "RightScale CAT created"
  #description last(split(@@deployment.description, /CloudApp description: /))
end