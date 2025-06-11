```markdown
# Flask CI/CD Pipeline with GitHub Actions & DockerHub

This project demonstrates a complete CI/CD pipeline for a Flask application using GitHub Actions and DockerHub, with a self-hosted runner.

## Table of Contents
1. [Project Setup](#project-setup)
2. [Docker Configuration](#docker-configuration)
3. [GitHub Actions Setup](#github-actions-setup)
4. [Troubleshooting](#troubleshooting)
5. [Final Workflow File](#final-workflow-file)

## Project Setup

### 1. Create Flask Application
```python
# app.py
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/metrics')
def metrics():
    return jsonify({"status": "healthy", "version": "1.0.0"})

if __name__ == '__main__':
    app.run(host='0.0.0.0')
```

### 2. Project Structure
```
.
├── .github/
│   └── workflows/
│       └── ci.yml
├── src/
│   └── app.py
├── tests/
│   └── test_app.py
├── Dockerfile
├── Makefile
├── requirements.txt
└── README.md
```

## Docker Configuration

### 1. Dockerfile
```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src/ .
EXPOSE 5000
CMD ["python", "app.py"]
```

### 2. Manual Docker Testing
```bash
docker build -t yourusername/flask-metrics-app .
docker run -p 5000:5000 yourusername/flask-metrics-app
```

## GitHub Actions Setup

### 1. Workflow File (`.github/workflows/ci.yml`)
See [Final Workflow File](#final-workflow-file) section for complete version.

### 2. Self-Hosted Runner Setup
1. Create new runner in GitHub repo Settings > Actions > Runners
2. On your server:
```bash
mkdir actions-runner && cd actions-runner
curl -o actions-runner.tar.gz -L https://github.com/actions/runner/releases/download/v2.309.0/actions-runner-linux-x64-2.309.0.tar.gz
tar xzf actions-runner.tar.gz
./config.sh --url https://github.com/yourrepo --token YOUR_TOKEN
./run.sh
```

## Troubleshooting

### Issue 1: Workflow Not Triggering Automatically
**Symptoms**:
- Changes to `app.py` didn't trigger workflow
- Only triggered on YAML file changes

**Solution**:
```yaml
on:
  push:
    branches: [ "main" ]
    paths:
      - 'src/**'
      - 'tests/**'
      - 'Dockerfile'
      - 'requirements.txt'
```

### Issue 2: "Unknown revision HEAD^" Error
**Symptoms**:
```
fatal: ambiguous argument 'HEAD^': unknown revision
```

**Solution**:
```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 2  # Get commit history
```

### Issue 3: Docker Login Hanging
**Symptoms**:
- Login step stuck indefinitely
- Runner becomes unresponsive

**Solution**:
1. Verify Docker is running on runner machine:
```bash
sudo systemctl status docker
```
2. Add timeout to workflow:
```yaml
- name: Login to Docker Hub
  timeout-minutes: 2
  run: echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin
```

### Issue 4: Runner Files Polluting Repository
**Symptoms**:
- `actions-runner/_work` files appearing in git status

**Solution**:
1. Move runner outside project directory:
```bash
mv actions-runner ~/
```
2. Add to `.gitignore`:
```
actions-runner/
_diag/
```

## Final Workflow File

```yaml
name: CI Pipeline

on:
  push:
    branches: [ "main" ]
    paths:
      - 'src/**'
      - 'tests/**'
      - 'Dockerfile'
      - 'requirements.txt'
      - 'Makefile'

jobs:
  build-and-push:
    runs-on: self-hosted
    
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2
          path: 'code'
          clean: true

      - name: Show changes
        run: |
          if [ $(git rev-list --count HEAD) -gt 1 ]; then
            git diff --name-only HEAD^ HEAD
          else
            git ls-files
          fi

      - name: Set up Python
        working-directory: ./code
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Run tests
        working-directory: ./code
        run: make test

      - name: Login to Docker Hub
        timeout-minutes: 2
        run: |
          echo "${{ secrets.DOCKER_PASSWORD }}" | \
          docker login -u "${{ secrets.DOCKER_USERNAME }}" \
          --password-stdin docker.io

      - name: Build and push
        working-directory: ./code
        run: |
          docker build -t ${{ secrets.DOCKER_USERNAME }}/flask-metrics-app:latest .
          docker push ${{ secrets.DOCKER_USERNAME }}/flask-metrics-app:latest
```

## Best Practices
1. Keep runner separate from codebase
2. Use `fetch-depth: 2` for proper git history
3. Always add timeouts to network operations
4. Regularly clean runner workspace:
```bash
cd actions-runner
./run.sh --cleanup
```

```

This README covers:
- The complete setup process.
- All major issues I encountered.
- Detailed solutions for each problem.
- Final working configuration.
- Maintenance best practices.
