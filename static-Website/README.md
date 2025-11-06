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
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> terraform | >= 1.3.0 |
| <a name="requirement_google"></a> google | >= 4.50.0 |
| <a name="requirement_random"></a> random | >= 3.1.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_name_prefix"></a> bucket\_name\_prefix | Prefix for the GCS bucket name. A random suffix will be appended. | `string` | `"resume-website"` | no |
| <a name="input_common_labels"></a> common\_labels | Labels to apply to all resources for billing and organization. | `map(string)` | <pre>{<br>  "environment": "dev",<br>  "managed_by": "terraform",<br>  "project": "resume-website"<br>}</pre> | no |
| <a name="input_project_id"></a> project\_id | The GCP project ID. | `string` | n/a | yes |
| <a name="input_region"></a> region | The region to deploy the resources in. | `string` | `"US"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_website_bucket_name"></a> website\_bucket\_name | The name of the GCS bucket hosting the website. |
| <a name="output_website_url"></a> website\_url | The public URL of the static website. |
<!-- END_TF_DOCS -->
