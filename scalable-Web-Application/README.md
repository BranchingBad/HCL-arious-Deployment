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
<!-- END_TF_DOCS -->
