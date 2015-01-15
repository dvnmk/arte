# arte

       nummer
         |    
      \  v  /
    +--\   /----------------------------+
    |                                   |
    |        (arte) dvnmk 2015          |
    |                                   |
    +---------------------------/   \---+
                               /  |  \
                                  v     
                                sendung
                                       
* DONE filename zv datum.
* DONE fur shell / ccl only 
* DONE Unicode suppport als file-name y alle.
* TODO file-nanme.log - "mp4"

Example
-------
```common-lisp
CL-USER> (i 043784-000)
```

* TITL : "Schleierhaft"
* KURZ : "Über die höchst komplexen Bedeutungsebenen des Schleiers in Deutschland und Frankreich."
* INFO : Dokumentation (Deutschland, 2011, 52mn) ZDF
* AIRD : 12/01/2015 03:30:00 +0100 - 19/01/2015 03:33:07 +0100
* BESS : Heute finden sich Schleier in der westlichen Welt nur noch als Relikte in Form von Braut-, Witwen- oder Nonnenschleiern. Schleier sowie Kopftuch werden als typische Kopfbedeckung muslimischer Frauen angesehen. Und um den muslimischen Schleier und dessen Symbolgehalte geht es in der Dokumentation.
T

```common-lisp
CL-USER> (g 043784-000)
```
#<EXTERNAL-PROCESS (sh -c wget -c http://artestras.vo.llnwd.net/v2/am/HBBTV/043784-000-A_SQ_1_VOA_01623938_MP4-2200_AMM-HBBTV.mp4 -O Schleierhaft-1201.mp4 --no-verbose  -o Schleierhaft-1201.mp4.log --tries=4)[1309] (RUNNING) #x30200221B3FD>

```common-lisp
CL-USER> (kill)
```

#<EXTERNAL-PROCESS (killall wget)[1310] (EXITED : 0) #x30200221879D>
