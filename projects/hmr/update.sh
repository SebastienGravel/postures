#!/bin/sh

# This gets the latest list of names and adds an escape character for commas because Pd will break up messages when it sees commas.

wget -r --user=admin --password='viewNX2' http://127.0.0.1/musee/donateurs.php
sed -i 's/,/\\,/g' 127.0.0.1/musee/donateurs.php
