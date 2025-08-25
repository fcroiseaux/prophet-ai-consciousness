# Configuration des Clés API - Prophet

Ce projet utilise un système de configuration sécurisé pour gérer les clés API. Suivez ces étapes pour configurer vos clés :

## 🚀 Configuration rapide

### Étape 1: Copier le fichier de configuration

```bash
# Depuis le dossier xcode/Prophet/
cp Config.xcconfig.example Config.xcconfig
```

### Étape 2: Éditer vos clés API

Ouvrez le fichier `Config.xcconfig` et remplacez les valeurs par défaut par vos vraies clés API :

```xcconfig
// Remplacez par votre vraie clé OpenAI
OPENAI_API_KEY = sk-proj-votre_vraie_cle_openai_ici

// Remplacez par votre vraie clé ElevenLabs  
ELEVENLABS_API_KEY = votre_vraie_cle_elevenlabs_ici
```

### Étape 3: Build et run

```bash
# Build le projet
xcodebuild -project Prophet.xcodeproj -scheme Prophet -configuration Debug -sdk iphonesimulator build

# Ou ouvrez Xcode et lancez normalement
open Prophet.xcodeproj
```

## 🔑 Obtenir vos clés API

### OpenAI
1. Allez sur https://platform.openai.com/api-keys
2. Connectez-vous à votre compte
3. Cliquez sur "Create new secret key"
4. Copiez la clé qui commence par `sk-proj-`
5. IMPORTANT: Sauvegardez cette clé, elle ne sera plus visible après

### ElevenLabs  
1. Allez sur https://elevenlabs.io/settings/api-keys
2. Connectez-vous à votre compte
3. Copiez votre clé API existante ou créez-en une nouvelle

## ⚙️ Comment ça fonctionne

- Le fichier `Config.xcconfig` est référencé dans les Build Settings du projet Xcode
- Les variables sont injectées comme variables d'environnement lors du build
- L'application lit les clés via `ProcessInfo.processInfo.environment`
- Si pas de clés trouvées, fallback vers `UserDefaults` (interface utilisateur)

## 🛡️ Sécurité

- ✅ Le fichier `Config.xcconfig` est dans le `.gitignore` et ne sera jamais commité
- ✅ Seul `Config.xcconfig.example` est versionné comme template
- ✅ Vos vraies clés API restent locales sur votre machine
- ✅ Les clés ne sont jamais stockées en dur dans le code

## 🐛 Dépannage

### L'application ne trouve pas les clés :
1. Vérifiez que `Config.xcconfig` existe dans le dossier `xcode/Prophet/`
2. Vérifiez que les clés ne contiennent pas les valeurs d'exemple `your_*_api_key_here`
3. Clean et rebuild le projet : `Product > Clean Build Folder` dans Xcode
4. Vérifiez que le fichier xcconfig est bien référencé dans Project Settings

### Build échoue :
1. Vérifiez que vous êtes dans le bon dossier : `xcode/Prophet/`
2. Utilisez le simulateur iOS plutôt qu'un device physique pour les tests
3. Assurez-vous que Xcode 15+ est installé

### Alternative manuelle :
Si le système xcconfig ne fonctionne pas, utilisez l'interface utilisateur de l'app pour configurer les clés via UserDefaults.