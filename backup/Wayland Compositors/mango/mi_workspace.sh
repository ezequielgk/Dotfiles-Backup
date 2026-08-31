#!/bin/bash
# Llama a Mango IPC para mapear todo
map=$(mmsg get workspaces | jq -r '.[] | if .active then "["+.name+"]" elif .windows > 0 then "("+.name+")" else .name end')
# Junta los tags en una sola línea y los escupe a Noctalia
echo $map | tr '\n' ' '
