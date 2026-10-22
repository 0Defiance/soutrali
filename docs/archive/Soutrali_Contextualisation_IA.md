# SOUTRALI --- Fichier de contextualisation pour une IA

> **Rôle de ce document :** fournir à une IA le contexte de référence du
> projet Soutrali afin qu'elle puisse contribuer de manière cohérente à
> sa conception, sa documentation, son développement et sa présentation.
>
> **Langue de travail :** français.
>
> **Statut :** document de cadrage contextuel évolutif. Les éléments
> marqués « à valider » ne doivent pas être présentés comme des
> décisions définitives.

------------------------------------------------------------------------

## 1. Identité du projet

-   **Nom du projet :** Soutrali
-   **Slogan retenu :** « L'entraide à porter de main »
-   **Pays et contexte d'usage :** Côte d'Ivoire
-   **Nature du projet :** plateforme numérique d'entraide entre
    habitants d'une même ville.
-   **Idée centrale :** permettre aux habitants de proposer une aide, de
    rechercher un service ou de trouver quelqu'un pour une petite
    mission, puis de prendre directement contact.
-   **Périmètre géographique :** une **ville**, et non un seul quartier.
    La ville de lancement reste à confirmer.
-   **Approche :** concevoir d'abord un produit minimum viable (MVP),
    utile, compréhensible, mobile et réaliste à mettre en œuvre.

Soutrali doit répondre à des besoins concrets de la vie quotidienne. Le
projet ne doit pas être transformé par défaut en logiciel de gestion
d'entreprise, ERP, CRM ou outil réservé aux professionnels.

## 2. Vision et problème à résoudre

Dans une ville, les habitants peuvent avoir besoin d'une aide
ponctuelle, rechercher une personne proposant un service, offrir leur
savoir-faire ou trouver quelqu'un pour réaliser une petite mission. Ces
informations peuvent être dispersées dans les conversations, les groupes
de messagerie ou les réseaux personnels.

Soutrali vise à rendre ces possibilités plus faciles à publier,
découvrir et contacter au même endroit, avec une organisation simple par
ville, zone et catégorie.

### Vision

Créer un point de rencontre numérique local où les habitants peuvent
plus facilement **demander de l'aide, proposer leur aide et trouver des
services ou de petites missions**.

### Objectifs principaux

1.  Faciliter la publication d'une demande d'aide ou d'une offre.
2.  Aider les habitants à trouver des annonces pertinentes dans leur
    ville.
3.  Permettre la recherche par catégorie et zone géographique.
4.  Favoriser la mise en relation directe entre les personnes.
5.  Donner aux utilisateurs un moyen de signaler les contenus
    problématiques.
6.  Prévoir une modération simple pour limiter les abus.
7.  Garder l'expérience accessible aux personnes utilisant
    principalement un téléphone.

## 3. Publics et utilisateurs

Les profils ci-dessous sont des rôles fonctionnels, pas nécessairement
des catégories de comptes distinctes.

-   **Visiteur :** consulte les contenus publics et découvre le
    fonctionnement de la plateforme.
-   **Utilisateur inscrit :** gère son profil, publie et gère ses
    annonces, contacte d'autres personnes selon les règles retenues.
-   **Personne qui demande de l'aide :** publie un besoin ou une petite
    mission.
-   **Personne qui propose son aide :** publie une offre de service ou
    répond à un besoin.
-   **Modérateur :** examine les signalements et traite les contenus qui
    enfreignent les règles.
-   **Administrateur :** gère les paramètres, catégories, comptes et
    droits de la plateforme.

Une même personne peut demander de l'aide à un moment et en proposer à
un autre.

## 4. Fonctionnalités envisagées pour le MVP

### Fonctionnalités incluses dans le périmètre initial

-   Inscription et connexion.
-   Création et modification d'un profil utilisateur.
-   Publication d'une annonce de demande ou d'offre.
-   Informations de base pour une annonce : titre, description,
    catégorie, ville/zone, type d'annonce, date de publication et moyen
    de contact selon les règles qui seront retenues.
-   Consultation des annonces.
-   Recherche et filtres par catégorie et zone.
-   Consultation du détail d'une annonce.
-   Prise de contact directe entre les personnes.
-   Gestion par l'auteur de ses propres annonces : modifier, clôturer ou
    supprimer, selon les règles définitives.
-   Signalement d'une annonce ou d'un comportement inapproprié.
-   Outils de modération et d'administration de base.
-   Interface responsive adaptée en priorité aux téléphones, sans
    exclure les ordinateurs.

### Éléments à ne pas ajouter automatiquement au MVP

Sauf décision explicite ultérieure, ne pas inclure dans le périmètre
initial :

-   paiement intégré ou portefeuille électronique ;
-   livraison ou logistique intégrée ;
-   géolocalisation GPS en temps réel ;
-   application mobile native Android/iOS ;
-   vérification exhaustive de l'identité de chaque utilisateur ;
-   système complexe de notation, de réputation ou de recommandation ;
-   fonctionnalités complètes de gestion d'entreprise ;
-   automatisations complexes ou architecture surdimensionnée.

Ces éléments peuvent être étudiés plus tard si un besoin réel est
établi.

## 5. Principes de conception

Toute proposition concernant Soutrali doit respecter les principes
suivants :

1.  **Utilité quotidienne :** partir de besoins concrets des habitants.
2.  **Simplicité :** limiter les étapes et les champs inutiles.
3.  **Accessibilité mobile :** rendre les écrans lisibles et utilisables
    sur téléphone.
4.  **Contexte ivoirien :** tenir compte des usages, de la connectivité,
    des moyens de contact et des habitudes locales, sans faire de
    suppositions non vérifiées.
5.  **Confiance et prudence :** prévoir des règles claires, le
    signalement et la modération.
6.  **Protection des données :** ne collecter que les données
    nécessaires et éviter d'exposer publiquement les coordonnées sans
    décision explicite.
7.  **Évolutivité raisonnable :** construire une base simple,
    maintenable et documentée.
8.  **Cohérence :** ne pas contredire les décisions validées dans les
    documents du projet.
9.  **Validation humaine :** signaler les décisions ouvertes plutôt que
    les inventer.

## 6. Identité visuelle et ton

### Identité de marque

-   **Nom :** Soutrali
-   **Slogan :** « L'entraide à porter de main »
-   **Couleurs de marque souhaitées :** orange, blanc et vert.
-   **Motif visuel :** une main, des mains solidaires ou un symbole
    immédiatement associé à l'entraide.
-   **Sens à transmettre :** solidarité, proximité, accessibilité,
    confiance et action concrète.

Les codes couleurs exacts et leurs usages techniques doivent être repris
de la charte graphique validée lorsqu'elle est disponible. Ne pas
inventer de codes hexadécimaux et les présenter comme définitifs.

### Ton éditorial

Utiliser un français clair, chaleureux, direct et compréhensible par un
public large. Éviter le jargon technique dans les textes destinés aux
habitants. Les messages doivent être respectueux, inclusifs et orientés
vers l'action.

## 7. Démarche UML et cahier des charges

Le cahier des charges de Soutrali doit être structuré selon une approche
UML. Les diagrammes utiles comprennent notamment :

-   diagramme de cas d'utilisation ;
-   diagramme de classes ;
-   diagramme de séquence ;
-   diagramme d'activité ;
-   diagramme d'états/transitions lorsque pertinent.

Les diagrammes doivent correspondre aux règles métier et aux
fonctionnalités réellement retenues. Ils ne doivent pas être ajoutés
uniquement pour faire du volume.

Le cahier des charges de référence produit dans le cadre du projet est
intitulé **« Soutrali --- Cahier des charges UML v1 »**. Il existe en
versions PDF et DOCX dans l'historique du projet. Avant de modifier une
règle ou une fonctionnalité, consulter la version disponible et vérifier
si le point est déjà défini.

## 8. Organisation du travail et feuille de route

Le projet suit les grandes étapes suivantes :

1.  Choisir et cadrer un projet pilote simple et réalisable.
2.  Rassembler les documents et matériaux déjà générés par IA.
3.  Produire et faire valider le cahier des charges complet.
4.  Définir la stack technique, notamment avec l'aide de Claude si cela
    reste pertinent.
5.  Mettre en place un environnement de travail collaboratif et de
    livraison (par exemple Notion, GitHub Projects, GitLab ou un
    ensemble d'outils cohérent).
6.  Effectuer des tests de validation internes.
7.  Produire la documentation de prise en main et la documentation
    technique nécessaire.
8.  Préparer la présentation à la maîtrise d'ouvrage (MOA).

Cette feuille de route doit être suivie de manière progressive. Ne pas
considérer une étape comme validée sans décision ou retour explicite.

## 9. Règles de collaboration attendues de l'IA

Quand tu aides sur Soutrali :

-   Commence par identifier le livrable demandé et son usage.
-   Réutilise le contexte de ce document et les documents de référence
    disponibles.
-   Réponds en français, sauf demande contraire.
-   Fournis des résultats structurés, directement exploitables et
    suffisamment concrets.
-   Pour un document pratique, produis un contenu prêt à copier,
    enregistrer ou transmettre.
-   Pour du code, indique les fichiers concernés, les prérequis, les
    commandes et les étapes de vérification.
-   Pour les choix techniques, compare les options selon la simplicité,
    le coût, la maintenance, la sécurité, les compétences nécessaires et
    l'adéquation au contexte.
-   Distingue clairement les **décisions validées**, les **hypothèses**,
    les **recommandations** et les **questions ouvertes**.
-   Ne prétends pas qu'un fichier, un test, une intégration ou un
    déploiement a été effectué si ce n'est pas le cas.
-   Ne fabrique pas de chiffres d'usage, de budgets, de partenariats, de
    contraintes réglementaires précises ou de résultats de tests.
-   Évite d'élargir le périmètre sans expliquer le besoin, les coûts et
    les conséquences.
-   Si une information essentielle manque, pose une question ciblée. Si
    le travail peut avancer sans elle, formule une hypothèse explicite
    et continue.
-   Lorsque tu proposes une modification du cahier des charges, précise
    les sections et diagrammes UML potentiellement concernés.
-   Privilégie les solutions simples et proportionnées à un projet
    pilote.

## 10. Décisions et points à confirmer

Les éléments suivants sont des décisions ouvertes tant qu'ils ne sont
pas validés par le porteur du projet :

-   ville de lancement et éventuel calendrier de déploiement ;
-   catégories initiales d'aide et de services ;
-   inscription par numéro de téléphone, adresse e-mail ou autre méthode
    ;
-   canal de contact entre utilisateurs ;
-   visibilité publique ou protection des coordonnées personnelles ;
-   politique de modération, délais et responsabilités ;
-   langues proposées au lancement ;
-   modèle économique éventuel ;
-   budget, hébergement et nom de domaine ;
-   stack technique définitive ;
-   durée de conservation des données et règles de suppression ;
-   éventuelles exigences juridiques applicables et modalités de
    conformité.

Ne pas remplir ces champs par invention. Les présenter comme des
questions à arbitrer et proposer, au besoin, une recommandation
argumentée.

## 11. Sécurité, confiance et limites

Soutrali facilite la mise en relation, mais ne doit pas garantir qu'une
personne ou une annonce est fiable sans processus réel de vérification.

Les recommandations fonctionnelles doivent envisager :

-   la protection des comptes et des sessions ;
-   la validation des données saisies ;
-   la limitation du spam et des abus ;
-   le signalement et le traitement des contenus problématiques ;
-   la minimisation des données personnelles ;
-   des consignes de prudence adaptées aux échanges entre inconnus ;
-   des droits d'accès distincts pour les utilisateurs, modérateurs et
    administrateurs ;
-   des procédures de suppression ou de clôture des annonces.

Toute affirmation juridique ou de conformité doit être vérifiée à partir
de sources fiables et actuelles avant d'être présentée comme certaine.

## 12. Critères généraux de réussite du MVP

Le MVP sera mieux aligné sur la vision du projet si un utilisateur peut
:

1.  comprendre rapidement à quoi sert Soutrali ;
2.  consulter les annonces pertinentes pour sa ville ou sa zone ;
3.  publier une demande ou une offre sans difficulté inutile ;
4.  retrouver et gérer ses annonces ;
5.  contacter une autre personne selon les règles de confidentialité
    retenues ;
6.  signaler un contenu problématique ;
7.  utiliser les fonctions essentielles sur un téléphone.

Des indicateurs mesurables (par exemple annonces publiées, recherches
abouties, prises de contact et signalements traités) pourront être
définis lorsque la stratégie de test et de lancement sera précisée. Ne
pas inventer de seuils de réussite avant validation.

## 13. Format recommandé pour les futurs livrables

Selon la demande, privilégier :

-   **Cahier des charges :** Markdown, DOCX ou PDF.
-   **Documentation de prise en main :** guide pas à pas, avec prérequis
    et captures d'écran lorsque disponibles.
-   **Backlog produit :** épics, user stories, priorités, critères
    d'acceptation et dépendances.
-   **Conception UML :** diagrammes lisibles et cohérents avec les
    règles métier.
-   **Documentation technique :** architecture, stack, configuration,
    installation, tests, déploiement et maintenance.
-   **Présentation MOA :** problème, public cible, solution, périmètre
    MVP, parcours clés, risques, planning et décisions attendues.

Ne produis pas plusieurs formats ou livrables non demandés si cela
ajoute de la complexité inutile.

## 14. Instruction de départ à l'IA

À partir de ce contexte, aide-moi à faire avancer **Soutrali**, une
plateforme ivoirienne d'entraide à l'échelle d'une ville. Respecte le
slogan « L'entraide à porter de main », l'identité orange-blanc-vert et
l'objectif d'un MVP simple, mobile et utile dans la vie quotidienne.
Appuie-toi sur les documents de référence disponibles, notamment le
cahier des charges UML v1. Ne transforme pas le projet en outil de
gestion d'entreprise et n'ajoute pas automatiquement des fonctionnalités
hors périmètre. Distingue toujours les décisions validées des hypothèses
et des points à confirmer. Propose des livrables concrets, cohérents et
directement exploitables.

------------------------------------------------------------------------

*Fin du fichier de contextualisation.*
