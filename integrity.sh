#!/bin/bash


#Determining the working path. (Path of the files placed.)
workingPath="$( cd "$(dirname "$0")" ; pwd -P )"

if [[ $1 == "stop" ]]; then
	crontab -r
	workingPath="$( cd "$(dirname "$0")" ; pwd -P )"
	[[ -e $workingPath/execute.sh ]] && rm $workingPath/execute.sh	
elif [[ $1 == "start" ]]; then

shift
pathOfInputFolder=""
pathOfRegistryFile=""
pathOfLogFile=""
hashFunction=""
privateKeyFile=""
publicKeyFile=""
intervalTime=0
numberOfArgs=$#



#Parsing the arguments when first executed the script
for (( i=1; i <= $numberOfArgs; i++)); do
	case "$1" in
		"-p" )
			shift	
			pathOfInputFolder="$1"
		;;
		"-r" )
			shift
			pathOfRegistryFile="$1"
		;;
		"-l" )
			shift
			pathOfLogFile="$1"	
		;;
		"-h" )
			shift
			hashFunction="$1"
		;;
		"-k" )
			shift	
			privateKeyFile="$1"
			shift
			publicKeyFile="$1"
		;;
		"-i" )
			shift	
			intervalTime=$1
		;;
		*)
			shift
		;;
	esac
done

echo -n "" > $pathOfLogFile

#Hash function validation
if [[ $hashFunction -eq "MD5" ]]; then
	hashFunction="md5"
else
	hashFunction="sha512"
fi

#After parsing, creating registry file and signing it.
$workingPath/monitorInitial.sh $pathOfInputFolder $pathOfRegistryFile $hashFunction $privateKeyFile

#To add it to crontab, needs a script file that is executable.
touch $workingPath/execute.sh
chmod +x $workingPath/execute.sh

#Sending necessary arguments to executable file.
echo "$workingPath/monitorPeriodic.sh $pathOfInputFolder $pathOfRegistryFile $pathOfLogFile $hashFunction $publicKeyFile" > $workingPath/execute.sh

#Accessing the crontab list without using crontab editor.
echo "*/$intervalTime * * * * $workingPath/execute.sh" > addTask
crontab addTask
rm addTask

else
	echo -e "ERROR :: Undefined command!!!\n'integrity.sh start [args1] [args2] ..' and 'integrity.sh stop' is defined"

fi
