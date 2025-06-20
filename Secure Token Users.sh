#!/usr/bin/env zsh --no-rcs

# Extension attribute to report all user accounts who have a secure token
# If a user is found to have a secure token, the results will be displayed as:
#   Admins: user1, user2 (or "None" if none found)
#   Non-Admins: user1, user2 (or "None" if none found)
#
# If no user is found to have a secure token, the result will be:
#   "No Secure Token Users"
# If an unsupported file system is found, the result will be:
#   Unsupported File System: (File System Type)

# Variable to determine File System Personality
fsType="$(/usr/sbin/diskutil info / | /usr/bin/awk '/File System Personality:/{print $4}')"

if [[ "$fsType" != *APFS* ]]; then
    echo "<result>Unsupported File System: $fsType</result>"
    exit 0
fi

secureTokenAdmins=()
secureTokenUsers=()

# Loop through UUIDs of secure token holders
for uuid in $(/usr/sbin/diskutil apfs listUsers / | /usr/bin/awk '/\+\-\-/ {print $2}'); do
    username="$(/usr/bin/dscl . -search /Users GeneratedUID "$uuid" | /usr/bin/awk 'NR==1{print $1}')"
    
    if /usr/sbin/dseditgroup -o checkmember -m "$username" admin &>/dev/null; then
        secureTokenAdmins+=("$username")
    else
        secureTokenUsers+=("$username")
    fi
done

if [[ -z ${secureTokenAdmins[*]} ]]; then
    stList="Admins: None"
else
    stList="Admins: ${secureTokenAdmins[1]}"

    if ((${#secureTokenAdmins[@]} > 1 )); then
        for user in $"{secureTokenAdmins[@]:1}"; do
            stList+=", $user"
        done
    fi
fi

if [[ -z ${secureTokenAdmins[*]} ]] && [[ -z ${secureTokenUsers[*]} ]]; then
    stList="No Secure Token Users"
elif [[ -z ${secureTokenUsers[*]} ]]; then
    stList+="\nNon-Admins: None"
else
    stList+="\nNon-Admins: ${secureTokenUsers[1]}"

    if ((${#secureTokenUsers[@]} > 1 )); then
        for user in "${secureTokenUsers[@]:1}"; do
            stList+=", $user"
        done
    fi
fi

echo "<result>$stList</result>"
