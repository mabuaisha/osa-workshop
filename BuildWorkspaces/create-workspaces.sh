#!/bin/bash
#
# account running this script should have sudo group 
# 
if [ "$#" -ne 3 ] ; then
  echo "Usage: $0 Packet-Auth-Token Packet-Project-ID Number-Workspaces-To-Create" >&2
  exit 1
fi

#must be lower case since usernames must be lowercase
LAB_NAME="osa"

PACKET_AUTH_TOKEN="$1"
PACKET_PROJECT_ID="$2"
NUMBER_WORKSPACES="$3"

echo PACKET_AUTH_TOKEN=$PACKET_AUTH_TOKEN
echo PACKET_PROJECT_ID=$PACKET_PROJECT_ID
echo NUMBER_WORKSPACES=$NUMBER_WORKSPACES

git clone https://github.com/OpenStackSanDiego/osa-workshop
cd osa-workshop

# Terraform needs access to these to install plugins
chmod 755 ~root
touch ~root/.netrc
chmod 777 ~root/.netrc

for i in `seq -w 01 $NUMBER_WORKSPACES`
do
  # setup the new student account
  USER=$LAB_NAME$i
  echo "Creating $USER"
  #  encrypted password is openstack
  sudo useradd -d /home/$USER -p 42ZTHaRqaaYvI -s /bin/bash $USER 
  sudo mkdir /home/$USER
  sudo chown $USER.sudo /home/$USER
  sudo chmod 2775 /home/$USER


  echo ""                                       >  terraform/terraform.tfvars
  echo packet_auth_token=\"$PACKET_AUTH_TOKEN\" >> terraform/terraform.tfvars
  echo packet_project_id=\"$PACKET_PROJECT_ID\" >> terraform/terraform.tfvars
  echo lab_number=\"$i\"                        >> terraform/terraform.tfvars
  echo lab_name=\"$USER\"                       >> terraform/terraform.tfvars
  echo terraform_username=\"$USER\"             >> terraform/terraform.tfvars
  echo project_name=\"$USER\"                   >> terraform/terraform.tfvars


  # copy over the student files from the base template
  sudo -u $USER cp -r terraform /home/$USER/
  pushd /home/$USER/terraform
  sudo touch terraform.tfstate
  sudo chown $USER.sudo terraform.tfstate
  sudo -u $USER terraform init
#  screen -dmS $USER-terraform-apply terraform apply -auto-approve
  popd
done

cat <<EOF >> /etc/ssh/sshd_config
Match user $LAB_NAME*
  PasswordAuthentication yes
EOF
service sshd restart