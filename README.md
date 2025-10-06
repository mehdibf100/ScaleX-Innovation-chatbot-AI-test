# Chatbot App

Ce projet est une application de chatbot complète, utilisant **Flutter pour le frontend**, **Node.js + TypeScript avec Prisma pour le backend**, et **PostgreSQL (Neon)** pour la base de données. L’objectif est de permettre aux utilisateurs de discuter avec un assistant intelligent, tout en sauvegardant l’historique des conversations et en offrant une interface réactive.

<!-- Technologies utilisées -->
Technologies : Flutter (UI, gestion d'état, intégration API), Node.js + TypeScript (API REST, logique métier), Prisma (ORM), PostgreSQL sur Neon (stockage persistant).

<!-- Fonctionnalités principales -->
Fonctionnalités : Authentification utilisateurs (Google/Email), interface de chat réactive, historique des conversations, support multilingue, gestion des rôles (admin/utilisateur), communication sécurisée frontend/backend.

<!-- Architecture -->
Architecture générale : 
Flutter Frontend <--> Node.js/TypeScript Backend <--> Prisma <--> PostgreSQL (Neon)
Le frontend gère l'affichage et les interactions, le backend fournit l'API et la logique métier, Prisma sert d'ORM, et PostgreSQL stocke les données.

<!-- Instructions pour le Frontend -->
Étapes pour le frontend (Flutter) : 
1. Installer Flutter depuis [docs officiels](https://docs.flutter.dev/get-started/install). 
2. Cloner le projet : `git clone <URL_DU_PROJET>` puis `cd frontend`. 
3. Installer les dépendances : `flutter pub get`. 
4. Lancer l’application : `flutter run`.

<!-- Instructions pour le Backend -->
Étapes pour le backend (TypeScript + Prisma) :
1. Installer Node.js >=18 et npm/yarn. 
2. Se placer dans le dossier backend : `cd backend`. 
3. Installer les dépendances : `npm install` ou `yarn install`. 
4. Créer le fichier `.env` avec : 
5. Générer Prisma client et appliquer la migration initiale : `npx prisma generate` puis `npx prisma migrate dev --name init`. 
6. Lancer le serveur en mode développement : `npm run dev` ou `yarn dev`.

<!-- Configuration -->
Configuration : Le backend nécessite un `.env` avec DATABASE_URL et PORT. Le frontend doit avoir `API_BASE_URL` dans `lib/config.dart` ou fichier de configuration similaire.

<!-- Scripts utiles -->
Scripts utiles : Backend : `npm run dev` (développement), `npm run build` (production), `npx prisma studio` (exploration DB). Frontend : `flutter run` (développement), `flutter build apk` ou `flutter build ios`.

