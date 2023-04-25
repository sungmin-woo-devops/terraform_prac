module "firewall" {
  name        = "my-firewall"
  description = "my firewall for this vpc"

  # Cannot use vpc dependency as vpc will also depend on this
  subnet_ids = [
   "subnet-1a",
   "subnet-1b",
   "subnet-1c"
  ]

  vpc_id = "vpc-xx"

  # the key name will be used in sid, only accept numeric :*
  blocked_ips = {
    "30092021": [
      "277.333.444.555/32", "333.444.555.666/32"
    ]
  }

  blocked_domains = {
    "my-blocked-domain-list": [
      "example.com"
    ]
  }
}