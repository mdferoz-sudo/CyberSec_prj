#! /bin/bash

#Banner introduction
figlet -mini Project - LINUX Fundamentals
echo " ******* S10 - Muhammad Feroz ***********
"
# Variables to store string to be displayed in Select loop
version="Display Linux version"
IP="Display private, public and default gatway"
disk="Display the hard disk size, free and used space"
directory="Display the top 5 directories and their size"
cpu="Display the CPU usuage, refresh every 10 sec"

# PS3 custom prompt for select loop
PS3="Enter your option (number only)==>"
select num in "$version" "$IP" "$disk" "$directory" "$cpu" "Exit_Menu" #listing all variables
do
	case $num in "$version")
	echo -n "Description: "; lsb_release -a |grep "Description:" | awk '{print $2, $3 ,$4}' #grep only the value and customise the output from 3 columns
	echo -n "Version: ";lsb_release -a |grep -i "Release:" | awk '{print $2}' 				#grep only the value and customise the output 1 column
	;;
		"$IP")
		echo -n "Private IP address: ";hostname -I											#use flag to get the value and customise the output for hostname
		echo -n "Public IP address: ";curl ifconfig.me										#curl to get the value and customise the output for IP add							
		echo ""										
		echo -n "Defaulr Gateway: ";ip route | grep default | awk '{print $3}'				#grap default and customise the output for Gateway from 3rd column

	;; 
		"$disk")
		 df -h /dev/sda1
		 echo -n "Total Hard disk space: ";df -h /dev/sda1 | awk '{print $2}'|grep -v 'Size' #grep value from 2nd column and customise the output for total space
		 echo -n "Availabe Hard disk space: ";df -h /dev/sda1 | awk '{print $4}'|grep -v 'Avail' #grep value from 4th column and customise the output for avail space
		 echo -n "Used Hard disk space: ";df -h /dev/sda1 | awk '{print $3}'|grep -v 'Used'	 #grep value from 3rd column and customise the output for used space

	;;
		"$directory")
		echo "Top 5 directories and their size: ";du -h / 2>/dev/null |sort -h -r |head -n5 # search from root, error msg passed to temp folder and result sorted and top 5 displayed
	;;
		"$cpu")
		echo -n "Please provide the number of iteration for this report : "						# to prevent manual exit which affect the select loop
		read countA
		echo -n "CPU usuage, refresh every 10 sec: ";	sar -h -u 10 "$countA" | awk '{print $1,$2,$3,$4;}' #10 sec refresh of values

	;;
		Exit_Menu)
			break # To exit the selection loop
	;;
	*) echo "ERROR: Invalid selection" # Any other option apart from the 6 choices is repeat the loop
	
	;;
	
	esac
done
