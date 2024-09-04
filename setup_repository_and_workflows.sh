#!/bin/bash

# Variables
REPO_NAME="central-sequence"
REPO_DESCRIPTION="Central Sequence Service repository for automating OpenAPI linting, validation, and deployment."
GITHUB_USERNAME="Contexter"  # Replace with your GitHub username
WORKFLOWS_DIR=".github/workflows"
LINT_WORKFLOW="$WORKFLOWS_DIR/lint.yml"
VALIDATE_WORKFLOW="$WORKFLOWS_DIR/validate.yml"
DEPLOY_WORKFLOW="$WORKFLOWS_DIR/deploy.yml"
COMMIT_MESSAGE="chore: setup repository, workflows, and gitflow"
BRANCH_NAME="feature/add-workflows"
GITIGNORE=".gitignore"
README="README.md"
API_DIR="api"
OPENAPI_SPEC="$API_DIR/openapi.yml"

# Function to create GitHub repository using GitHub CLI
create_github_repo() {
  echo "Creating GitHub repository..."
  gh repo create "$GITHUB_USERNAME/$REPO_NAME" --public --description "$REPO_DESCRIPTION" --confirm
}

# Function to initialize git repository locally
initialize_local_repo() {
  echo "Initializing local git repository..."
  git init
  git remote add origin https://github.com/$GITHUB_USERNAME/$REPO_NAME.git
}

# Function to set up a blank slate repo, .gitignore, README, and openapi.yml
setup_blank_slate_repo() {
  echo "Setting up a blank slate repository..."
  
  # Create .gitignore
  echo "# Ignore macOS system files
.DS_Store

# Ignore node_modules
node_modules/

# Ignore log files and environment files
*.log
.env

# Ignore GitHub Actions workflow logs
.github/workflows/*.log
" > $GITIGNORE

  # Create README
  echo "# $REPO_NAME

$REPO_DESCRIPTION
" > $README

  # Create api directory and openapi.yml stub
  mkdir -p $API_DIR
  echo "openapi: 3.0.0
info:
  title: Central Sequence Service API
  description: OpenAPI specification for the Central Sequence Service.
  version: 1.0.0
paths: {}
" > $OPENAPI_SPEC

  git add $GITIGNORE $README $OPENAPI_SPEC
  git commit -m "chore: initialize repository with .gitignore, README, and OpenAPI spec stub"
  git push -u origin main
}

# Function to set up Gitflow branching strategy
setup_gitflow() {
  echo "Setting up Gitflow..."
  git checkout -b develop
  git push -u origin develop

  git checkout -b $BRANCH_NAME
  git push -u origin $BRANCH_NAME
}

# Function to create workflows directory if it doesn't exist
create_workflows_directory() {
  if [ ! -d "$WORKFLOWS_DIR" ]; then
    echo "Creating workflows directory..."
    mkdir -p $WORKFLOWS_DIR
  fi
}

# Function to create linting workflow
create_lint_workflow() {
  cat > $LINT_WORKFLOW << EOF
name: Lint OpenAPI Specifications

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v2

      - name: Set up Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '14'

      - name: Install Redocly OpenAPI CLI
        run: npm install -g @redocly/openapi-cli

      - name: Lint OpenAPI spec
        run: openapi lint api/openapi.yml
EOF
}

# Function to create validation workflow
create_validation_workflow() {
  cat > $VALIDATE_WORKFLOW << EOF
name: Validate OpenAPI Specifications with AWS API Gateway

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v2

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: \${{ secrets.CENTRAL_SEQUENCE_AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: \${{ secrets.CENTRAL_SEQUENCE_AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Validate OpenAPI spec with AWS API Gateway
        run: aws apigateway get-rest-apis --cli-input-json file://api/openapi.yml
EOF
}

# Function to create deploy workflow
create_deploy_workflow() {
  cat > $DEPLOY_WORKFLOW << EOF
name: Deploy OpenAPI Specifications to AWS API Gateway

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v2

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: \${{ secrets.CENTRAL_SEQUENCE_AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: \${{ secrets.CENTRAL_SEQUENCE_AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Deploy OpenAPI spec to AWS API Gateway
        run: aws apigateway import-rest-api --body file://api/openapi.yml
EOF
}

# Function to push changes to GitHub
commit_and_push_changes() {
  echo "Committing and pushing changes..."
  git add $WORKFLOWS_DIR
  git commit -m "$COMMIT_MESSAGE"
  git push -u origin $BRANCH_NAME
}

# Main function to orchestrate all tasks
main() {
  create_github_repo
  initialize_local_repo
  setup_blank_slate_repo
  setup_gitflow

  create_workflows_directory
  create_lint_workflow
  create_validation_workflow
  create_deploy_workflow

  commit_and_push_changes

  echo "Repository, Gitflow, and workflows set up successfully."
}

# Execute the main function
main

