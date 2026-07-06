# Partie 10 : Analyse critique

Bloc commun final (équipe complète) : bilan sur les performances, le rôle du Maximal Munch, les limites assumées du projet et les pistes d'amélioration.

## 1. Performances

L'analyseur repose entièrement sur le code généré par JavaCC, ce qui donne des garanties de performance fortes et prévisibles :

- **Lexer** : JavaCC compile les règles `TOKEN` en un unique automate fini déterministe (DFA). La reconnaissance d'un token est donc en **temps linéaire** par rapport à sa longueur, et l'analyse lexicale complète d'un fichier est en **O(n)** par rapport à la taille du fichier (chaque caractère est lu une seule fois par le `SimpleCharStream`, sans retour en arrière).
- **Parser** : la grammaire `Start → Token* EOF` (Partie 6) est purement itérative, sans récursion ni alternative ambiguë au niveau syntaxique — c'est un parser LL(1) trivial. Le coût du parsing est donc lui aussi linéaire et négligeable devant le coût du lexer.
- **Mémoire** : le programme actuel charge et réécrit le texte au fil de l'eau, token par token (`out.print(...)` immédiat dans les actions de `Start()`), sans construire de structure intermédiaire ni charger tout le fichier en mémoire d'un coup — seul le buffer interne du `SimpleCharStream` est conservé.
- **Limite pratique constatée** : aucune, sur les tailles de fichiers testées (`tests/*.txt`, de quelques lignes à un document multi-paragraphes). Le passage à des fichiers de plusieurs Mo ne poserait pas de problème algorithmique (toujours O(n)), seulement un usage I/O plus soutenu.

En résumé : la complexité du projet n'est pas dans la performance brute (un DFA est optimal par construction) mais dans la **précision des règles lexicales** face à l'ambiguïté du langage naturel — voir section 3.

## 2. Rôle du Maximal Munch

Le Maximal Munch (cf. Partie 5) est le mécanisme central qui rend le projet réalisable avec un simple lexer, sans logique de désambiguïsation écrite à la main :

- Il résout automatiquement les **conflits structurels** identifiés en Partie 1 (difficulté n°5) : un numéro de téléphone (`77 123 45 67`) n'est jamais confondu avec une suite de mots isolés, une adresse email n'est jamais coupée en un `WORD` suivi de symboles, une date n'est jamais scindée en fragments numériques — dans chaque cas, la règle la plus spécifique produit un match strictement plus long que les règles génériques, donc elle l'emporte.
- L'ordre de déclaration des règles (`EMAIL > PHONE > DATE > AMOUNT > PERSON > WORD > OTHER`, du plus spécifique au plus générique) ne sert qu'en cas d'**égalité stricte de longueur** — dans la pratique du projet, ce cas ne se présente jamais entre deux catégories sensibles (leurs alphabets ne se chevauchent pas complètement), il ne joue vraiment que pour départager `OTHER` (longueur 1) face à tout le reste.
- **Limite du mécanisme** : le Maximal Munch résout des conflits *syntaxiques* (quelle règle matche le plus de caractères), mais ne résout aucun conflit *sémantique*. Il ne peut pas, par construction, distinguer un vrai nom propre d'un mot en début de phrase (`Le` dans `Le paiement...`) : les deux produisent un match de même nature pour la règle `PERSON`, il n'y a pas de "match plus long" à départager — c'est une question de sens, hors de portée d'un lexer à base d'automate fini. C'est la limite structurelle la plus importante du projet (cf. section 3).

## 3. Limites assumées

Récapitulatif des limites déjà identifiées au fil du projet, avec leur origine :

| # | Limite | Origine / statut |
|---|---|---|
| 1 | `PERSON` capture aussi les mots en début de phrase (`Le`, `Son`, `Monsieur`) | Partie 1 difficulté n°1 — imposé par la règle simplifiée de l'énoncé, illustré dans tous les tests (`test1`…`test4`) |
| 2 | Un nom composé (`Amadou Diallo`) produit deux tokens `<PERSONNE>` distincts, jamais regroupés | Partie 1 difficulté n°2 — conforme à l'exemple officiel du sujet, qui attend bien deux marqueurs séparés |
| 3 | Les titres de civilité (`Dr`, `M.`, `Mme`) sont traités comme des `PERSON` | Partie 1 difficulté n°7 |
| 4 | `DATE` ne valide pas la cohérence calendaire complète (`31/04/2026` accepté syntaxiquement, années bissextiles non gérées pour `29/02`) | Partie 3 — un automate fini ne peut pas exprimer "nombre de jours du mois" sans expansion déraisonnable, et la validation des années bissextiles (arithmétique modulo 4/100/400) n'est pas un problème reconnaissable par un automate fini pour un intervalle d'années non borné |
| 5 | `AMOUNT` n'accepte la devise qu'**après** le nombre (`250000 FCFA` ✓, `$100` ✗) | Partie 1 difficulté n°4 — décision de scope volontaire, alignée sur l'unique exemple officiel du sujet ; confirmé et documenté en Partie 9 lors de l'intégration |
| 6 | Un sigle tout en majuscules (`ESP`, `CROUS`, `GLSI`) est découpé en autant de `<PERSONNE>` d'une lettre que de lettres | Constaté lors des tests d'intégration (Partie 9, `test3`/`test4`) — conséquence directe de la règle `PERSON` naïve, non identifiée avant l'écriture de tests réalistes |
| 7 | Le programme traite un seul fichier à la fois (pas de traitement par lot / dossier) | Choix d'implémentation (Partie 7), conforme au périmètre du sujet (`java Anonymiseur <entrée> <sortie>`) |

Ces limites ne sont pas des bugs : ce sont des conséquences directes et documentées du choix (imposé par l'énoncé) d'une analyse **purement lexicale/syntaxique**, sans dictionnaire de noms propres ni analyse sémantique. Le seul véritable bug détecté en cours de projet (le jour `"00"` accepté par `DATE`, cf. Partie 5/Partie 9) a lui été corrigé, contrairement aux limites ci-dessus qui restent hors du périmètre par construction.

## 4. Améliorations possibles

Pistes d'évolution, classées par facilité de mise en œuvre :

- **Sigles/acronymes (limite n°6)** — la plus simple à corriger : ajouter une règle `ACRONYM` (`(["A"-"Z"]){2,}`) au-dessus de `PERSON` dans l'ordre de priorité, pour capturer un sigle en un seul token plutôt qu'un `<PERSONNE>` par lettre. Risque faible, ne change aucun test existant portant sur des noms propres classiques.
- **Titres de civilité (limite n°3)** — utiliser une liste fermée de mots (`M`, `Mme`, `Dr`, `Pr`...) déclarée comme des tokens littéraux prioritaires sur `PERSON`, pour les recopier tels quels plutôt que de les anonymiser.
- **Mots en début de phrase (limite n°1)** — la piste la plus intéressante mais la plus complexe : nécessiterait de sortir du cadre purement lexical, par exemple en gardant en mémoire dans le parser si le token précédent était un `OTHER` de fin de phrase (`.`, `!`, `?`) pour ne déclencher `PERSON` qu'après un vrai point capital, ou en s'appuyant sur une liste de mots-outils français (`Le`, `La`, `Un`, `Ce`...) à exclure. Aucune solution n'est parfaite sans une vraie liste de prénoms/noms de référence.
- **Validation calendaire de `DATE` (limite n°4)** — techniquement faisable en dur pour les bornes jour/mois (12 automates différents selon le mois), mais les années bissextiles restent hors de portée d'un automate fini sur un intervalle d'années non borné ; à limiter à une plage d'années fixe si cette validation devient nécessaire.
- **Devise en préfixe (limite n°5)** — si le périmètre du projet évolue, ajouter une alternative symétrique dans la règle `AMOUNT` (devise puis nombre) ne pose pas de difficulté technique, seule la décision de scope (Partie 1) l'exclut actuellement.
- **Tests automatisés** — actuellement, la validation (Partie 9) se fait par comparaison manuelle de la sortie console/fichier avec la sortie attendue documentée. Un script (`build.sh` étendu, ou script séparé) qui exécute les 4 fichiers de `tests/` et diffe automatiquement la sortie produite contre un fichier de référence `*.expected.txt` permettrait de détecter une régression instantanément (utile pour la maintenance après ce projet).
- **Traitement par lot** — étendre `main()` pour accepter un dossier en entrée et anonymiser tous les fichiers `.txt` qu'il contient, plutôt qu'un seul fichier à la fois.
