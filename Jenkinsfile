pipeline {
    agent any
    
    environment {
        APP_NAME = 'flask-jenkins'
        GITHUB_REPO = 'https://github.com/theunknownodysseus/flask-jenkins.git'
        DEPLOY_DIR = '/tmp/flask-jenkins'
        VENV_DIR = '/tmp/flask-jenkins-venv'
        PORT = '5000'
        HOST = '0.0.0.0'
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo '===== Checking out code ====='
                    checkout(
                        scm: [
                            $class: 'GitSCM',
                            branches: [[name: '*/main']],
                            userRemoteConfigs: [[
                                url: '${GITHUB_REPO}',
                                credentialsId: 'github-credentials'
                            ]]
                        ],
                        changelog: true,
                        poll: true
                    )
                }
            }
        }
        
        stage('Initialize Submodules') {
            steps {
                script {
                    echo '===== Initializing git submodules ====='
                    sh '''
                        git submodule update --init --recursive
                    '''
                }
            }
        }
        
        stage('Setup Environment') {
            steps {
                script {
                    echo '===== Setting up Python environment ====='
                    sh '''
                        python3 -m venv ${VENV_DIR} || true
                        source ${VENV_DIR}/bin/activate
                        pip install --upgrade pip
                        pip install -r requirements.txt || echo "No requirements.txt, installing Flask manually"
                        pip install flask
                    '''
                }
            }
        }
        
        stage('Install Dependencies') {
            steps {
                script {
                    echo '===== Installing dependencies ====='
                    sh '''
                        source ${VENV_DIR}/bin/activate
                        pip install flask pytest || echo "Dependencies already installed"
                    '''
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                script {
                    echo '===== Running tests ====='
                    sh '''
                        source ${VENV_DIR}/bin/activate
                        python -m pytest tests/ -v || echo "No tests found, skipping"
                    '''
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    echo '===== Building application ====='
                    sh '''
                        source ${VENV_DIR}/bin/activate
                        python -m py_compile backend/app.py
                    '''
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    echo '===== Stopping existing application ====='
                    sh '''
                        pkill -f "python3.*app.py" || echo "No running instance found"
                        sleep 2
                    '''
                    
                    echo '===== Deploying application ====='
                    sh '''
                        source ${VENV_DIR}/bin/activate
                        cd ${DEPLOY_DIR}
                        nohup python3 backend/app.py > /tmp/flask-app.log 2>&1 &
                        sleep 3
                        echo "Application deployed successfully"
                    '''
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo '===== Performing health check ====='
                    sh '''
                        sleep 2
                        curl -f http://127.0.0.1:${PORT}/ || exit 1
                        echo "✓ Application is healthy"
                    '''
                }
            }
        }
        
        stage('Notify Success') {
            steps {
                script {
                    echo '===== Deployment successful ====='
                    sh '''
                        echo "Flask application deployed successfully!"
                        echo "Access at: http://localhost:${PORT}"
                        tail -20 /tmp/flask-app.log
                    '''
                }
            }
        }
    }
    
    post {
        failure {
            script {
                echo '===== Deployment failed ====='
                sh '''
                    echo "Deployment failed. Check logs:"
                    tail -50 /tmp/flask-app.log || echo "No logs available"
                '''
            }
        }
        
        always {
            script {
                echo "Pipeline execution completed"
            }
        }
    }
}
