<p align="center">
  <img src="brand/logo/soutrali-logo-vertical-v1.svg" alt="Soutrali – L’entraide à porter de main" width="260">
</p>

# Soutrali

**L’entraide à porter de main**

Plateforme d’entraide et de services de proximité entre habitants d’une même ville de Côte d’Ivoire. Projet pilote lancé à **Abidjan**.

> **Ce fichier est le document unique de référence du projet** : présentation, décisions, état d’avancement, règles de travail et journal. Il remplace l’ancien `ContexteSoutrali.md`. Il est mis à jour à la fin de chaque séance de travail.
>
> **Statut : cadrage et conception.** Le dépôt ne contient pas encore de code. Le choix technique (stack v3) sera défini ensemble plus tard : rien de technique n’est arrêté ici.
>
> **Dernière mise à jour :** 20 octobre 2026 · **Langue de travail :** français

---

## 1. L’idée

Trouver rapidement quelqu’un pour un coup de main (plombier, répétiteur, réparateur de téléphone, aide pour un déménagement) passe souvent par les connaissances, les appels ou les groupes de discussion. Les demandes se perdent, les compétences manquent de visibilité.

Soutrali rassemble au même endroit :

- **l’entraide** : demander ou proposer une aide ponctuelle, bénévole ou non ;
- **les services** : trouver ou proposer une prestation de proximité ;
- **les opportunités** : donner de la visibilité aux compétences et aux petites missions.

Soutrali n’est ni un logiciel de gestion d’entreprise, ni une place de marché complexe dès sa première version.

## 2. Le projet pilote

| | |
|---|---|
| **Ville pilote** | Abidjan (décision validée) |
| **Public** | Habitants : personnes qui cherchent de l’aide, prestataires, volontaires |
| **Principe** | Un produit minimum viable (MVP) simple, pensé d’abord pour le téléphone |
| **Double objectif** | Un service utile aux habitants **et** une méthode de travail collaboratif reproductible, de l’idée à la présentation à la maîtrise d’ouvrage (MOA) |

**Le MVP doit permettre de :** créer un compte et un profil ; publier une demande ou une offre, bénévole ou rémunérée ; rechercher par commune, catégorie, type et mot-clé ; contacter l’auteur d’une annonce ; suivre, modifier et clôturer ses annonces ; signaler un contenu ; modérer et administrer (de base).

**Hors MVP :** paiement en ligne, livraison, géolocalisation en temps réel, application mobile native, vérification d’identité exhaustive, notes et avis, aide aux personnes vulnérables, collectes d’argent, actions collectives.

**Règles sensibles proposées :** annonces concernant des mineurs publiées par un adulte seulement ; aide aux personnes vulnérables et collectes interdites au MVP ; message de prudence pour les services à domicile ; distinction claire entre informations « déclarées » et « vérifiées ».

## 3. Feuille de route

| Phase | Contenu | État |
|---|---|---|
| 1 | Cadrage du projet pilote | Fait |
| 2 | Rassembler l’existant dans le projet | Fait |
| 3 | Cahier des charges complet | En cours (v2 rédigé, à valider ; maquettes à produire) |
| 4 | Stack technique | À définir ensemble (version v3) |
| 5 | Environnement de travail collaboratif | À faire |
| 6 | Test interne de validation | À faire |
| 7 | Documentation de prise en main | À faire |
| 8 | Présentation à la MOA | À faire |

*Une phase n’est « validée » qu’après un retour explicite du porteur du projet.*

## 4. Registre des décisions

Statuts : **Validé** (décidé par le porteur) · **Proposé** (à valider) · **Ouvert** (à arbitrer).

| ID | Sujet | Statut | Contenu |
|---|---|---|---|
| D-01 | Ville pilote | **Validé** | Abidjan |
| D-02 | Identité visuelle | Proposé | Logo reçu = modèle de départ ; palette v2 mesurée sur le logo : orange `#FE7402`, vert `#037C30`, dérivés dans la charte v2 |
| D-03 | Zones | Proposé | Commune obligatoire + quartier libre ; les 13 communes du district d’Abidjan comme base, à confirmer par la MOA |
| D-04 | Inscription | Ouvert | Téléphone (avec code) ou e-mail ; coût d’envoi des SMS non vérifié |
| D-05 | Canal de contact | Ouvert | Recommandation : canaux choisis par l’auteur, visibles aux seuls utilisateurs connectés |
| D-06 | Modération | Ouvert | Recommandation pilote : publication immédiate, modération après signalement |
| D-07 | Catégories initiales | Ouvert | 8 catégories proposées dans le cahier des charges v2 |
| D-08 | Langues | Ouvert | Français au lancement |
| D-09 | Budget, hébergement, nom de domaine | Ouvert | Aucun chiffre inventé |
| D-10 | Données personnelles, conformité locale | Ouvert | Avis juridique nécessaire ; rien d’affirmé |
| D-11 | Âge minimum d’inscription | Ouvert | Lié aux règles sur les mineurs |
| D-12 | Modèle économique | Ouvert | Gratuit au pilote proposé ; rien d’autre défini |
| D-13 | Stack technique | Ouvert | Mise en attente : la stack v3 sera construite ensemble ; compétences et budget écartés pour l’instant |
| D-14 | README sans contenu technique | **Validé** | Tant que la stack v3 n’est pas arrêtée |
| D-15 | Document unique | **Validé** | `README.md` remplace `ContexteSoutrali.md` (contexte + README fusionnés) |

## 5. Documents et fichiers du projet

| Livrable | Version | État |
|---|---|---|
| `README.md` (ce fichier) | 3.0 | Vivant |
| Cahier des charges UML | 2.0 | À valider (pages de garde incluses) |
| Charte graphique | 2.0 | À valider |
| Stack technique | 0.1 | **En attente** : base de réflexion pour la v3, sans engagement |
| Dossier `brand/` | 1 | Logos, icônes, favicons, couleurs : à valider sur appareils réels |
| Anciennes versions (CDC v1, charte v1, contextualisation v1) | — | Remplacées, à archiver |

Les décisions détaillées, les règles métier (RM-xx), les fonctionnalités (F-xx) et les diagrammes UML sont dans le cahier des charges v2. Les règles visuelles sont dans la charte graphique v2.

## 6. Identité visuelle

- **Signature :** « L’entraide à porter de main ». **Couleurs de marque :** orange et vert, sur fond ivoire.
- **Contrastes (calculés) :** le blanc sur l’orange est interdit en texte (2,7 : 1) ; texte sombre `#1F2A24` sur orange 5,5 : 1 ; blanc sur vert 5,3 : 1 ; orange de texte `#B24A00` sur ivoire 5,2 : 1.
- **Fichiers :** 13 variantes SVG du logo, PNG transparents, PDF d’impression, favicons et icônes d’application (dossier `brand/`).
- **Réserves :** le tracé vectoriel reproduit fidèlement le logo reçu, mais n’est pas un dessin d’origine ; les polices de la charte ne sont pas encore incluses ; le détail du favicon à 16 px est à vérifier sur écran réel.

## 7. Règles de travail (humains et IA)

1. Identifier le livrable demandé et son usage ; relire ce fichier avant de commencer.
2. Distinguer décisions validées, hypothèses, recommandations et questions ouvertes ; ne jamais présenter une proposition comme une décision.
3. Ne rien inventer : chiffres d’usage, budgets, partenariats, exigences juridiques, résultats de tests.
4. Garder le périmètre du MVP ; toute extension est d’abord discutée (besoin, coût, conséquences).
5. Ne pas prétendre qu’un test, une intégration ou un déploiement a eu lieu s’il n’a pas eu lieu.
6. Lors d’un changement du cahier des charges, citer les sections et diagrammes concernés.
7. Ne jamais partager de mot de passe ou de jeton d’accès dans une conversation.
8. Privilégier des solutions simples et proportionnées à un projet pilote.

**Mise à jour de ce fichier :** ajouter une ligne au journal, mettre à jour le registre des décisions, l’état des phases et la liste des documents.

## 8. Questions ouvertes principales

Inscription et contact (D-04, D-05) · modération (D-06) · catégories (D-07) · budget, hébergement et nom de domaine (D-09) · conservation des données et conformité locale (D-10) · âge minimum (D-11) · modèle économique (D-12) · stack technique v3 (D-13).

## 9. Journal des séances

| Date | Réalisé | Décisions |
|---|---|---|
| 15 oct. 2026 | Rédaction du cahier des charges v1, de la charte v1 et de la contextualisation v1 (en amont) | — |
| 19 oct. 2026 | Intégration de l’existant ; cadrage des 18 besoins ; réception du logo ; extraction des couleurs, vectorisation et icônes ; cahier des charges v2, charte v2, stack v0.1 | D-01 Abidjan ; palette et stack proposées |
| 20 oct. 2026 | Pages de garde des trois documents ; README non technique ; essais d’accès GitHub (lecture seule, écriture impossible depuis la conversation) ; publication manuelle décidée ; fusion contexte + README | D-13 stack remise à la v3 ; D-14 ; D-15 |

## 10. Prochaines étapes

1. Publier ce `README.md` et le dossier `brand/` dans le dépôt (manuellement).
2. Valider ou corriger les décisions proposées (D-02, D-03, D-05, D-06).
3. Phase 3 : maquettes des écrans clés (accueil, résultats, détail, publier, mes annonces, modération) sur la charte v2, puis arrêt du cahier des charges.
4. Phase 4 : construire ensemble la stack technique v3.
5. Phase 5 : choisir les outils collaboratifs et créer le backlog à partir du cahier des charges.

---

*Soutrali : l’entraide à porter de main.*
