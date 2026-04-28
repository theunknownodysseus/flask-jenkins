# Jenkins Automated Deployment Guide

## Overview
This guide helps you set up automatic deployment for your Flask Jenkins application using Jenkins CI/CD pipeline.

## Prerequisites
- Jenkins server installed and running
- Git installed on Jenkins server
- Python3 and pip installed on Jenkins server
- GitHub account with access to your repositories
- Jenkins credentials configured for GitHub

## Step 1: Install Jenkins Plugins

Go to **Manage Jenkins** → **Manage Plugins** and install:
- Pipeline
- Git
- GitHub
- GitHub Integration
- Log Parser (optional)
- Email Extension (optional)
- Slack Notification (optional)

## Step 2: Configure GitHub Credentials

1. Go to **Manage Jenkins** → **Manage Credentials**
2. Click **Global** → **Add Credentials**
3. Select **Kind: GitHub**
4. Enter your GitHub username and personal access token
5. Save with ID: `github-credentials`

### To create a GitHub Personal Access Token:
1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Click "Generate new token"
3. Select scopes: `repo`, `admin:repo_hook`
4. Copy the token and use it in Jenkins

## Step 3: Create Jenkins Pipeline Job

### Method A: Using Web UI
1. Click **New Item**
2. Enter job name: `flask-jenkins-deploy`
3. Select **Pipeline**
4. Click **OK**

### Configure Pipeline:
- **Definition**: Pipeline script from SCM
- **SCM**: Git
- **Repository URL**: `https://github.com/theunknownodysseus/flask-jenkins.git`
- **Credentials**: Select `github-credentials`
- **Branch Specifier**: `*/main`
- **Script Path**: `Jenkinsfile`
- **Additional Behaviors**: 
  - Add **Clean before checkout**
  - Add **Submodule Options** (to handle git submodules)

### Build Triggers:
- Check **GitHub hook trigger for GITScm polling**
- Check **Poll SCM** (Optional, for fallback): `H/5 * * * *` (every 5 minutes)

## Step 4: Set Up GitHub Webhook

1. Go to your GitHub repository
2. Settings → Webhooks → Add webhook
3. **Payload URL**: `http://your-jenkins-url:8080/github-webhook/`
4. **Content type**: `application/json`
5. **Events**: Push events, Pull requests
6. Click **Add webhook**

## Step 5: Configure Jenkins Server Settings

1. Go to **Manage Jenkins** → **Configure System**
2. Find **GitHub** section
3. Set **GitHub API URL**: `https://api.github.com`
4. Add your GitHub credentials
5. Click **Test connection**

## Step 6: Set Up Build Triggers

### Option A: Automatic (Recommended)
- Push to `main` branch → Jenkins automatically triggers build

### Option B: Manual
- Click **Build Now** to manually trigger deployment

### Option C: Scheduled
- Poll SCM every 5-15 minutes

## Step 7: Monitor Deployments

1. Click on your job
2. View **Build History**
3. Click on a build to see:
   - Console output
   - Stage logs
   - Build artifacts

## Environment Variables

The Jenkinsfile uses these environment variables:
```
APP_NAME = 'flask-jenkins'
GITHUB_REPO = 'https://github.com/theunknownodysseus/flask-jenkins.git'
DEPLOY_DIR = '/tmp/flask-jenkins'
VENV_DIR = '/tmp/flask-jenkins-venv'
PORT = '5000'
HOST = '0.0.0.0'
```

Edit `Jenkinsfile` to customize these values.

## Deployment Stages

1. **Checkout**: Clone the repository
2. **Initialize Submodules**: Set up git submodules (backend)
3. **Setup Environment**: Create Python virtual environment
4. **Install Dependencies**: Install required packages
5. **Run Tests**: Execute test suite
6. **Build**: Compile Python files
7. **Deploy**: Stop old app, start new app
8. **Health Check**: Verify application is running
9. **Notify Success**: Send completion notification

## Manual Deployment Script

You can also deploy manually using the provided script:

```bash
chmod +x /tmp/flask-jenkins/deploy.sh
./deploy.sh
```

## Troubleshooting

### Build Fails at Checkout
- Verify GitHub credentials are correct
- Check firewall allows Jenkins to reach GitHub
- Ensure Jenkins user can access git commands

### Health Check Fails
- Check if port 5000 is available
- Look at `/tmp/flask-app.log` for errors
- Verify Flask dependencies are installed

### Submodule Not Updating
- In Jenkinsfile, ensure `git submodule update --init --recursive` is called
- Check credentials have access to both repositories

### Application Crashes After Deploy
- Check `/tmp/flask-app.log` for errors
- Verify template files exist
- Ensure virtual environment is activated

## Logs and Debugging

### Jenkins Build Logs
- Navigate to job → build number → Console Output

### Application Logs
```bash
tail -f /tmp/flask-app.log
```

### Check Running Processes
```bash
ps aux | grep app.py
```

### View Deployed Application
```bash
curl http://127.0.0.1:5000/
```

## Security Considerations

1. **Use HTTPS** for webhook URLs
2. **Protect Jenkins** with authentication
3. **Restrict job permissions** to authorized users
4. **Rotate GitHub tokens** regularly
5. **Use environment variables** for sensitive data
6. **Enable Jenkins audit logs**

## Advanced Configuration

### Email Notifications
Add to Jenkinsfile:
```groovy
post {
    success {
        emailext(
            subject: 'Deployment Successful',
            body: 'Flask app deployed successfully',
            to: 'your-email@example.com'
        )
    }
    failure {
        emailext(
            subject: 'Deployment Failed',
            body: 'Check Jenkins logs for details',
            to: 'your-email@example.com'
        )
    }
}
```

### Slack Notifications
```groovy
post {
    success {
        slackSend(
            color: 'good',
            message: 'Flask deployment successful'
        )
    }
}
```

### Docker Integration
For containerized deployment, modify deploy stage to build and run Docker image.

## Quick Reference

### Useful Jenkins URLs
- Dashboard: `http://localhost:8080/`
- Job: `http://localhost:8080/job/flask-jenkins-deploy/`
- Console: `http://localhost:8080/job/flask-jenkins-deploy/lastBuild/console`
- Configure: `http://localhost:8080/job/flask-jenkins-deploy/configure`

### Common Jenkins Commands
```bash
# View Jenkins status
sudo systemctl status jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# View Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log
```

## Next Steps

1. ✅ Install Jenkins plugins
2. ✅ Configure GitHub credentials
3. ✅ Create pipeline job
4. ✅ Set up GitHub webhook
5. ✅ Verify first build succeeds
6. ✅ Monitor deployments
7. ✅ Configure notifications
8. ✅ Set up backup strategy

## Support

For issues or questions:
- Check Jenkins logs: `/var/log/jenkins/jenkins.log`
- Review build console output
- Check GitHub webhook delivery logs
- Test webhook manually: `curl -X POST http://your-jenkins-url:8080/github-webhook/`
