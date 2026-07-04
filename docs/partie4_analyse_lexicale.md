# Partie 4 : Analyse lexicale avec JavaCC

Ce document décrit les choix d'implémentation et la configuration de l'analyseur lexical (Lexer) dans le fichier `src/Anonymiseur.jj`.

## 1. Choix des options de configuration
- `STATIC = false;` : Permet d'instancier le parser et le lexer sous forme d'objets Java indépendants, ce qui facilite la manipulation des flux de fichiers en mémoire.
- `IGNORE_CASE = false;` : **Crucial pour notre projet.** La distinction entre le token `PERSON` (qui commence obligatoirement par une majuscule) et le token `WORD` (exclusivement en minuscules) repose entièrement sur la casse. Si `IGNORE_CASE` avait été activé, le lexer n'aurait pas pu faire la différence entre un nom propre et un mot ordinaire.

## 2. Traduction et ordre de priorité des Jeton (Tokens)
Les expressions régulières fournies par le Membre A ont été intégrées dans la section `TOKEN`. L'ordre de déclaration suit strictement une logique du **plus spécifique au plus générique** pour garantir qu'un token complexe ne soit pas court-circuité :
1. `EMAIL`
2. `PHONE`
3. `DATE`
4. `AMOUNT`
5. `PERSON`
6. `WORD`
7. `OTHER` (Le jeton de repli pour la ponctuation et caractères isolés)

## 3. Instrumentation du Lexer (Tâche 18)
Pour valider le comportement du lexer de manière autonome (sans attendre la grammaire BNF), une méthode d'instrumentation a été ajoutée dans la classe principale :
```java
public static void logToken(Token t) {
    String typeToken = AnonymiseurConstants.tokenImage[t.kind];
    System.out.println("DEBUG [Lexer] -> Type: " + typeToken + " | Lexème: \"" + t.image + "\"");
}