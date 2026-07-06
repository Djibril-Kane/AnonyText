# Partie 9 : Validation

## 19. Tests sur plusieurs documents

### Test 1 — Cas simple (exemple du sujet)

**Fichier** : `tests/test1_simple.txt`

**Entrée** :
```
Monsieur Amadou Diallo est joignable au 77 123 45 67.
Son adresse est amadou.diallo@gmail.com.
Le paiement de 250000 FCFA a été effectué le 15/06/2026.
```

**Sortie attendue** (`output/test1_anonymise.txt`) :
```
<PERSONNE> <PERSONNE> <PERSONNE> est joignable au <TELEPHONE>.
<PERSONNE> adresse est <EMAIL>.
<PERSONNE> paiement de <MONTANT> a été effectué le <DATE>.
```

> Note : "Monsieur", "Son" et "Le" commencent par une majuscule → PERSON → `<PERSONNE>`.
> C'est la limitation assumée de la règle simplifiée (cf. Partie 1, difficulté n°1).

---

### Test 2 — Cas complet

**Fichier** : `tests/test2_complet.txt`

**Entrée** :
```
Dr Fatou Sarr travaille à l'Université Cheikh Anta Diop.
Contact : fatou.sarr@ucad.edu.sn ou +221 76 543 21 09.
Réunion prévue le 08/07/2026 pour un budget de 1 500 000 FCFA.
Copie à ousmane.ndiaye@esp.sn et à Pierre Dupont.
Référence dossier : esp-2026-gl.
```

**Sortie attendue** :
```
<PERSONNE> <PERSONNE> <PERSONNE> travaille à l'<PERSONNE> <PERSONNE> <PERSONNE> <PERSONNE>.
<PERSONNE> : <EMAIL> ou <TELEPHONE>.
<PERSONNE> prévue le <DATE> pour un budget de <MONTANT>.
<PERSONNE> à <EMAIL> et à <PERSONNE> <PERSONNE>.
<PERSONNE> dossier : esp-2026-gl.
```

---

### Test 3 — Cas limites

**Fichier** : `tests/test3_edge_cases.txt`

| Entrée | Token attendu | Marqueur |
|---|---|---|
| `test@` | OTHER (email invalide) | `test@` recopié |
| `77 12 34` | OTHER + OTHER + ... (phone incomplet) | chiffres recopiés |
| `32/13/2026` | OTHER (date invalide) | caractères recopiés |
| `250000` (sans devise) | OTHER ×6 | chiffres recopiés |
| `éléphant` | WORD | `éléphant` recopié |
| `Éric` | PERSON | `<PERSONNE>` |
| `771234567` | PHONE | `<TELEPHONE>` |
| `1500 EUR` | AMOUNT | `<MONTANT>` |
| `00/06/2026` (jour "00") | OTHER (jour invalide) | `00/06/2026` recopié — régression du bug corrigé lors de l'intégration (cf. Partie 5) |
| `79 123 45 67` (préfixe hors plage `70`-`78`) | OTHER ×… | chiffres recopiés, pas de `<TELEPHONE>` |
| `$100` (devise en préfixe) | OTHER ×4 (comportement attendu) | `$100` recopié — conforme au scope documenté |
| `1000€` | AMOUNT | `<MONTANT>` |
| `ESP` (sigle 3 majuscules) | PERSON ×3 | `<PERSONNE><PERSONNE><PERSONNE>` |
| `a.b-c+tag@sous.domaine.univ-dakar.sn` | EMAIL | `<EMAIL>` |

> **Comportement conforme au scope documenté** : la règle `AMOUNT` n'accepte le symbole de devise qu'**après** les chiffres (`1000€` ✓), jamais **avant** (`$100`, recopié via `OTHER`). Ce n'est pas une limite technique mais une décision de portée déjà actée en Partie 1 (difficulté n°4) : le projet se limite au format « nombre puis devise » de l'exemple officiel du sujet. L'exemple `$100` cité par erreur dans `docs/partie2_regex.md` (Partie 2) a été retiré pour rester cohérent avec cette décision.

> **Limite déjà connue, illustrée ici** : un sigle tout en majuscules (`ESP`) est découpé en autant de tokens `PERSON` d'une lettre qu'il y a de lettres, faute de règle dédiée aux acronymes (cf. Partie 1, difficulté n°1).

---

### Test 4 — Document réel

**Fichier** : `tests/test4_document_reel.txt`

Lettre administrative réaliste (note de service ESP) mêlant naturellement toutes les catégories sur plusieurs paragraphes, pour valider le pipeline complet dans des conditions proches de l'usage réel — en particulier la préservation de la mise en forme (paragraphes, lignes vides) via les tokens `OTHER`, depuis la suppression du `SKIP` par le Membre C.

**Sortie obtenue** (`output/test4_anonymise.txt`, vérifiée par exécution) :
```
<PERSONNE> <PERSONNE> <PERSONNE> de <PERSONNE>
<PERSONNE> de service - <PERSONNE> 1 <PERSONNE><PERSONNE><PERSONNE><PERSONNE>

<PERSONNE>, le <DATE>

<PERSONNE> : <PERSONNE> à la soutenance de projet de compilation

<PERSONNE>, <PERSONNE>,

<PERSONNE> comité pédagogique, présidé par <PERSONNE> <PERSONNE> et composé de <PERSONNE> <PERSONNE>
et de <PERSONNE> <PERSONNE>, vous informe que la soutenance du projet "<PERSONNE><PERSONNE>"
est fixée au <DATE>.

<PERSONNE> toute question, vous pouvez contacter le secrétariat par email à
<EMAIL> ou par téléphone au <TELEPHONE>. <PERSONNE> référent du projet,
<PERSONNE> <PERSONNE>, reste également joignable au <TELEPHONE> ou à
l'adresse <EMAIL>.

<PERSONNE> frais de dossier, fixés à <MONTANT>, doivent être réglés avant le
<DATE>. <PERSONNE> supplément de <MONTANT> est demandé pour les retardataires, ou
son équivalent de $55 pour les étudiants étrangers.

<PERSONNE> du dossier : esp-2026-gl. <PERSONNE> dossier est suivi par l'<PERSONNE><PERSONNE><PERSONNE> en
lien avec le <PERSONNE><PERSONNE><PERSONNE><PERSONNE><PERSONNE>.

<PERSONNE>,
<PERSONNE> service de la scolarité
```

Observations :
- Les paragraphes et lignes vides sont préservés à l'identique dans la sortie (confirme la conception "tout est recopié via OTHER" du Membre C).
- `$55` illustre le même comportement que `$100` dans le Test 3 (devise en préfixe hors scope, cf. Partie 1, difficulté n°4).
- `AnonyText`, `ESP`, `CROUS`, `GLSI` (sigles/mots à casse mixte) se décomposent en plusieurs `<PERSONNE>` consécutifs — limite déjà documentée, ici observée en contexte réel.
- Tous les emails, téléphones (avec et sans `+221`), dates et montants (`FCFA`, `€` en suffixe) du document sont correctement anonymisés.

---

## 20. Tableau récapitulatif des résultats

| Test | Tokens EMAIL | Tokens PHONE | Tokens DATE | Tokens AMOUNT | Tokens PERSON | Résultat |
|---|---|---|---|---|---|---|
| test1_simple | 1 | 1 | 1 | 1 | 5 | OK |
| test2_complet | 2 | 1 | 1 | 1 | 13 | OK |
| test3_edge_cases | 1 | 1 | 0 | 2 | 20 | OK (cas limites documentés, dont `$100` hors scope) |
| test4_document_reel | 2 | 2 | 3 | 2 | 42 | OK (`$55` hors scope, cf. Test 3) |

> Comptages vérifiés par exécution réelle (`grep -o "<TOKEN>" output/*.txt \| wc -l`) le 2026-07-06 — les valeurs `PERSON` de `test1_simple` (5, pas 3) et `test2_complet` (13, pas 10) corrigent une erreur de comptage manuel préexistante dans cette table.

### Correction apportée lors de l'intégration

Le token `AMOUNT` défini par le Membre A utilisait `(["0"-"9"]){1,3}` comme groupe initial, ce qui empêchait de reconnaître `250000 FCFA` (6 chiffres consécutifs sans séparateur). Corrigé en `(["0"-"9"])+` lors de l'intégration par le Membre C.

| Avant correction | Après correction |
|---|---|
| `250000 FCFA` → non reconnu | `250000 FCFA` → `<MONTANT>` ✓ |
| `250 000 FCFA` → `<MONTANT>` ✓ | `250 000 FCFA` → `<MONTANT>` ✓ |
