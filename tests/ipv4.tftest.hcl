run "cidr_merge_test" {
    variables {  
        cidr_sets_ipv4 = [
            // Set 0
            [
                "192.168.1.0/24",
                "192.168.2.0/24",
                "192.168.3.0/24",
                "192.168.4.0/23",
                "192.168.6.0/24",
                "192.168.7.0/24",
                "192.168.8.0/24",
            ],

            // Set 1
            [
                "192.168.0.0/24",
                "192.168.1.0/24",
                "192.168.2.0/24",
                
                "192.168.4.0/23",
                "192.168.6.0/23",
                "192.168.7.0/24",

                "192.168.15.0/24",
                "192.168.16.0/24",
                "192.168.17.0/24",
                "192.168.18.0/23",
                "192.168.20.0/23",
                "192.168.22.0/24",
                "192.168.23.0/24",
                "192.168.24.0/24",
            ],

            // Set 2
            [
                "1.1.1.1/23",
                "198.222.32.0/5",
                "0.0.0.0/0",
            ],

            // Set 3
            [
                "10.6.0.0/15",
                "10.8.0.0/20",
                "10.0.0.0/15",
                "10.4.0.0/15",
                "10.2.0.0/16",
                "10.8.0.0/24",
                "10.3.0.0/16",
            ],

            // Set 4
            [
                "0.0.0.0/1",
                "128.0.0.0/1",
            ]
        ]
    }
    assert {
        condition = output.merged_cidr_sets_ipv4[0] == [
            "192.168.1.0/24",
            "192.168.2.0/23",
            "192.168.4.0/22",
            "192.168.8.0/24",
        ]
        error_message = "Incorrect respose in set 0: ${jsonencode(output.merged_cidr_sets_ipv4[0])}"
    }

    assert {
        condition = output.merged_cidr_sets_ipv4[1] == [
            "192.168.0.0/23",
            "192.168.2.0/24",
            "192.168.4.0/22",
            "192.168.15.0/24",
            "192.168.16.0/21",
            "192.168.24.0/24",
        ]
        error_message = "Incorrect respose in set 1: ${jsonencode(output.merged_cidr_sets_ipv4[1])}"
    }

    assert {
        condition = output.merged_cidr_sets_ipv4[2] == [
            "0.0.0.0/0",
        ]
        error_message = "Incorrect respose in set 2: ${jsonencode(output.merged_cidr_sets_ipv4[2])}"
    }

    assert {
        condition = output.merged_cidr_sets_ipv4[3] == [
           "10.0.0.0/13",
           "10.8.0.0/20",
        ]
        error_message = "Incorrect respose in set 3: ${jsonencode(output.merged_cidr_sets_ipv4[3])}"
    }

    assert {
        condition = output.merged_cidr_sets_ipv4[4] == [
           "0.0.0.0/0",
        ]
        error_message = "Incorrect respose in set 4: ${jsonencode(output.merged_cidr_sets_ipv4[4])}"
    }
}
