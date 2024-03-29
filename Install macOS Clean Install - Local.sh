#!/bin/bash

# Initialize varables
latestVersion="11.5"
adminSignedIn="False"
nonAdminSignedIn="False"
onlyAdminSignedIn="False"

downloadInstaller(){

    # Downloads the last version of the macOS installer form the inventory site
    echo "Copying macOS installer to applications folder"

    # Prevent the comptuer from sleeting
    caffeinate -dis &
    caffeinatePID=$!

    # Copy the installer to the applications folder
    cp -R "/Volumes/Hive/Install macOS Big Sur.app" /Applications

    # Allow the computer to sleep again
    kill "${caffeinatePID}"
    echo "macOS installer copied"
}

# Loop through each logged in user to see if the admin is currently logged in
for user in $(who | awk '{ print $1 }') ; do
    if [[ "${user}" == "admin" ]] ; then
		adminSignedIn="True"
    else
        nonAdminSignedIn="True"
    fi
done

if $adminSignedIn; then
    if !($nonAdminSignedIn); then
        onlyAdminSignedIn="True"
    fi
fi

if $onlyAdminSignedIn; then

    # Check to see if there is more than 10GB free
    freeSpace=$(df -k / | tail -n +2 | awk '{ print $4 }')                     
    if [[ ${freeSpace%.*} -ge 10000000 ]]; then
        echo "More that 10GB available"
    else
        echo "Not enough disk space to download macOS installer"
        exit 0
    fi

    # See if they already have a copy downloaded and if it's the correct version
    if (test -e "/Applications/Install macOS Big Sur.app"); then
        installerVersion=$(defaults read /Applications/Install\ macOS\ Big\ Sur.app/Contents/Info.plist| grep DTPlatformVersion | tail -n1 | awk -F\" '{print $2}')

        if [[ "$latestVersion" == "$installerVersion" ]]; then
            echo "macOS installer already downloaded"
        else
            echo "Deleted old macOS instller"
            rm -rfd "/Applications/Install macOS Big Sur.app"
            downloadInstaller
        fi
    else
        downloadInstaller
    fi

    # Uncomment the line below to make the script work.  This will wipe your drive!
    # /Applications/Install\ macOS\ Big\ Sur.app/Contents/Resources/startosinstall --agreetolicense --nointeraction --eraseinstall

fi

echo "Unable to install macOS"