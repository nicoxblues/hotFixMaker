#!/usr/bin/env bash


cd /home/nicoblues/workspaceSVN/Interelec

# crear un branch a partir del ultimo tag
 git branch tmpHotFix  $(git describe --tags `git rev-list --tags --max-count=1`)

# obtener la lista de modificaciones con el current branch y el branch del tag generado
 git diff --name-only  tmpHotFix   $(git rev-parse --abbrev-ref HEAD)


 # borrar el branch creado desde el tag

 git  branch -D tmpHotFix
