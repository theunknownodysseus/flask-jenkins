# Flask Jenkins CI/CD Setup Guide

This guide walks you through setting up automated deployment for the Flask Jenkins application.

## Quick Start Options

### Option 1: Using Docker (Recommended)
```bash
cd /tmp/flask-jenkins
docker-compose up -d
```
Access Jenkins at: `http://localhost:8080`

### Option 2: Manual Installation
```bash
sudo bash jenkins-setup.sh
```

### Option 3: Use Existing Jenkins
If you already have Jenkins running, follow the detailed setup guide below.

---

## Detailed Setup Guide

### Prerequisites
- Jenkins server (installed and running)
- Git
- Python 3.x
- Access to GitHub repositories

### Step 1: Configure GitHub Credentials

1. Go to Jenkins Dashboard
2. **Manage Jenkins** → **Manage Credentials** → **Global** → **Add Credentials**
3. Select **Kind: Username with password** or **SSH Key**
4. Enter your GitHub credentials
5. Save with ID: `github-credentials`

### Step 2: Create Pipeline Job

1. Click **New Item** on Jenkins dashboard
2. Enter job name: `flask-jenkins-deploy`
3. Select **Pipeline** and click **OK**

### Step 3: Configure Pipeline

In the **Pipeline** section, choose one of these methods:

#### Method A: Pipeline Script from SCM (Recommended)
- **Definition**: Pipeline script from SCM
- **SCM**: Git
- **Repository URL**: `https://github.com/theunknownodysseus/flask-jenkins.git`
- **Credentials**: Select your GitHub credentials
- **Branch Specifier**: `*/main`
- **Script Path**: `Jenkinsfile`

#### Method B: Declarative Pipeline
- **Definition**: Pipeline script
- Copy the contents of `Jenkinsfile` into the script field

### Step 4: Configure Build Triggers

Check these options:
- ✅ **GitHub hook trigger for GITScm polling** (for webhook triggers)
- ✅ **Poll SCM** with schedule: `H/5 * * * *` (fallback, every 5 min)

### Step 5: Set Up GitHub Webhook

1. Go to your GitHub repository
2. **Settings** → **Webhooks** → **Add webhook**
3. **Payload URL**: `http://<your-jenkins-ip>:8080/github-webhook/`
4. **Content type**: `application/json`
5. **Events**: Push events
6. Click **Add webhook**

### Step 6: Test the Setup

1. Click **Build Now** on the Jenkins job
2. Watch the build in the console
3. Verify the application deployed successfully

---

## Pipeline Stages Explained

```
1. Checkout          → Clone the repository
2. Initialize        → Set up git submodules
3. Setup Environment → Create Python venv
4. Install Deps      → Install Flask, pytest
5. Run Tests         → Execute test suite
6. Build             → Compile Python files
7. Deploy            → Stop old & start new app
8. Health Check      → Verify app is running
9. Notify Success    → Send completion message
```

---

## Manual Deployment

Deploy without Jenkins using the provided script:

```bash
# Make it executable
chmod +x /tmp/flask-jenkins/deploy.sh

# Run deployment
./deploy.sh
```

This will:
- Pull latest code
- Create virtual environment
- Install dependencies
- Run tests
- Deploy the application
- Verify health

---

## Environment Variables

Edit these in the **Jenkinsfile** to customize:

```groovy
environment {
    APP_NAME = 'flask-jenkins'
    DEPLOY_DIR = '/tmp/flask-jenkins'
    VENV_DIR = '/tmp/flask-jenkins-venv'
    PORT = '5000'
    HOST = '0.0.0.0'
}
```

---

## Monitoring Deployments

### View Build Logs
```
Jenkins Dashboard → Job → Build Number → Console Output
```

### View Application Logs
```bash
tail -f /tmp/flask-app.log
```

### Check Application Status
```bash
curl http://localhost:5000/
```

### Check Running Process
```bash
ps aux | grep app.py
cat /tmp/flask-app.pid
```

---

## Troubleshooting

### Build fails at "Checkout"
**Problem**: Cannot access repository
**Solution**: 
- Verify GitHub credentials in Jenkins
- Check firewall allows Jenkins to reach GitHub
- Test SSH key permissions

### Health check fails
**Problem**: Application doesn't respond to requests
**Solution**:
- Check port 5000 is not in use: `lsof -i :5000`
- Review logs: `tail /tmp/flask-app.log`
- Manually test: `curl http://localhost:5000`

### Submodule not updating
**Problem**: Backend submodule not syncing
**Solution**:
- Check `git submodule update --init --recursive` in Jenkinsfile
- Verify credentials have access to both repos
- Manually test in Jenkins workspace

### Permission denied errors
**Problem**: Script execution fails
**Solution**:
```bash
chmod +x /tmp/flask-jenkins/deploy.sh
chmod +x /tmp/flask-jenkins/jenkins-setup.sh
```

---

## Advanced Configuration

### Email Notifications

Add to Jenkinsfile `post` section:
```groovy
post {
    success {
        mail to: 'your-email@example.com',
             subject: "Build Success: ${env.JOB_NAME}",
             body: "Build #${env.BUILD_NUMBER} deployed successfully"
    }
    failure {
        mail to: 'your-email@example.com',
             subject: "Build Failed: ${env.JOB_NAME}",
             body: "Build #${env.BUILD_NUMBER} failed. Check logs."
    }
}
```

### Slack Notifications

Add to Jenkinsfile `post` section:
```groovy
post {
    success {
        slackSend(
            color: 'good',
            message: "Flask app deployed successfully - Build #${env.BUILD_NUMBER}"
        )
    }
    failure {
        slackSend(
            color: 'danger',
            message: "Flask app deployment failed - Build #${env.BUILD_NUMBER}"
        )
    }
}
```

### Docker Deployment

Modify the Deploy stage in Jenkinsfile to use Docker:
```groovy
stage('Deploy') {
    steps {
        sh '''
            docker build -t flask-jenkins:${BUILD_NUMBER} .
            docker stop flask-jenkins || true
            docker run -d --name flask-jenkins \
                       -p 5000:5000 \
                       flask-jenkins:${BUILD_NUMBER}
        '''
    }
}
```

---

## File Structure

```
/tmp/flask-jenkins/
├── Jenkinsfile                 # Pipeline definition
├── deploy.sh                   # Manual deployment script
├── jenkins-setup.sh            # Jenkins installation script
├── docker-compose.yml          # Docker Compose for Jenkins
├── JENKINS_SETUP.md            # Detailed setup documentation
├── QUICK_START.md              # This file
├── requirements.txt            # Production dependencies
├── requirements-dev.txt        # Development dependencies
├── backend/                    # Flask app (submodule)
│   └── app.py
├── templates/                  # HTML templates
│   └── index.html
└── tests/                      # Test suite
    └── test_app.py
```

---

## Important URLs

- **Jenkins Dashboard**: `http://localhost:8080`
- **Job Page**: `http://localhost:8080/job/flask-jenkins-deploy/`
- **Build Console**: `http://localhost:8080/job/flask-jenkins-deploy/lastBuild/console`
- **Flask App**: `http://localhost:5000`

---

## Commands Reference

```bash
# View Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Restart Jenkins
sudo systemctl restart jenkins

# Check app status
curl -v http://localhost:5000/

# View app logs
tail -f /tmp/flask-app.log

# Manual deploy
./deploy.sh

# Run tests locally
python -m pytest tests/ -v
```

---

## Security Checklist

- [ ] Jenkins is behind HTTPS
- [ ] GitHub credentials are secured
- [ ] Webhook URL uses HTTPS
- [ ] Jenkins has strong admin password
- [ ] Restrict job permissions
- [ ] Rotate GitHub tokens regularly
- [ ] Enable audit logging
- [ ] Use environment variables for secrets
- [ ] Regular backups of Jenkins configuration

---

## Next Steps

1. ✅ Install Jenkins (Option 1, 2, or 3)
2. ✅ Configure GitHub credentials
3. ✅ Create pipeline job
4. ✅ Set up GitHub webhook
5. ✅ Make first commit to trigger build
6. ✅ Verify deployment succeeds
7. ✅ Configure email/Slack notifications
8. ✅ Set up monitoring/alerting

---

## Support & Resources

- [Jenkins Documentation](https://jenkins.io/doc/)
- [Jenkinsfile Documentation](https://jenkins.io/doc/book/pipeline/jenkinsfile/)
- [GitHub Webhooks](https://docs.github.com/en/developers/webhooks-and-events/webhooks)
- [Flask Documentation](https://flask.palletsprojects.com/)

---

**Last Updated**: April 2026
**Maintainer**: Your Team
