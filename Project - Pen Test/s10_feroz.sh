#! /bin/bash

function getIP_func
{
read -p 'Enter network to be scanned with the CIDR notation (Eg. 12.123.123.0/24 or 123.123.154.20/16) : ' ip_add 
pattern="[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,2}" #rgex pattern for IP address
#Validation of user input
if [[ $ip_add =~ $pattern ]]; then
  echo -e "\n Network address matches the pattern : $ip_add \n"
  sleep 3s
else
  echo -e "\n Network address does not match the pattern \n"
   getIP															# repeat function due to invalid IP address
fi
}
function netdis_func
{
echo -e '\n Running Net discovery \n'
netdis_results=$(sudo netdiscover -r $ip_add -P) 					# run netdiscovery for given network
echo "$netdis_results" > netdis_results.txt							# log results to a file
echo "$netdis_results"|grep -oP '([0-9]{1,3}\.){3}[0-9]{1,3}' > IP_only.txt # extract only IP address base on the pattern
echo -e '\n Running Net discovery completed ! \n' 
}
function getUsrpath_func
{
#Validation of user input
while true 
read -p 'Provide output directory path : ' usr_path
do
	if [ -d $usr_path ]												# check if input is a directory
	then
		echo -e "\n Directory exists. Content within $usr_path \n"
		ls -lah $usr_path											# print contents within path
		break
	else 
		echo -e "\n Directory not exists. \n"						# repeat function due to invalid dir
		continue
	fi
done
}

function nmap_func
{
echo -e '\n Running Nmap scan \n' 
#nmap_results=$(sudo masscan -p1-65535,U:1-65535 -iL ./IP_only.txt --banners --rate=1000|pv -t)			# Takes long time to complete
nmap_results=$(sudo nmap -sU -sS -sV -F -iL ./IP_only.txt --open -T4 --version-intensity 0|pv -t)		# get TCP/UDP port/services details
echo "$nmap_results" > nmap_results.txt							# log results to a file
sudo nmap -sV -F -iL ./IP_only.txt -oX nmap_resultsXML.xml >/dev/null # get XML for NMAP Vul analysis
echo -e '\n Running Nmap scan completed ! \n'
}

function vulner_func
{
echo -e '\n Running vulnerabilities scan \n' 
nmap_Vulresults=$(sudo nmap -sU -sS -sV -F -iL ./IP_only.txt --open -T4 --version-intensity 0 --script=vulners.nse 2> /dev/null |pv -t) # get CEV details
ssp_results=$(searchsploit --nmap ./nmap_resultsXML.xml 2> /dev/null |pv -t) # get posible expolit details
echo "$nmap_Vulresults" > nmap_Vulresults.txt					# log results to a file
echo "$ssp_results" > ssp_results.txt							# log results to a file
echo -e '\n Running vulnerabilities scan completed ! \n' 
}

function wkpass_func
{
read -p 'Would like to to use the default password list [y/n] : ' choice_wk
echo 'Running weak password scan /n' 
# Descesion making proceess to supply new lst
case $choice_wk in 
	n)
		while true 
		read -p 'Please provide full path and file name : ' usr_file
		do
			if [ -f $usr_file ]									# check path provided inpu is a file
			then
				echo -e "\n File exists : $usr_file \n"
				ls -lah $usr_file								# print file properties
				break
			else 
				echo -e "\n File not exists. \n"
				continue
			fi
		done
	;;
	y)
	
		passlst='./wordlst/top-passwords-shortlist.txt'			# default password list
		echo "Existing password list : $passlst"
	;;
	*)
		echo "Invalid option"
		wkpass_func												# repeat case for an invalid option
	;;
esac

# ssh brute force, out put of commands not displayed to terminal and counter in place to measure progress
echo 'Testing weak password for ssh servicer (Kindly be patient)'
weakp_ssh=$(hydra -L ./wordlst/top-usernames-shortlist.txt  -P $passlst -M ./IP_only.txt ssh -t6 2> /dev/null |pv -t)
echo "$weakp_ssh" > weakp_ssh.txt

# rdp brute force, out put of commands not displayed to terminal and counter in place to measure progress
echo 'Testing weak password for rdp servicer (Kindly be patient)'
weakp_rdp=$(hydra -L ./wordlst/top-usernames-shortlist.txt  -P $passlst -M ./IP_only.txt rdp -t6 2> /dev/null |pv -t)
echo "$weakp_rdp" > weakp_rdp.txt

# ftp brute force, out put of commands not displayed to terminal and counter in place to measure progress
echo 'Testing weak password for ftp servicer (Kindly be patient)'
weakp_ftp=$(hydra -L ./wordlst/top-usernames-shortlist.txt  -P $passlst -M ./IP_only.txt ftp -t6 2> /dev/null |pv -t)
echo "$weakp_ftp" > weakp_ftp.txt

# telnet brute force, out put of commands not displayed to terminal and counter in place to measure progress
echo 'Testing weak password for telnet servicer (Kindly be patient)'
#weakp_telnet=$(hydra -L ./wordlst/top-usernames-shortlist.txt  -P $passlst -M ./IP_only.txt telnet -t12 2> /dev/null |pv -t) # takes longer time for excution
weakp_telnet=$(medusa -U ./wordlst/top-usernames-shortlist.txt -P $passlst -H ./IP_only.txt -M telnet 2> /dev/null |pv -t)
echo "$weakp_telnet" > weakp_telnet.txt

echo 'Running weak password scan comeplted ! /n' 
}

function logRst_func
{
# Output of results are displayed at the end
echo -e '\n Output of results \n' 
echo -e "\n This is the RESULTS for Netdiscovery : \n $netdis_results"
echo -e "\n This is the RESULTS for Nmap Ports/Services : \n $nmap_results"
echo -e "\n This is the RESULTS for Nmap Vulnerability (CVES): \n $nmap_Vulresults"
echo -e "\n This is the RESULTS for Searchsploit (possible exploit) : \n $ssp_results"
echo -e "\n This is the RESULTS for Weak SSH Password: \n $weakp_ssh"
echo -e "\n This is the RESULTS for Weak RDP Password: \n $weakp_rdp"
echo -e "\n This is the RESULTS for Weak FTP Password: \n $weakp_ftp"
echo -e "\n This is the RESULTS for Weak TELNET Password: \n $weakp_telnet"
echo -e '\n Output of results completed ! \n' 

while true 
do
	read -p 'Would like to search the through the results [y/n] : ' choice_lg
# serach of contents within the results with grep
	case $choice_lg in
		n) 
		  break
		;;
		
		y)
		 read -p "Enter Text to be search : " searcht
		 # grep with variable use to filter the results
		 echo -e '\n Output of results \n' 
		 echo -e "\n This is the RESULTS for Netdiscovery : \n $netdis_results" | grep "$searcht"
		 echo -e "\n This is the RESULTS for Nmap Ports/Services : \n $nmap_results" | grep "$searcht"
		 echo -e "\n This is the RESULTS for Nmap Vulnerability (CVES): \n $nmap_Vulresults" | grep "$searcht"
		 echo -e "\n This is the RESULTS for Searchsploit (possible exploit) : \n $ssp_results" | grep "$searcht"
		 echo -e "\n This is the RESULTS for Weak SSH Password: \n $weakp_ssh" | grep "$searcht"
		 echo -e "\n This is the RESULTS for Weak RDP Password: \n $weakp_rdp" | grep "$searcht"
		 echo -e "\n This is the RESULTS for Weak FTP Password: \n $weakp_ftp" | grep "$searcht"
		 echo -e "\n This is the RESULTS for Weak TELNET Password: \n $weakp_telnet" | grep "$searcht"
		 echo -e '\n Output of results completed ! \n'		 
		 continue
		;;
		
		*)
		echo "Invalid option"  						# repeat case for an invalid option
		continue
		;;
	
	esac
done
}

function doczip_func
{
read -p 'Would like to zip file [y/n] : ' choice_zp
# Descesion making proceess to zip files and/or move files to output dir
case $choice_zp in 
	n)
		echo -e '\n Files are not ziped and they are located in : $usr_path \n'
		Deletefiles											# delete unrequired tempfiles
		for count in $(ls |grep -e .txt)					# get list of txt files from dir
		do
			echo "$count"
			mv $count $usr_path								# move txt files 
		done											
		echo -e '\n List of Files in the folder \n'
		ls -lah $usr_path
	;;
	y)
		echo -e '\n Files are ziped and they are located in : $usr_path \n'
		Deletefiles											# delete unrequired tempfiles
		echo -e '\n Running zip compression \n' 	
		for count in $(ls |grep -e .txt -e .xml)			# get list of txt and xml files from dir
		do
			echo "$count"
			tar -uf $(date +"%y%m%d" ).tar $count			# zip multiple logs to a single tar file with current date a the name
		done
		mv ./$(date +"%y%m%d" ).tar $usr_path				# move tar file to a output dir
		echo -e '\n List of Files in the folder \n'
		ls -lah $usr_path
les
		echo -e '\n Running zip compression completed !\n' 			
	;;
	*)
		echo "Invalid option"
		doczip
	;;
esac
}

function Deletefiles
{
echo -e "\n Deleting tempfiles \n"
rm -f IP_only.txt 									#delete temp ip file
rm -f nmap_resultsXML.xml 							# delete temp files
echo -e "\n Deleting tempfiles completed ! \n"									
echo -e "\n Deleting tempfiles completed ! \n"
}

### start script log ###
touch ./Penl.log # create log file
(date; hostname) |tr '\n' '\t'|tee -a ./Penl.log #timestamp to log file

#Banner introduction
figlet -mini Project - PENETRATION TESTING
echo -e " ******* S10 - Muhammad Feroz (PRJ: VULNER)*********** \n"
echo "*\*Start Script*/*"

### Main Function ###
getIP_func > >(tee -ap ./Penl.log) #get network address and screen output to log file
getUsrpath_func > >(tee -ap ./Penl.log) #get output path and screen output to log file
while true
do
	echo "1 for Basic Scan"
	echo "2 for Full Scan"
	echo "e for Exit Scan"
	read -p 'Choose the scan you would like to perform : ' usr_Option #get user option on scan output
	case $usr_Option in 
		1)
			echo -e '\n *** RUNNING BASIC SCAN *** \n'
			(date; hostname) |tr '\n' '\t'|tee -a ./Penl.log 
			### Functions ###
			sleep 5s
			netdis_func > >(tee -ap ./Penl.log) #run netdiscovery and screen output to log file
			nmap_func   > >(tee -ap ./Penl.log) 			#run nmap and screen output to log file
			wkpass_func > >(tee -ap ./Penl.log)			#run brute force tools and screen output to log file
			logRst_func > >(tee -ap ./Penl.log)			#get outputs to be displayed and screen output to log file
			doczip_func > >(tee -ap ./Penl.log)			#run zip options for file and screen output to log file
			echo -e '\n *** BASIC SCAN COMPLETED *** \n'			
		;;
		2)
			echo -e '\n *** RUNNING FULL SCAN *** \n'
			(date; hostname) |tr '\n' '\t'|tee -a ./Penl.log
			### Functions ###
			sleep 5s
			netdis_func > >(tee -ap ./Penl.log)
			nmap_func   > >(tee -ap ./Penl.log)
			wkpass_func > >(tee -ap ./Penl.log)
			vulner_func > >(tee -ap ./Penl.log)			#run vulerbility testing and exploit suggestion and screen output to log file
			logRst_func > >(tee -ap ./Penl.log)
			doczip_func > >(tee -ap ./Penl.log)
			echo -e '\n *** FULL SCAN COMPLETED *** \n'
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
echo "*\*End Script*/*"

