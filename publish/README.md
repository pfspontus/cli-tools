# Publiceringsprocess för Eleventy + Cloudflare Pages

## Snabbkommando (automatiserad publicering)

De manuella stegen längre ned ersätts nu av enklare skript i `../`.
Utgå alltid från repots rot.

1. Skapa och pusha publish-tagg från main, samt deploy till staging
`../publish.sh -t -d`

2. (Efter granskning) deploya samma tagg till production
`../publish.sh -d production`

3. (Om nödvändigt) rulla tillbaka staging eller production
`../publish.sh -r [staging|production]`

Skriptet tar hand om datum, sekvensnummer, push, samt branch-hantering.
Taggar skapas i formatet publish-YYYY-MM-DD-N.
Det går fortfarande att följa de manuella stegen nedan om du behöver mer kontroll eller vill felsöka.

---

## Förberedelser (engångs)
- Cloudflare Pages: Production branch = `production`.  
- Skapa en `staging` branch och ge den en egen preview-domän.  
- Lägg `_site/` i `.gitignore` (Pages bygger själv).  
- Skydda `staging` och `production` (kräv godkända checks).  

---

## 1. Välj commit och skapa tagg
På `main`, skapa en publish-tagg med datum + löpnummer:

`git checkout main`

säkerställ rätt commit, t.ex:
`git log --oneline -n 3`

skapa och pusha taggen
```
git tag publish-YYYY-MM-DD-N
git push origin publish-YYYY-MM-DD-N
```
Exempel: `publish-2025-09-28-1`

## 2. Peka staging till taggen (för granskning)

```
git checkout staging
git reset --hard publish-YYYY-MM-DD-N
git push -f origin staging
```

Cloudflare Pages bygger och deployar automatiskt på staging-URL:en.
Granska och verifiera.

## 3. Peka production till samma tagg (go live)

```
git checkout production
git reset --hard publish-YYYY-MM-DD-N
git push -f origin production
```
Cloudflare Pages bygger och deployar på produktionsdomänen.

## 4. (Valfritt) Märk release med semver-tagg

```
git tag vX.Y.Z publish-YYYY-MM-DD-N
git push origin vX.Y.Z
```

## Rollback

```
git checkout production
git reset --hard publish-YYYY-MM-DD-N-previous
git push -f origin production
```

## Hantering av taggar

- Ta bort lokalt:
`git tag -d publish-YYYY-MM-DD-N`

- Ta bort remote:
`git push origin :refs/tags/publish-YYYY-MM-DD-N`

- Flytta/ändra:
```
git tag -f publish-YYYY-MM-DD-N <sha>
git push -f origin publish-YYYY-MM-DD-N
```

## Tips
- Håll staging och production snabbspolade (ingen merge).
- Använd git cherry-pick på main om du behöver in med en fix snabbt.
- Följ konsekvent namnstandard: publish-YYYY-MM-DD-N.
