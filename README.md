# Métaheuristiques pour le Problème d'Affectation Généralisé (GAP)

Ce projet implémente diverses heuristiques et métaheuristiques pour résoudre le **Problème d'Affectation Généralisé (GAP)**. L'objectif est d'affecter des tâches à des agents tout en minimisant les coûts ou en maximisant les bénéfices, en respectant les contraintes de ressource de chaque agent.

## 📂 Structure des Fichiers

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
  


## 🚀 Dépendances

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
```


## 📖 Instructions d'Utilisation

1. **Préparation des Instances** Placez vos instances de problème GAP dans le dossier `instances/` avec des noms de fichiers sous le format `gap<i>.txt` (par exemple, `gap1.txt`, `gap2.txt`).
 
2. **Exécution du Programme** Le point d'entrée du programme est la fonction `main()` qui exécute l'ensemble du processus. Voici un résumé des étapes :
    - Lecture des instances : Les instances de problèmes sont lues à partir de fichiers avec `readfile()`.
    - Multi-Démarrage : Plusieurs solutions initiales sont générées pour chaque instance à l'aide de différentes heuristiques.
    - Amélioration des solutions initiales : Pour chaque solution initiale, des métaheuristiques comme la descente de voisinage variable et la recherche tabou sont utilisées pour améliorer la solution.
    - Évaluation des solutions : À chaque itération, la qualité de la solution (coût final, écart par rapport à l'optimum) est calculée et stockée.
    - Sauvegarde des résultats : Les résultats finaux (meilleure solution, écart par rapport à l'optimum, méthode utilisée) sont sauvegardés dans un fichier CSV.
  
3. **Résultats**
Les résultats sont enregistrés dans le dossier `results/` sous forme de fichiers CSV, contenant des informations telles que :
    - Instance : Le nom de l'instance.
    - Best value : La meilleure valeur trouvée.
    - Best gap : L'écart entre la solution trouvée et l'optimum.
    - Best method : La méthode heuristique utilisée pour obtenir la meilleure solution.
    - Opt : La valeur optimale (si elle est donnée).

  
## 📜 Format des Fichiers d'Instance
Chaque fichier d'instance (par exemple, gap1.txt) doit contenir :
- Les ressources disponibles pour chaque agent.
- Les exigences en ressources des tâches.
- Les coûts d'affectation des tâches aux agents.


## ⚙️ Paramètres Personnalisables
Vous pouvez ajuster plusieurs paramètres dans le fichier `main.jl` pour tester différentes configurations :

- `tabu_len` : Longueur de la liste tabou (par défaut : 50).
- `max_iterations` : Nombre maximal d'itérations (par défaut : 1000).
- Temps limite : Temps maximal pour chaque instance (par défaut : 2 minutes).

