# Containerized App on Google Kubernetes Engine

Deploys a production-ready, VPC-native Google Kubernetes Engine (GKE) cluster. This configuration focuses on security and modern best practices by creating a private cluster with autoscaling node pools.

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
| <a name="input_cluster_name"></a> cluster\_name | The name for the GKE cluster. | `string` | `"resume-gke-cluster"` | no |
| <a name="input_machine_type"></a> machine\_type | Machine type for GKE nodes. | `string` | `"e2-medium"` | no |
| <a name="input_max_nodes"></a> max\_nodes | Maximum number of nodes per zone. | `number` | `3` | no |
| <a name="input_min_nodes"></a> min\_nodes | Minimum number of nodes per zone. | `number` | `1` | no |
| <a name="input_project_id"></a> project\_id | The GCP project ID. | `string` | n/a | yes |
| <a name="input_region"></a> region | The region to create the GKE cluster in. | `string` | `"us-central1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_endpoint"></a> cluster\_endpoint | The public endpoint of the GKE cluster's master. |
| <a name="output_cluster_name"></a> cluster\_name | The name of the GKE cluster. |
| <a name="output_kubeconfig"></a> kubeconfig | A command to configure kubectl for this cluster. |
<!-- END_TF_DOCS -->
