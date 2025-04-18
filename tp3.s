# Fichier unique : Routine allocT avec programme de test intégré
# Ce programme alloue un maillon sur le tas, initialise ses champs et affiche l'adresse.

.data 
inputBuffer: .space 500

.text
.global main
.global makeP
.global allocT
.global addT
.global printP
.global mulT

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
    # Etape 1 : Créer un polynôme
    call makeP                
    
    mv s0, a5                 # Sauvegarder la tête du polynôme dans s0
    mv a1, s0                 # Charger l'adresse de la tête dans a0
    
    # Étape 2 : Afficher le polynôme créé
    call printP               # Afficher le polynôme initial            # Attribuer a t6 l'adresse dans a0
    
    mv a1, s0                 # Charger l'adresse de la tête dans a0
    mv a2, s9
    mv a3, s10
    
    # Étape 3 : Multiplier un terme du polynôme
    call mulT                 # Multiplier le terme
    beqz a0, mulT_success  # Vérifier si la multiplication a réussi
    li a0, '0'                  # Afficher 0
    li a7, 11            
    ecall
    j fin

mulT_success:
    # Étape 4 : Afficher le polynôme après modification
    mv a1, s0                 # Charger l'adresse de la tête dans a0
    call printP               # Afficher le polynôme modifié
    j fin                     # Terminer la routine principale
    

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
#   s3 : Adresse du maillon de tête du polynôme ou x0 si aucun terme n'est saisi.
makeP:
    addi sp, sp, -4    # Réduire le pointeur de pile pour faire de la place
    sw ra, 0(sp)       # Sauvegarder `t1` dans la pile
    li a3, 0                # Pointeur de maillons
    li a4, 0                # Tampon de maillons
    li a5, 0                # Adresse de la tete
    li t0, 0                # Conpteur 1er chiffre
    li t5, 0                # Compteur pour identifier le 1er maillon
    li s1, 0                # Variable degre
    li s0, 0                # Variable coefficient
    li s4, 0                # Valeur negative
    li t4, 1                # Multiplicateur
    li s8, 0                # fin
    li s9, -1
    li s10, 0
    
new_buffer:
    la a0, inputBuffer              # Adresse du tampon
    li a1, 100                  # Taille maximale du tampon
    li a7, 8                    # Syscall pour lire une chaîne
    ecall
    mv t6, a0               # Attribuer a t6 l'adresse dans a0
next_deg:
saisir_deg:
    lb t2, 0(t6)                # Lire le mot
    li t3, -1
    beq t2, t3, fin                 # Si caractère NULL ('\0'), fin de la chaîne
    li t3, '\n'
    beq t2, t3, move_back_pointer_1    # Vérifier fin du nombre
    li t3, '-'
    beq t2, t3, deg_and_const       # Saisi degres et constantes
    li t3, 48
    blt t2, t3, fin             # Si le caractère est un non-chiffre, sortir (caractère de fin de nombre)
    li t3, 57
    bgt t2, t3, fin             # Si ce n'est pas un chiffre (>= '0' et <= '9'), sortir
    li t3, 48
    sub t2, t2, t3          # Changer la valeur ASCII en entier
    beqz t0, deg_first_num      # Si 1er nombre, on ne multipli pas par 10
    li t3, 10
    mul t4, t4, t3          # t4 = t4 * 10
    j add_deg_num
deg_first_num:
    addi t4, t4, -1
add_deg_num:
    add t4, t4, t2          # Ajouter le chiffre des unites
    addi t0, t0, 1          # Incrementer le compteur
    addi t6, t6, 1          # Avancer le tampon
    j saisir_deg
   
move_back_pointer_1:
    bnez s8, saisir_const
    addi t6, t6, -1         # Sauter les caracteres pour lire le chiffre du degre
    mv s1, t4
    li t4, 1
    sub t6, t6, t0 
    li t0, 0
    li a1, 100                  # Taille maximale du tampon
    li a7, 8                    # Syscall pour lire une chaîne (8)
    ecall
    j next_coef             # On va lire le coefficient
    
move_back_pointer_2:
    addi t6, t6, -1            # Sauter les caracteres pour lire le chiffre du coefficient
    mv s0, t4
    li t4, 1
    sub t6, t6, t0 
    li t0, 0
    call allocT             # Paasse a l'allocation
    call addT
    li s1, 0
    li s0, 0        
    j new_buffer
    
next_coef:
    addi t6, t6, 1
saisir_coef:
    lb t2, 0(t6)                # Charger un octet (caractère) à la position actuelle
    li t3, -1
    beq t2, t3, end_of_input        # Vérifier fin du nombre
    li t3, '\n'
    beq t2, t3, is_positive_or_negative     # Vérifier fin du nombre 
    li t3, '-'
    beq t2, t3, set_neg_true        # Vérifier fin du nombre 
    li t3, 48
    blt t2, t3, fin             # Si le caractère est un non-chiffre, sortir (caractère de fin de nombre)
    li t3, 57
    bgt t2, t3, fin             # Si ce n'est pas un chiffre (>= '0' et <= '9'), sortir
    li t3, 48
    sub t2, t2, t3          # Changer la valeur ASCII en entier
    beqz t0, coef_first_num
    li t3, 10
    mul t4, t4, t3
    j add_coef_num
coef_first_num:
    addi t4, t4, -1
add_coef_num:
    add t4, t4, t2
    addi t0, t0, 1
do_nothing:             # Passser au prochain caractere sans traitement         
    addi t6, t6, 1
    j saisir_coef

is_positive_or_negative:
    li s7, -1
    bne s9, s7, end_of_input
    beqz s4, move_back_pointer_2
    sub t4, zero, t4
    li s4, 0
    j move_back_pointer_2

set_neg_true:
    li s4, 1
    j do_nothing

deg_and_const:
    lw ra, 0(sp)       # Adresse de retour du main
    addi sp, sp, 4
    bnez s8, fin       # Pas de degres negatifs
    # Initialiser le dregre et la constante
    li t0, 0
    li s8, 1
    li s9, -1
    li s10, 0
d_and_c:
    la a0, inputBuffer              # Adresse du tampon
    li a1, 100                  # Taille maximale du tampon
    li a7, 8                    # Syscall pour lire une chaîne
    ecall
    mv t6, a0   
    li a1, -1
    beq s9, a1 saisir_deg         # Attribuer a t6 l'adresse dans a0
    li t0, 0
    li t4, 1
    j saisir_coef
saisir_const:
    mv s9, t4
    j d_and_c
end_of_input:
    beqz s4, return_makeP
    sub t4, zero, t4
    li s4, 0
return_makeP:
    mv s10, t4
    ret

fin:
    li a7, 10                   # Terminer le programme
    ecall


# -------------------------
# Routine allocT
# -------------------------
# Description: 
#   Alloue un maillon de 32 octets (taille d'un maillon) sur le tas,
#   initialise les champs du maillon (coefficient, degré, NULL pour prev et next),
#   et retourne l'adresse du maillon dans a0.
# Paramètres d'entrée:
#   s1 : Coefficient du terme
#   s0 : Degré du terme
# Sorties:
#   s2 : Adresse du maillon alloué
allocT:
    # Taille d'un maillon : 2 mots + 2 ponteurs = 24 octets
    li a7, 9                    # Appel système sbrk
    li a0, 24
    ecall                           # Allouer mémoire sur le tas   
    mv s2, a0
    # Résultat de l'allocation est dans a0, l'adresse du maillon
    # Initialisation du maillon
    sw s0, 0(s2)                # Coefficient : stocke le coefficient (s0)
    sw s1, 4(s2)                # Degré : stocke le degré (s1)
    sw t0, 8(s2)                # Pointeur prev = NULL
    sw t0, 16(s2)               # Pointeur next = NULL
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
    # PREV = 8
    # NEXT = 16
    # addi s3, a3 adresse du nouveau maillon
    # s5 et s6 tampons interchangeables pour parcourir les maillons
    beqz t5, start_list
    # Parcourir la liste pour trouver l'emplacement correct
browse_channel:
    lw t1, 4(s2)        # Charger le degré du nouveau maillon
    lw t2, 4(a5)            # Charger le degré du maillon actuel (tête)
    bgt t2, t1, next_head       # Si l'actuel est plus grand que le nouveau, passer au suivant
    # Inserer a la tete de la liste
    sw s2, 8(s3)        # Mettre l'adresse du nouveau dans le PREV de l'acienne tete
    addi s3, s3, 24
    sw a5, 16(s3)           # Mettre l'adresse de l'ancienne tete dans le NEXT du nouveau
    mv, a5, s2
    j end_addT
    
next_head:          # Verifier la valeur
    lw t3, 16(a5)       # Recuperer l'adresse dans NEXT
    beqz t3, insert_after_first
    lb t2, 4(t3)        # Recuperer la valeur a cette adressse
    bgt t2, t1, next        # Si le maillon NEXT plus grand, continuer le parcours
    # Sinon, s'il a un PREV
    # Soit V1 V2 les 2 maillons et V3 qu'on veut ajouter au milieu
    sw s2, 8(t3)        # V2->PREV = adresse V3
    addi s3, s3, 24
    sw t3, 16(s3)       # V3->NEXT = adresse V2
    sw a5, 8(s3)        # V3->PREV = adresse V1
    sw s2, 16(a5)       # V1->NEXT = adresse V3
    j end_addT
    
next:
    lw s5, 16(t3)
    beqz s5, insert_end
    lb t2, 4(s5)        # Recuperer la valeur a cette adressse
    mv t3, s5
    bgt t2, t1, next
    lw t2, 8(t3)
    sw s2, 8(t3)
    addi s3, s3, 24
    sw t3, 16(s3)       # V3->NEXT = adresse V2
    sw t2, 8(s3)        # V3->PREV = adresse V1
    sw s2, 16(t2)       # V1->NEXT = adresse V3
    j end_addT
    
insert_after_first:
    sw s2, 16(s3)       # Modifier le NEXT de precedent avec l'adresse actuelle
    addi s3, s3, 24
    sw a5, 8(s3)        # Modifier le PREV actuel avec l'adresse de la tete
    j end_addT
    
insert_end:
    sw s2, 16(t3)       # Modifier le NEXT de precedent avec l'adresse actuelle
    # Recuperer le precedent lans le NEXt du PREV
    lw s5, 8(t3)
    lw s6, 16(s5)
    addi s3, s3, 24
    sw s6, 8(s3)        # Modifier le PREV actuel avec l'adresse du precedent
    j end_addT
    
start_list:
    li t5, 1
    mv s3, s2
    mv a5, s2
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
    beq a1, x0, end_printP        # Si la liste est vide, rien à afficher.

print_loop:
    lw t0, 0(a1)                 # Charger le coefficient du terme courant.
    lw t1, 4(a1)                 # Charger le degré du terme courant.
    # Afficher le signe si nécessaire (pas pour le premier terme positif)
    li t3, 0
    bge t0, t3, skip_sign        # Si le coefficient est positif, sauter le signe.
    li a7, 11                    # Appeler ecall pour afficher '-'.
    li a0, 45
    ecall
    neg t0, t0                   # Rendre le coefficient positif pour l'affichage.
    
skip_sign:
    li s7, 1
    beq t0, s7, skip_one
    # Afficher le coefficient
    li a7, 1                     # Appeler ecall pour afficher un entier.
    mv a0, t0
    ecall
    # Vérifier le degré et afficher la partie x^n si nécessaire
    beq t1, x0, skip_degree      # Si degré == 0, ne pas afficher x^n.
skip_one:
    beqz t1, print_1
    # Afficher 'x'
    li a7, 11                    # Appeler ecall pour afficher un caractère.
    li a0, 120                   # ASCII de 'x'.
    ecall
    # Si le degré est supérieur à 1, afficher '^' suivi du degré.
    li t2, 1
    bne t1, t2, print_degree
    j skip_degree                # Si degré == 1, ne pas afficher '^'.

print_1:
    li a7, 11                    # Appeler ecall pour afficher un caractère.
    li a0, 49                   # ASCII de 'x'.
    ecall
    j skip_degree

print_degree:
    li a0, 94                    # ASCII de '^'.
    ecall
    li a7, 1                     # Appeler ecall pour afficher un entier.
    mv a0, t1
    ecall

skip_degree:
    # Passer au terme suivant
    lw a1, 16(a1)                # Charger l'adresse du maillon suivant.
    beq a1, x0, end_printP       # Si fin de la liste, terminer.
    # Ajouter le signe '+' entre termes si le suivant est positif
    lw t0, 0(a1)                 # Charger le coefficient du prochain terme.
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
    beq a1, x0, mulT_not_found   # Si la liste est vide, le terme n'existe pas.

mulT_loop:
    lw t1, 4(a1)                # Charger le degré du maillon courant.
    beq t1, a2, mulT_found      # Si le degré correspond, passer à la modification.
    
    lw a1, 16(a1)               # Charger l'adresse du maillon suivant.
    beq a1, x0, mulT_not_found  # Si fin de la liste, le terme n'a pas été trouvé.
    j mulT_loop                 # Continuer à parcourir la liste.

mulT_found:
    # Charger le coefficient du maillon courant
    lw t4, 0(a1)                # Charger le coefficient dans t4 (valeur initiale).
    # Vérification si le coefficient est négatif
    bltz t4, coeff_neg          # Si coefficient (t4) < 0, branche vers 'coeff_neg'.
    # Vérification si la constante est négative
    bltz a3, const_neg          # Si constante (a3) < 0, branche vers 'const_neg'.
    # Multiplier normalement si les deux sont positifs
    mul t4, t4, a3              # Multiplier le coefficient par la constante.
    j mulT_store                # Passer au stockage.

coeff_neg:
    # Débogage : Le coefficient est négatif
    # Pas besoin de manipulation supplémentaire, la multiplication gère les signes.
    sub t4, zero, t4
    mul t4, t4, a3              # Multiplier le coefficient par la constante.
    j mulT_store                # Passer au stockage.

const_neg:
    # Débogage : La constante est négative
    mul t4, t4, a3              # Multiplier le coefficient par la constante.

mulT_store:
    sw t4, 0(a1)                # Sauvegarder le nouveau coefficient dans le maillon.
    li a0, 0                    # Retourner 0 pour indiquer le succès.
    ret

mulT_not_found:
    li a0, -1                   # Retourner -1 pour indiquer que le terme n'a pas été trouvé.
    ret
