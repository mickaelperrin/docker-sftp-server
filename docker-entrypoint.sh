#!/bin/bash
set -e

# Allow to run complementary processes or to enter the container without
# running this init script.
if [ "$1" == '/usr/sbin/sshd' ]; then

  # Ensure time is in sync with host
  # see https://wiki.alpinelinux.org/wiki/Setting_the_timezone
  if [ -n ${TZ} ] && [ -f /usr/share/zoneinfo/${TZ} ]; then
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
    echo ${TZ} > /etc/timezone
  fi

  # Regenerate keys
  if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
  fi
  if [ ! -f "/etc/ssh/ssh_host_dsa_key" ]; then
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
  fi
  if [ ! -f "/etc/ssh/ssh_host_ecdsa_key" ]; then
    ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa
  fi

  # Grab UID of owner of sftp home directory
  if [ -z $OWNER_ID ]; then
    OWNER_ID=$(stat -c '%u' $FOLDER)
  fi

  # Create appropriate SFTP user
  # If uid doesn't exist on the system
  if ! cut -d: -f3 /etc/passwd | grep -q $OWNER_ID; then
    echo "no user has uid $OWNER_ID"
    # If user doesn't exist on the system
    if ! cut -d: -f1 /etc/passwd | grep -q $USERNAME; then
      echo "no user has name $USERNAME"
      useradd -u $OWNER_ID -M -d $FOLDER -G sftp -s /bin/false $USERNAME
    else
      echo "an user has name $USERNAME"
      usermod -u $OWNER_ID -G sftp -a -d $FOLDER -s /bin/false $USERNAME
    fi
  else
    # If user doesn't exist on the system
    echo "user with uid $OWNER_ID already exist"
    existing_user_with_uid=$(awk -F: "/:$OWNER_ID:/{print \$1}" /etc/passwd)
    usermod -d $FOLDER -G sftp -a -s /bin/false -l $USERNAME $existing_user_with_uid
  fi

  # Change sftp password
  echo "$USERNAME:$PASSWORD" | chpasswd

  # Mount the data folder in the chroot folder
  if [ $CHROOT == 1 ]; then
    mkdir -p /chroot${FOLDER}
    sed -i -e 's/#ChrootDirectory/ChrootDirectory/' /etc/ssh/sshd_config
    mount --bind $FOLDER /chroot${FOLDER}
  fi

  # Check if a script is available in /docker-entrypoint.d and source it
  # You can use it for example to create additional sftp users
  for f in /docker-entrypoint.d/*; do
    case "$f" in
      *.sh)  echo "$0: running $f"; . "$f" ;;
      *)     echo "$0: ignoring $f" ;;
    esac
  done

fi

exec "$@"


