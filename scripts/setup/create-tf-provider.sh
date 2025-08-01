#!/usr/bin/env bash
# shellcheck disable=SC2154
# -----------------------------------------------------------------------------
# PURPOSE:  1-time setup for the admin-project and terraform user account.
#           Some controls are necessary at the Organization and project level.
# -----------------------------------------------------------------------------
# PREREQS:  source-in all your environment variables from build.env
# -----------------------------------------------------------------------------
#    EXEC:  scripts/setup/create-tf-backend.sh
# -----------------------------------------------------------------------------
: "${state_bucket?  I dont have my vars, bro!}"
set -x

###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
backendTmpl="$template_dir/provider.tmpl"
backendFile='provider.tf'


###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
function pMsg() {
    theMessage="$1"
    printf '%s\n' "$theMessage"
}

###----------------------------------------------------------------------------
### MAIN
###----------------------------------------------------------------------------
### Create the Terraform bucket definition for the backend
###---
pMsg "  Creating Terraform backend definition..."
envsubst < "$backendTmpl" > "$backendFile"


###---
### fin~
###---
exit 0

