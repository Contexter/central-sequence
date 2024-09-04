# Automating OpenAPI Linting, Validation, and Deployment for Central Sequence Service API

## 1. Introduction

**Purpose**: This guide outlines an automated approach to create a new GitHub repository, initialize a Gitflow branching strategy, and set up workflows for linting, validating, and deploying the OpenAPI specification to AWS API Gateway. The process is automated using GitHub CLI (`gh`) and shell scripts for a consistent and efficient setup.

### Objectives:
- **Create a new GitHub repository** with GitHub CLI (`gh`).
- **Set up Gitflow branching strategy**.
- **Automate workflow creation** for OpenAPI linting, validation, and deployment.
- **Generate and store AWS credentials** as GitHub Secrets for use in workflows.
- **Create an `api` directory** with an `openapi.yml` stub for future OpenAPI definitions.

---

## 2. Prerequisites

Before you start, ensure you have the following:

- **GitHub CLI** (`gh`) installed: [Install GitHub CLI](https://cli.github.com/)
- **AWS CLI** installed: [Install AWS CLI](https://aws.amazon.com/cli/)
- Access to **AWS** with permissions to create and manage IAM users, API Gateway, and credentials.
- Permissions to create and manage repositories in **GitHub**.

---

## 3. Automating the Repository Creation and Setup

This section includes a shell script that automates the repository creation, Gitflow setup, and workflow integration for a blank slate repository.

### Script: `setup_repository_and_workflows.sh`

```bash
#!/bin/bash

# Variables
REPO_NAME="central-sequence"
REPO_DESCRIPTION="Central Sequence Service repository for automating OpenAPI linting, validation, and deployment."
GITHUB_USERNAME="YourGitHubUsername"  # Replace with your GitHub username
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
```

### 4. Executing the Script

1. Make the script executable:
   ```bash
   chmod +x setup_repository_and_workflows.sh
   ```

2. Run the script:
   ```bash
   ./setup_repository_and_workflows.sh
   ```

This script will:
- **Create the repository** on GitHub.
- **Initialize the local repository** with `.gitignore`, `README.md`, and `api/openapi.yml`.
- **Set up Gitflow** with the `develop` branch and a `feature/add-workflows` branch.
- **Create GitHub Actions workflows** for linting, validating, and deploying the OpenAPI spec.

---

## 5. Setting Up AWS Credentials as GitHub Secrets

To securely store AWS credentials as GitHub Secrets for use in the workflows:

### Step 1: Generate AWS IAM Access Keys
1. Log in to the AWS Management Console.
2. Navigate to **IAM > Users > Add User**.
3. Create a new user, e.g., `CentralSequenceAPIUser`, with **Programmatic Access**.
4. Attach the following policies:
   - `AmazonAPIGatewayAdministrator`
   - `AmazonAPIGatewayPushToCloudWatchLogs`
5. After user creation, download the **Access Key ID** and **Secret Access Key**.

### Step 2: Store the Credentials in GitHub Secrets
1. In your GitHub repository, go to **Settings > Secrets and variables > Actions**.
2. Click **New repository secret** and add the following:
   - **CENTRAL_SEQUENCE_AWS_ACCESS_KEY_ID**
   - **CENTRAL_SEQUENCE_AWS_SECRET_ACCESS_KEY**

These credentials will be used by the workflows to authenticate with AWS services like API Gateway.

---

## 6. Final Repository Structure

After running the script, the repository will look like this:

```bash
.
├── .github
│   └── workflows
│       ├── lint.yml
│       ├── validate.yml
│       └── deploy.yml
├── api
│   └── openapi.yml
├── .gitignore
└── README.md
```

---

## 7. Official Documentation Links

- [GitHub CLI Documentation](https://cli.github.com/)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Redocly OpenAPI CLI Documentation](https://redocly.com/docs/cli/)

---

## 8. Using Conventional Commits and Gitflow

**Conventional Commits** standardizes commit messages for better readability and automation. In this guide, we use messages like:

- `chore: setup repository, workflows, and gitflow`

**Gitflow** is a branching strategy where:
- `main` holds production-ready code.
- `develop` is the default integration branch for ongoing development.
- `feature/*` branches are for individual features or updates.


