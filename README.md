# Métaheuristiques pour le Problème d'Affectation Généralisé (GAP)

Ce projet implémente diverses heuristiques et métaheuristiques pour résoudre le **Problème d'Affectation Généralisé (GAP)**. L'objectif est d'affecter des tâches à des agents tout en minimisant les coûts ou en maximisant les bénéfices, en respectant les contraintes de ressource de chaque agent.

## Structure des Fichiers

- `readfile.jl` : Fonction pour lire les données des instances GAP depuis des fichiers texte.
- `get_opts_values.jl` : Récupère les valeurs optimales pour chaque instance.

- `heuristic.jl` : Implémentation des heuristiques de base.
- `metaheuristics.jl` : Implémentation des métaheuristiques avancées (e.g. VND, recuit simulé) sauf recherche tabou.
- `tabu_search.jl` : Implémentation de la recherche tabou.
  
Ensuite, il y a 4 fichiers dédiés aux fonctions spécifiques à chaque voisinage: 
- `change_one_agent.jl` : Méthodes spécifiques pour le voisinage de changement d'agent pour une tâche.
- `change_two_agents.jl` : Méthodes spécifiques pour le voisinage de changement d'agent pour deux tâches.
- `swap_two_tasks.jl` : Méthodes spécifiques pour le voisinage d'échanges de deux tâches.
- `swap_three_tasks.jl` : Méthodes spécifiques pour le voisinage de 3-échange de tâches.
  


## Dépendances

Le projet utilise **Julia** et nécessite les paquets suivants :
- `CSV` : Pour lire et écrire des fichiers CSV.
- `DataFrames` : Pour manipuler les données sous forme de tableaux.
- `OrderedCollections` : Pour des collections ordonnées.
- `ProgressMeter` : Pour afficher la progression des calculs.
- `Base.Threads` : Pour le traitement multithread.

Pour installer les dépendances nécessaires, exécutez :
```julia
using Pkg
Pkg.add(["CSV", "DataFrames", "OrderedCollections", "ProgressMeter"])
