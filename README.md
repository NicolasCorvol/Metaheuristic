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


## Fonctionnement Principal

La fonction principale `main()` exécute l'ensemble du processus. Voici un résumé des étapes :

1. **Lecture des instances** : Les instances de problèmes sont lues à partir de fichiers avec `readfile()`.
2. **Multi-Démarrage** : Plusieurs solutions initiales sont générées pour chaque instance à l'aide de différentes heuristiques.
3. **Amélioration des solutions initiales** : Pour chaque solution initiale, des métaheuristiques comme la descente de voisinage variable et la recherche tabou sont utilisées pour améliorer la solution.
4. **Évaluation des solutions** : À chaque itération, la qualité de la solution (coût final, écart par rapport à l'optimum) est calculée et stockée.
5. **Sauvegarde des résultats** : Les résultats finaux (meilleure solution, écart par rapport à l'optimum, méthode utilisée) sont sauvegardés dans un fichier CSV.

