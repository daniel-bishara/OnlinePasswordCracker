# OnlinePasswordCracker
This Script was created for Educational purposes only. Neither the accounts cracked nor the website are real, and were both created specifically for the purposes of this assignement. The purpose of this assignment was to understand how malicious hackers can abuse flaws in a websites design to find both usernames and passwords of its users. 

The website created for this assignment had a simple defence mechanism to prevent online cracking attacks. In the event that a user had three failed log in attempts within the same hour, the account would be locked for several hours. 

While this protected against targetted attacks, it had little effectiveness against trawling attacks. That is, this made it difficult to crack a single account at a time, however by attempting to crack thousands of accounts at the same time, by the time that an account was revisited, the hour would already be over.

This script sends HTTP requests to the backend of the website to mimic a login attempt. It monitors the response of the website to identify if the username is incorrect or if the password is incorrect, and records the results into a textfile.
