IDENTIFICATION DIVISION.
PROGRAM-ID. bugs.
DATA DIVISION.
WORKING-STORAGE SECTION.
01 WS-ARGC USAGE IS BINARY-LONG.
01 WS-ARGV PIC X(256) VALUE SPACES.
01 WS-RESULT USAGE IS BINARY-LONG.

01 WS-SOCKETFD USAGE IS BINARY-LONG.
01 WS-SOCKADDR.
       05 SIN-FAMILY SYNCHRONIZED USAGE IS BINARY-SHORT UNSIGNED VALUE IS 2.
       05 SIN-PORT SYNCHRONIZED USAGE IS BINARY-SHORT UNSIGNED VALUE IS 80.
       05 SIN-ADDR SYNCHRONIZED USAGE IS POINTER.
01 WS-SOCKADDR-LEN USAGE IS BINARY-LONG UNSIGNED.
01 WS-INADDR.
       05 S-ADDR SYNCHRONIZED USAGE IS BINARY-LONG VALUE IS ZEROES.

01 WS-CON-SOCKETFD USAGE IS BINARY-LONG.
01 WS-CON-SOCKADDR.
       05 CON-SIN-FAMILY SYNCHRONIZED USAGE IS BINARY-SHORT UNSIGNED.
       05 CON-SIN-PORT SYNCHRONIZED USAGE IS BINARY-SHORT UNSIGNED.
       05 CON-SIN-ADDR SYNCHRONIZED USAGE IS POINTER.
01 WS-CON-SOCKADDR-LEN USAGE IS BINARY-LONG UNSIGNED.
01 WS-CON-INADDR.
       05 CON-S-ADDR SYNCHRONIZED USAGE IS BINARY-LONG.

01 WS-CON-BUFFER PIC X(20).
01 WS-HTTP-METHOD PIC A(8).
01 WS-HTTP-PATH PIC X(100).
01 WS-HTTP-STATUS PIC X(100).
01 WS-CON-RESPONSE PIC X(100).

01 WS-N USAGE IS BINARY-LONG.
01 WS-RANDOM-INDEX USAGE IS BINARY-LONG.
01 WS-DIRENT USAGE IS POINTER.
01 WS-DIRENT-POINTER USAGE IS POINTER.
01 WS-FILTER USAGE IS PROGRAM-POINTER.
01 WS-COMPAR USAGE IS PROGRAM-POINTER.
01 WS-GIF-DIRECTORY PIC X(256) VALUE "/root/gifs/" & X"00".
01 WS-FILE-PATH PIC X(256).
01 WS-FILE-DESCRIPTOR USAGE IS BINARY-LONG.
01 WS-STAT.
       05 WS-STAT-INO SYNCHRONIZED USAGE IS BINARY-DOUBLE UNSIGNED.
       05 WS-STAT-DEV SYNCHRONIZED USAGE IS BINARY-DOUBLE UNSIGNED.
       05 WS-STAT-MODE SYNCHRONIZED USAGE IS BINARY-LONG UNSIGNED.
       05 WS-STAT-NLINK SYNCHRONIZED USAGE IS BINARY-DOUBLE UNSIGNED.
       05 WS-STAT-UID SYNCHRONIZED USAGE IS BINARY-LONG UNSIGNED.
       05 WS-STAT-GID SYNCHRONIZED USAGE IS BINARY-LONG UNSIGNED.
       05 WS-STAT-RDEV SYNCHRONIZED USAGE IS BINARY-DOUBLE UNSIGNED.
       05 WS-STAT-SIZE SYNCHRONIZED USAGE IS BINARY-DOUBLE SIGNED.
       05 WS-STAT-BLKSIZE SYNCHRONIZED USAGE IS BINARY-DOUBLE SIGNED.
       05 WS-STAT-BLOCKS SYNCHRONIZED USAGE IS BINARY-DOUBLE SIGNED.
       05 WS-STAT-ATIME SYNCHRONIZED USAGE IS BINARY-DOUBLE SIGNED.
       05 WS-STAT-MTIME SYNCHRONIZED USAGE IS BINARY-DOUBLE SIGNED.
       05 WS-STAT-CTIME SYNCHRONIZED USAGE IS BINARY-DOUBLE SIGNED.
       05 FILLER SYNCHRONIZED PIC X(48).
01 WS-BUFFER PIC X(64).
01 WS-FILE-BUFFER-SIZE USAGE IS BINARY-LONG.
01 WS-FILE-BUFFER-POINTER USAGE IS POINTER.
01 WS-HEADER-STATUS PIC X(7) VALUE "200 OK" & X"00".
01 WS-HEADER-TYPE PIC X(10) VALUE "image/gif" & X"00".
01 WS-HEADER-FORMAT PIC X(67) VALUE "HTTP/1.1 %s" & X"0A" & "Connection: close" & X"0A" & "Content-Type: %s" & X"0A" & "Content-Length: %d" & X"0A0A".
01 WS-READ-POINTER USAGE IS POINTER.

LINKAGE SECTION.
>>IF BUGS32 IS DEFINED
01 L-DIRENT-POINTERS USAGE IS BINARY-LONG OCCURS 0 TO 20 TIMES DEPENDING ON WS-N.
01 L-DIRENT.
       05 L-DIRENT-INO SYNCHRONIZED USAGE IS BINARY-LONG.
       05 L-DIRENT-OFF SYNCHRONIZED USAGE IS BINARY-LONG.
>>ELSE
01 L-DIRENT-POINTERS USAGE IS BINARY-DOUBLE OCCURS 0 TO 20 TIMES DEPENDING ON WS-N.
01 L-DIRENT.
       05 L-DIRENT-INO SYNCHRONIZED USAGE IS BINARY-DOUBLE.
       05 L-DIRENT-OFF SYNCHRONIZED USAGE IS BINARY-DOUBLE.
>>END-IF
       05 L-DIRENT-RECLNE SYNCHRONIZED USAGE IS BINARY-SHORT UNSIGNED.
       05 L-DIRENT-TYPE SYNCHRONIZED USAGE IS BINARY-CHAR UNSIGNED.
       05 L-DIRENT-NAME SYNCHRONIZED PIC X(256).
PROCEDURE DIVISION.
Main.
       ACCEPT WS-ARGC FROM ARGUMENT-NUMBER.
       IF WS-ARGC = 1 THEN
           ACCEPT WS-ARGV FROM COMMAND-LINE
           STRING WS-ARGV DELIMITED BY SPACE, X"00" DELIMITED BY SIZE INTO WS-GIF-DIRECTORY
       END-IF.
       IF WS-ARGC > 1 THEN
           DISPLAY "usage: bugs [gif-directory]"
           GOBACK
       END-IF.

       CALL "socket" USING BY VALUE 2, 1, 0 GIVING WS-SOCKETFD.
       IF WS-SOCKETFD = -1 THEN
              CALL "perror" USING "socket"
              CALL "exit" USING BY VALUE 1
       END-IF.
       
       CALL "htons" USING BY VALUE SIN-PORT GIVING SIN-PORT.
       SET SIN-ADDR TO ADDRESS OF WS-INADDR.
       CALL "bind" USING
           BY VALUE WS-SOCKETFD,
           BY REFERENCE WS-SOCKADDR,
           BY VALUE LENGTH OF WS-SOCKADDR
           RETURNING WS-RESULT
       END-CALL.
       IF WS-RESULT = -1 THEN
              CALL "perror" USING "bind"
              CALL "exit" USING BY VALUE 2
       END-IF.
       
       CALL "listen" USING BY VALUE WS-SOCKETFD, 10 RETURNING WS-RESULT.
       IF WS-RESULT = -1 THEN
              CALL "perror" USING "listen"
              CALL "exit" USING BY VALUE 3
       END-IF.
       SET WS-FILTER TO ENTRY "filter".
       SET WS-COMPAR TO ENTRY "alphasort".
       PERFORM Respond FOREVER.
       GOBACK.

Respond.
       DISPLAY "waiting for a connection...".
       SET WS-CON-SOCKADDR-LEN TO LENGTH OF WS-CON-SOCKADDR.
       CALL "accept" USING
           BY VALUE WS-SOCKETFD,
           BY REFERENCE WS-CON-SOCKADDR,
           BY REFERENCE WS-CON-SOCKADDR-LEN
           RETURNING WS-CON-SOCKETFD
       END-CALL.
       IF WS-CON-SOCKETFD = -1 THEN
              CALL "perror" USING "accept"
              CALL "exit" USING BY VALUE 4
       END-IF.
       DISPLAY "Accepted connection from " CON-S-ADDR.
       
      *> CALL "read" USING
      *>     BY VALUE WS-CON-SOCKETFD,
      *>     BY REFERENCE WS-CON-BUFFER,
      *>     BY VALUE LENGTH OF WS-CON-BUFFER
      *>     RETURNING WS-RESULT
      *> END-CALL.
      *> IF WS-RESULT = -1 THEN
      *>        CALL "perror" USING "read"
      *>        CALL "exit" USING BY VALUE 5
      *> END-IF.
      *> DISPLAY "Got request:".
      *> DISPLAY WS-CON-BUFFER.
       
      *> UNSTRING WS-CON-BUFFER DELIMITED BY SPACE
      *>        INTO WS-HTTP-METHOD, WS-HTTP-PATH
      *> END-UNSTRING.

       DISPLAY "Searching " WS-GIF-DIRECTORY.
       CALL "scandir" USING
           BY CONTENT WS-GIF-DIRECTORY,
           BY REFERENCE WS-DIRENT,
           BY VALUE WS-FILTER,
           BY VALUE WS-COMPAR
           RETURNING WS-N
       END-CALL.
       IF WS-N = -1 THEN
              CALL "perror" USING "scandir"
              CALL "exit" USING BY VALUE 6
       END-IF.
       DISPLAY "Found " WS-N " gifs".

       SET ADDRESS OF L-DIRENT-POINTERS(1) TO WS-DIRENT.
       COMPUTE WS-RANDOM-INDEX = FUNCTION RANDOM * WS-N + 1.
       MOVE L-DIRENT-POINTERS(WS-RANDOM-INDEX) TO WS-DIRENT-POINTER.
       SET ADDRESS OF L-DIRENT TO WS-DIRENT-POINTER.
       MOVE WS-GIF-DIRECTORY TO WS-FILE-PATH.
       CALL "strcat" USING WS-FILE-PATH, L-DIRENT-NAME.
       DISPLAY "Selected randomly: " WS-FILE-PATH.

       PERFORM VARYING WS-RESULT FROM 1 BY 1 UNTIL WS-RESULT > WS-N
           MOVE L-DIRENT-POINTERS(WS-RESULT) TO WS-DIRENT-POINTER
           CALL "free" USING BY VALUE WS-DIRENT-POINTER
       END-PERFORM.
       CALL "free" USING BY VALUE WS-DIRENT.

       CALL "open" USING WS-FILE-PATH, BY VALUE 0 RETURNING WS-FILE-DESCRIPTOR.
       IF WS-FILE-DESCRIPTOR = -1 THEN
              CALL "perror" USING "open"
              CALL "exit" USING BY VALUE 7
       END-IF.
       DISPLAY "FD: " WS-FILE-DESCRIPTOR.
       CALL "fstat" USING BY VALUE WS-FILE-DESCRIPTOR, BY REFERENCE WS-STAT RETURNING WS-RESULT.
       IF WS-RESULT = -1 THEN
              CALL "perror" USING "fstat"
              CALL "exit" USING BY VALUE 8
       END-IF.
       DISPLAY "Size: " WS-STAT-SIZE.

       CALL "sprintf" USING BY REFERENCE WS-BUFFER, Z"%d", BY VALUE WS-STAT-SIZE RETURNING WS-RESULT.
       DISPLAY "Requires " WS-RESULT " characters in the header".

       COMPUTE WS-FILE-BUFFER-SIZE = LENGTH OF WS-HEADER-FORMAT - 6 + LENGTH OF WS-HEADER-STATUS - 1 + LENGTH OF WS-HEADER-TYPE - 1 + WS-RESULT + WS-STAT-SIZE.
       ALLOCATE WS-FILE-BUFFER-SIZE CHARACTERS RETURNING WS-FILE-BUFFER-POINTER.
       DISPLAY "Allocated " WS-FILE-BUFFER-SIZE " bytes".

       CALL "sprintf" USING
           BY VALUE WS-FILE-BUFFER-POINTER,
           BY REFERENCE WS-HEADER-FORMAT,
           BY REFERENCE WS-HEADER-STATUS,
           BY REFERENCE WS-HEADER-TYPE,
           BY VALUE WS-STAT-SIZE
           RETURNING WS-RESULT
       END-CALL.
       MOVE WS-FILE-BUFFER-POINTER TO WS-READ-POINTER.
       SET WS-READ-POINTER UP BY WS-RESULT.
       CALL "read" USING BY VALUE WS-FILE-DESCRIPTOR, WS-READ-POINTER, WS-STAT-SIZE RETURNING WS-RESULT.
       IF WS-RESULT = -1 THEN
              CALL "perror" USING "read"
              CALL "exit" USING BY VALUE 9
       END-IF.
       DISPLAY "Read " WS-RESULT " bytes".
       CALL "close" USING BY VALUE WS-FILE-DESCRIPTOR.

       CALL "write" USING
           BY VALUE WS-CON-SOCKETFD,
           BY VALUE WS-FILE-BUFFER-POINTER,
           BY VALUE WS-FILE-BUFFER-SIZE
           RETURNING WS-RESULT
       END-CALL.
       IF WS-RESULT = -1 THEN
              CALL "perror" USING "write"
              CALL "exit" USING BY VALUE 10
       END-IF.
       DISPLAY "Wrote " WS-RESULT " bytes".

       FREE WS-FILE-BUFFER-POINTER.
       CALL "close" USING BY VALUE WS-CON-SOCKETFD.
       
END PROGRAM bugs.

IDENTIFICATION DIVISION.
PROGRAM-ID. filter.
DATA DIVISION.
LINKAGE SECTION.
01 L-DIRENT-POINTER USAGE IS POINTER.
01 L-DIRENT.
>>IF BUGS32 IS DEFINED
       05 L-DIRENT-INO SYNCHRONIZED USAGE IS BINARY-LONG.
       05 L-DIRENT-OFF SYNCHRONIZED USAGE IS BINARY-LONG.
>>ELSE
       05 L-DIRENT-INO SYNCHRONIZED USAGE IS BINARY-DOUBLE.
       05 L-DIRENT-OFF SYNCHRONIZED USAGE IS BINARY-DOUBLE.
>>END-IF
       05 L-DIRENT-RECLNE SYNCHRONIZED USAGE IS BINARY-SHORT UNSIGNED.
       05 L-DIRENT-TYPE SYNCHRONIZED USAGE IS BINARY-CHAR UNSIGNED.
       05 L-DIRENT-NAME SYNCHRONIZED PIC X(256).
PROCEDURE DIVISION USING BY VALUE L-DIRENT-POINTER.
       SET ADDRESS OF L-DIRENT TO L-DIRENT-POINTER.
       IF L-DIRENT-TYPE = 8 THEN
           MOVE 1 TO RETURN-CODE
       ELSE
           MOVE 0 TO RETURN-CODE
       END-IF.
       GOBACK.
END PROGRAM filter.
