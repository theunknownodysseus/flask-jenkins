pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/theunknownodysseus/flask-jenkins.git'
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                cd /var/lib/jenkins/workspace/flask-jenkins-deploy

                # Stop old app
                pkill -f "backend/app.py" || true

                # Fix log permission
                touch /tmp/flask-app.log
                chmod 777 /tmp/flask-app.log

                # Start new app
                nohup python3 backend/app.py > /tmp/flask-app.log 2>&1 &

                # Wait for app
                sleep 3

                # Verify app
                curl --fail http://127.0.0.1:5000 || exit 1

                echo "✅ Deployment successful"
                '''
            }
        }
    }
}
