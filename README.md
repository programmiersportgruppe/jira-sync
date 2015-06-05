[![Gem Version](https://badge.fury.io/rb/jirasync.svg)](http://badge.fury.io/rb/jirasync)

## Installation

    gem install jirasync

## Usage

### Initial Fetch

The following command will start synchronising the project `MYPROJ` from the server at
`https://jira.myorganisation.com`. The issues from that project will be written to the
`issues/MYPROJ` folder:

    jira-sync \
        --baseurl https://jira.myorganisation.com \
        --project MYPROJ  \
        --user jira_user \
        --password jira_password \
        --target issues/MYPROJ/raw \
        fetch

When this passes successfully the `issues/MYPROJ/raw` directory will contain the following structure:

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

~~~ {.bash}

jira-sync \
    --baseurl https://jira.myorganisation.com \
    --project MYPROJ  \
    --user jira_user \
    --password jira_password \
    --target issues/MYPROJ/raw \
    update

~~~

### Fetching and Storing Attachments

 
Passing in the `--store-attachments` option leads to attachments being fetched and stored in the local filesystem.
They will we be stored in the `attachments/` sub-directory of the target directory.
 
### Formatting Issues

While JSON files are very handy to use in code, they are not very readable. The `jira-format-issues` command
formats JSON issues to markdown. It is invoked as follows:

~~~ {.sh}

jira-format-issues \
    --source  issues/MYPROJ/raw\
    --target  issues/MYPROJ/markdown

~~~

This will create the following structure in the `issues/MYPROJ/markdown`:

    MYPROJ-1.md
    MYPROJ-2.md
    MYPROJ-3.md
    MYPROJ-4.md
    …

The individual files look like this:

~~~ {.md}
[MYPROJ-1](https://jira.myorganisation.com/browse/MYPROJ-1): Build a working System
===================================================================================

Type
:   Story

Status
:   Closed

Reporter
:   fleipold

Labels
:   triaged

Updated
:   20. Jan 2014 11:30 (UTC)

Created
:   01. Aug 2013 12:29 (UTC)


Description
-----------

The myproj system shall be built to be *delpoyable* and *working*.


Comments
--------

### fleipold - 20. Jan 2014 12:19 (UTC):

Is this still relevant?

~~~

These files can be easily searched by ensuring they get indexed by a desktop search engine, e.g.
[spotlight](https://gist.github.com/gereon/3150445) on the Mac.

 There is also the possibility to render custom jira fields by supplying a *custom data* file, which declares *simple
 data* fields which are rendered as definitions at the top of the ticket and *sections* that are rendered as one or more paragraphs
 with a heading. Here is an example file, `custom-data.json`:

~~~ {.json}
{
    "simple_fields" : {
         "Audience" : ["customfield_10123", "value"]
    },
    "sections" : {
         "Release Notes" : ["customfield_10806"]
    }
}

~~~


This file can be passed in like this:

~~~ {.bash}

jira-format-issues \
    --source  issues/MYPROJECT/json \
    --target  issues/MYPROJECT/markdown \
    --custom-data-path custom-data.json

~~~

## Motivation

Having a local, unix-friendly copy of all tickets to avoid JIRA performance issues and
make information available offline.

## Potential Future Work

- [X] Make progress bar work
- [X] Make output less noisy
- [X] Download attachments
- [ ] Produce tabular output
- [ ] Deal with authentication problems explicitly
- [ ] Remove tickets that have been moved to a different project
- [ ] Use OAuth authentication

