# Static Website on Google Cloud Storage

Deploys a secure, highly available static website using Google Cloud Storage. This project includes a separate bucket for access logging and provisions placeholder content for immediate demonstration.

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
