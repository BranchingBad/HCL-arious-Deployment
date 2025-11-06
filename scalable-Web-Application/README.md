# Scalable Web Application on Google Compute Engine

Provisions a complete, auto-scaling, and load-balanced web application infrastructure on Google Compute Engine. It is designed for high availability and security by placing instances in a private subnet with a Cloud NAT for egress traffic.

## Usage

1.  **Configure:** Create a `terraform.tfvars` file in this directory with the required inputs (at a minimum, `project_id`).
    ```hcl
    # terraform.tfvars
    project_id = "your-gcp-project-id"
    ```

2.  **Deploy:** Run the standard Terraform commands.
    ```sh
    terraform init
    terraform apply
    ```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> terraform | >= 1.3.0 |
| <a name="requirement_google"></a> google | >= 4.50.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_env_prefix"></a> env\_prefix | Prefix for resource names (e.g., prod, dev, staging). | `string` | `"dev"` | no |
| <a name="input_machine_type"></a> machine\_type | Compute Engine machine type. | `string` | `"e2-small"` | no |
| <a name="input_max_replicas"></a> max\_replicas | Maximum number of MIG instances. | `number` | `5` | no |
| <a name="input_min_replicas"></a> min\_replicas | Minimum number of MIG instances. | `number` | `2` | no |
| <a name="input_project_id"></a> project\_id | The GCP project ID. | `string` | n/a | yes |
| <a name="input_region"></a> region | The region to deploy resources. | `string` | `"us-central1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_load_balancer_ip"></a> load\_balancer\_ip | The public IP address of the HTTP load balancer. |
| <a name="output_mig_self_link"></a> mig\_self\_link | The self-link of the managed instance group. |
<!-- END_TF_DOCS -->
