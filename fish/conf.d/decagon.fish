# Aliases
alias server="uvicorn backend.server_cs.server:app --reload"
alias vserver="uvicorn backend.server_cs.voice_server:app --reload --port 8080"
alias bngrok="ngrok http --url=[replace with your static ngrok url] 8080"
alias gc_login="gcloud auth login"
alias gc_app_login="gcloud auth application-default login"

# Pyenv setup
set -gx PYENV_ROOT $HOME/.pyenv
if test -d $PYENV_ROOT/bin
    fish_add_path $PYENV_ROOT/bin
end
status is-interactive; and pyenv init - fish | source

# Project setup
set -gx PYTHONPATH /Users/harry/dev/duet . $PYTHONPATH
set -gx DECAGON_ENV dev
