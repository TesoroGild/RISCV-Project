# Fichier unique : Routine allocT avec programme de test intégré
# Ce programme alloue un maillon sur le tas, initialise ses champs et affiche l'adresse.

.data
# Définition des chaînes de format dans la section .data
format_term_positive: .asciz "%d"
format_term_negative: .asciz "-%d"
format_x_power: .asciz "x^%d"
format_plus: .asciz "+"

.text
.global main
.global makeP
.global allocT
.global addT
.global printP
.global mulT



# -------------------------
# Routine allocT
# -------------------------
# Description: 
#   Alloue un maillon de 32 octets (taille d'un maillon) sur le tas,
#   initialise les champs du maillon (coefficient, degré, NULL pour prev et next),
#   et retourne l'adresse du maillon dans a0.
# Paramètres d'entrée:
#   a0 : Coefficient du terme
#   a1 : Degré du terme
# Sorties:
#   a0 : Adresse du maillon alloué

allocT:
    # Taille d'un maillon : 32 octets
    li a2, 32               # Taille d'un maillon en octets
    li a7, 9                # Appel système sbrk
    ecall                   # Allouer mémoire sur le tas
    bgez a0, init_maillon   # Si l'allocation a réussi, aller à l'initialisation
    li a0, -1               # Si l'allocation échoue, retourner -1
    ret                     # Retourner

init_maillon:
    # Initialiser le champ coefficient (offset 0)
    sw a0, 0(a0)            # Coefficient stocké à l'adresse de début du maillon
    # Initialiser le champ degré (offset 4)
    sw a1, 4(a0)            # Degré stocké à l'adresse (a0 + 4)
    # Initialiser le champ prev (offset 8)
    li t0, 0                # NULL pour pointeur précédent
    sw t0, 8(a0)
    # Initialiser le champ next (offset 16)
    sw t0, 16(a0)           # NULL pour pointeur suivant
    # Retourner l'adresse du maillon dans a0
    ret
    

# -------------------------
# Routine addT
# -------------------------
# Description: 
#    Insère le maillon (a1) dans la liste à la position correcte selon le degré (ordre décroissant).
# Paramètres d'entrée:
#   a0 : adresse de la tête de la liste (NULL si la liste est vide).
#   a1 : Adresse du maillon à insérer 
# Sortie:
#   a0 : nouvelle adresse de la tête de la liste.

addT:
    beq a0, x0, insert_as_head   # Si la liste est vide (tête NULL), insérer comme tête

find_position:
    # Charger le degré du maillon courant (tête actuelle)
    lw t0, 4(a0)                 # t0 = degré du maillon courant (a0)
    lw t1, 4(a1)                 # t1 = degré du maillon à insérer (a1)
    blt t0, t1, insert_before    # Si t1 > t0, insérer avant le maillon courant
    lw t2, 16(a0)                # Charger l'adresse du maillon suivant
    beq t2, x0, insert_at_end    # Si pas de maillon suivant, insérer en fin
    mv a0, t2                    # Passer au maillon suivant
    j find_position              # Répéter la recherche

insert_as_head:
    sw a0, 16(a1)                # Lien suivant de a1 pointe sur l'ancienne tête
    sw x0, 8(a1)                 # Lien précédent de a1 reste NULL
    beq a0, x0, end_addT         # Si la liste était vide, fin
    sw a1, 8(a0)                 # Lien précédent de l'ancienne tête pointe sur a1
    mv a0, a1                    # Mettre à jour la tête de la liste
    ret

insert_before:
    lw t2, 8(a0)                 # Charger l'adresse du maillon précédent
    sw t2, 8(a1)                 # Lien précédent de a1 pointe sur t2
    sw a0, 16(a1)                # Lien suivant de a1 pointe sur le maillon courant
    beq t2, x0, insert_as_head   # Si t2 est NULL, insérer comme tête
    sw a1, 16(t2)                # Lien suivant de t2 pointe sur a1
    sw a1, 8(a0)                 # Lien précédent du maillon courant pointe sur a1
    ret

insert_at_end:
    sw a0, 8(a1)                 # Lien précédent de a1 pointe sur le dernier maillon
    sw x0, 16(a1)                # Lien suivant de a1 reste NULL
    sw a1, 16(a0)                # Lien suivant du dernier maillon pointe sur a1
    ret

end_addT:
    ret

# -------------------------
# Routine printP
# -------------------------
# Description: 
#   Affiche le polynôme en respectant la notation avec x^n, + et - selon les coefficients et les degrés.
# Paramètre d'entrée:
#   a0 : Adresse du maillon de tête du polynôme
# Sorties :
#   Aucun (affichage du polynôme dans le format attendu).

printP:
    beq a0, x0, end_printP        # Si la liste est vide, rien à afficher.

print_loop:
    lw t0, 0(a0)                 # Charger le coefficient du terme courant.
    lw t1, 4(a0)                 # Charger le degré du terme courant.
    
    # Afficher le signe si nécessaire (pas pour le premier terme positif)
    bge t0, x0, skip_sign        # Si le coefficient est positif, sauter le signe.
    li a7, 11                    # Appeler ecall pour afficher '-'.
    li a0, 45
    ecall
    neg t0, t0                   # Rendre le coefficient positif pour l'affichage.
    
skip_sign:
    # Afficher le coefficient
    li a7, 1                     # Appeler ecall pour afficher un entier.
    mv a0, t0
    ecall

    # Vérifier le degré et afficher la partie x^n si nécessaire
    beq t1, x0, skip_degree      # Si degré == 0, ne pas afficher x^n.

    # Afficher 'x'
    li a7, 11                    # Appeler ecall pour afficher un caractère.
    li a0, 120                   # ASCII de 'x'.
    ecall

    # Si le degré est supérieur à 1, afficher '^' suivi du degré.
    li t2, 1
    bne t1, t2, print_degree
    j skip_degree                # Si degré == 1, ne pas afficher '^'.

print_degree:
    li a0, 94                    # ASCII de '^'.
    ecall

    li a7, 1                     # Appeler ecall pour afficher un entier.
    mv a0, t1
    ecall

skip_degree:
    # Passer au terme suivant
    lw a0, 16(a0)                # Charger l'adresse du maillon suivant.
    beq a0, x0, end_printP       # Si fin de la liste, terminer.

    # Ajouter le signe '+' entre termes si le suivant est positif
    lw t0, 0(a0)                 # Charger le coefficient du prochain terme.
    blez t0, print_loop          # Si coefficient <= 0, continuer sans '+'

    li a7, 11                    # Appeler ecall pour afficher '+'.
    li a0, 43
    ecall

    j print_loop

end_printP:
    # Terminer avec un saut de ligne
    li a7, 11
    li a0, 10                    # ASCII de '\n'.
    ecall
    ret
    
    
# -------------------------
# Routine mulT
# -------------------------
# Description: 
#   Parcourt la liste et multiplie le coefficient du terme ayant le degré spécifié par a2.
# Paramètres d'entrée:
#   a0 : Adresse du maillon de tête du polynôme
#   a1 : Degré du terme à multiplier
#   a2 : Valeur de multiplication du coefficient.
# Résultat:
#   a0 : 0 si la modification a réussi.
#        -1 si aucun terme avec le degré spécifié n'existe.

mulT:
    beq a0, x0, mulT_not_found   # Si la liste est vide, le terme n'existe pas.

mulT_loop:
    lw t0, 4(a0)                # Charger le degré du maillon courant.
    beq t0, a1, mulT_found      # Si le degré correspond, passer à la modification.
    
    lw a0, 16(a0)               # Charger l'adresse du maillon suivant.
    beq a0, x0, mulT_not_found  # Si fin de la liste, le terme n'a pas été trouvé.
    j mulT_loop                 # Continuer à parcourir la liste.

mulT_found:
    lw t1, 0(a0)                # Charger le coefficient du maillon courant.
    mul t1, t1, a2              # Multiplier le coefficient par la constante a2.
    sw t1, 0(a0)                # Sauvegarder le nouveau coefficient dans le maillon.
    li a0, 0                    # Retourner 0 pour indiquer le succès.
    ret

mulT_not_found:
    li a0, -1                   # Retourner -1 pour indiquer que le terme n'a pas été trouvé.
    ret
    
    
# -------------------------
# Routine makeP
# -------------------------
# Description:
#   Crée une liste doublement chaînée représentant un polynôme.
#   Utilise les routines `allocT` et `addT` pour créer et ajouter des termes.
#   La saisie se termine lorsque l'utilisateur entre un degré négatif.
# Paramètres d'entrée:
#   Aucun paramètre d'entrée (valeurs saisies par l'utilisateur via syscall).
# Résultat:
#   a0 : Adresse du maillon de tête du polynôme ou x0 si aucun terme n'est saisi.

makeP:
    li a0, 0                # Initialiser l'adresse de la tête de liste à NULL (x0)
    mv s0, a0               # Sauvegarder la tête de liste dans s0

makeP_loop:
    # Lire le coefficient
    li a7, 5                # Syscall pour lire un entier (read_int)
    ecall
    mv t0, a0               # Sauvegarder le coefficient dans t0

    # Lire le degré
    li a7, 5                # Syscall pour lire un entier (read_int)
    ecall
    mv t1, a0               # Sauvegarder le degré dans t1

    # Vérifier si le degré est négatif
    blt t1, x0, makeP_end   # Si degré < 0, sortir de la boucle.

    # Allouer un nouveau maillon
    mv a0, t0               # Charger le coefficient dans a0
    mv a1, t1               # Charger le degré dans a1
    call allocT             # Appeler la routine allocT
    mv t2, a0               # Sauvegarder l'adresse du nouveau maillon dans t2

    # Ajouter le nouveau maillon à la liste
    mv a0, s0               # Charger l'adresse de la tête dans a0
    mv a1, t2               # Charger l'adresse du nouveau maillon dans a1
    call addT               # Appeler la routine addT
    mv s0, a0               # Mettre à jour la tête de liste

    j makeP_loop            # Retourner pour saisir le prochain terme.

makeP_end:
    mv a0, s0               # Retourner l'adresse de la tête de liste.
    ret
    
    
# -------------------------
# Routine testMain (main)
# -------------------------
# Description :
#   Routine principale pour tester les fonctionnalités de la bibliothèque :
#   - Créer un polynôme avec makeP
#   - Afficher le polynôme avec printP
#   - Multiplier un terme du polynôme avec mulT
#   - Afficher à nouveau le polynôme après modification

main:
    # Étape 1 : Créer un polynôme
    call makeP                # Créer un polynôme
    mv s0, a0                 # Sauvegarder la tête du polynôme dans s0

    # Étape 2 : Afficher le polynôme créé
    mv a0, s0                 # Charger l'adresse de la tête dans a0
    call printP               # Afficher le polynôme initial

    # Étape 3 : Multiplier un terme du polynôme
    li a1, 6                  # Terme de degré 6 (exemple)
    li a2, 10                 # Multiplication du coefficient par 10
    mv a0, s0                 # Charger l'adresse de la tête dans a0
    call mulT                 # Multiplier le terme
    bne a0, x0, mulT_success  # Vérifier si la multiplication a réussi
    li a7, 4                  # Syscall pour afficher une chaîne (print_str)
    la a0, errorMsg           # Charger le message d'erreur
    ecall
    j testMain_end

mulT_success:
    # Étape 4 : Afficher le polynôme après modification
    mv a0, s0                 # Charger l'adresse de la tête dans a0
    call printP               # Afficher le polynôme modifié

testMain_end:
    ret                       # Terminer la routine principale

# Message d'erreur si la multiplication échoue
errorMsg: .asciiz "Erreur : Terme non trouvé pour la multiplication.\n"
