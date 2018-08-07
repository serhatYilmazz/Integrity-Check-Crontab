#!/bin/bash

pathOfInputFolder=$1
pathOfRegistryFile=$2
pathOfLogFile=$3
hashFunction=$4
publicKeyFile=$5
workingPath="$( cd "$(dirname "$0")" ; pwd -P )" 


verifyRegistryFile(){
	tempFiles=$workingPath/tempfiles	
	mkdir $tempFiles
	
	#Verification is executed on the file that contains file paths and their hash values. Therefore ##signature
	#line is seperated. After this line is executed, two tmp files are created. One of them is included paths and hashes of files.
	#The other contains signature value.
	awk 'BEGIN {RS="##signature: "; ORS=""} {print > sprintf("'${workingPath}'/registryFilePart%d.tmp", NR)}' $pathOfRegistryFile
	
	${hashFunction}sum $workingPath/registryFilePart1.tmp | awk '{print $1}' >> $tempFiles/registryHash.tmp
	
	openssl base64 -d -in $workingPath/registryFilePart2.tmp -out $tempFiles/registrySignature.tmp
	isVerified=$(openssl dgst -$hashFunction -verify $publicKeyFile -signature $tempFiles/registrySignature.tmp $tempFiles/registryHash.tmp)
	
	rm -r $tempFiles
	rm $workingPath/registryFilePart2.tmp
}

compareHashFunction(){

	touch $pathOfLogFile
	while IFS='' read -r line; do
	name=$(echo $line | cut -d " " -f 1)
	hashF=$(echo $line | cut -d " " -f 2)
	if [[ ! -e $name ]]; then
		echo "$(date +%s | awk '{print strftime("%d-%m-%Y %H:%M:%S", $1)}'): $name deleted" >> $pathOfLogFile	
	elif [[ $hashF != $(${hashFunction}sum $name | awk '{print $1}') ]]; then	
		echo "$(stat -c %Y $name | awk '{print strftime("%d-%m-%Y %H:%M:%S", $1)}'): $name altered" >> $pathOfLogFile	
	fi
	done < $workingPath/registryFilePart1.tmp #In verifyRegistryFile create the file that contains files hashes with named registryFilePart1.tmp
	
	rm $workingPath/registryFilePart1.tmp 

	isNew $pathOfInputFolder

}

#If a new file created in monitored folder, it is not in the registry file.
isNew(){
	for i in $1/*; do
		if [[ -d $i ]]; then
			isNew $i
		else
			
			if [[ $pathOfRegistryFile -ot $i ]] && [[ -z "$(grep $i $pathOfRegistryFile)" ]]; then 
			echo "$(stat -c %Y $i | awk '{print strftime("%d-%m-%Y %H:%M:%S", $1)}'): $i created" >> $pathOfLogFile	
		fi
	fi
	done	
}

verifyRegistryFile
if [[ $isVerified == "Verified OK" ]]; then
	compareHashFunction $pathOfRegistryFile
else
	echo "$(date +%s | awk '{print strftime("%d-%m-%Y %H:%M:%S", $1)}'): verification failed" >> $pathOfLogFile
	# When verification failed, then execution is ended.
	rm $workingPath/registryFilePart1.tmp 
	crontab -r
	rm $workingPath/execute.sh	
fi
