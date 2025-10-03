# Unity Export

Inserisci qui l'export "Unity as a Library" generato da Unity.

Struttura attesa:

```
android/
└── UnityExport/
    ├── launcher/
    └── unityLibrary/
```

Copia l'intero contenuto della cartella `export` generata da Unity dentro `android/UnityExport/`. Il modulo Flutter cercherà automaticamente `unityLibrary` e lo collegherà alla build Android.
