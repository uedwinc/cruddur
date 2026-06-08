#!/usr/bin/env bash
set -euo pipefail

# Emulate Gitpod's THEIA_WORKSPACE_ROOT as the current workspace folder
export THEIA_WORKSPACE_ROOT="$(pwd)"

# Ensure /workspace exists (Gitpod-style path) and points to Codespaces workspaces
if [ ! -d /workspace ]; then
  sudo ln -s /workspaces /workspace || true
fi

# ----- Task: aws-cli -----
export AWS_CLI_AUTO_PROMPT=on-partial

#cd /workspace
#curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
#unzip awscliv2.zip
#sudo ./aws/install
#cd "$THEIA_WORKSPACE_ROOT"
#bash bin/ecr/login
#
## ----- Task: aws-sam -----
#cd /workspace
#wget https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip
#unzip aws-sam-cli-linux-x86_64.zip -d sam-installation
#sudo ./sam-installation/install
#cd "$THEIA_WORKSPACE_ROOT"
#
## ----- Task: cfn -----
#bundle update --bundler
#pip install cfn-lint
#cargo install cfn-guard
#gem install cfn-toml
#
## ----- Task: postgres -----
#curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
#echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
#sudo apt update
#sudo apt install -y postgresql-client-13 libpq-dev
#
#export GITPOD_IP="$(curl -s ifconfig.me)"
#source "$THEIA_WORKSPACE_ROOT/bin/rds/update-sg-rule"
#
## ----- Task: react-js -----
#ruby "$THEIA_WORKSPACE_ROOT/bin/frontend/generate-env"
#cd "$THEIA_WORKSPACE_ROOT/frontend-react-js"
#npm i
#
## ----- Task: flask -----
#ruby "$THEIA_WORKSPACE_ROOT/bin/backend/generate-env"
#cd "$THEIA_WORKSPACE_ROOT/backend-flask"
#pip install -r requirements.txt
#
## ----- Task: fargate -----
#cd /workspace
#curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
#sudo dpkg -i session-manager-plugin.deb
#cd "$THEIA_WORKSPACE_ROOT"
#cd backend-flask
#
## ----- Task: cdk -----
#npm install aws-cdk -g
#cd "$THEIA_WORKSPACE_ROOT/thumbing-serverless-cdk"
#cp .env.example .env
#npm i