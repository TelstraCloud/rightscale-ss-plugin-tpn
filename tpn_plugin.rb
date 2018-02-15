name 'Telstra Programmable Network Self-Service Plugin'
type 'plugin'
rs_ca_ver 20161221
short_description "Telstra Programmable Network Self-Service Plugin"
long_description "Version: 0.1"
package "plugins/telstra_programmable_network"
import "sys_log"

plugin "telstra_programmable_network" do
  endpoint do
    default_host "https://penapi.pacnetconnect.com"
    default_scheme "https"
  end

  parameter "account_id" do
    type "string"
    label "Account ID"
    description "The TPN account/domain ID"
  end

  type "topology" do
    href_templates "/ttms/1.0.0/topology_tag/{{uuid}}","/ttms/1.0.0/topology_tag/{{[*].uuid}}"

    field "name" do
      required true
      type "string"
    end

    field "description" do
      required true
      type "string"
    end

    action "create" do 
      verb "POST"
      path "/ttms/1.0.0/topology_tag"
      type "topology"
    end

    action "list" do 
      verb "GET"
      path "/ttms/1.0.0/topology_tag"
      type "topology"
    end

    action "show" do
      path "/ttms/1.0.0/topology_tag/$uuid"
      verb "GET"
      type "topology"

      field "uuid" do 
        location "path"
      end
    end

    action "destroy" do
      path "/ttms/1.0.0/topology_tag/$uuid"
    end

    output "uuid","name","description","status","customer_uuid","nsd_uuid","gui_topology","created_by","creation_date","deletion_date"
  end
end

resource_pool "telstra_programmable_network" do
  plugin $telstra_programmable_network
  parameter_values do
    account_id "<TPN Account ID>"
  end

  auth "tpn_auth", type: "api_key" do
    key cred("TPN_ACCESS_TOKEN")
    location "header"
    field "Authorization"
    type "Bearer"
  end
end