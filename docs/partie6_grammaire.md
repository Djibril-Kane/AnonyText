# Partie 6 : Analyse syntaxique

## 13. Grammaire BNF acceptant toute suite valide de tokens

### Principe

Le rôle du parser est minimal dans ce projet : tout texte d'entrée est valide, quel que soit l'ordre des tokens. La grammaire accepte donc **toute suite** de tokens produite par le lexer, sans restriction syntaxique.

C'est la même approche que le Bowdlerizer du tutoriel JavaCC (section 1.4) : le parser n'impose aucune structure, il se contente d'itérer sur les tokens et d'agir sur chacun.

### Grammaire en notation BNF

```
Start → Token* EOF

Token → EMAIL
      | PHONE
      | DATE
      | AMOUNT
      | PERSON
      | WORD
      | OTHER
```

### Traduction JavaCC

```javacc
void Start(PrintWriter out) :
{ Token t; }
{
    (
        t=<EMAIL>    { out.print("<EMAIL>");      logToken(t); }
      | t=<PHONE>    { out.print("<TELEPHONE>"); logToken(t); }
      | t=<DATE>     { out.print("<DATE>");       logToken(t); }
      | t=<AMOUNT>   { out.print("<MONTANT>");    logToken(t); }
      | t=<PERSON>   { out.print("<PERSONNE>");   logToken(t); }
      | t=<WORD>     { out.print(t.image);        logToken(t); }
      | t=<OTHER>    { out.print(t.image);        logToken(t); }
    )*
    <EOF>
    { out.flush(); }
}
```

### Propriétés de la grammaire

- **Totale** : comme le lexer (grâce à `OTHER`), le parser n'échoue jamais — `ParseException` ne peut pas être levée.
- **Sans ambiguïté** : chaque token appartient à exactement une alternative (déterminée par le lexer via le Maximal Munch).
- **Sans récursion** : la grammaire est purement itérative (`*`), ce qui correspond à un parser LL(1) trivial.

### Actions Java (Tâches 15-16)

Chaque alternative contient deux actions :
1. `out.print(...)` — écrit le marqueur anonymisé (ou le lexème original) dans le fichier de sortie.
2. `logToken(t)` — affiche le token reconnu sur la console (instrumentation, Tâche 18).

| Token | Sortie produite |
|---|---|
| `EMAIL` | `<EMAIL>` |
| `PHONE` | `<TELEPHONE>` |
| `DATE` | `<DATE>` |
| `AMOUNT` | `<MONTANT>` |
| `PERSON` | `<PERSONNE>` |
| `WORD` | lexème original (recopié) |
| `OTHER` | lexème original (recopié) |
