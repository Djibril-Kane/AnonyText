# AnonyText

Outil d'anonymisation de textes développé avec **JavaCC** dans le cadre du projet de Compilation — M1 GLSI, ESP Dakar (2025-2026).

Le programme analyse un fichier texte et remplace automatiquement les informations sensibles par des marqueurs anonymisés : `<PERSONNE>`, `<TELEPHONE>`, `<EMAIL>`, `<MONTANT>`, `<DATE>`.

## Stack technique

- **JavaCC** (génération lexer + parser)
- **Java** (JDK 17+ recommandé)
- Pas de build tool (pas de Maven/Gradle) : un seul fichier source `.jj`, compilé et exécuté directement en ligne de commande avec `javacc` + `javac`.

## Structure du dépôt

```
AnonyText/
├── README.md
├── build.sh                        # script javacc + javac
├── .gitignore
│
├── src/
│   └── Anonymiseur.jj              # fichier source UNIQUE : options + tokens + grammaire + main
│
├── generated/                      # sortie de "javacc" (non versionnée, voir ci-dessous)
│
├── tests/                          # fichiers de test (*.txt)
│
├── output/                         # fichiers anonymisés générés à l'exécution (non versionné)
│
└── docs/
    ├── partie1_etude_probleme.md
    ├── partie2_regex.md
    ├── partie3_automates.md
    ├── partie4_analyse_lexicale.md
    ├── partie5_maximal_munch.md
    ├── partie6_grammaire.md
    ├── partie9_validation.md
    ├── partie10_analyse.md
    └── images/
        ├── automate_email.png
        ├── automate_telephone.png
        └── automate_date.png
```

## Commandes utiles

```bash
# 1. Générer les .java à partir de la spec JavaCC (à relancer à chaque modif du .jj)
javacc src/Anonymiseur.jj 

# 2. Compiler les .java générés
cd generated
javac *.java
cd ..

# 3. Exécuter sur un fichier de test
java -cp generated Anonymiseur tests/test1_simple.txt output/test1_anonymise.txt
```

Ou plus simplement, pour générer + compiler en une seule commande :

```bash
./build.sh
```