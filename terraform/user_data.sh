#!/bin/bash

yum update -y

curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -

yum install -y nodejs git

cd /home/ec2-user

git clone https://github.com/Claudiasuarez28/Parcual-de-Infraestructura.git

cd Parcual-de-Infraestructura/app

npm install

cat > .env <<EOF
PORT=3000
DB_HOST=localhost
DB_USER=clau_user_new
DB_PASSWORD=1234
DB_NAME=appdb
EOF

nohup npm start > app.log 2>&1 &