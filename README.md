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
1. Edit `tpn_plugin.rb` and replace `<TPN Account ID>` with your Account/Domain ID
1. Upload `tpn_plugin.rb` and `tpn_example.cat.rb` to Self-Service.
1. (Optional) Publish `tpn_example.cat.rb` to the Catalog.
1. Create a Credential in Cloud Management called `TPN_ACCESS_TOKEN`. Generate the access_token value using the TPN API (See https://dev.telstra.com/content/getting-started-tpn).

# Usage
1. Launch the `TPN Topology` CloudApp from Self Service Designer or Catalog.
1. Provide a name for the cloud app and click Launch.
1. A Topology will be provisioned in TPN with the same name as provided. The Topology's UUID and Status will be displayed as outputs.
1. Click Terminte to deprovision the Topology

# Limitations
1. Currently only Topologies are supported.
1. The `access_token` needs to be updated quite frequently