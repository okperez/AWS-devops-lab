# AWS DevOps Lab

A learning project for deploying a containerized Flask application on AWS.
The infrastructure is managed with Terraform and is expected to evolve.

## Architecture

- Public Application Load Balancer serving HTTP on port 80
- Private EC2 instance running the application in Docker on port 8080
- Public bastion host for SSH access to the private instance
- Amazon ECR for the application image, with EC2 access through an IAM role
- VPC networking with public and private subnets, an Internet Gateway, and a
  NAT Gateway
- Private S3 bucket with encryption, public access blocking, versioning, and a
  lifecycle policy

The current setup uses one application instance in one Availability Zone and
does not configure HTTPS. It is intended for learning, not production use.

## Repository layout

```text
backend/             Flask application
terraform/           AWS infrastructure and EC2 user data
docker-compose.yml   Local container setup
Makefile             Local development shortcuts
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

## AWS deployment

Requirements: Terraform, AWS CLI credentials, Docker, and an SSH key pair. The
Terraform configuration expects the public key at `~/.ssh/devops_pro.pub`.

The AWS region is `eu-west-3`. Before applying, review the environment-specific
settings in `terraform/`, including the SSH ingress CIDR, ECR image URI and tag,
and S3 bucket name. The image referenced by `terraform/user_data.sh` must exist
in ECR before the application instance starts.

Initialize and review the Terraform configuration from the `terraform/`
directory:

```bash
terraform init
terraform plan
terraform apply
```

The ALB DNS name is available in the AWS console. The application and health
endpoint can be checked with:

```bash
curl -i http://<ALB-DNS-NAME>/
curl -i http://<ALB-DNS-NAME>/health
```

## Terraform state and credentials

No remote Terraform backend is configured. The state is local at
`terraform/terraform.tfstate` and is excluded from Git. It must not be committed.
GitHub Actions cannot manage existing infrastructure using a state file that
exists only on a developer machine; a persistent remote backend and secure AWS
authentication are prerequisites for CI automation.

AWS credentials belong in the local AWS CLI configuration or environment, not
in the repository. Local environment files, `terraform.tfvars`, Terraform state,
and Python virtual environments should remain untracked.

## Costs and cleanup

AWS resources such as the NAT Gateway, ALB, public IPv4 addresses, EC2 instances,
and storage may incur charges while provisioned. Review the destroy plan before
removing resources:

```bash
terraform plan -destroy
terraform destroy
```

Destroying the ECR repository also deletes its images (`force_delete = true`).
The S3 bucket has versioning enabled; any data that must be retained should be
backed up before cleanup. Destruction does not reverse charges already incurred.
