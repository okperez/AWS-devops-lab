#!/bin/bash
set -euxo pipefail

apt-get update
apt-get install -y docker.io unzip
systemctl enable --now docker

curl -fsSL https://awscli.amazonaws.com/v2/install.sh | bash -s -- --system

IMAGE_TAG="app-20261023-1217"
IMAGE_URI="118273046270.dkr.ecr.eu-west-3.amazonaws.com/image-repo:${IMAGE_TAG}"

aws ecr get-login-password --region eu-west-3 \
  | docker login --username AWS --password-stdin \
    118273046270.dkr.ecr.eu-west-3.amazonaws.com

docker pull "${IMAGE_URI}"
docker run -d \
  --name my-container \
  --restart unless-stopped \
  -p 8080:8080 \
  "${IMAGE_URI}"