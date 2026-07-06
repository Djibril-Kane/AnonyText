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

---

## 20. Tableau récapitulatif des résultats

| Test | Tokens EMAIL | Tokens PHONE | Tokens DATE | Tokens AMOUNT | Tokens PERSON | Résultat |
|---|---|---|---|---|---|---|
| test1_simple | 1 | 1 | 1 | 1 | 3 | OK |
| test2_complet | 2 | 1 | 1 | 1 | 10 | OK |
| test3_edge_cases | 0 | 1 | 0 | 1 | 2 | OK (cas limites documentés) |

### Correction apportée lors de l'intégration

Le token `AMOUNT` défini par le Membre A utilisait `(["0"-"9"]){1,3}` comme groupe initial, ce qui empêchait de reconnaître `250000 FCFA` (6 chiffres consécutifs sans séparateur). Corrigé en `(["0"-"9"])+` lors de l'intégration par le Membre C.

| Avant correction | Après correction |
|---|---|
| `250000 FCFA` → non reconnu | `250000 FCFA` → `<MONTANT>` ✓ |
| `250 000 FCFA` → `<MONTANT>` ✓ | `250 000 FCFA` → `<MONTANT>` ✓ |
