#!/bin/bash
mkdir -pv public/{js,css,images}
mkdir -pv src/{views,handlers,model,css}
mkdir -pv client-src

function copySkel {
    if [ ! -f $1 ]; then
        cp -v node_modules/fp-backend/skel/$1 $1
    fi
}

copySkel '.gitignore'
copySkel 'app.coffee'
copySkel 'src/handlers/index.coffee'
copySkel 'src/views/index.jade'
