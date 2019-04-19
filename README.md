Sample log output:

Erlang shell
```
    1> c(server).
    {ok,server}
    2> server:start(4000).
    {#Port<0.2069>,<0.67.0>}
    Sending ["NEW COMER: ","Alice\r\n"]
    Sending ["NEW COMER: ","Bob\r\n"]
    Sending ["Bob",": ","Hello\r\n"]
    Sending ["Alice",": ","Hi\r\n"]
    Sending ["Alice",": ","Howdy?\r\n"]
    Sending ["Bob",": ","I have to leave\r\n"]
    Sending ["LEAVING: ","Bob","\r\n"]
    Sending ["NEW COMER: ","Carol\r\n"]
    Sending ["Carol",": ","Bonjour\r\n"]
    Sending ["Alice",": ","Salut\r\n"]
    3> server:stop({#Port<0.2069>,<0.67.0>}).
    true
```

Session 1
```
    >telnet localhost 4000
    Connected to localhost.

    --------------
    At any time enter 'quit' to leave
    Enter your name?
    Alice
    --[History]---
    --------------
    NEW COMER: Bob
    Bob: Hello
    Hi
    Howdy?
    Bob: I have to leave
    LEAVING: Bob
    NEW COMER: Carol
    Carol: Bonjour
    Salut
    Connection closed by foreign host.
```

Session 2
```
    >telnet localhost 4000
    Connected to localhost.

    --------------
    At any time enter 'quit' to leave
    Enter your name?
    Bob
    --[History]---
    NEW COMER: Alice
    --------------
    Hello
    Alice: Hi
    Alice: Howdy?
    I have to leave
    quit
    Connection closed by foreign host.
```

Session 3
```
    > telnet localhost 4000
    Connected to localhost.

    --------------
    At any time enter 'quit' to leave
    Enter your name?
    Carol
    --[History]---
    NEW COMER: Alice
    NEW COMER: Bob
    Bob: Hello
    Alice: Hi
    Alice: Howdy?
    Bob: I have to leave
    LEAVING: Bob
    --------------
    Bonjour
    Alice: Salut
    Connection closed by foreign host.
```