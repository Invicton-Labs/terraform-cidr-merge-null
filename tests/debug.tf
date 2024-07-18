module "cidr_merge" {
  source = "../"
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
