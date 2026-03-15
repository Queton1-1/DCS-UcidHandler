# DCS-UcidHandler
[Update 2026-03]

Téléchargement / Download  
-- 
Pour télécharger le script, rdv à la page [Releases](https://github.com/Queton1-1/DCS-UcidHandler/releases)

# = FR =  
Script pour sauvegarder les identifiants UCID des joueurs, utile principalement pour les serveurs DCS  
Créée un dossier `\Saved Games\DCS Multiplayer UcidHandler` avec des listes lua contenant :
- `UCID log.lua` : historique des UCIDS / pseudos connectés  
- `UCID blacklist.lua` : UCIDS bannis  
- `UCID whitelist.lua` : si activée, n'autorise l'accés aux slots qu'aux UCIDS présent dans cette liste
- `UCID redlist.lua` : si activée, n'autorise l'accés aux slots rouges qu'aux UCIDS présent dans cette liste
- `UCID bluelist.lua` : si activée, n'autorise l'accés aux slots bleux qu'aux UCIDS présent dans cette liste

**Mises à jour / Updates**
--  
/!\ Rien n'est jamais parfait, ce script évoluera au fil des idées d'améliorations, des bugs éventuels à corriger et surtout du temps que je peux y consacrer.  

**Installation**  
--
Déposez le script dans votre `\Saved Games\DCS\Scripts\Hooks\`  

**Utilisation**  
--  
Alimentez les listes à partir `\Saved Games\DCS Multiplayer UcidHandler\UCIDS history list.lua`  
