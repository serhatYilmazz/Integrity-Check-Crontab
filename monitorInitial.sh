#!/bin/bash

pathOfInputFolder=$1
pathOfRegistryFile=$2
hashFunction=$3
privateKeyFile=$4


#The function first reset if the registry file exists before
#Then get all files specified hash functions with getHashFunction() 
#To get registry file's hash; it is call the function hashOfRegistry
updateHash(){
	echo -n "" > $pathOfRegistryFile # Reset registry file.
	getHashFunction $1 #Getting hash functions of files that is included by monitored folder.
	signRegistryFile #Signing the hash value of registry file.
}

#Getting all files' hash values in monitored folder (includes inner folder' content) 
#and recording them to registry file
getHashFunction(){
	for i in $1/*; do
		if [[ -d $i ]]; then
			getHashFunction $i
		elif [[ -f $i ]]; then 
			echo "$i $(${hashFunction}sum $i | awk '{print $1}')" >> $pathOfRegistryFile
		fi
	done

}


signRegistryFile(){
	workingPath="$( cd "$(dirname "$0")" ; pwd -P )"
	tempFiles=$workingPath/tempfiles	
	mkdir $tempFiles
	
	#Getting hash value of regsitry file.
	${hashFunction}sum $pathOfRegistryFile | awk '{print $1}' >> $tempFiles/registryHash.tmp

	#Writing the signed part to a tmp file
	openssl dgst -$hashFunction -sign $privateKeyFile -out $tempFiles/registrySignature.tmp $tempFiles/registryHash.tmp
	openssl base64 -in $tempFiles/registrySignature.tmp -out $tempFiles/registrySignatureBase64.tmp
	
	#Appending the signature value into ##signature.
	echo -en "##signature: " >> $pathOfRegistryFile
	cat $tempFiles/registrySignatureBase64.tmp >> $pathOfRegistryFile
	
	#Created tmp files deletion.
	rm -r $tempFiles
}
updateHash $pathOfInputFolder
