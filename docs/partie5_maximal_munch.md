# Partie 5 : Gestion du Maximal Munch et conflits lexicaux

L'analyseur lexical de JavaCC applique par défaut la règle du **Maximal Munch** : face à plusieurs règles correspondantes, il choisit toujours celle qui consomme la plus longue chaîne de caractères. Si deux chaînes ont la même longueur, c'est la première règle définie dans le fichier `.jj` qui l'emporte.

## 1. Démonstration par l'exemple (Tests validés)

Avec notre fichier de test contenant la phrase :  
`"Bonjour Amadou, votre rendez-vous est fixé au 15/06/2026."`

### Cas n°1 : Le conflit Email/Téléphone vs Mots simples
Dans la chaîne `amadou.diallo@gmail.com` :
- Le lexer aurait pu s'arrêter après `amadou` et renvoyer un token `WORD`.
- Cependant, en vertu du *Maximal Munch*, il continue à lire le flux car le motif `@` et le domaine étendent la correspondance. C'est donc un unique token `<EMAIL>` de 23 caractères qui est émis, résolvant l'ambiguïté.

### Cas n°2 : Le formatage des numéros de téléphone (`77 123 45 67`)
Le numéro `77 123 45 67` contient des espaces internes. 
- Sans le Maximal Munch, le lexer verrait une suite de nombres isolés (`<WORD>` ou erreur).
- Grâce à la règle du Membre A qui intègre des espaces optionnels `(" ")?`, le lexer préfère englober l'ensemble des 9 chiffres et de leurs espaces pour former un grand token `<PHONE>`.

### Cas n°3 : Le jeton de repli `OTHER`
La règle `<OTHER: ~["\0"]>` placée tout à la fin sert de filet de sécurité. Elle ne capture qu'**un seul caractère à la fois** (longueur = 1). 
- Face à un mot comme `Bonjour` (longueur = 7), la règle `WORD` gagne car 7 > 1.
- Face à une virgule `,` ou un point `.`, aucune règle (`WORD`, `EMAIL`, etc.) ne correspond. C'est alors `OTHER` qui prend le relais, évitant ainsi une erreur fatale du gestionnaire de jetons (`TokenMgrError`).