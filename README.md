# Terraform CIDR Merge

This module takes one or more input sets of CIDRs and, for each set independently, returns a minimal set of CIDRs that includes all of the IP addresses in the input CIDRs but does not include any additional. This is useful for calculating the most efficient network rules. We initially developed this module for AWS Client VPN Authorization Rules, but have also found it to be very useful for network ACLs and other networking configurations.

The module accepts a list of lists of CIDRs so that multiple CIDR sets can be merged (independently of one another) with a single instance of the module, which prevents a `for_each` or `count` on the module with a value that may not be known at plan time.

The module works by:
1. Converting all CIDRs to use their first IP address as the prefix (e.g. `["10.0.1.0/16"]` becomes `["10.0.0.0/16"]`).
1. Removing any duplicate CIDRs.
2. Removing any CIDRs that are included in another CIDR (e.g. `["10.0.0.0/15", "10.1.0.0/16"]` would be reduced to `["10.0.0.0/15"]` since "10.1.0.0/16" is included within "10.0.0.0/15").
3. Grouping all CIDRs that are contiguous (one starts immediately after the other).
4. Reducing contiguous CIDRs to a fewer number of larger CIDRs where possible (e.g. `["10.0.0.0/16", "10.1.0.0/16", "10.2.0.0/16"]` gets reduced to `["10.0.0.0/15", "10.2.0.0/16"]`). Note new IP addresses are **never introduced** through this process; this is different than finding the smallest CIDR that encompasses all CIDRs in a contiguous group.

Example:
```terraform
module "cidr_merge" {
  source = "Invicton-Labs/cidr-merge/null"
  cidr_sets_ipv4 = [
    // Set 1
    [
      "192.168.0.0/24",
      "192.168.1.0/24",
      "192.168.2.0/23",
      "192.168.3.0/24",
      "192.168.4.0/22",
      "192.168.6.0/24",
      "192.168.7.0/24",
      "192.168.8.0/24",
      "1.0.1.5/16",
      "1.2.2.1/15",
      "1.1.0.0/16",
      "1.4.0.10/16",
      "1.5.0.0/16",
      "1.6.0.0/17",
    ],

    // Set 2 (merged independently of Set 1)
    [
      "0.0.0.0/1",
      "128.0.0.0/1",
    ]
  ]
}

output "merged_cidrs" {
  value = module.cidr_merge.merged_cidr_sets_ipv4
}
```

```
$ terraform plan

Changes to Outputs:
  + merged_cidrs = [
      + [
          + "1.0.0.0/14",
          + "1.4.0.0/15",
          + "1.6.0.0/17",
          + "192.168.0.0/21",
          + "192.168.8.0/24",
        ],
      + [
          + "0.0.0.0/0",
        ],
    ]

You can apply this plan to save these new output values to the Terraform state, without changing any real infrastructure.
```
