#!/bin/bash

#Provisioning file path
PROVISIONING_FILE=$1

function convertProvisioningToPlist {
    if ([[ -f "${PROVISIONING_PROFILE_PLIST}" ]]); then
        rm -rf "${PROVISIONING_PROFILE_PLIST}"
    fi

    security cms -D -i "${PROVISIONING_FILE}" >> ${PROVISIONING_PROFILE_PLIST}
}

function exportProvisioningProfileUUID {
  export PROVISIONING_PROFILE_SPECIFIER="$(/usr/libexec/PlistBuddy -c "Print UUID" "${PROVISIONING_PROFILE_PLIST}")"
}

function extractBundleIdentifier {

   export BUNDLE_IDENTIFIER=""
   DEVELOPMENT_TEAM="$(/usr/libexec/PlistBuddy -c "Print Entitlements:com.apple.developer.team-identifier" "${PROVISIONING_PROFILE_PLIST}")"
   BUNDLE_IDENTIFIER="$(/usr/libexec/PlistBuddy -c "Print Entitlements:application-identifier" "${PROVISIONING_PROFILE_PLIST}")"

   BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER//${DEVELOPMENT_TEAM}./$EMPTY}"

}

function extractCodeSigningIdentiy {
    export CODE_SIGN_IDENTITY=""
    INDEX=0
    while true
    do
         CODE_SIGN_IDENTITY="$( /usr/libexec/PlistBuddy -c "Print DeveloperCertificates:${INDEX}" "${PROVISIONING_PROFILE_PLIST}" | openssl x509 -inform DER -noout -subject | grep -o 'CN=.*/OU=' | sed "s/CN=//" | sed "s/\/OU=//")"
         if security find-identity -p codesigning -v | grep "${CODE_SIGN_IDENTITY}" > /dev/null; then
             break
         fi
         ((INDEX+=1))
    done
}

function extractExportType {
     DEBUG="$(/usr/libexec/PlistBuddy -c "Print Entitlements:get-task-allow" "${PROVISIONING_PROFILE_PLIST}")"

     export IPA_EXPORT_TYPE=""
     if [[ $DEBUG == "true" ]]; then
            IPA_EXPORT_TYPE="development"
     else
            set +e
            ENTERPRISE="$(/usr/libexec/PlistBuddy -c "Print ProvisionsAllDevices" "${PROVISIONING_PROFILE_PLIST}")"
            set -e
             if [[ $ENTERPRISE == "true" ]]; then
                    IPA_EXPORT_TYPE="enterprise"
              else
                    set +e
                    PROVISIONED_DEVICES="$(/usr/libexec/PlistBuddy -c "Print ProvisionedDevices" "${PROVISIONING_PROFILE_PLIST}")"
                    set -e
                    if [[ ! -z $PROVISIONED_DEVICES ]]; then
                        IPA_EXPORT_TYPE="ad-hoc"
                    else
                        IPA_EXPORT_TYPE="app-store"
                    fi
               fi
     fi
}


PROVISIONING_PROFILE_PLIST="distribution.plist"
#to convert a provisioning profile to a plist, the certificate (dev/dist) of the account that holds the provisioning profile needs to be already installed.
convertProvisioningToPlist

exportProvisioningProfileUUID
echo "Your provisioning profile uuid: ${PROVISIONING_PROFILE_SPECIFIER}"

extractCodeSigningIdentiy
echo "Your code signing identity: ${CODE_SIGN_IDENTITY}"

extractBundleIdentifier
echo "Your bundle identifier: ${BUNDLE_IDENTIFIER}"

extractExportType
echo "Provisioning profile type: ${IPA_EXPORT_TYPE}"
