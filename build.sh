#!/bin/bash
set -e

# 1. Generer les .java a partir de la spec JavaCC (a relancer a chaque modif du .jj)
# (OUTPUT_DIRECTORY est defini directement dans le bloc options de Anonymiseur.jj)
#
# Sous Git Bash, le script "javacc" fourni par l'installeur Windows est bugue quand
# son chemin d'installation contient un espace (ex. "Program Files"), a cause d'un
# "dirname $0" non quote qui casse le chemin vers javacc.jar. On contourne donc ce
# script en appelant nous-memes le jar, avec un chemin correctement quote.
JAVACC_JAR="$(dirname "$(command -v javacc)")/lib/javacc.jar"
java -Dfile.encoding=UTF-8 -classpath "$JAVACC_JAR" javacc src/Anonymiseur.jj

# 2. Compiler les .java generes
cd generated
javac *.java
cd ..

echo "Build OK. Executer avec : java -cp generated Anonymiseur <fichier_entree> <fichier_sortie>"
