# Exfiltration de données par ICMP

## asm_icmp_leaker

### Compilation

```
./build.sh

```

### Utilisation

```
./main test.txt
```

### Information

Ce script va exfiltré les données du fichier passé en paramètre par ICMP. Il va lire le fichier et envoyer par ICMP le contenu du fichier découpé en plusieurs partie. Le script va attendre une réponse ICMP pour envoyer le caractère suivant de facon a ne pas avoir de perte d'information.
