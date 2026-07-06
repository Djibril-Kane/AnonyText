# Partie 2 : Expressions régulières

## 4. Expressions régulières par catégorie

Pour chaque catégorie, l'expression est donnée sous deux formes :
- **notation standard** (PCRE-like), pour la lisibilité et la discussion ;
- **notation JavaCC**, directement réutilisable par le Membre B dans la section `TOKEN` de `Anonymiseur.jj` (Partie 4).

Rappel de l'ordre de priorité (maximal munch, cf. Partie 5) à respecter lors de la déclaration : `EMAIL > PHONE > DATE > AMOUNT > PERSON > WORD > OTHER`.

### EMAIL

**Standard** : `[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}`

**JavaCC** :
```
< EMAIL:
    (["a"-"z","A"-"Z","0"-"9",".","_","%","+","-"])+
    "@"
    (["a"-"z","A"-"Z","0"-"9","-"])+
    ("." (["a"-"z","A"-"Z","0"-"9","-"])+)*
    "." (["a"-"z","A"-"Z"]){2,}
>
```

Exemples reconnus : `amadou.diallo@gmail.com`, `contact@esp.sn`, `a.b-c+tag@sous.domaine.univ-dakar.sn`.

### PHONE

**Standard** : `(\+221[ ]?)?7[0-8][ ]?[0-9]{3}[ ]?[0-9]{2}[ ]?[0-9]{2}`

**JavaCC** :
```
< PHONE:
    ("+221" (" ")?)?
    "7" ["0"-"8"] (" ")?
    (["0"-"9"]){3} (" ")?
    (["0"-"9"]){2} (" ")?
    (["0"-"9"]){2}
>
```

Exemples reconnus : `77 123 45 67`, `771234567`, `+221 78 654 32 10`, `+22176123 4567`.

### DATE

**Standard** : `(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/[0-9]{4}`

**JavaCC** :
```
< DATE:
    (["0"-"2"] ["0"-"9"] | "3" ["0"-"1"])
    "/"
    ("0" ["1"-"9"] | "1" ["0"-"2"])
    "/"
    (["0"-"9"]){4}
>
```

Exemples reconnus : `15/06/2026`, `01/01/2000`, `31/12/2025`.

### AMOUNT

**Standard** : `[0-9]{1,3}([ ][0-9]{3})*[ ]?(FCFA|EUR|USD|€|\$)`

**JavaCC** :
```
< AMOUNT:
    (["0"-"9"]){1,3} ((" ") (["0"-"9"]){3})*
    (" ")?
    ("FCFA" | "EUR" | "USD" | "€" | "$")
>
```

Exemples reconnus : `250000 FCFA`, `250 000 FCFA`, `1000€`, `2500 USD`.

Note : la devise en préfixe (ex. `$100`) est hors périmètre — cf. Partie 1, difficulté n°4 : le choix retenu se limite au format « nombre puis devise », conformément à l'exemple officiel du sujet.

### PERSON

**Standard** : `[A-ZÀÂÄÉÈÊËÎÏÔÖÙÛÜÇ][a-zà-ÿ]*`

**JavaCC** :
```
< PERSON:
    ["A"-"Z","À","Â","Ä","É","È","Ê","Ë","Î","Ï","Ô","Ö","Ù","Û","Ü","Ç"]
    (["a"-"z","à","â","ä","é","è","ê","ë","î","ï","ô","ö","ù","û","ü","ç"])*
>
```

Exemples reconnus : `Amadou`, `Diallo`, `Éric`, `Ousmane`.

### WORD

**Standard** : `[a-zà-ÿ]+`

**JavaCC** :
```
< WORD:
    (["a"-"z","à","â","ä","é","è","ê","ë","î","ï","ô","ö","ù","û","ü","ç"])+
>
```

Exemples reconnus : `est`, `joignable`, `au`, `été`, `effectué`.

### OTHER

**Standard** : `.` (un caractère quelconque, non capturé par les règles précédentes)

**JavaCC** :
```
< OTHER: ~[] >
```

`~[]` est l'idiome JavaCC signifiant « n'importe quel caractère unique ». Placé en dernier dans l'ordre des règles, il ne s'applique que si aucune autre règle n'a produit de correspondance à cette position (ponctuation, espace isolé, symbole).

## 5. Justification des choix

- **EMAIL** — Le format retenu ne vise pas une conformité stricte à la RFC 5322 (qui autorise des cas très exotiques rarement rencontrés en pratique), mais couvre tous les formats usuels d'adresses professionnelles/académiques : partie locale avec points, tirets, underscores ; domaine multi-niveaux (`sous.domaine.tld`) ; extension d'au moins 2 lettres pour exclure une simple abréviation numérique.

- **PHONE** — Le préfixe mobile sénégalais couvre la plage `70`-`78` (opérateurs Orange, Free, Expresso), avec indicatif international `+221` optionnel et espaces optionnels entre les groupes de chiffres, pour accepter aussi bien la forme compacte que la forme groupée de l'exemple officiel (`77 123 45 67`). Les groupes de chiffres sont de taille fixe (2 puis 3 puis 2 puis 2) plutôt qu'une simple suite `[0-9]{9}` : cela permet de tolérer les espaces à des positions précises sans pour autant accepter n'importe quel découpage arbitraire.

- **DATE** — Le format est restreint à `JJ/MM/AAAA` comme demandé par l'énoncé, avec des bornes de plage sur le jour (`01`-`31`) et le mois (`01`-`12`) pour rejeter des dates syntaxiquement absurdes (`45/13/2026`). La validation calendaire complète (ex. rejeter `31/04/2026`, ou gérer les années bissextiles pour `29/02`) est volontairement hors de portée d'une règle lexicale : un automate/regex ne connaît pas le nombre de jours par mois sans complexifier démesurément la règle ; cette limite est documentée en Partie 10.

- **AMOUNT** — Le format retenu suit celui de l'exemple officiel (nombre puis devise, sans virgule décimale). Le séparateur de milliers par espace est optionnel pour couvrir à la fois `250000 FCFA` et `250 000 FCFA`. La liste de devises est fermée (`FCFA`, `EUR`, `USD`, `€`, `$`) plutôt qu'un motif générique de lettres, afin d'éviter qu'un mot ordinaire suivant un nombre ne soit confondu avec un montant.

- **PERSON** — Règle strictement conforme à l'énoncé (« mots commençant par une majuscule »), volontairement naïve : elle ne distingue pas un vrai nom propre d'un mot en début de phrase. Ce choix est assumé (cf. Partie 1, difficulté n°1) plutôt que de complexifier la règle avec une liste de prénoms/noms, ce qui sortirait du cadre d'une analyse purement lexicale.

- **WORD** — Restreinte aux mots commençant par une minuscule (accents français inclus) pour ne jamais chevaucher la règle `PERSON` : la distinction entre les deux tokens se fait uniquement sur la casse de la première lettre, sans ambiguïté possible entre les deux règles elles-mêmes (l'ambiguïté possible avec `PERSON` porte sur le sens, pas sur la reconnaissance lexicale).

- **OTHER** — Règle « fourre-tout » indispensable pour garantir qu'aucun caractère du fichier d'entrée ne provoque une erreur lexicale (`TokenMgrError`). Elle doit être déclarée en dernier : comme elle matche un seul caractère quelconque, une règle plus spécifique placée avant elle sera toujours préférée à longueur de match égale ou supérieure (cf. Partie 5, Maximal Munch).

## Table récapitulative

| Token | Regex (standard) | Priorité |
|---|---|---|
| `EMAIL` | `[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}` | 1 (la plus haute) |
| `PHONE` | `(\+221[ ]?)?7[0-8][ ]?[0-9]{3}[ ]?[0-9]{2}[ ]?[0-9]{2}` | 2 |
| `DATE` | `(0[1-9]\|[12][0-9]\|3[01])/(0[1-9]\|1[0-2])/[0-9]{4}` | 3 |
| `AMOUNT` | `[0-9]{1,3}([ ][0-9]{3})*[ ]?(FCFA\|EUR\|USD\|€\|\$)` | 4 |
| `PERSON` | `[A-ZÀÂÄÉÈÊËÎÏÔÖÙÛÜÇ][a-zà-ÿ]*` | 5 |
| `WORD` | `[a-zà-ÿ]+` | 6 |
| `OTHER` | `.` (tout caractère restant) | 7 (la plus basse) |
