# Terraform CIDR Merge

This module takes one or more input sets of CIDRs and, for each set independently, returns a minimal set of CIDRs that includes all of the IP addresses in the input CIDRs but does not include any additional. This is useful for calculating the most efficient network rules. We initially developed this module for AWS Client VPN Authorization Rules, but have also found it to be very useful for network ACLs and other networking configurations.

The module accepts a map of lists of objects so that multiple CIDR sets can be merged (independently of one another) with a single instance of the module, which prevents a `for_each` or `count` on the module with a value that may not be known at plan time. Each list in the map contains objects that have fields for a CIDR and metadata. The output of the module includes, for each merged CIDR, the set of CIDR/metadata objects that it contains. This allows metadata such as a description (e.g. "route to database subnet") to be merged by the user to create merged metadata (e.g. a description for a merged CIDR that includes the descriptions for all of the CIDRs contained within).

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
  cidr_sets_ipv4 = {
    // Set 1
    set-0 = [
      {
        cidr = "192.168.0.0/24"
        metadata = {
          description = "CIDR #0"
        }
      },
      {
        cidr = "192.168.1.0/24"
        metadata = {
          description = "CIDR #1"
        }
      },
      {
        cidr = "192.168.2.0/23"
        metadata = {
          description = "CIDR #2"
        }
      },
      {
        cidr = "192.168.3.0/24"
        metadata = {
          description = "CIDR #3"
        }
      },
      {
        cidr = "192.168.4.0/22"
        metadata = {
          description = "CIDR #4"
        }
      },
      {
        cidr = "192.168.6.0/24"
        metadata = {
          description = "CIDR #5"
        }
      },
      {
        cidr = "192.168.7.0/24"
        metadata = {
          description = "CIDR #6"
        }
      },
      {
        cidr = "192.168.8.0/24"
        metadata = {
          description = "CIDR #7"
        }
      },
      {
        cidr = "1.0.1.5/16"
        metadata = {
          description = "CIDR #8"
        }
      },
      {
        cidr = "1.2.2.1/15"
        metadata = {
          description = "CIDR #9"
        }
      },
      {
        cidr = "1.1.0.0/16"
        metadata = {
          description = "CIDR #10"
        }
      },
      {
        cidr = "1.4.0.10/16"
        metadata = {
          description = "CIDR #11"
        }
      },
      {
        cidr = "1.5.0.0/16"
        metadata = {
          description = "CIDR #12"
        }
      },
      {
        cidr = "1.6.0.0/17"
        metadata = {
          description = "CIDR #13"
        }
      },
      {
        cidr = "1.6.0.0/17"
        metadata = {
          description = "CIDR #14"
        }
      },
    ],

    // Set 2 (merged independently of Set 1)
    set-1 = [
      {
        cidr = "0.0.0.0/1"
        metadata = {
          description = "CIDR #0"
        }
      },
      {
        cidr = "128.0.0.0/1"
        metadata = {
          description = "CIDR #1"
        }
      },
    ]
  }
}

output "merged_cidrs" {
  value = module.cidr_merge.merged_cidr_sets_ipv4
}
```

```
$ terraform apply -auto-approve

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

merged_cidrs = {
  "set-0" = [
    {
      "cidr" = "1.0.0.0/14"
      "contains" = [
        {
          "cidr" = "1.0.1.5/16"
          "metadata" = {
            "description" = "CIDR #8"
          }
        },
        {
          "cidr" = "1.2.2.1/15"
          "metadata" = {
            "description" = "CIDR #9"
          }
        },
        {
          "cidr" = "1.1.0.0/16"
          "metadata" = {
            "description" = "CIDR #10"
          }
        },
      ]
    },
    {
      "cidr" = "1.4.0.0/15"
      "contains" = [
        {
          "cidr" = "1.4.0.10/16"
          "metadata" = {
            "description" = "CIDR #11"
          }
        },
        {
          "cidr" = "1.5.0.0/16"
          "metadata" = {
            "description" = "CIDR #12"
          }
        },
      ]
    },
    {
      "cidr" = "1.6.0.0/17"
      "contains" = [
        {
          "cidr" = "1.6.0.0/17"
          "metadata" = {
            "description" = "CIDR #13"
          }
        },
        {
          "cidr" = "1.6.0.0/17"
          "metadata" = {
            "description" = "CIDR #14"
          }
        },
      ]
    },
    {
      "cidr" = "192.168.0.0/21"
      "contains" = [
        {
          "cidr" = "192.168.0.0/24"
          "metadata" = {
            "description" = "CIDR #0"
          }
        },
        {
          "cidr" = "192.168.1.0/24"
          "metadata" = {
            "description" = "CIDR #1"
          }
        },
        {
          "cidr" = "192.168.2.0/23"
          "metadata" = {
            "description" = "CIDR #2"
          }
        },
        {
          "cidr" = "192.168.3.0/24"
          "metadata" = {
            "description" = "CIDR #3"
          }
        },
        {
          "cidr" = "192.168.4.0/22"
          "metadata" = {
            "description" = "CIDR #4"
          }
        },
        {
          "cidr" = "192.168.6.0/24"
          "metadata" = {
            "description" = "CIDR #5"
          }
        },
        {
          "cidr" = "192.168.7.0/24"
          "metadata" = {
            "description" = "CIDR #6"
          }
        },
      ]
    },
    {
      "cidr" = "192.168.8.0/24"
      "contains" = [
        {
          "cidr" = "192.168.8.0/24"
          "metadata" = {
            "description" = "CIDR #7"
          }
        },
      ]
    },
  ]
  "set-1" = [
    {
      "cidr" = "0.0.0.0/0"
      "contains" = [
        {
          "cidr" = "0.0.0.0/1"
          "metadata" = {
            "description" = "CIDR #0"
          }
        },
        {
          "cidr" = "128.0.0.0/1"
          "metadata" = {
            "description" = "CIDR #1"
          }
        },
      ]
    },
  ]
}
```
