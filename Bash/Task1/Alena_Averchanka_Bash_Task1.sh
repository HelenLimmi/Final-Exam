#!/bin/bash

#create new file with parse lines
awk -vFPAT='([^,]*)|("[^"]+")' -vOFS=, '{.
	if ($5 != "name") {
		split($5,a," ");.
		firstLetterName = toupper(substr(a[1],1,1));.
		upperName = firstLetterName""substr(a[1],2);
		
		firstLetterSurname = toupper(substr(a[2],1,1));.
		upperSurname = firstLetterSurname""substr(a[2],2);.

		$5 = upperName" "upperSurname.
		$7 = tolower(firstLetterName""a[2])"@abc.com"
	}
	print $1,$2,$3,$4,$5,$6,$7,$8
}' accounts.csv |

#formating email with the same ID
awk -F, '{ d=dup[$7]++; email = $7; if (d>0) res=gsub("@",(d "@"),$email); echo res} 1' > accounts_new.csv
