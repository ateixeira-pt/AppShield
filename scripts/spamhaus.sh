#!/usr/bin/python3

# ==============================================================================
# Import Helpers
# ==============================================================================

from subprocess import call

# ==============================================================================
# Public Functions Helpers
# ==============================================================================

# Main Loop Function
def main():

	# Download Files Using Curl
	call(["curl", "-fSL", "https://www.spamhaus.org/drop/drop.txt", "-o", "drop.txt"])
	call(["curl", "-fSL", "https://www.spamhaus.org/drop/edrop.txt", "-o", "edrop.txt"])

	# This Will Overwrite The Default File
	call(["cp", "/etc/nginx/bots.d/blacklist-ips.conf.orig", "/etc/nginx/bots.d/blacklist-ips.conf"])

	# Open As Append File
	with open('/etc/nginx/bots.d/blacklist-ips.conf', 'a') as FileObj:

		# Append Delimiter
		FileObj.write('\n\n')
		FileObj.write('###################################################\n')
		FileObj.write('### Spamhaus Drop ###\n')
		FileObj.write('###################################################\n')

		#  Loop Trough Drop Files
		DropObj = open('drop.txt', 'r')
		for DropEntry in DropObj.readlines()[4:]:
			FileObj.write('\t%s\t\t1;\n' % DropEntry.split(';')[0].strip())

		# Append Delimiter
		FileObj.write('\n\n')
		FileObj.write('###################################################\n')
		FileObj.write('### Spamhaus EDrop ###\n')
		FileObj.write('###################################################\n')

		#  Loop Trough Drop Files
		DropObj = open('edrop.txt', 'r')
		for DropEntry in DropObj.readlines()[4:]:
			FileObj.write('\t%s\t\t1;\n' % DropEntry.split(';')[0].strip())			


# Main Loop
if __name__ == '__main__':
	main()