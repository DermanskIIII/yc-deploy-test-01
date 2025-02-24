#!/usr/bin/env bash
set -e

USERNAME=$(whoami)
echo "Подготовка для доступа к репозиторию (.ssh/known_hosts, deploy_key для доступа к репозиторию)..."
install -m 700 -d /home/$USERNAME/.ssh

cat >> /home/$USERNAME/.ssh/known_hosts << EOF
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
EOF
chmod 600 /home/$USERNAME/.ssh/known_hosts

cat > /home/$USERNAME/.ssh/test_deploy_key << EOF
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACD4NnQZ3XP59WGDmT384theyR0/szRi0L5jE4MUWYh0igAAAJB3ZCENd2Qh
DQAAAAtzc2gtZWQyNTUxOQAAACD4NnQZ3XP59WGDmT384theyR0/szRi0L5jE4MUWYh0ig
AAAEDp8BbTZeXNluUmCczWP5z8Jscg+Yu+xNIp3jJgn+E2Tvg2dBndc/n1YYOZPfzi2F7J
HT+zNGLQvmMTgxRZiHSKAAAAC2l2YW5kQG1zYXRhAQI=
-----END OPENSSH PRIVATE KEY-----
EOF
chmod 600 /home/$USERNAME/.ssh/test_deploy_key

YC_FOLDER_NAME=default
DOCKER_IMAGE_NAME=genotek-test
DOCKER_IMAGE_TAG=latest
CONTAINER_NAME=genotek-test
GITHUB_CLONE_URL=git@github.com:DermanskIIII
GITHUB_REPO_NAME=yc-deploy-test-01

echo "Установка ПО git, docker.io и их зависимостей (может выполняться несколько минут)..."
sudo apt-get update 2>&1 >/dev/null
sudo apt-get install -y --no-install-recommends git docker.io 2>&1 >/dev/null
echo "Успешно"

sudo usermod -aG docker $USERNAME

echo "Установка ПО Yandex.Cloud (утилита yc)..."genotek
GIT_REPO_DIR=`mktemp -dq`
cd $GIT_REPO_DIR

OLD_GIT_SSHCOMMAND=`bash +e -c "git config --global core.sshCommand; exit 0"`
git config --global core.sshCommand "ssh -i /home/$USERNAME/.ssh/test_deploy_key"
echo "Клонируем репозиторий приложения..."
git clone $GITHUB_CLONE_URL/$GITHUB_REPO_NAME.git
echo "Успешно"
if [[ -z "$OLD_GIT_SSHCOMMAND" ]]
then
  git config --global --unset core.sshCommand
else
  git config --global core.sshCommand "$OLD_GIT_SSHCOMMAND"
fi

read -sp "Введите OAuth токен Yandex.Cloud (введённые символы не отображаются!):" YC_OAUTH_TOKEN

newgrp docker << EOF
  set -e
  /opt/yc/bin/yc config set cloud-id "$YC_CLOUD_ID"
  /opt/yc/bin/yc config set folder-id "$YC_FOLDER_ID"
  /opt/yc/bin/yc config set token "$YC_OAUTH_TOKEN"
  echo "Создаём реестр докер-образов ..."
  export YC_REGISTRY_ID=\`yc container registry create | grep -E "^id" | awk '{ print \$2 }'\`
  /opt/yc/bin/yc container registry configure-docker
  cd $GIT_REPO_DIR/$GITHUB_REPO_NAME/docker
  echo "Приступаем к сборке образа..."
  docker build -t $DOCKER_IMAGE_NAME .
  echo "Успешно"
  cd ~
  rm -rf $GIT_REPO_DIR
  docker tag $DOCKER_IMAGE_NAME cr.yandex/\$YC_REGISTRY_ID/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG
  echo "Загружаем образ в реестр..."
  docker push cr.yandex/\$YC_REGISTRY_ID/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG
  echo "Успешно"
  docker run --restart unless-stopped --name $CONTAINER_NAME cr.yandex/\$YC_REGISTRY_ID/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG
exit 0
EOF









# sudo tee /etc/systemd/system/genotek-test.service >/dev/null << SERVICE_EOF
# [Unit]
#   Description=Genotek test container
#   After=docker.service

# [Service]
#   User=$USERNAME
#   Group=docker
#   Type=exec
#   Restart=on-failure
#   ExecStart=/usr/bin/docker run --rm --name $CONTAINER_NAME cr.yandex/\$YC_REGISTRY_ID/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG
#   ExecStop=/usr/bin/docker stop $CONTAINER_NAME
# [Install]
#   WantedBy=multi-user.target
# SERVICE_EOF


# sudo systemctl daemon-reload
# sudo systemctl enable --now genotek-test.service

#echo "Контейнер запущен и работает"
#read -p ""


#curl `docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' genotek-test
