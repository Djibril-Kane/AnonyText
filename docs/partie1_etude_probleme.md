# Partie 1 : Étude du problème

## Contexte

Les administrations, universités et entreprises manipulent quotidiennement des documents contenant des informations sensibles. Avant leur diffusion, ces documents doivent être anonymisés. L'objectif est de développer avec JavaCC un outil capable d'analyser automatiquement un texte et de remplacer certaines catégories d'informations sensibles par des marqueurs anonymisés.

Exemple :

```
Texte d'entrée :
Monsieur Amadou Diallo est joignable au 77 123 45 67.
Son adresse est amadou.diallo@gmail.com.
Le paiement de 250000 FCFA a été effectué le 15/06/2026.

Texte obtenu :
<PERSONNE> <PERSONNE> est joignable au <TELEPHONE>.
Son adresse est <EMAIL>.
Le paiement de <MONTANT> a été effectué le <DATE>.
```

## 1. Catégories d'informations à anonymiser

| Catégorie | Marqueur de sortie | Token JavaCC | Description |
|---|---|---|---|
| Adresse électronique | `<EMAIL>` | `EMAIL` | Adresse e-mail (ex. `amadou.diallo@gmail.com`) |
| Numéro de téléphone | `<TELEPHONE>` | `PHONE` | Numéro de téléphone (ex. `77 123 45 67`) |
| Date | `<DATE>` | `DATE` | Date au format `JJ/MM/AAAA` (ex. `15/06/2026`) |
| Montant financier | `<MONTANT>` | `AMOUNT` | Nombre suivi (ou précédé) d'une devise (ex. `250000 FCFA`) |
| Nom propre | `<PERSONNE>` | `PERSON` | Mot commençant par une majuscule (ex. `Amadou`, `Diallo`) |
| Mot générique | *(non anonymisé)* | `WORD` | Tout autre mot du texte (articles, verbes, noms communs...) |
| Autre caractère | *(non anonymisé)* | `OTHER` | Ponctuation et caractères ne formant pas un mot (`.`, `,`, espaces, etc.) |

Seules les 4 premières catégories (EMAIL, PHONE, DATE, AMOUNT) et les noms propres (PERSON) sont remplacées par un marqueur dans le texte de sortie. Les tokens WORD et OTHER sont recopiés tels quels : ils servent à faire en sorte que **tout** le texte d'entrée soit couvert par la grammaire (aucun caractère ne doit être laissé sans token correspondant), mais ils ne représentent pas une information sensible.

## 2. Règles de reconnaissance

Ces règles sont volontairement décrites ici de façon informelle ; leur traduction en expressions régulières précises fait l'objet de la Partie 2.

- **EMAIL** : une séquence de caractères autorisés (lettres, chiffres, `.`, `_`, `%`, `+`, `-`) suivie de `@`, puis d'un nom de domaine (lettres, chiffres, `-`, `.`) contenant au moins un point et se terminant par une extension d'au moins deux lettres (ex. `.com`, `.sn`).
- **PHONE** : une suite de chiffres correspondant à un numéro de téléphone sénégalais, éventuellement précédée de l'indicatif `+221`, et éventuellement groupée par des espaces (ex. `77 123 45 67`, `771234567`, `+221 77 123 45 67`).
- **DATE** : trois groupes de chiffres séparés par `/`, au format `JJ/MM/AAAA` (jour sur 2 chiffres, mois sur 2 chiffres, année sur 4 chiffres).
- **AMOUNT** : une suite de chiffres (éventuellement groupés par des espaces ou points comme séparateurs de milliers) suivie d'un symbole ou code de devise (`FCFA`, `€`, `$`, ...).
- **PERSON** : un mot commençant par une lettre majuscule, suivi de lettres minuscules — règle simple retenue par l'énoncé du projet (« mots commençant par une majuscule »), sans base de noms propres ni analyse grammaticale.
- **WORD** : une suite de lettres minuscules (accents français compris) ne correspondant à aucune des catégories précédentes.
- **OTHER** : tout caractère restant (ponctuation, espaces, symboles isolés) une fois les catégories précédentes reconnues.

## 3. Difficultés possibles

1. **Ambiguïté PERSON / début de phrase.** La règle « mot commençant par une majuscule » capture aussi bien les vrais noms propres (`Amadou`, `Diallo`) que le premier mot d'une phrase écrit avec une majuscule grammaticale (`Le paiement...` → `Le` serait reconnu comme `PERSON`). C'est une limitation connue et acceptée de la règle simplifiée imposée par l'énoncé ; elle est documentée dans la Partie 10 (analyse critique).

2. **Noms composés de plusieurs mots.** `Amadou Diallo` est constitué de deux tokens `PERSON` consécutifs (un par mot) et non d'une seule entité "prénom + nom". Le lexer ne fait pas de regroupement sémantique : chaque mot capitalisé est anonymisé indépendamment (cf. l'exemple officiel, qui produit bien `<PERSONNE> <PERSONNE>` et non `<PERSONNE>` unique).

3. **Formats de téléphone variables.** Un numéro peut être écrit avec ou sans indicatif (`+221`), avec ou sans espaces entre les groupes de chiffres, ce qui multiplie les variantes à couvrir par la même règle lexicale.

4. **Formats de montant variables.** Le montant peut être écrit avec un séparateur de milliers ou non (`250000` vs `250 000`), avec la devise avant ou après le nombre, en toutes lettres (`FCFA`) ou en symbole (`€`, `$`). Le choix retenu (Partie 2) se limite au format observé dans l'exemple (nombre puis devise), afin de rester cohérent avec le périmètre du projet.

5. **Chevauchement entre catégories (conflits lexicaux).** Une même séquence de chiffres pourrait, selon son contexte, être candidate à plusieurs tokens : un numéro de téléphone (`77 123 45 67`, uniquement des chiffres et espaces) ressemble structurellement à un montant sans devise, et une date (`15/06/2026`) contient des groupes de chiffres qui, isolément, ressembleraient à un numéro partiel. C'est le rôle du principe du **Maximal Munch** et de l'ordre de priorité des règles (`EMAIL > PHONE > DATE > AMOUNT > PERSON > WORD > OTHER`) de lever ces ambiguïtés — étudié en détail en Partie 5.

6. **Accents et caractères spéciaux du français.** Les mots du texte peuvent contenir des lettres accentuées (`é`, `è`, `à`, `ç`, `ù`...) qui doivent être acceptées par les règles `WORD` et `PERSON` sous peine de fragmenter un mot en plusieurs tokens invalides.

7. **Abréviations et titres de civilité.** Des mots comme `M.`, `Mme`, `Dr` commencent par une majuscule mais ne sont pas nécessairement des noms propres à anonymiser ; le projet ne traite pas ce cas particulier (limitation assumée, cf. règle PERSON ci-dessus).

8. **Robustesse du lexer face aux erreurs.** Un caractère non prévu par aucune règle (emoji, caractère de contrôle...) doit malgré tout être capturé par une règle `OTHER` générique pour éviter un échec de l'analyse lexicale (`TokenMgrError`).
