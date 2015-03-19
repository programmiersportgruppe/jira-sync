# jira-sync
A utility to synchronise jira projects to the local file system

## Installation

    gem install jirasync


## Usage

### Initial Fetch

The following command will start synchronising a the project `MYPROJ` from the server at
`https://jira.myorganisation.com`. The issues from that project will be written to the
`issues/MYPROJ` folder:


    jira-sync \
        --baseurl https://jira.myorganisation.com \
        --project MYPROJ  \
        --user jira_user \
        --password jira_password \
        --target issues/MYPROJ \
        fetch


When this passes successfully the `issues/MYPROJ` folder will contain the following structure:

    MYPROJ-1.json
    MYPROJ-2.json
    MYPROJ-3.json
    MYPROJ-4.json
    …
    sync_state.json

Each issue file contains a pretty-printed json representation of the ticket. The modified date of the files is set to
the value of the `updated` field of the corresponding ticket, so that a makefile can be used to render the
json files incrementally into a more readable representation.

The `sync_state.json` file contains information about the last sync, such as the time and errors that occurred.

### Updating

The following statement will sync issues that have changed or where added during the last sync:

    jira-sync \
        --baseurl https://jira.myorganisation.com \
        --project MYPROJ  \
        --user jira_user \
        --password jira_password \
        --target issues/MYPROJ \
        fetch

## Motivation

Having a local, unix-friendly copy to avoid jira performance issues and make information available offline.

## Potential Future Work

* Remove tickets that have been moved to a different project
* Use OAuth authentication
* Improved error handling
* Provide example makefile for neat rendering and indexing