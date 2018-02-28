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
    # login must be performed by the CAT template and access token stored in a
    # credential called TPN_ACCESS_TOKEN 
    headers do {
      "Authorization": "Bearer " + cred("TPN_ACCESS_TOKEN")
    } end
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

    link "objects" do
      path "$href/objects"
      type "topology_objects"
    end

    action "destroy" do
      path "/ttms/1.0.0/topology_tag/$uuid"
    end

    output "uuid","name","description","status","customer_uuid","nsd_uuid","gui_topology","created_by","creation_date","deletion_date"
  end

  type "topology_objects" do
    href_templates "/ttms/1.0.0/topology_tag/{{topology_tag}}/objects"

    provision "no_operation"
    delete "no_operation"

    action "show" do
      path "/ttms/1.0.0/topology_tag/$uuid/objects"
      verb "GET"
      type "topology_objects"

      field "uuid" do 
        location "path"
      end
    end

    output "endpoints", "links", "sharedvports", "topology_tag"
  end

  type "endpoint" do
    href_templates "/1.0.0/inventory/endpoint/{{datacenter[0].port[0].endpointuuid}}","/1.0.0/inventory/endpoint/{{endpointlist[*].endpointuuid}}"
    
    provision "no_operation"
    delete "no_operation"

    action "list" do
      verb "GET"
      path "/1.0.0/inventory/endpoints/customeruuid/$customer_uuid"
      type "endpoint"

      field "customer_uuid" do 
        location "path"
      end

      output_path "endpointlist[]"
    end

    action "show" do
      verb "GET"
      path "/1.0.0/inventory/endpoint/$endpointuuid" # "$href"

      field "endpointuuid" do 
        location "path"
      end

      output_path "datacenter[]"
    end

    output "endpointuuid", "datacenteruuid"

    output "port" do
      type "array"
    end
  end
end

define no_operation(@declaration) do
end

resource_pool "telstra_programmable_network" do
  plugin $telstra_programmable_network
end