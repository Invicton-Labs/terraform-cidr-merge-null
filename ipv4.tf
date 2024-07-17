locals {
  // This switches all CIDRs to using a consistent format (first IP of their range, plus prefix),
  // then takes the distinct set. This ensures they are all, in fact, distinct.
  cidrs_distinct = [
    for group in var.cidr_sets_ipv4 :
    distinct([
      for cidr in group :
      "${cidrhost(cidr, 0)}/${split("/", cidr)[1]}"
    ])
  ]

  // This adds the first and last IP addresses (in octet format) to each CIDR
  cidrs_with_first_last = [
    for group in local.cidrs_distinct :
    [
      for cidr in group :
      {
        cidr     = cidr
        first_ip = cidrhost(cidr, 0)
        last_ip  = cidrhost(cidr, pow(2, 32 - tonumber(split("/", cidr)[1])) - 1)
      }
    ]
  ]

  // This adds the first and last IP addresses (in decimal format) to each CIDR
  cidrs_with_first_last_decimal = [
    for group in local.cidrs_with_first_last :
    [
      for cidr_data in group :
      merge(cidr_data, {
        first_ip_decimal = pow(2, 24) * tonumber(split(".", cidr_data.first_ip)[0]) + pow(2, 16) * tonumber(split(".", cidr_data.first_ip)[1]) + pow(2, 8) * tonumber(split(".", cidr_data.first_ip)[2]) + tonumber(split(".", cidr_data.first_ip)[3])
        last_ip_decimal  = pow(2, 24) * tonumber(split(".", cidr_data.last_ip)[0]) + pow(2, 16) * tonumber(split(".", cidr_data.last_ip)[1]) + pow(2, 8) * tonumber(split(".", cidr_data.last_ip)[2]) + tonumber(split(".", cidr_data.last_ip)[3])
      })
    ]
  ]

  // This removes any CIDRs that are contained entirely within a different CIDR in the set
  cidrs_largest_only = [
    for group in local.cidrs_with_first_last_decimal :
    [
      for idx1, cidr_data in group :
      cidr_data
      if length([
        for idx2, compare_data in group :
        true
        if(
          (compare_data.first_ip_decimal < cidr_data.first_ip_decimal && compare_data.last_ip_decimal >= cidr_data.last_ip_decimal) ||
          (compare_data.first_ip_decimal <= cidr_data.first_ip_decimal && compare_data.last_ip_decimal > cidr_data.last_ip_decimal)
        )
      ]) == 0
    ]
  ]

  // This adds a sort key to each CIDR, which is in the format {FIRST_IP_DECIMAL_PADDED}-{LAST_IP_DECIMAL_PADDED}.
  // This sort key format allows us to sort by start IP ascending, then end IP ascending.
  cidrs_with_sort_keys = [
    for group in local.cidrs_largest_only :
    [
      for cidr_data in group :
      merge(cidr_data, {
        sort_key = "${join("", [for i in range(9 - floor(log(max(1, cidr_data.first_ip_decimal), 10))) : "0"])}${cidr_data.first_ip_decimal}-${join("", [for i in range(9 - floor(max(1, log(cidr_data.last_ip_decimal, 10)))) : "0"])}${cidr_data.last_ip_decimal}"
      })
    ]
  ]

  // This is just the sort keys, sorted. We do this as a separate list because the Terraform sort function
  // can't handle sorting a list of objects by a field.
  cidrs_keys_sorted = [
    for group in local.cidrs_with_sort_keys :
    sort([
      for cidr_data in group :
      cidr_data.sort_key
    ])
  ]

  // This sorts the CIDRs by their sort key.
  cidrs_sorted = [
    for group_idx, group in local.cidrs_with_sort_keys :
    [
      for key in local.cidrs_keys_sorted[group_idx] :
      [
        for cidr_data in group :
        cidr_data
        if cidr_data.sort_key == key
      ][0]
    ]
  ]

  // This gets sets of contiguous CIDR blocks, which contains all CIDRs coming after
  // a given CIDR that have an first IP immediately after the last block's last IP.
  // Note that not all CIDRs within each set are all contiguous; if you have values [1, 2, 5, 6, 9, 10],
  // a set starting at index 0 would include [1, 2, 6, 10] since 6 and 10 are each contiguous with the
  // element in the list before them. We fix this issue in the next step.
  contiguous_cidr_sets_tmp = [
    for group_idx, group in local.cidrs_sorted :
    [
      for cidr_idx, cidr_data in group :
      flatten([
        [
          cidr_data
        ],
        [
          for next_idx in range(cidr_idx + 1, length(group)) :
          group[next_idx]
          if group[next_idx].first_ip_decimal == group[next_idx - 1].last_ip_decimal + 1
        ]
      ])
      if cidr_idx == 0 ? true : cidr_data.first_ip_decimal != group[cidr_idx - 1].last_ip_decimal + 1
    ]
  ]

  // For each contiguous set, create a list of flags that shows whether a given CIDR is contiguous
  // with the CIDR preceding it.
  contiguous_cidr_sets_flags = [
    for group_idx, group in local.contiguous_cidr_sets_tmp :
    [
      for contiguous_set in group :
      [
        for cidr_idx, cidr_data in contiguous_set :
        cidr_idx == 0 ? true : cidr_data.first_ip_decimal == contiguous_set[cidr_idx - 1].last_ip_decimal + 1
      ]
    ]
  ]

  // Use the flags to find the first CIDR in each contiguous set that isn't actually contiguous, and cut off the set there.
  contiguous_cidr_sets = [
    for group_idx, group in local.contiguous_cidr_sets_tmp :
    [
      for set_idx, contiguous_set in group :
      slice(contiguous_set, 0, try(index(local.contiguous_cidr_sets_flags[group_idx][set_idx], false), length(contiguous_set)))
    ]
  ]

  // For each CIDR in each contiguous set, determine if it can be merged into the CIDRs succeeding it.
  contiguous_cidrs_meta = [
    for group_idx, group in local.contiguous_cidr_sets :
    [
      for set_idx, contiguous_set in group :
      [
        for cidr_idx, cidr_data in contiguous_set :
        merge(cidr_data, {
          merges = [
            for i in range(cidr_idx, length(contiguous_set)) :
            {
              first_ip = cidr_data.first_ip
              // Calculate the prefix length as 32 minus (the number of IPs in the CIDR, log base 2)
              // There is some floating point precision difficulty, so if the log2 is within 10e-14 of a whole number, we assume it's valid.
              prefix_length = 32 - (
                abs(
                  floor(
                    log(contiguous_set[i].last_ip_decimal - cidr_data.first_ip_decimal + 1, 2) + 0.5
                  ) - log(contiguous_set[i].last_ip_decimal - cidr_data.first_ip_decimal + 1, 2)
              ) < 10e-14 ? floor(log(contiguous_set[i].last_ip_decimal - cidr_data.first_ip_decimal + 1, 2) + 0.5) : log(contiguous_set[i].last_ip_decimal - cidr_data.first_ip_decimal + 1, 2))

              // Debugging values
              # cidr_set = slice(contiguous_set, cidr_idx, i + 1)
              # first_ip_decimal = cidr_data.first_ip_decimal
              # last_ip          = contiguous_set[i].last_ip
              # last_ip_decimal  = contiguous_set[i].last_ip_decimal
              # ip_count = contiguous_set[i].last_ip_decimal - cidr_data.first_ip_decimal + 1
            }
          ]
        })
      ]
    ]
  ]

  // For each CIDR in each contiguous set, identify the maximum number of succeeding CIDRs it can be merged with.
  contiguous_cidrs_meta_2 = [
    for group in local.contiguous_cidrs_meta :
    [
      for contiguous_set in group :
      [
        for cidr_data in contiguous_set :
        merge(cidr_data, {
          max_forward_merge = length(cidr_data.merges) - index(reverse([
            for m in cidr_data.merges :
            floor(m.prefix_length) == m.prefix_length ? cidrhost("${m.first_ip}/${m.prefix_length}", 0) == m.first_ip : false
          ]), true) - 1

          // Debugging values
          # merge_results = concat([
          #   for m in cidr_data.merges :
          #   floor(m.prefix_length) == m.prefix_length ? cidrhost("${m.first_ip}/${m.prefix_length}", 0) == m.first_ip : false
          # ])
        })
      ]
    ]
  ]

  // For each contiguous set, create a list of all possible mergings.
  contiguous_cidrs_meta_3 = [
    for group in local.contiguous_cidrs_meta_2 :
    [
      for contiguous_set in group :
      {
        cidr_data = contiguous_set

        // A merge pair is [first index (inclusive), last index (inclusive)] of all of the 
        // CIDRs in the contiguous set that should be merged.
        merge_idx_pairs_all = [for idx, val in [
          for cidr_data in contiguous_set :
          cidr_data.max_forward_merge
          ] :
          [idx, idx + val]
        ]

        // Debugging values
        # max_forward_merges = [
        #   for cidr_data in contiguous_set :
        #   cidr_data.max_forward_merge
        # ]
      }
    ]
  ]

  // For each contiguous set, narrow down the list of mergings to only be the best ones (maximum number of CIDRs merged for each).
  contiguous_cidrs_meta_4 = [
    for group in local.contiguous_cidrs_meta_3 :
    [
      for contiguous_set in group :
      merge(contiguous_set, {
        merge_idx_pairs = [
          for idx, pair in contiguous_set.merge_idx_pairs_all :
          pair
          // Include a merge pair in the final list of merge pairs if it's the first one (can't be a better one before that might include this CIDR)
          // or if none of the previous merge pairs subsume this merge pair (has an end index less than this CIDR's index).
          if idx == 0 ? true : max([
            for cmp_idx in range(0, idx) :
            contiguous_set.merge_idx_pairs_all[cmp_idx][1]
          ]...) < idx
        ]
      })
    ]
  ]

  // For each contiguous set, identify the complete set of merges (also includes "single CIDR" merges, which isn't actually a merge but includes
  // the CIDRs that can't be merged with anything else).
  merged_cidrs = [
    for group in local.contiguous_cidrs_meta_4 :
    [
      for contiguous_set in group :
      [
        for idx_pair in contiguous_set.merge_idx_pairs :
        contiguous_set.cidr_data[idx_pair[0]].merges[idx_pair[1] - idx_pair[0]]
      ]
    ]
  ]

  // Create the final list of CIDRs, which is all of the merges from all of the contiguous sets.
  final_cidrs_ipv4 = [
    for group in local.merged_cidrs :
    flatten([
      for contiguous_set in group :
      [
        for merging in contiguous_set :
        "${merging.first_ip}/${merging.prefix_length}"
      ]
    ])
  ]
}
