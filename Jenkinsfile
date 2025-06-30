pipeline {
    agent any

    environment {
        COMPOSE_DIR = 'nginx-odoo-setup-docker'
        ADDONS_DIR = "${COMPOSE_DIR}/addons"
        ODOO_CONTAINER = 'odoo18-app'  
        DEPLOY_SCRIPT = 'script/deploy.sh'
    }

    triggers {
        pollSCM('H/5 * * * *') 
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/your-org/odoo_project.git' 
            }
        }

        stage('Run Setup Script If Needed') {
            when {
                expression {
                    !fileExists(COMPOSE_DIR)
                }
            }
            steps {
                echo "Setup directory not found, running odoo_install.sh..."
                sh 'bash odoo_install.sh'
            }
        }

        stage('Detect Addon Changes') {
            when {
                changeset "${ADDONS_DIR}/**"
            }
            stages {
                stage('Pull Latest Addons') {
                    steps {
                        dir("${COMPOSE_DIR}") {
                            echo "Pulling latest addons changes..."
                            sh 'git pull || true'
                        }
                    }
                }

                stage('Restart Odoo Container') {
                    steps {
                        dir("${COMPOSE_DIR}") {
                            echo "Restarting Odoo container..."
                            sh "docker-compose restart ${ODOO_CONTAINER}"
                        }
                    }
                }

                stage('Run Deploy Script in Odoo') {
                    when {
                        expression {
                            fileExists("${DEPLOY_SCRIPT}")
                        }
                    }
                    steps {
                        script {
                            def containerId = sh(
                                script: "docker ps -qf name=${ODOO_CONTAINER}",
                                returnStdout: true
                            ).trim()
                            if (!containerId) {
                                error "Odoo container not found!"
                            }
                            echo "Copying and executing deploy script inside Odoo container..."
                            sh "docker cp ${DEPLOY_SCRIPT} ${containerId}:/tmp/deploy.sh"
                            sh "docker exec ${containerId} bash /tmp/deploy.sh"
                        }
                    }
                }
            }
        }

        stage('No Addon Changes') {
            when {
                not {
                    changeset "${ADDONS_DIR}/**"
                }
            }
            steps {
                echo "No changes detected in addons/ — skipping restart."
            }
        }
    }

    post {
        success {
            echo "Deployment pipeline finished successfully."
        }
        failure {
            echo "Deployment pipeline failed."
        }
    }
}
