# Environment variables

In this directory I keep files with sets of env variables for different purposes.

To set up the environment for backstage, use the backstage.conf file and so on.

Use `cq_env_select` to select the env file you want to use.

## Use a file in current shell

You can't set the env vars using a script since it will only be set in the subshell
then disappear when the scripts shell exists.

We have to use `source`.

`set -o allexport && source ~/.config/env/backstage.conf && set +o allexport`

`env_file() {set -o allexport; source $@; set +o allexport}`

## Using in scripts

To import env vars file in a script, do it like this:

```sh
set -o allexport
source ~/.config/env/backstage.conf
set +o allexport
```
