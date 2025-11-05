# cli-tools

Ett personligt repo med små, fristående kommandoradsverktyg för utveckling.
Varje verktyg ligger i en egen katalog och kan köras direkt i terminalen.

## Struktur

```
cli-tools/
├── new-from-template.sh      # skapa nytt repo från mall
└── publish/                  # publiceringsflöde för git/Cloudflare Pages
    ├── README.md
    ├── deploy-to.sh
    ├── publish.sh
    ├── rollback-deploy.sh
    └── tag-today.sh
```

## Användning

Kör verktygen direkt via sökväg, t.ex.:

```bash
~/dev/cli-tools/publish/publish.sh -t -d
```

### Alias (rekommenderat)

Lägg till ett alias i `~/.bashrc` eller `~/.zshrc`:

```bash
alias publish="~/dev/cli-tools/publish/publish.sh"
```

Sedan kan du använda det var som helst:

```bash
publish -t -d
```

## Utbyggnad

Lägg till fler verktyg på samma sätt —
egna mappar, egna README-filer, och fristående skript.
