# System Terminal Live — compagnon Windows 1.0.0

Windows 10/11 et PowerShell 5.1. Aucun module à télécharger. Le GPU NVIDIA requiert nvidia-smi installé avec son pilote ; sur AMD/Intel, les panneaux GPU restent indisponibles. Le reste du tableau de bord fonctionne indépendamment.

1. Extraire ce ZIP dans un dossier personnel permanent et accessible en écriture, hors du dossier du fond.
2. S'abonner au fond, l'appliquer, puis dans Wallpaper Engine : clic droit sur le fond → Ouvrir dans l'Explorateur.
3. Double-cliquer Demarrer.cmd dans le compagnon et sélectionner le dossier du fond contenant index.html et terminal-live.marker. Ne pas sélectionner le dossier parent Workshop.
4. Les mesures apparaissent après quelques secondes. Le compagnon ne lance pas Wallpaper Engine ; il écrit uniquement telemetry.js et settings.js dans le dossier choisi. Aucun administrateur n'est nécessaire si ce dossier est accessible en écriture.

Regler-vitesse.cmd : intervalles de 1 à 60 s, initialement acquisition 2 s / affichage 1 s. RAM au plus toutes les 2 s, processus 3 s, espace libre 30 s. Une acquisition plus lente limite aussi ces fréquences. La collecte peut prendre plus longtemps que l'intervalle demandé. Les animations ne créent pas de mesures supplémentaires.

Arreter.cmd arrête les collecteurs lancés depuis ce dossier. Choisir-fond.cmd permet de changer de dossier. Un compagnon dessert un dossier de fond ; plusieurs écrans utilisant le même fond partagent les mesures.

Activer-demarrage-auto.cmd installe un raccourci utilisateur (facultatif, après le premier lancement). Desactiver-demarrage-auto.cmd le supprime. Pour désinstaller : désactiver le démarrage automatique, lancer Arreter.cmd, puis supprimer le dossier du compagnon. Wallpaper Engine gère séparément son propre démarrage.

## Données et dépannage

Les mesures restent locales, sans serveur ni connexion réseau. Elles incluent noms/PID des cinq processus les plus actifs, matériel, charge, RAM, volumes et interface réseau. Les fichiers générés dans le fond restent lisibles par les autres applications locales. Ne pas republier ces fichiers après utilisation. Aucun nom d'utilisateur, numéro de série, IP ou secret n'est collecté intentionnellement.

Si le fond reste hors ligne, vérifier le dossier choisi et collecteur-error.log dans le compagnon. Une mise à jour Workshop peut réinitialiser les fichiers du fond ; relancer le compagnon au besoin. Si le fond a changé de dossier, utiliser Choisir-fond.cmd. Le collecteur continue tant qu'il n'est pas arrêté, même si Wallpaper Engine est fermé.

Sans compagnon, l'horloge fonctionne mais les mesures sont indisponibles. Les scripts sont fournis lisibles, sans binaire compilé, et doivent être lancés volontairement. Les commandes n'installent pas de logiciel ni de service système.
