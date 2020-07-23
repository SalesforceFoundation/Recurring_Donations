#!/bin/bash

## Verify that hasSampleData is set to false before continuing
if grep -q '"hasSampleData": true' orgs/feature.json
then
    echo "WARNING: The feature.json still has \"hasSampleData\" set to true. Cannot continue until this is set to false."
    exit
fi

echo "###############################################################################################"
echo "What this script does:"
echo "1. Deploy all metadata to a scratch org"
echo "2. Use the cci 'retrieve_unpackaged' command to retrieve all configuration from the org into the src folder"
echo "3. Reset and/or delete any retrieved metadata that is unrelalated to translations"
echo "4. Execute the cci 'cleanup_translation_metadata' task against the metadata to strip invalid or extranous xml content"
echo ""
echo ""
echo "When the script has fully completed, the developer should review any pending changes in an IDE, such as VSCode"
echo "to verify that all changes are expected."
echo ""
echo "ONLY changes to the 'objectTranslation' and 'translation' files should be commited to the repository."
echo "ALL OTHER CHANGED FILES SHOULD BE IGNORED."
echo "###############################################################################################"
read -s -n 1 -p "Press any key to continue ..."
echo ""

echo "# ==== CREATE THE SCRATCH ORG ===="
cci org remove translations
cci org scratch feature translations --days 1
cci flow run dependencies --org translations 
cci flow run deploy_unmanaged --org translations
cci task run update_admin_profile --org translations

echo "# ==== RESET the Package.xml and use retrieve_unpackaged to pull down the metadata ===="
git checkout src/package.xml
cci task run retrieve_unpackaged --org translations -o path src -o package_xml src/package.xml

cci org remove translations

echo "# ==== DISCARD other files pulled down by the above task that we do not need ===="
git checkout src/classes/*
git checkout src/homePageComponents/*
git checkout src/labels/*
git checkout src/layouts/*
git checkout src/objects/*
git checkout src/pages/*
git checkout src/reports/*
git checkout src/tabs/*
git checkout src/weblinks/*
git checkout src/workflows/*
git checkout src/package.xml

echo "# ==== CLEANUP task to strip out extraneous elements from the translation files ===="
cci task run cleanup_translation_metadata

echo "# ==== DONE! - Review the remaining modified translation files before committing back into the branch"
