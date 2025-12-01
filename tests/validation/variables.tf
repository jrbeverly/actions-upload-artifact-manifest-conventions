# CI passes the Terraform workspace name (pr-<n> / main / branch-<x>) so
# resource names are unique per PR. The workspace isolates state; this
# isolates the cloud resource names.
variable "name_prefix" {
  type = string
}
