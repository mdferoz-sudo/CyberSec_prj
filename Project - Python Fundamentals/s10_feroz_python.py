#!/usr/bin/phython3
import platform # retrieving information on os version
import os		# retrieving information on contents, changing and identifying the current directory, etc.
import socket 	# retrieving information on ip address
import requests # retrieving information on ext_ipaddress
import shutil 	# retrieving information on disk space
import psutil 	# retrieving information on running processes and system utilization
import operator # retrieving information on itemgetter to sort dictionary

def os_version():
	#Display os details
	print("******************************")
	print("\nName of the release version: ", platform.version()) #system’s release version
	print("Name of the OS system: ", platform.system()) #get the name of the OS the system is running on
	print("Version of the operating system: ", platform.release()) #get the version of the operating system
	
def dp_address():
	#Display the private IP address, public IP address, and the default gateway
	print("******************************")
	print("Host name is:",socket.gethostname()) #to get the hostname
	#print("Private IP addess is:",socket.gethostbyname(socket.gethostname())) 
	print("Public IP addess is:",requests.get('https://api.ipify.org').text) #Use a external site's API to get IP
	s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
	s.connect(("8.8.8.8", 80)) # temporary connection to 8.8.8.8 using port 80
	print("Private IP addess is:",s.getsockname()[0]) #get local IP address that initiate the connection
	dgateway = os.popen('ip r | grep default | awk \'{print $3}\'').read() #pass Linux command as a subprocess
	print("Default gate way:",dgateway)


def hard_disk():
	#Display the hard disk size; free and used space.
	print("Total disk space:",round(shutil.disk_usage('/').total/ 1024 / 1024 / 1024,2),"GB") # Total space in GB
	print("Free disk space:",round(shutil.disk_usage('/').free/ 1024 / 1024 / 1024,2),"GB") # Free space in GB
	print("Used disk space:",round(shutil.disk_usage('/').used/ 1024 / 1024 / 1024,2),"GB") # Used space in GB
	
	
def list_dir():
	#Display the top five (5) directories and their size.
	
	path='/home/kali/Desktop' 	#set a fix path
	dic_dir ={} 				#dictory to contain dir name and size
	size1=0						#store dir size
	for p in os.listdir(path): 	#step in each dir of the given path
		full_path = os.path.join(path, p) #require full path of walk()
		if os.path.isdir(full_path): #check to ensure no files, onld dir
			#print(p,os.path.getsize(full_path))
			for dirpath, dirnames, filenames in os.walk(full_path): #step into each dir, to calcualte size
				for f in filenames:
					fp = os.path.join(dirpath, f) #require full path of getsize()
					size1 += int(os.path.getsize(fp)) #within a dir caluculate all the file size
					dic_dir.update({p:size1}) #store the dir name (only parent folder) and size only
					
	newdic_dir = dict (sorted (dic_dir.items(), key=operator.itemgetter (1), reverse=True) [:5])
	print(newdic_dir) # sort the dic values (1) in accending order but only the to 5


def usage_cpu():
	#Display the CPU usage; refresh every 10 seconds
	#https://www.geeksforgeeks.org/how-to-get-current-cpu-and-ram-usage-in-python/
	counter=0
	while counter<10: # maxed at 10 counts,to prevent cont loop.
		print('The CPU usage is (every 10s): ', psutil.cpu_percent(10)) #10sec interval 
		counter+=1
print ('Project: Python Fundamentals\n','Name: Muhammad Feroz (S10)')	
print ('\n 1 for Display the OS version')
print ('\n 2 for Display the private/public IP address')
print ('\n 3 for Display the disk utilisation')
print ('\n 4 Display the top five (5) directories')
print ('\n 5 Display the CPU usage')


user_input = input('Enter Menu number between 1-5 \nEnter 0 to exit\n')
match user_input:
	case '1':
		os_version()
	case '2':
		dp_address()
	case '3':
		hard_disk()
	case '4':
		list_dir()
	case '5':
		usage_cpu()
	case _:				#wild-card catch
		print ('Out of range, Exit Program')
		exit()
