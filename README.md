# AWS DevOps Lab

A learning project for deploying a containerized Flask application on AWS.
Terraform manages the infrastructure, while GitHub Actions automates Terraform
apply/destroy operations and estimates infrastructure costs for pull requests.

## Architecture

- An internet-facing Application Load Balancer serves HTTP on port 80.
- A private EC2 instance runs the application container on port 8080.
- A public bastion host provides SSH access to the private instance.
- Amazon ECR stores the application image; an EC2 IAM role allows the instance
  to pull it.
- A VPC has two public subnets, a private subnet, an Internet Gateway, and a
  NAT Gateway.

The current setup uses one application instance in one Availability Zone and
does not configure HTTPS. It is intended for learning, not production use.
NAT Gateway, load balancer, EC2, and public IPv4 usage can incur ongoing AWS
charges.

## Repository layout

```text
backend/                  Flask application
terraform/                Main AWS infrastructure configuration
terraform-bootstrap/      Terraform state bucket and GitHub OIDC setup
.github/workflows/        Apply, destroy, and Infracost workflows
docker-compose.yml        Local container setup
Makefile                  Local development shortcuts
```

## Run locally

With Docker Compose:

```bash
docker compose up --build
```

The app is available at <http://localhost:8000>; its health endpoint is
<http://localhost:8000/health>. Stop it with:

```bash
docker compose down
```

## Terraform state and bootstrap

The main infrastructure configuration in `terraform/` uses an S3 backend:

- Bucket: `terraform-state-storage-2026`
- State key: `terraform/terraform.tfstate`
- Region: `eu-west-3`
- State locking: S3 lock file (`use_lockfile = true`)

The separate `terraform-bootstrap/` configuration creates the state bucket and
the GitHub OIDC provider/role used by Actions. Bootstrap itself keeps its state
locally; back up its state files and do not commit them. Create the bucket with
the bootstrap configuration before initializing the main configuration:

```bash
terraform -chdir=terraform-bootstrap init
terraform -chdir=terraform-bootstrap plan
terraform -chdir=terraform-bootstrap apply
```

The main configuration's existing state is stored remotely in S3. Initialize
and operate on it from the repository root with:

```bash
terraform -chdir=terraform init
terraform -chdir=terraform validate
terraform -chdir=terraform plan
terraform -chdir=terraform apply
```

Terraform also needs AWS credentials configured locally (for example, through
the AWS CLI profile) and values for both required variables. Create the ignored
file `terraform/terraform.tfvars` with your own values:

```hcl
ssh_ingress_cidr = "YOUR_PUBLIC_IPV4/32"
ssh_public_key   = "CONTENTS_OF_YOUR_SSH_PUBLIC_KEY"
```

Use only the SSH **public** key. Restrict SSH ingress to an address range you
control. `terraform.tfvars`, Terraform state, and credentials must not be
committed.

## GitHub Actions

The workflows in `.github/workflows/` behave as follows:

- `apply.yml` runs `terraform apply -auto-approve` after a push to `main`.
- `destroy.yml` runs `terraform destroy -auto-approve` on a daily schedule
  (`19:30 UTC`) and can also be started manually with `workflow_dispatch`.
- Both Terraform workflows use the same S3 state and GitHub OIDC role, and are
  serialized to avoid concurrent state operations.

**Important:** the scheduled destroy removes the main project's AWS resources
every day. Disable or change that schedule if the infrastructure should remain
running. Destroying the main project does not remove the separate bootstrap
state bucket or its OIDC resources.

Configure these GitHub repository **Variables** for Terraform automation:

- `AWS_ROLE_ARN`: ARN of the OIDC role created by the bootstrap configuration.
- `SSH_INGRESS_CIDR`: allowed public IPv4 CIDR for SSH access.
- `SSH_PUBLIC_KEY`: SSH public key contents.

The OIDC role must trust this repository's `main` branch and have the
permissions required by both the S3 backend and resources managed in
`terraform/`. Local AWS credentials do not demonstrate that the GitHub role
has sufficient permissions.

The EC2 startup script pulls a specific image URI and tag from ECR, currently
defined in `terraform/user_data.sh`. Ensure that image exists in the repository
before creating the application instance; this project does not build or push
the image through its Terraform workflows.

After deployment, find the ALB DNS name in the AWS console and check the app:

```bash
curl -i http://<ALB-DNS-NAME>/
curl -i http://<ALB-DNS-NAME>/health
```

## Infracost pull request estimates

`infracost.yml` runs on pull requests and has two jobs:

- `infracost_breakdown` runs `infracost breakdown --path terraform`, showing a
  full estimate in the Actions logs.
- `infracost_diff` compares the pull request's Terraform configuration with
  its base branch and posts the cost change to the pull request.

These are estimates from Terraform configuration, not measurements of current
AWS usage or billing. Destroying AWS resources does not change an estimate
unless the Terraform configuration changes.

Configure the repository **Secrets** used by the workflow:

- `INFRACOST_API_KEY` for the standalone CLI setup used by the breakdown job.
- `INFRACOST_CLI_AUTHENTICATION_TOKEN` for `infracost-ci diff`.

The workflow uses the GitHub-provided `GITHUB_TOKEN` to post its PR comment; it
does not need to be created as a repository secret.

## Costs and cleanup

Review the destroy plan before removing resources locally:

```bash
terraform -chdir=terraform plan -destroy
terraform -chdir=terraform destroy
```

The ECR repository is configured with `force_delete = true`, so destroying it
also deletes its images. Destruction does not reverse charges already incurred.
