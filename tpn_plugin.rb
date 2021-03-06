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

  type "topology" do
    href_templates "/ttms/1.0.0/topology_tag/{{uuid}}","/ttms/1.0.0/topology_tag/{{[*].uuid}}"

    field "name" do
      required true
      type "string"
    end

    field "authorization" do
      type "string"
      location "header"
    end

    field "description" do
      required true
      type "string"
    end

    action "create" do 
      verb "POST"
      path "/ttms/1.0.0/topology_tag"
      type "topology"

      field "authorization" do
        location "header"
      end
    end

    action "list" do 
      verb "GET"
      path "/ttms/1.0.0/topology_tag"
      type "topology"

      field "authorization" do
        location "header"
      end
    end

    action "show" do
      path "/ttms/1.0.0/topology_tag/$uuid"
      verb "GET"
      type "topology"

      field "authorization" do
        location "header"
      end

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

      field "authorization" do
        location "header"
      end
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

      field "authorization" do
        location "header"
      end

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

      field "authorization" do
        location "header"
      end

      field "customer_uuid" do 
        location "path"
      end

      output_path "endpointlist[]"
    end

    action "show" do
      verb "GET"
      path "/1.0.0/inventory/endpoint/$endpointuuid" # "$href"

      field "authorization" do
        location "header"
      end

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

  # type "session" do
  #   href_templates "{{access_token}}"

  #   field "body" do
  #     type "string"
  #     location "body"
  #   end

  #   action "create" do 
  #     verb "POST"
  #     path "/1.0.0/auth/generatetoken"
  #     type "session"
  #   end
  # end

end

define no_operation(@declaration) do
end

resource_pool "telstra_programmable_network" do
  plugin $telstra_programmable_network

  # auth "tpn_auth", type: "api_key" do
  #   key cred("TPN_ACCESS_TOKEN")
  #   location "header"
  #   field "Authorization"
  #   type "Bearer"
  # end
end