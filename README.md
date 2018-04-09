# Provisioning Profile Reader

A Shell script that extract provisioning profile specific information such as: uuid, bundle identifier, code signing identity, provisioning profile type.
This can be used when archiving and generating an ipa that you would like to resign it knowing only the provisioning profile.
Moreover, if you wish to build an iOS app, the script above extract all the information needed to resign, and generate an ipa.

Note: That in order to read the provisioning profile information, its associated certificate needs to be installed on the machine you are running the script.


## <a name="usage"></a>Usage

```
 ./provisioning_profile_reader.sh ${PROVISIONING_PROFILE_PATH}

```
