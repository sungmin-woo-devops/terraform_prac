resource "aws_vpc" "tobi-vpc-01" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
    intstance_tenancy = default # dedicated
    
}

resource "aws_internet_gateway" "tobi-igw-01" {
    vpc_id = "${aws_vpc.tobi-vpc-01}"
    tags = {
        type = "igw"
    }
}

resource "aws_default_route_table" "tobi-router-01" {
    default_route_table_id = "${aws_vpc.tobi-vpc-01}"
}

resource "aws_route" "tobi-route-table-01" {
    route_table_id = "${aws_vpc.side_effect.main_route_table_id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.tobi-igw-01}"
}

resource "aws_subnet" "tobi-pub-subnet-1" {
    vpc_id = "${aws_vpc.tobi-vpc-01.id}"
    cidr_block = "10.10.1.0/24"
    map_public_ip_on_launch = false 

    tag = {
        env = "pub",
    }

}

resource "aws_subnet" "tobi-pub-subnet-2" {
    vpc_id = "${aws_vpc.tobi-vpc-01.id}"
    cidr_block = "10.10.2.0/24"
    
    tag = {
        env = "pub"
    }
}

resource "aws_subnet" "tobi-priv-subnet-1" {
    vpc_id = "${aws_vpc.tobi-vpc-01.id}"
    cidr_block = "10.10.10.0/24"
    map_public_ip_on_launch = false

    tag = {
        env = "priv"
    }
}

resource "aws_subnet" "tobi-priv-subnet-1" {
    vpc_id = "${aws_vpc.tobi-vpc-01.id}"
    cidr_block = "10.10.11.0/24"
    map_public_ip_on_launch = false

    tag = {
        env = "priv"
    }
}

// eip for NAT
resource "aws_eip" "tobi-eip-01" {
    vpc = true
    // 인터넷 게이트웨이 생성 후 생성되게 의존성 지정
    depends_on = ["aws_internet_gateway.side_effect_igw"]
}

// NAT Gateway
resource "aws_nat_gateway" "tobi-nat-01" {
    allocation_id = "${aws_eip.side_effect_nat_eip.id}"
    subnet_if = "${aws_subnet.side_effect_public_subnet1.id}"
    depends_on = ["aws_internet_gateway.tobi-igw-01"]
}

// Private route table
resource "aws_route_table" "tobi-priv-rt" {
    vpc_id = "${aws_vpc.side_effect.id}"
    tags {
        name = "private"
    }
}

resource "aws_route" "tobi-priv-r" {
    route_table_id = "${aws_route_table.tobi-priv-rt}"
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.tobi-nat-01}"
}

// Associate subnets to route tables
resource "aws_route_table_association" "tobi-pub-subnet1-association" {
    subnet_id = "${aws_subnet.tobi-route-table-01.id}"
    route_table_id = "${aws_vpc.tobi-vpc-01.main_route_table_id}"
}

resource "aws_route_table_association" "tobi-pub-subnet2-association" {
    subnet_id = "${aws_subnet.tobi-route-table-01.id}"
    route_table_id = "${aws_vpc.tobi-vpc-01.main_route_table_id}"
}

resource "aws_route_table_association" "tobi-priv-subnet1-association" {
    subnet_id = "${aws_subnet.side_effect_public_subnet2.id}"
    route_table_id = "${aws_vpc.tobi-vpc-01.main_route_table_id}"
}

resource "aws_route_table_association" "tobi-priv-subnet2-association" {
    subnet_id = "${aws_subnet.side_effect_public_subnet2.id}"
    route_table_id = "${aws_vpc.tobi-vpc-01.main_route_table_id}"
}

// default security group
resource "aws_default_security_group" "side_effect_default" {
    vpc_id = "${aws_vpc.tobi-vpc-01.id}"

    ingress {
        protcol = -1
        self = true
        from_port = 0
        to_port = 0
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        name = "default"
    }
}

resource "aws_default_network_acl" "tobi-default-nacl" {
    default_network_acl_id = "${aws_vpc.tobi-vpc-01.default_network_acl_id}"

    ingress {
        protocol = -1
        rule_no = 100
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = 0
        to_port = 0
    }

    egress {
        protocol = -1
        rule_no = 100
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = 0
        to_port = =0
    }

    tags {
        name = "default"
    }
}

resource "aws_network_acl" "tobi-nacl" {
    vpc_id = "${aws_vpc.tobi-vpc-01}"

    ingress {
        protocol = "tcp"
        rule_no = 100
        action = "allow"
        cidr_block = "10.3.0.0/18"
        from_port = 443
        to_port = 443
    }

    egress {
        protocol   = "tcp"
        rule_no    = 200
        action     = "allow"
        cidr_block = "10.3.0.0/18"
        from_port  = 443
        to_port    = 443
    }

    tag = {
        "type": "nacl"
    }

}

resource "aws_security_group" "allow_tls" {
    name = "allow_tls"
    description = "Allow TLS inbound traffic"
    vpc_id = "${aws_vpc.main.id}"

    ingress {
        description = "TLS from VPC"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_block = [aws_vpc.main.cidr_block]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]

        tags = {
            "name" = "allow_tls"
        }
    }
}

https://blog.outsider.ne.kr/1301
https://terraform101.inflearn.devopsart.dev/cont/vpc-practice/vpc-practice-with-igw/