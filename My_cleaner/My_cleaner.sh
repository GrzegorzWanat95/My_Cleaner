#!/bin/bash

function Koniec(){
echo "Zakończono działanie programu MyCleaner."
exit
}

function ROOT(){
if [[ $(id -u) -ne 0 ]] ; then
echo "Nie masz koniecznych uprawnień. Zaloguj się jako ROOT i ponownie uruchom program."
Koniec
fi
}

function Czy_istnieje(){ #Funkcja pomocnicza sprawdzająca czy katalog istnieje
if [ ! -d "$sciezka" ]; then
echo "Podany katalog nie istnieje. naciśnij ENTER by wrócic do menu."
read
Main
fi
}

function Swiadoma_zgoda(){ #Funkcja pomocnicza - potwierdzenie chęci skasowania plików.
echo "Czy jesteś pewien, że chcesz skasować te pliki? [y] tak / [n] nie."
read wybor
if [ $wybor != 'y' ]; then
echo "Naciśnij ENTER aby zamknąć program"
read 
clear
Koniec
fi
}

function Szybkie_Skanowanie(){ #Skanowanie katalogu pod kątem zawartości i wagi plików.
clear
#Sprawdzenie, czy katalog istnieje. 
Czy_istnieje $sciezka
#Katalog istnieje. Przygotowanie ścieżki katalogu do skanowania.
skanowany=$(echo ${sciezka##*/})
sciezka_2=$(echo "$sciezka" | sed -e "s/$skanowany$//")
slash=$(echo "${sciezka_2%?}")
cd $slash
#Skanowanie katalogu pod kątem zajmowanej pamięci. 
dane=$(du -s -h $skanowany) 
pamiec=$(echo $dane | cut -d ' ' -f1)
cd
echo "Zajęta pamięć przez katalog: " $pamiec 
#Wypisanie ile plikow znajduje się w katalogu.
cd $sciezka
ile_kat=$(ls -lR | grep "^d" | wc -l)
cd $slash
ile_plikow=$(find $skanowany -type f | wc -l)
ile_katalog=$(expr $ile_plikow + $ile_kat)
echo "W katalogu znajduje się " ${ile_katalog} "plikow zawierających:"
cd $sciezka
#Wypisanie ile miejsca zajmują pliki o danym rozszerzeniu.
ftypes=$(find . -type f | grep -E ".*\.[a-zA-Z0-9]*$" | sed -e 's/.*\(\.[a-zA-Z0-9]*\)$/\1/' | sort | uniq)
for ft in $ftypes
do
    echo -ne "$ft\t"
    find . -name "*${ft}" -exec du -bcsh '{}' + | tail -1 | sed 's/\stotal//'
done
echo 
echo "Wybierz odpowiednią opcję:" #Menu wyboru dalszego działania. 
echo "1. Skasuj wszystkie pliki."
echo "2. Skasuj pliki o wybranym formacie."
echo "3. Wroc do menu."
echo "4. Zamknij program."
read przycisk
case "$przycisk" in 
#Kasowanie wszystkich plików
1) clear
Swiadoma_zgoda
rm -r -f $HOME/$sciezka/*
#Wyświetlenie efektów i koniec funkcji.
echo "Skasowano " $ile_katalog "plikow."
echo "Zwolniono " $pamiec "miejsca. Naciśnij ENTER aby zamknąć program."
read
clear
Koniec ;;
#Sprawdzenie czy uzytkownik nie wprowadził pustej zmiennej.
2) clear 
echo "Pliki o jakim rozszerzeniu chcesz usunąć? Wprowadź typ np. .txt"
read rozszerzenie
if [ -z $rozszerzenie ]; then
echo "Nie wprowadzono rozszerzenia - naciśnij Enter aby zamknąć."
read
Koniec
fi 
#Sprawdzenie czy zmienna istnieje w katalogu/czy użytkownik nie zrobił literówki w rozszerzeniu.
ftypes=$(find . -type f | grep -E ".*\.[a-zA-Z0-9]*$" | sed -e 's/.*\(\.[a-zA-Z0-9]*\)$/\1/' | sort | uniq)
for ft in $ftypes
do
test=$(echo -ne "$ft\t")
if [ $rozszerzenie == $test];
then 
#Skierowanie do funkcji kasującej.
Kasowanie_format $slash $sciezka $rozszerzenie
fi
done
echo "Podany format nie istnieje. Naciśnij ENTER aby zamknąć program."
read
Koniec ;;
#Powrot do menu.
3) clear
Main;;
#Zamkniecie programu.
4) clear
Koniec ;;
#Błędnie wprowadzona wartość. 
*) clear
Main ;;
esac
}

#Kasowanie plikow o wybranym przez uzytkownika formacie.
function Kasowanie_format(){
cd
Swiadoma_zgoda
cd $slash
skasowano=$(find -type f -name *$rozszerzenie | wc -l)
zwolniono=$({ find $sciezka -type f -name *$rozszerzenie -printf "%s+"; echo 0; } | bc | numfmt --to=si)
rm -r -f $HOME/$sciezka/*$rozszerzenie
#Wyswietlenie efektow i koniec funkcji.
echo "Skasowano " $skasowano "plikow."
echo "Zwolniono " $zwolniono "miejsca". 
echo "Naciśnij Enter aby zamknąć program."
read
clear
Koniec 
}

function Kosz_Pobrane(){ #Usuwanie plikow z kosza i Pobranych.
cd .local/share/Trash/files
#Wypisanie ile plikow znajduje się w koszu.
ile_kosz=$(ls -lR | grep "^d" | wc -l) #Zliczenie plików w katalogu.
cd
cd .local/share/Trash 
#Skanowanie kosza pod kątem zajmowanej pamięci. 
dane=$(du -s -b  files)
kosz=$(echo $dane | cut -d ' ' -f1) 
cd 
#Wypisanie ile plikow znajduje się w katalogu Pobrane.
cd  Pobrane #Skanowanie Pobranych.
ile_pobrane=$(ls -lR | grep "^d" | wc -l)
#Skanowanie Pobranych pod kątem zajmowanej pamięci. 
cd
dane2=$(du -s -b  Pobrane) 
pobrane=$(echo $dane2 | cut -d ' ' -f1)
#Potwierdzenie usunięcia plikow. 
Swiadoma_zgoda
#Sprawdzenie czy kosz nie jest pusty. 
if [ -z "$(ls -A /$HOME/.local/share/Trash/files)" ]; then 
echo "Kosz jest pusty."
ile_kosz=0
kosz=0
else 
#Skasowanie plikow.
rm -r -f $HOME/.local/share/Trash/files/*
fi
#Sprawdzenie czy katalog Pobrane nie jest pusty. 
if [ -z "$(ls -A /$HOME/Pobrane)" ]; then 
echo "Katalog Pobrane jest pusty."
ile_pobrane=0
pobrane=0
else 
#Skasowanie plikow.
rm -r -f $HOME/Pobrane/*
fi
#Wyswietlenie efektow i koniec funkcji.
suma_plikow=$(expr $ile_kosz + $ile_pobrane)
suma=$(expr $kosz + $pobrane)
czytelnie=$(numfmt --to=si $suma)
echo "Usunięto: " $suma_plikow "plików".
echo "Zwolniono: " $czytelnie "KB miejsca"
echo "Naciśnij ENTER aby zamknąć program"
read
clear
Koniec
} 

function Katalog(){ #Usuwanie plików z kosza i Pobranych.
#Sprawdzenie, czy katalog istnieje. 
Czy_istnieje $sciezka
#Katalog istnieje. #Przygotowanie ścieżki katalogu do skanowania.
skanowany=$(echo ${sciezka##*/})
sciezka_2=$(echo "$sciezka" | sed -e "s/$skanowany$//")
slash=$(echo "${sciezka_2%?}")
cd $slash
#Skanowanie katalogu pod kątem zajmowanej pamięci. 
dane=$(du -s -h $skanowany) 
pamiec=$(echo $dane | cut -d ' ' -f1)
cd
echo "Zajęta pamięć przez katalog: " $pamiec 
#Wypisanie ile plikow znajduje się w katalogu.
cd $sciezka
ile_kat=$(ls -lR | grep "^d" | wc -l)
cd $slash
ile_plikow=$(find $skanowany -type f | wc -l)
ile_katalog=$(expr $ile_plikow + $ile_kat)
echo "W katalogu znajduje się " ${ile_katalog} "plikow."
#Potwierdzenie usunięcia plikow. 
Swiadoma_zgoda
#Sprawdzenie czy katalog nie jest pusty. 
if [ -z "$(ls -A /$HOME/$sciezka)" ]; then 
echo "Katalog jest pusty."
pamiec=0
else 
#Skasowanie plikow.
rm -r -f $HOME/$sciezka/*
fi
#Wyswietlenie efektów i koniec funkcji.
echo "Usunięto: " ${ile_katalog} "plików".
echo "Zwolniono: " $pamiec "KB miejsca"
echo "Naciśnij ENTER aby zamknąć program"
read
clear
Koniec
} 

function Szukaj_zdublowanych(){
#Przeszukiwanie wszystkich katalogów:
dirname=$HOME
rm -f $HOME/MyCleaner_raport.txt
echo "Zdublowane pliki:" >> $HOME/MyCleaner_raport.txt
find $dirname -type f | sed 's_.*/__' | sort|  uniq -d| 
while read fileName
do
#Porównanie, czy nazwa nie powtarza się w różnych katalogach. Zapis do pliku. 
find $dirname -type f | grep "$fileName" >> $HOME/MyCleaner_raport.txt
done
echo "Wygenerowano raport w katalogu:" $HOME
echo "Naciśnij ENTER aby zamknąć program"
read
clear
Koniec 
}

function Usun_uzytkownika(){ #Funckja usuwająca użytkownika. 
#Sprawdzenie, czy użytkownik posiada odpowiednie uprawnienia. 
#ROOT
#Wypisanie listy użytkowników:
echo "Istniejący użytkownicy w katalogu:"
cat -n /etc/passwd | awk -F: '{print $1}'
#Pobranie od użytkownika nazwy grupy do skasowania.
echo "Wprowadź nazwę użytkownika, którego chcesz usunąć:"
read uzytkownik
#Sprawdzenie, czy wprowadzona nazwa uzytkownika istnieje w katalogu.
if cut -d: -f1 /etc/passwd | grep "$uzytkownik" > /dev/null; then
userdel $uzytkownik #Usunięcie użytkownika. 
echo "Usunięto użytkownika" $uzytkownik ". Naciśnij ENTER aby zamknąć program"
read
clear
Koniec
else
echo "Wprowadzono błędną nazwę użytkownika. Naciśnij ENTER aby zamknąć program"
read
clear
Koniec
fi
}

function Usun_grupe(){ #Funkcja usuwająca grupę.
#Sprawdzenie, czy użytkownik posiada odpowiednie uprawnienia.  
ROOT
#Wypisanie grup.
echo "Istniejące grupy w katalogu:"
cat -n /etc/group | awk -F: '{print $1}'
#Pobranie od użytkownika nazwy grupy do skasowania.
echo "Wprowadź nazwę grupy, którą chcesz usunąć:"
read grupa
#Sprawdzenie, czy wprowadzona nazwa istnieje w katalogu.
if cut -d: -f1 /etc/group | grep "$grupa" > /dev/null; then
groupdel $grupa #Usunięcie grupy.
echo "Usunięto grupę" $grupa ". Naciśnij ENTER aby zamknąć program"
read
clear
Koniec
else
echo "Wprowadzono błędną nazwę grupy. Naciśnij ENTER aby zamknąć program"
read
clear
Koniec
fi
}

function Main(){ #Funckja główna.
clear
#Menu główne programu.
echo -e ' \t'"My Cleaner"
echo "Co chciałbyś dzisiaj zrobić?" 
echo "1. Szybkie skanowanie."
echo "2. Usuń pliki z kosza i pobranych."
echo "3. Usuń pliki z wybranego katalogu."
echo "4. Szukaj zdublowanych plików."
echo "5. Usuń użytkownika."
echo "6. Usuń grupę."
echo "7. Zamknij program."
#Menu wyboru oparte o instrukcje case. 
echo "By wybrać wprowadź numer polecenia bez krokpki:"
read wybor
case "$wybor" in 
1) echo "Skanuję:" 
echo "Podaj bezpośrednią ścieżkę skanowanego katalogu w formacie /home/user/katalog"
read sciezka
Szybkie_Skanowanie $sciezka ;;
2) echo "Wykonuję czyszczenie:" 
Kosz_Pobrane ;;
3) echo "Podaj ścieżkę do katalogu:"
read sciezka
Katalog  $sciezka ;;
4) echo "Szukam zdublowanych plików:" 
Szukaj_zdublowanych ;;
5) echo "Usuń użytkownika:"
Usun_uzytkownika ;;
6) echo "Usuń grupę:"
Usun_grupe ;;
7) echo "Do zobaczenia!"
clear
Koniec ;;
*) echo "Wprowadzono błędną wartośc. Naciśnij ENTER aby wrócić do menu:" 
read
clear
Main ;;
esac
}
Main #Funkcja glowna. 


