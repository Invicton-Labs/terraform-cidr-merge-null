variable "cidr_sets_ipv4" {
  description = "A map of lists of IPv4 CIDRs. All CIDRs within each sublist will be merged to the minimum set of CIDRs that cover exactly the same IP ranges. The sublists are handled independently; the module is structured this way to support processing multiple independent lists of CIDRs with a single instance of the module."
  type        = map(list(string))
  nullable    = false

  // Ensure all CIDR blocks are valid
  validation {
    condition = length([
      for idx, cidr in concat(values(var.cidr_sets_ipv4)...) :
      true
      if !can(cidrhost(cidr, 0))
    ]) == 0
    error_message = "CIDR blocks at indecies [${join(", ", flatten([
      for grp_idx, group in var.cidr_sets_ipv4 :
      [
        for cidr_idx, cidr in group :
        "${grp_idx}[${cidr_idx}]"
        if !can(cidrhost(cidr, 0))
      ]
    ]))}] are invalid."
  }
}
