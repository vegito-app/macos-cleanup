# macOS Cleanup

Suite de scripts Bash pour analyser l’occupation du disque, nettoyer certains fichiers temporaires et automatiser un nettoyage léger sur macOS avec `launchd`.

Les scripts sont conçus pour être distribués depuis un dépôt Git, un partage NAS en lecture seule (NFS/SMB) ou SFTPGo, puis **installés localement** pour rester utilisables sans connexion réseau.

## Prérequis

- macOS avec `launchctl` et `/bin/bash` (Bash 3.2 compatible).
- Une session utilisateur ouverte ; ne pas exécuter l’installation avec `sudo`.
- Outils facultatifs : Go, Homebrew et Docker, uniquement pour les analyses/nettoyages correspondants.

## Contenu

```text
cleanup/
├── mac-cleanup.sh             # Nettoyage léger (utilisé par launchd)
├── mac-cleanup-analyze.sh     # Rapport d’occupation du disque
├── mac-cleanup-deep.sh        # Nettoyage approfondi manuel
├── mac-cleanup-install.sh     # Installation locale et LaunchAgent
├── mac-cleanup-uninstall.sh   # Désinstallation, journaux conservés
├── mac-cleanup-activate.sh    # Activation du LaunchAgent
├── mac-cleanup-disable.sh     # Désactivation du LaunchAgent
├── mac-cleanup-exec.sh        # Déclenchement immédiat
├── mac-cleanup-status.sh      # État et configuration
├── mac-cleanup-logs.sh        # Dernières lignes du journal
└── README.md
```

## Installation

Depuis le dossier distribué (par exemple `/Volumes/nas_vanves/scripts/macos/cleanup`) :

```bash
cd /Volumes/nas_vanves/scripts/macos/cleanup
bash mac-cleanup-install.sh
```

L’installateur copie les scripts dans :

```text
~/Library/Application Support/mac-cleanup/
```

Il enregistre le LaunchAgent :

```text
~/Library/LaunchAgents/local.mac-cleanup.plist
```

Le LaunchAgent doit exécuter la **copie locale** :

```text
~/Library/Application Support/mac-cleanup/mac-cleanup.sh
```

Vérifier :

```bash
plutil -p "$HOME/Library/LaunchAgents/local.mac-cleanup.plist"
launchctl print "gui/$(id -u)/local.mac-cleanup"
ls -lah "$HOME/Library/Application Support/mac-cleanup/"
```

**Important :** l’installateur doit copier l’ensemble des fichiers `mac-cleanup*.sh`, et pas uniquement `mac-cleanup.sh`, pour que toutes les commandes ci-dessous soient disponibles localement.

## Utilisation

Après installation :

```bash
cd "$HOME/Library/Application Support/mac-cleanup"

./mac-cleanup-status.sh     # Vérifier le service
./mac-cleanup-exec.sh       # Déclencher le nettoyage
./mac-cleanup-logs.sh       # Consulter les journaux
./mac-cleanup-analyze.sh    # Analyser l’occupation du disque
./mac-cleanup-deep.sh       # Nettoyage approfondi manuel
./mac-cleanup-disable.sh    # Désactiver le LaunchAgent
./mac-cleanup-activate.sh   # Réactiver le LaunchAgent
```

Le nettoyage automatique utilise `RunAtLoad=true`, `StartInterval=86400` (environ 24 heures) et `KeepAlive=false`. Le service ne tourne pas en permanence. `launchd` ne garantit pas une exécution exacte à la seconde, notamment lorsque le Mac est en veille.

## Ce qui est nettoyé

### Nettoyage automatique : `mac-cleanup.sh`

- Fichiers de journaux VS Code de plus de 14 jours.
- Fichiers `*.log` de plus de 30 jours sous `~/Library/Logs`, à l’exception des journaux de mac-cleanup.

### Nettoyage manuel : `mac-cleanup-deep.sh`

- Cache de compilation Go via `go clean -cache`, si Go est installé.
- Nettoyage Homebrew via `brew cleanup -s`, si Homebrew est installé.
- Répertoires `Cache` et `CachedData` de VS Code lorsque le processus `Code` n’est pas détecté.

Le nettoyage approfondi peut entraîner une reconstruction ou un nouveau téléchargement de caches.

## Rapports et journaux

```text
~/Library/Logs/mac-cleanup/
├── cleanup.log
├── launchd.stdout.log
├── launchd.stderr.log
└── analysis/
    ├── analysis-YYYY-MM-DD_HH-MM-SS.log
    └── latest.log
```

Le rapport d’analyse inspecte notamment APFS, les snapshots, les répertoires utilisateur, les caches d’applications, VS Code, Go, Docker, Homebrew et certains répertoires système accessibles. Il est destiné à être exécuté **sans `sudo`** : les emplacements protégés peuvent donc être partiellement visibles.

## Mise à jour

Depuis une nouvelle copie du dossier distribué :

```bash
bash mac-cleanup-install.sh
```

L’installateur met à jour les scripts locaux et recharge le LaunchAgent. Vérifier ensuite :

```bash
bash "$HOME/Library/Application Support/mac-cleanup/mac-cleanup-status.sh"
```

## Désinstallation

Depuis le dossier local ou le dossier source :

```bash
bash "$HOME/Library/Application Support/mac-cleanup/mac-cleanup-uninstall.sh"
```

La désinstallation arrête le service, retire son plist et supprime les scripts installés. Les journaux et rapports sont conservés. Le désinstallateur actuel prend également en charge l’ancien identifiant `com.david.mac-cleanup` pour migration ; retirer cette compatibilité historique avant une publication publique si elle n’est plus nécessaire.

## Distribution NAS et SFTP

Le dossier `cleanup/` peut être publié en lecture seule sur le NAS et exposé aux utilisateurs autorisés via NFS, SMB ou SFTPGo. Les utilisateurs peuvent exécuter l’installateur depuis le montage ou télécharger une copie au préalable. L’installation locale évite toute dépendance au NAS pour l’exécution planifiée.

Ne donner l’accès en écriture au dossier de distribution qu’aux administrateurs autorisés. Vérifier le contenu et la provenance des scripts avant leur exécution.

## Développement et validation

Vérification syntaxique des scripts :

```bash
for script in mac-cleanup*.sh; do
    bash -n "$script" || exit 1
done
```

L’identifiant launchd générique est `local.mac-cleanup`. Les chemins personnels doivent être construits à partir de `$HOME` et non d’un nom d’utilisateur codé en dur.

## Licence

MIT
