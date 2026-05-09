# uatm_paiements

Application Flutter de gestion des paiements de scolarité pour l'UATM GASA Formation.

## Objectif du projet

UATM Paiement est une application mobile développée avec le framework Flutter, destinée à moderniser et informatiser la gestion des paiements académiques au sein de l'Université Africaine de Technologie et de Management (UATM). L'application s'inscrit dans le projet global de gestion de la scolarité de l'institution (gestionscolariteuatm) et vise à remplacer les processus manuels par une solution numérique fiable, sécurisée et accessible.
Elle permet d'enregistrer, suivre et imprimer les reçus de paiement des étudiants en temps réel, en s'appuyant sur Firebase comme infrastructure cloud.

## Utilisation du projet


## Backend utilisé

Le projet utilise actuellement :

- `Firebase Authentication` pour la connexion
- `Cloud Firestore` pour les données métier principales
- `Firebase Realtime Database` pour les tests temps réel et les flux réactifs

## Pour tester

1. Vérifie que le projet Firebase `gestionscolariteuatm` existe bien dans la console Firebase.
2. Active `Authentication > Sign-in method > Email/Password`.
3. Crée `Cloud Firestore` dans la console Firebase.
4. Crée aussi `Realtime Database` dans la console Firebase.
5. Lance l'application.
6. Depuis l'écran de connexion, ouvre `Tester le backend Firebase`.

Si ta Realtime Database vient juste d'être créée, lance l'application avec un `dart-define` :

### Dart define : Mon lien vers Firebase Realtime Database

```bash
flutter run --dart-define=FIREBASE_DATABASE_URL=https://gestionscolariteuatm-default-rtdb.europe-west1.firebasedatabase.app
```

## Collections / nœuds de test

Les tests backend écrivent dans :

- Firestore : `system_checks/firestore_ping`
- Realtime Database : `system_checks/rtdb_ping`

## Sécurité Firebase

Les fichiers de sécurité ont été ajoutés :

- `firestore.rules`
- `firestore.indexes.json`
- `database.rules.json`

Pour les déployer :

```bash
firebase deploy --only firestore:rules,firestore:indexes,database
```

Si le CLI ne détecte pas le projet, on peut forcer l'ID explicitement :

```bash
firebase deploy --only firestore:rules,firestore:indexes,database --project gestionscolariteuatm
```

Remarque :

- les comptes de démonstration `admin@uatm.test`, `secretaire@uatm.test` et `etudiant@uatm.test` sont pris en charge par les règles pour le bootstrap initial
- pour un vrai déploiement, la création d'administrateurs et de secrétaires doit idéalement passer par le serveur, Cloud Functions, ou la console Firebase plutôt que par le client mobile
