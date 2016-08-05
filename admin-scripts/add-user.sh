#!/bin/bash

print_usage () {
	echo "add-user.sh"
	echo "	--username=UserName"
	echo "	--group=GroupName"
	exit 1
}

echo "
This version is incomplete. It also needs to automate the specification
of the home directory. Currently, it will simply print out the necessary
commands to add a user with LDAP-based auth to paste in.
"

# Process the arguments
for i in "$@"
do
case $i in
	-u=*|--username=*)
	USERNAME="${i#*=}"
	shift # past argument=value
	;;
	-g=*|--group=*)
	GROUP="${i#*=}"
	shift # past argument=value
	;;
	-t=*|--type=*)
	TYPE="${i#*=}"
	shift # past argument=value
	;;
	*)
		# unknown option
	;;
esac
done


if [ -z $USERNAME ] || [ -z $GROUP ]
then
	print_usage
fi

# This section pulls the employee number out of LDAP. We use that to make sure 
# that we don't get uid collisions, or lack of consistency.

USERID=`ldapsearch -v -h bcmds.bcm.edu -x -b "uid=${USERNAME},ou=people,dc=bcm,dc=edu" employeeNumber | grep employeeNumber | sed 's/[^0-9]*//g'`

echo $USERID

if [ -z $USERID ]
then
	echo "Unable to determine uid from LDAP. Bug Tanner to add the non-Baylor code"
	exit 1
fi

GROUPID=`getent group ${GROUP}`
echo $GROUPID

if [ -z $GROUPID ]
then
	echo "${GROUP} does not yet exist as a group. Use the add-group script to create it first, then you can assign new or existing users to it."
	exit 1
fi

echo "Create user ${USERNAME} with uid & gid of ${USERID} in the group ${GROUP}?"
read -p "Are you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
	echo Nevermind...
	exit 1
else
	echo OK.
fi

echo groupadd -g $USERID ${USERNAME}
if [ $? -ne 0 ]
then
	echo "Failed to add group $USERID"
	exit -1
fi
echo useradd --base-dir /mnt/home -m ${USERNAME} --uid ${USERID} --gid ${USERID}
if [ $? -ne 0 ]
then
	echo "Failed to add ${USERNAME} with ${USERID}"
	exit -1
fi
