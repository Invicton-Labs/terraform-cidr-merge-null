run "cidr_merge_test" {
    variables {  
        cidr_sets_ipv4 = {
            // Set 0
            set-0 = [
                {
                    cidr = "192.168.1.0/24"
                },
                {
                    cidr = "192.168.2.0/24"
                },
                {
                    cidr = "192.168.3.0/24"
                },
                {
                    cidr = "192.168.4.0/23"
                },
                {
                    cidr = "192.168.6.0/24"
                },
                {
                    cidr = "192.168.7.0/24"
                },
                {
                    cidr = "192.168.8.0/24"
                },
            ],

            // Set 1
            set-1 = [
                {
                    cidr = "192.168.0.0/24"
                },
                {
                    cidr = "192.168.1.0/24"
                },
                {
                    cidr = "192.168.2.0/24"
                },

                {
                    cidr = "192.168.4.0/23"
                },
                {
                    cidr = "192.168.6.0/23"
                },
                {
                    cidr = "192.168.7.0/24"
                },

                
                {
                    cidr = "192.168.15.0/24"
                },
                {
                    cidr = "192.168.16.0/24"
                },
                {
                    cidr = "192.168.17.0/24"
                },
                {
                    cidr = "192.168.18.0/23"
                },
                {
                    cidr = "192.168.20.0/23"
                },
                {
                    cidr = "192.168.22.0/24"
                },
                {
                    cidr = "192.168.23.0/24"
                },
                {
                    cidr = "192.168.24.0/24"
                },
            ],

            // Set 2
            set-2 = [
                {
                    cidr = "1.1.1.1/23"
                },
                {
                    cidr = "198.222.32.0/5"
                },
                {
                    cidr = "0.0.0.0/0"
                },
            ],

            // Set 3
            set-3 = [
                {
                    cidr =  "10.6.0.0/15"
                },
                {
                    cidr = "10.8.0.0/20"
                },
                {
                    cidr = "10.0.0.0/15"
                },
                {
                    cidr = "10.4.0.0/15"
                },
                {
                    cidr = "10.2.0.0/16"
                },
                {
                    cidr = "10.8.0.0/24"
                },
                {
                    cidr = "10.3.0.0/16"
                },
            ],

            // Set 4
            set-4 = [
                {
                    cidr =  "0.0.0.0/1"
                },
                {
                    cidr =  "128.0.0.0/1"
                },
            ]
        }
    }

    assert {
        condition = output.merged_cidr_sets_ipv4.set-0 == [
            "192.168.1.0/24",
            "192.168.2.0/23",
            "192.168.4.0/22",
            "192.168.8.0/24",
        ]
        error_message = "Incorrect respose in set 0: ${jsonencode(output.merged_cidr_sets_ipv4.set-0)}"
    }

    assert {
        condition = output.merged_cidr_sets_ipv4.set-1 == [
            "192.168.0.0/23",
            "192.168.2.0/24",
            "192.168.4.0/22",
            "192.168.15.0/24",
            "192.168.16.0/21",
            "192.168.24.0/24",
        ]
        error_message = "Incorrect respose in set 1: ${jsonencode(output.merged_cidr_sets_ipv4.set-1)}"
    }

    assert {
        condition = output.merged_cidr_sets_ipv4.set-2 == [
            "0.0.0.0/0",
        ]
        error_message = "Incorrect respose in set 2: ${jsonencode(output.merged_cidr_sets_ipv4.set-2)}"
    }

    assert {
        condition = output.merged_cidr_sets_ipv4.set-3 == [
            "10.0.0.0/13",
            "10.8.0.0/20",
        ]
        error_message = "Incorrect respose in set 3: ${jsonencode(output.merged_cidr_sets_ipv4.set-3)}"
    }

    assert {
        condition = output.merged_cidr_sets_ipv4.set-4 == [
            "0.0.0.0/0"
        ]
        error_message = "Incorrect respose in set 4: ${jsonencode(output.merged_cidr_sets_ipv4.set-4)}"
    }
}
