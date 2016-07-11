# hubot-answerhub

A hubot script to return information about Q URLs.

## Installation

In hubot project repo, run:

`npm install hubot-answerhub --save`

Then add **hubot-answerhub** to your `external-scripts.json`:

```json
[
  "hubot-answerhub"
]
```

## Configuration

hubot-answerhubs requires the answerhub hostname, a user and a password to work use the follow environment variables to 
set them.

`ANSWERHUB_HOSTNAME`
`ANSWERHUB_USER`
`ANSWERHUB_PASSWORD`

For example, `export ANSWERHUB_HOSTNAME=answerhub.test.com`
