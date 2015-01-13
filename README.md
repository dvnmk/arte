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
* TODO fur shell / clisp, sbcl
* DONE Unicode suppport als file-name => asciify filename

Example
-------
'''
CL-USER> (ARTE-INFO-M 045260-001)
* TITEL : "Erã¶ffnungskonzert Salzburger Festspiele 2011"
* AIRED : 12/01/2015 02:00:00 +0100 - 19/01/2015 02:05:24 +0100
* CASE  : 408_maestro
* INFO  : (Deutschland, 2011, 87mn) ZDF
* KURZ  : "Pierre Boulez und die Wiener Philharmoniker spielen Gustav Mahlers Opus 1, \"Das klagende Lied\". "
* BES   : "Ein HÃ¶hepunkt jedes Musiksommers sind die Salzburger Festspiele. Der Programmschwerpunkt 2011 war das Werk Gustav Mahlers. Im ErÃ¶ffnungskonzert der Wiener Philharmoniker dirigierte Pierre Boulez dessen Opus 1, \"Das klagende Lied\", ergÃ¤nzt um Alban Bergs \"Lulu-Suite\". Durch den Abend fÃ¼hrt ARTE-Moderatorin Annette Gerlach."
* MODES : (RTMP_LQ_1 HLS_SQ_1 HTTP_MP4_SQ_1 HTTP_MP4_MQ_1 RTMP_EQ_1 RTMP_MQ_1
           HTTP_MP4_EQ_1 RTMP_SQ_1)
* WGET  :
 wget -c http://artestras.vo.llnwd.net/v2/am/HBBTV/045260-001-B_SQ_1_VO-STA_01623913_MP4-2200_AMM-HBBTV.mp4 -O ErAffnungskonzert_Salzburger_Festspiele_2011-12012015.mp4
NIL
'''
