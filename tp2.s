.data
# Tampon pour le texte
texte:      .space   300
            .eqv     txtLen, 300   # Taille du tampon

# Tableau pour les mots
tabMots:    .space   1800
            .eqv     tabLen, 1800   # Taille du tableau de mots

# Message d'erreur            
erreur_tampon: .asciz "Erreur : Tampon plein\n"

# Structure pour les mots
# Chaque mot contient l'adresse (8 octets) et sa longueur (4 octets)
.word_len:  .space   4                # Longueur d'un mot
.word_ptr:  .space   8                # Pointeur vers le mot

.text
.globl main

main:
    li t0, 0
    # Saisir le texte
    jal saisir
    
    # Vérifier si le tampon est plein
    li t0, -1                   # Charger -1 dans t0
    beq a0, t0, tampon_plein    # Comparer avec la valeur dans t0

    # Découper les mots
    mv a1, a0                  # Taille du texte saisi
    jal decMots

    # Afficher le tableau de mots non trié
    jal afficher

    # Trier les mots
    jal trier

    # Afficher le tableau de mots trié
    jal afficher

    # Terminer le programme
    li a7, 10                  # Appel système pour sortir
    ecall

tampon_plein:
    # Message d'erreur pour tampon plein
    li a7, 4                   # Appel système pour écrire
    la a0, erreur_tampon       # Adresse du message d'erreur
    ecall
    li a7, 10                  # Appel système pour exit
    ecall

###################
#      SAISIR     #
###################
saisir:
    li t0, 0                   # Compteur du tampon
    li t1, txtLen              # Longueur maximale
    la t2, texte               # Adresse du tampon
    li t6, 0                   # Compteur du mots

saisir_loop:
    li a7, 12            # Appel système pour lire un caractère
    ecall
    li t3, -1
    beq a0, t3, end_of_text    # Vérifier EOF
    sb a0, 0(t2)               # Sauvegarder le caractère dans le tampon
    addi t2, t2, 1             # Avancer l'adresse du tampon
    addi t0, t0, 1             # Incrémenter le compteur
    bge t0, t1, overflow       # Vérifier si le tampon est plein
    j saisir_loop

end_of_text:
    sb t3, 0(t2)
    addi t2, t2, 1             # Avancer l'adresse du tampon
    mv a0, t0
    ret

overflow:
    li a0, -1                  # Retourner -1 pour débordement
    ret

###################
#     DECMOTS     #
###################
decMots:
    # Entrée : taille du texte dans a1
    mv t0, a0                   # Taille du texte
    la t1, tabMots              # Adresse du tableau de mots
    la t2, texte                # Adresse du tampon
    li t6, 0                    # Longueur du mot                   
    mv a2, ra
    mv t5, t2
    li a3, 0            # Compteur de caracteres a skiper
        
decMots_loop:
    lb t4, 0(t2)                # Charger le caractère
    jal isalpha         # Vérifier si le caractère est une lettre
    li t3, 0
    beq a1, t3, is_next_or_end  # Si ce n'est pas une lettre, sauter
    sw t5, 0(t1)
    addi t6, t6, 1              # Incrémenter le compteur du mot
    addi t2, t2, 1      # Avancer dans le tampon
    j decMots_loop              # Recommencer à lire le mot

next_word:
    addi t2, t2, 1      # Avancer dans le tampon
    lb t4, 0(t2)                # Charger le caractère
    li t3, '\n'
    beq t4, t3, skip_adress # Verifier un espace suivi d'un saut de ligne
    li t3, 1
    sub t2, t2, t3
    # Sauvegarder le mot et sa longueur dans le tableau de mots
next_char:
    add t5, t5, t6
    addi t5, t5, 1
    sw t6, 4(t1)                # Longueur du mot
    li t3, 0
    ble t6,t3, next     # Si ce n'est pas un mot, le tableau de mots ne bouge pas
    addi t1, t1, 12             # Avancer dans le tableau de mots
next:
    addi t2, t2, 1      # Avancer dans le tampon
    li t6, 0            # Reinitialiser le compteur du mot
    j decMots_loop              # Recommencer

skip_adress:
    addi t5, t5, 1      # Avancer dans le tampon
    j next_char
    
skip_char:
    addi t5, t5, 1
    addi t2, t2, 1
    lb t4, 0(t2)                # Charger le caractère
    jal isalpha
    li t3, 0
    beq a1, t3 is_next_or_end           # Avancer dans le tableau de mots
    li t3, 1
    sub t2, t2, t3
    sub t5, t5, t3
    j next_word

is_next_or_end:
    li t3, ' '
    beq t4, t3, next_word   # Passer au mot suivant
    li t3, '\n'
    beq t4, t3, next_char
    li t3, -1
    beq t4, t3 end_decMots
    j skip_char
    
end_decMots:
    add t5, t5, t6
    addi t5, t5, 1
    sw t6, 4(t1)                # Longueur du mot
    sw t3, 0(t1)                # Terminer le tableau avec -1
    mv ra, a2
    ret

###################
#     ISALPHA     #
###################
isalpha:
    # Vérifier si le caractère est une lettre majuscule (A-Z)
    li t3, 'A'
    blt t4, t3, invalid_char
    li t3, 'Z'
    ble t4, t3 valid_char
    li t3, 'z'
    bgt t4, t3, invalid_char    # Vérifier si le caractère est une lettre minuscule (a-z) 
    li t3, 'a'
    bge t4, t3 valid_char
    j invalid_char

valid_char:
    li a1, 1
    ret
    
invalid_char: 
    li a1, 0
    ret

###################
#     AFFICHER    #
###################
afficher:
    la t0, tabMots              # Adresse du tableau de mots
    li t6, 0                    # Compteur de mots
    li t1, 0

new_word:
    lw t2, 0(t0)                # Charger l'adresse du mot
    lw t3, 4(t0)                # Charger la longueur du mot
    li, t4, 4 
    beq t6, t4, new_line    # Afficher le mot a la ligne
    
display_next_char:
    bge t1, t3, end_word
    lb t5, 0(t2)
    mv a0, t5                   # Adresse du mot
    li a7, 11
    ecall
    addi t2, t2, 1              # Passer a l'adresse suivante
    addi t1, t1, 1      # Incrementer la longueur de mots
    j display_next_char

end_word:
    addi t0, t0, 12         # Verifier si le dernier caratere est EOF
    lw t2, 0(t0)                # Charger l'adresse du mot
    li a0, -1
    beq t2, a0 end_afficher
    addi t6, t6, 1
    li, t4, 4 
    beq t6, t4, reset_count    # Afficher le mot a la ligne
    li a0, ' '
    li a7, 11
    ecall
reset_count:
    li t1, 0
    j new_word
    
new_line:
    # Afficher un saut de ligne
    li a0, 10                   # Code ASCII pour le saut de ligne
    ecall
    li t6, 0                    # Incrementer le nombre d'affichage
    j display_next_char             # Recommencer

end_afficher:
    ret

###################
#      TRIER      #
###################
trier:
    la t0, tabMots              # Adresse du tableau de mots
    li t1, 0                    # Compteur de mots
    li s0, 0            # Nombre de switch effectues
    li s1, 0
    li s2, 0
    
set_address_number:
    li, s1, 0
    lw t2, 0(t0)                # Adresse du mot
    li t4, -1
    beq t2, t4, end_count       # Fin du tableau si l'adresse est zéro
    lw t3, 4(t0)                # Longueur du mot
    addi t1, t1, 1              # Incrémenter le compteur de mots
    addi t0, t0, 12             # Passer au mot suivant
    lw t5, 0(t0)
    beq t5, t4, end_count       # Fin du tableau si l'adresse est zéro
    lw t6, 4(t0)                # Longueur du mot
    addi t1, t1, 1              # Incrémenter le compteur de mots
    li t4, 2
    li a4, 0
    beq t1, t4 strCmp
    j set_address_number                # Recommencer

end_count:
    bne s0, zero restart_sort
    li a0, 10
    li a7, 11
    ecall
    li a0, 10
    li a7, 11
    ecall
    ret
    
restart_sort:
    j trier

###################
#     STRCMP     #
###################
strCmp:
    # a0 : premier mot, a1 : second mot
    lb a2, 0(t2)               # Charger le caractère de var1
    lb a3, 0(t5)               # Charger le nombre de caractère dans var1
    bgt a2, a3 switch
    blt a2, a3, do_nothing
    addi a4, a4, 1
    bge a4, t3, first_greater
    bge a4, t6, do_nothing
    addi s1, s1, 1
    addi t2, t2, 1
    addi t5, t5, 1
    j strCmp

switch:
    li a5, 1
    mv a6, t2
    mv t2, t5
    mv t5, a6
    mv a6, t3
    mv t3, t6
    mv t6, a6
    addi s0, s0, 1
# Mettre les informations de var 2 dans var 1
    sub t2, t2, s1
    sub t5, t5, s1
    li a7, 12
    sub t0, t0, a7              # Revenir au mot precedent
    sw t2, 0(t0)
    sw t3, 4(t0)
    addi t0, t0, 12             # Passer au mot suivant
    sw t5, 0(t0)
    sw t6, 4(t0)
    li t1, 0
    j set_address_number

do_nothing:
    sub t2, t2, s1
    sub t5, t5, s1
    li t1, 0
    li a5, -1
    j set_address_number

first_greater:
    bne a4, t6 do_nothing
    sub t2, t2, s1
    sub t5, t5, s1
    li t1, 0
    li a5, 0
    j set_address_number
