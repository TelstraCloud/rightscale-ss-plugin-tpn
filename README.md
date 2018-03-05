# Telstra Programmable Networks RightScale Self Service Plugin

# Overview
This repo enables Telstra Programmable Network resources to be provisioned and
managed via RightScale. It contains:
- Self Service Plugin which provides the integration.
- An example CAT which shows how a Topology can be provisioned.
- A test CAT for exercising each function within the Plugin.

# Dependencies
1. RightScale's `sys_log` utility CAT.

# Installation
1. Install dependencies.
1. Upload `tpn_plugin.rb`, `tpn_example.cat.rb` and `tpn_unattached_vnf_endpoints.rb` to Self-Service.
1. (Optional) Publish `tpn_example.cat.rb` to the Catalog.
1. Create the following Credentials in Cloud Management:
  - store the username in `TPN_USERNAME`
  - store the password in `TPN_PASSWORD`
  - store the domain id in `TPN_DOMAIN_ID`
  - used by the CATs to store the access token after login occurs in `TPN_ACCESS_TOKEN`

# Usage
1. Launch the `TPN Topology` CloudApp from the Self Service Designer or Catalog.
1. Provide a name for the cloud app and click Launch.
1. A Topology will be provisioned in TPN with the same name as provided. The
   Topology's UUID and Status will be displayed as outputs.
1. Click Terminte to deprovision the Topology

# Limitations
1. Currently only Topologies (List, Read, Delete, Read Objects) and Endpoints
   (List, Read) are supported.
1. If the CAT takes longer the ~1h 40mins the access token will expire and
   script will fail