name 'TPN Unattached VNF Endpoints Policy'
rs_ca_ver 20161221
short_description "![TPN Logo](https://demostaticimages.blob.core.windows.net/icons/tpn_icon.png =85x64)\n
Telstra Programmable Network Policy which looks for unattached VNF Endpoints. 
The policy delivers a report via email and optionally deleted the VNFs."

import "sys_log"
import "plugins/telstra_programmable_network"

parameter "param_email" do
  category "Contact"
  label "Email addresses (separate with commas)"
  default "david.sackett@team.telstra.com"
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

define launch($param_email, $param_action) do
  # used to collect errors such as endpoints that cannot be read
  $$errors = []
  
  # login and get the access token. This will only be used next time but it
  call update_access_token() retrieve $access_token
  $$authorization = "Bearer " + $access_token
  # call start_debugging()
  # sub on_error: error_endpoint("error") do
  #   @session = telstra_programmable_network.session.create(body: "grant_type=password&username=110417804064%2FDavid.Sackett.demo&password=kB7O%233v5")
  # end
  # call stop_debugging()
  # call sys_log.detail("@session: " + to_s(to_object(@session)))

  # run automated tests
  # call unit_tests()

  call build_topologies_cache() retrieve $topologies, $all_topology_objects

  call check_for_unattached_endpoints($topologies, $all_topology_objects) retrieve $unattached_endpoints

  # testing email template
  # $unattached_endpoints = []
  #   @target_endpoint = telstra_programmable_network.endpoint.show(authorization: $$authorization, endpointuuid: "b8190e24-42af-4934-ae2a-619e3594d1d7")
  # $unattached_endpoints << to_object(@target_endpoint)

  # send email report if there are any unattached endpoints found
  if size($unattached_endpoints) > 0
    call sys_log.detail("Building email report")
    call build_email($param_action, $unattached_endpoints) retrieve $email_body
    call sys_log.detail("Sending email report")
    call send_email_mailgun($param_email, $email_body)
  end

  # log any endpoints that the script was not authorized to view
  call sys_log.detail("ERRORS: " + to_s($$errors))
end

define unit_tests() do

  #####################
  # is_vnf test cases #
  #####################

  # Non-vnf endpoint: cfc3ff96-5557-4aa2-931b-8e6e11ba48d6
  @endpoint = telstra_programmable_network.endpoint.show(authorization: $$authorization, endpointuuid: "cfc3ff96-5557-4aa2-931b-8e6e11ba48d6")
  call endpoint_uuid(@endpoint) retrieve $endpoint_uuid
  call is_vnf(@endpoint) retrieve $is_vnf
  call sys_log.detail("Endpoint " + $endpoint_uuid + " is NOT a VNF. is_vnf returned " + to_s($is_vnf))
  assert logic_not($is_vnf)

  # VNF Endpoint: b8190e24-42af-4934-ae2a-619e3594d1d7
  @endpoint = telstra_programmable_network.endpoint.show(authorization: $$authorization, endpointuuid: "b8190e24-42af-4934-ae2a-619e3594d1d7")
  call endpoint_uuid(@endpoint) retrieve $endpoint_uuid
  call is_vnf(@endpoint) retrieve $is_vnf
  call sys_log.detail("Endpoint " + $endpoint_uuid + " is a VNF. is_vnf returned " + to_s($is_vnf))
  assert $is_vnf

  #########################
  # unattached test cases #
  #########################

  # Unattached VNF Endpoint: a7fe9533-f7ea-4e81-b07d-3a152f0907bb
  @endpoint = telstra_programmable_network.endpoint.show(authorization: $$authorization, endpointuuid: "a7fe9533-f7ea-4e81-b07d-3a152f0907bb")
  call endpoint_uuid(@endpoint) retrieve $endpoint_uuid
  call is_unattached($topologies, $all_topology_objects, @endpoint) retrieve $is_unattached
  call sys_log.detail("Endpoint " + $endpoint_uuid + " is unattached. is_unattached returned " + to_s($is_unattached))
  assert $is_unattached

  # Attached VNF Endpoint: b8190e24-42af-4934-ae2a-619e3594d1d7
  @endpoint = telstra_programmable_network.endpoint.show(authorization: $$authorization, endpointuuid: "b8190e24-42af-4934-ae2a-619e3594d1d7")
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
define check_for_unattached_endpoints($topologies, $all_topology_objects) return $unattached_endpoints do
  # get the customer uuid and then the account's endpoints
  $customer_uuid = $topologies["details"][0]["customer_uuid"]
  @endpoints = telstra_programmable_network.endpoint.list(authorization: $$authorization, customer_uuid: $customer_uuid)
  $endpoints = to_object(@endpoints)

  call sys_log.detail("check_for_unattached_endpoints: Checking " +
    to_s(size(@endpoints)) + " endpoints for unattached VNFs")

  $unattached_endpoints = []
  
  foreach $endpoint in $endpoints["details"] do
    call sys_log.detail("$endpoint: " + to_s($endpoint))
    
    # we can't access some endpoints so need to catch the error caused by the
    # 4xx response
    sub on_error: error_endpoint($endpoint) do
      @target_endpoint = telstra_programmable_network.endpoint.show(authorization: $$authorization, endpointuuid: $endpoint["endpointuuid"])
      call endpoint_uuid(@target_endpoint) retrieve $endpointuuid
      call is_unattached($topologies, $all_topology_objects, @target_endpoint) retrieve $is_unattached
      if $is_unattached
        call sys_log.detail("check_for_unattached_endpoints: Endpoint " +
          $endpointuuid + " is an unattached VNF")
        $unattached_endpoints << to_object(@target_endpoint)
      end
    end
  end

  call sys_log.detail("check_for_unattached_endpoints: Completed checking " +
    to_s(size(@endpoints)) + " endpoints. " + to_s(size($unattached_endpoints)) +
    " were unattached VNFs")
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
  @topologies = telstra_programmable_network.topology.list(authorization: $$authorization)

  call sys_log.detail("build_topologies_cache: Retrieved " + to_s(size(@topologies)) +
    " topologies. Starting to retrieve all " + to_s(size(@topologies)) +
    " topology objects")

  # the following line is useful for testing as it avoids caching all topologies
  # @topologies = @topologies[0..1]
  $topologies = to_object(@topologies)
  $all_topology_objects = {}
  foreach $topology in $topologies["details"] do
    $topology_uuid = $topology["uuid"]
    @topology_objects = telstra_programmable_network.topology_objects.show(authorization: $$authorization, "uuid": $topology_uuid)
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
define error_endpoint($endpoint) do
  $$errors << ("ERROR: Can't process Endpoint: " + to_s($endpoint))
  $_error_behavior = "skip"
end

# Login to TPN and update access token
# store the username in the credential called TPN_USERNAME
# store the password in the credential called TPN_PASSWORD
# store the domain id in the credential called TPN_DOMAIN_ID
# the login function will store the access token in TPN_ACCESS_TOKEN (which must exist)
define update_access_token() return $access_token do
  $username = cred("TPN_USERNAME")
  $password = cred("TPN_PASSWORD")
  $domain_id = cred("TPN_DOMAIN_ID")
  
  $body = "grant_type=password&username=" + $domain_id + "%2f" + $username + "&password=" + $password
  $response = http_post(headers: { "content-type": "application/x-www-form-urlencoded" },
    url: "https://penapi.pacnetconnect.com/1.0.0/auth/generatetoken", 
    body: $body)

  if $response['code'] != 200
    raise 'Error Authenticating'
  end
  # response does not contain the content-type header with applicatin/json so
  # we need to manually decode it.
  $access_token = from_json($response['body'])['access_token']
  @access_token = rs_cm.credentials.get(filter: ["name==TPN_ACCESS_TOKEN"])
  @access_token.update(credential: {"value" : $access_token})
end

################################
# Email generation and sending #
################################

define build_email($param_action, $unattached_endpoints) return $email_body do
  #get account id to include in the email.
  call find_account_name() retrieve $account_name
  
  
  $email_msg = "
  <p>
    Cloud Management Platform detected the following unattached Telstra
    Programmable Network VNF Endpoints. These are monitored by the " +
    $account_name + " CMP account.
  </p>
"
  if $param_action == "Report and Delete"
    $email_msg = $email_msg + "
  <p>
    These VNFs have been deleted and are no longer accessible (delete not
    implemented yet!).
  </p>
"  
  else
    $email_msg = $email_msg + "
  <p>
    These VNFs are incurring charges and should be
    deleted if they are no longer being used.
  </p>
"

  end

  $header = "
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
  <img src=\"https://demostaticimages.blob.core.windows.net/assets/telstra-email-header.png\"
    alt=\"Telstra Header\" width=\"600\" style=\"display:block;width:100%\"
  />
  </a>
  <style>
    h1,
    h2,
    h3 {
      margin-left: 10px;
      margin-right: 10px;
    }

    p {
      margin-left: 20px;
      margin-right: 20px;
    }

    footer {
      margin-left: 10px;
      margin-right: 10px;
      font-style: italic;
      font-size: smaller;
    }

    hr {
      margin-top: 40px;
      margin-left: 10px;
      margin-right: 10px;
    }

    body {
      margin: 0;
      font-family: Akkurat, Arial, Helvectica, sans-serif;
    }

    .uuid {
      margin-left: 10px;
      margin-top: 5px;
      margin-right: 10px;
      text-align: center;
      font-weight: bold;
      font-family: monospace;
    }
  </style>
</head>

<body>
  <h1>Unattached VNF Endpoints Report</h1>
  <h2>Telstra Programmable Networks</h2>


  <!-- $email_msg -->
" + $email_msg + "

  <h3>Endpoint UUIDs</h3>
"
    $list_of_endpoints = ""
    
    foreach $endpoint in $unattached_endpoints do
      $endpointuuid = $endpoint["details"][0]["port"][0]['endpointuuid']
      $endpoint_row = "
  <div class=\"uuid\">
" + "    " + $endpointuuid + "
  </div>
"
      insert($list_of_endpoints, -1, $endpoint_row)
    end

    $footer="
  <hr>
  <footer>
    This report was automatically generated by the \"TPN Unattached VNF
    Endpoints\" Policy your organization has defined in RightScale.
  </footer>

</body>
</html>
"
    $email_body = $header + $list_of_endpoints + $footer
end


define send_email_mailgun($to, $email_body) do
  $mailgun_endpoint = "http://smtp.services.rightscale.com/v3/services.rightscale.com/messages"
  call find_account_name() retrieve $account_name

  $to = gsub($to,"@","%40")
  $post_body="from=policy-cat%40services.rightscale.com&to=" + $to + "&subject=[" + $account_name + "] TPN+Unattached+VNF+Endpoints+Policy+Report&html=" + $email_body

  $response = http_post(
     url: $mailgun_endpoint,
     headers: { "content-type": "application/x-www-form-urlencoded"},
     body: $post_body
    )
end

# Returns the RightScale account number in which the CAT was launched.
define find_account_name() return $account_name do
  $session_info = rs_cm.sessions.get(view: "whoami")
  $acct_link = select($session_info[0]["links"], {rel: "account"})
  $acct_href = $acct_link[0]["href"]
  $account_name = rs_cm.get(href: $acct_href).name
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