# uatm_paiements

Application Flutter de gestion des paiements de scolarité pour l'UATM GASA Formation.

## Backend utilisé

Le projet utilise actuellement :

- `Firebase Authentication` pour la connexion
- `Cloud Firestore` pour les données métier principales
- `Firebase Realtime Database` pour les tests temps réel et les flux réactifs

## Tester l'avancement

1. Vérifie que le projet Firebase `gestionscolariteuatm` existe bien dans la console Firebase.
2. Active `Authentication > Sign-in method > Email/Password`.
3. Crée `Cloud Firestore` dans la console Firebase.
4. Crée aussi `Realtime Database` dans la console Firebase.
5. Lance l'application.
6. Depuis l'écran de connexion, ouvre `Tester le backend Firebase`.

Si ta Realtime Database vient juste d'être créée, lance l'application avec un `dart-define` :

```bash
flutter run --dart-define=FIREBASE_DATABASE_URL=https://votre-url-realtime-database
```

Exemples d'URL possibles selon la documentation Firebase :

- `https://<databaseName>.firebaseio.com`
- `https://<databaseName>.<region>.firebasedatabase.app`

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

Si le CLI ne détecte pas le projet, force l'ID explicitement :

```bash
firebase deploy --only firestore:rules,firestore:indexes,database --project gestionscolariteuatm
```

Remarque :

- les comptes de démonstration `admin@uatm.test`, `secretaire@uatm.test` et `etudiant@uatm.test` sont pris en charge par les règles pour le bootstrap initial
- pour un vrai déploiement, la création d'administrateurs et de secrétaires doit idéalement passer par le serveur, Cloud Functions, ou la console Firebase plutôt que par le client mobile
