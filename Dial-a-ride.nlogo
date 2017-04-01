__includes["communication.nls"]

globals[time-recreate-requests nego-cars nego-times list-dealt-rq nb-all-rq nb-fini-rq]
breed[cars car]
breed[requests request]

requests-own[isalive alive-to destination-x destination-y]      ;;if the request is alive
                                                                ;;at what time the request should die

cars-own[isavailable time-finish-request all-possibilities car-decision isnego]

turtles-own[myId incoming-queue babyseat]                                              ;;ID of requests

to setup
  clear-all

  reset-timer    ;;reset time to 0, we can use <timer> to get the current time compared with 0

  set time-recreate-requests interval-recreate-requests
  set nego-cars initial_Nb_car
  set nego-times 0
  set list-dealt-rq []

  set-default-shape cars "car"
  let with-babyseat (int (initial_Nb_car *  percentage-car-with-babyseat) / 100 )
  let no-babyseat (initial_Nb_car - with-babyseat)

  create-cars with-babyseat  ;; create the cars with babyseat, then initialize their variables
  [
    set color blue
    set size 1
    set label-color blue - 2
    setxy random-xcor random-ycor

    set myId self
    set isavailable true
    set time-finish-request 0
    set incoming-queue []
    set all-possibilities []
    set all-possibilities lput myId all-possibilities
    set car-decision []
    set isnego true
    set babyseat 1

  ]

  create-cars no-babyseat  ;; create the cars with babyseat, then initialize their variables
  [
    set color white
    set size 1
    set label-color blue - 2
    setxy random-xcor random-ycor

    set myId self
    set isavailable true
    set time-finish-request 0
    set incoming-queue []
    set all-possibilities []
    set all-possibilities lput myId all-possibilities
    set car-decision []
    set isnego true
    set babyseat 0

  ]


  set-default-shape requests "person"
  let r-with-babyseat (int (initial_Nb_requests * percentage-request-with-babyseat) / 100)
  let r-no-babyseat (initial_Nb_requests - r-with-babyseat)

  create-requests r-with-babyseat  ;; create the requests with babyseat, then initialize their variables
  [
    set color magenta
    set size 1
    set label-color blue - 2
    setxy random-xcor random-ycor

    set myId self
    set isalive true
    set incoming-queue []
    set alive-to (timer + 10 + random 100)
    set babyseat 1
                                                     ;;need set other variables maybe need to set input nb

    set destination-x xcor + random-float 10                  ;;may be negative should change
    set destination-y ycor + random-float 10

    if ((random-float 1) > 0.5) [set destination-x (xcor - random-float 10 )]
    if ((random-float 1) > 0.5) [set destination-y (ycor - random-float 10 )]

  ]

  create-requests r-no-babyseat  ;; create the requests no babyseat, then initialize their variables
  [
    set color green
    set size 1
    set label-color blue - 2
    setxy random-xcor random-ycor

    set myId self
    set isalive true
    set incoming-queue []
    set alive-to (timer + 10 + random 100)
    set babyseat 0
                                                     ;;need set other variables maybe need to set input nb

    set destination-x xcor + random-float 10                  ;;may be negative should change
    set destination-y ycor + random-float 10

    if ((random-float 1) > 0.5) [set destination-x (xcor - random-float 10 )]
    if ((random-float 1) > 0.5) [set destination-y (ycor - random-float 10 )]

  ]



  set nb-all-rq (nb-all-rq + initial_Nb_requests)
  reset-ticks
end

to go

  creat-requests
  car-set-available           ;;set available if it is available

  set nego-cars initial_Nb_car
  set nego-times 0
  set list-dealt-rq []

  ask cars [ set incoming-queue []  ] ;;clear recevied information after every cycle

  ask requests [

    if isalive [
         send-request
    ]
    request-check-die
  ]
  ask cars [

    if isavailable [

       set all-possibilities []
       set all-possibilities lput myId all-possibilities

       let list-po fill-possibilities
       set all-possibilities lput list-po all-possibilities
    ]
    set incoming-queue []        ;;clear recevied information after every cycle
  ]

  ;;after synchronize all filled all-possibilities
  ;;make decision with negotiasion
  while [nego-times < 10][

      delete-dealt-rq                  ;;delete all dealt requests
      set list-dealt-rq []             ;;after clear list-dealt-rq

      let list-cars-all-pb all-cars-pb

      ask cars [

         if isavailable [

            if isnego [ negotiation list-cars-all-pb ]

         ]
      ]
  set nego-times (nego-times + 1)
  ]

  ;;respond to request
  ask cars [
    if isavailable [

      if(length car-decision > 0)[ finish-request car-decision]

    ]

  ]

  ;let nc 0
  ;ask cars [set nc (nc + 1)]
  ;show nc
  ;;show nego-times
  tick

end


to send-request                   ;;requests procedure

  let smsg create-message "request"
  let p []                       ;;list xcor ycor destination-x destination-y time-to-die babyseat
  ask self [set p lput xcor p]
  ask self [set p lput ycor p]
  ask self [set p lput destination-x p]
  ask self [set p lput destination-y p]
  ask self [set p lput alive-to p]
  ask self [set p lput babyseat p]

  set smsg add-content p smsg

  broadcast-to cars smsg

end


to finish-request [accept-request]                                  ;;cars procedure  accepte request and do it

   let rId item 0 accept-request          ;;get all needed information

   let dx1 item 1 accept-request
   let dy1 item 2 accept-request
   let dx2 item 3 accept-request
   let dy2 item 4 accept-request

   let d1 ((xcor - dx1) ^ 2 +(ycor - dy1) ^ 2) ^ (0.5)   ;;calcule time to finish request
   let d2 ((dx2 - dx1) ^ 2 +(dy2 - dy1) ^ 2) ^ (0.5)
   let d (d1 + d2)                                       ;;we consider the distance is the time
   let end-request (timer + d / 100)

   set isavailable false                  ;;not available
   set color red
   set time-finish-request end-request    ;;set the end of the request
   set isnego false

   ;let to-request (timer + d1)            ;; wait
   ;while [timer < to-request] []

   setxy dx1 dy1                     ;;move to request position

   ask requests [if(who = rId) [die]]     ;;rId is a number
   ;let to-destination (timer + d2)
   ;while [timer < to-destination] []                  ;;wait

   setxy dx2 dy2                          ;;move to destination

   set nb-fini-rq (nb-fini-rq + 1)

end


to request-check-die         ;;requests procedure
  if (timer >= alive-to) [die]

end

to car-set-available
  ask cars [
  if (timer >= time-finish-request) [

      set isavailable true                  ;;set available
      set isnego true
      set car-decision []
      set color white
      set all-possibilities []
      set all-possibilities lput myId all-possibilities
    ]
  ]
end

to creat-requests
  if (timer > time-recreate-requests)[

       let r-with-babyseat (int (initial_Nb_requests * percentage-request-with-babyseat) / 100)
       let r-no-babyseat (initial_Nb_requests - r-with-babyseat)

       create-requests r-with-babyseat  ;; create the requests with babyseat, then initialize their variables
       [
         set color magenta
         set size 1
         set label-color blue - 2
         setxy random-xcor random-ycor

         set myId self
         set isalive true
         set incoming-queue []
         set alive-to (timer + 10 + random 100)
         set babyseat 1
                                                     ;;need set other variables maybe need to set input nb

         set destination-x xcor + random-float 10                  ;;may be negative should change
         set destination-y ycor + random-float 10

         if ((random-float 1) > 0.5) [set destination-x (xcor - random-float 10 )]
         if ((random-float 1) > 0.5) [set destination-y (ycor - random-float 10 )]

       ]

       create-requests r-no-babyseat  ;; create the requests no babyseat, then initialize their variables
       [
         set color green
         set size 1
         set label-color blue - 2
         setxy random-xcor random-ycor

         set myId self
         set isalive true
         set incoming-queue []
         set alive-to (timer + 10 + random 100)
         set babyseat 0
                                                     ;;need set other variables maybe need to set input nb

         set destination-x xcor + random-float 10                  ;;may be negative should change
         set destination-y ycor + random-float 10

         if ((random-float 1) > 0.5) [set destination-x (xcor - random-float 10 )]
         if ((random-float 1) > 0.5) [set destination-y (ycor - random-float 10 )]

       ]

       set time-recreate-requests (timer + interval-recreate-requests)
       set nb-all-rq (nb-all-rq + initial_Nb_requests)
    ]

end

to-report fill-possibilities                             ;; cars procedure

  let list-sort []
  let no-sort []


  let n length incoming-queue
  let i 0
  while [i < n]
  [

     let rmsg item i incoming-queue
     let type-msg item 0 rmsg

     let rId get-sender rmsg
     set rId read-from-string rId



     if type-msg = "request" [

          let list-p get-content rmsg

          let dx1 item 0 list-p
          let dy1 item 1 list-p
          let dx2 item 2 list-p
          let dy2 item 3 list-p
          let request-live-time item 4 list-p
          let r-babyseat item 5 list-p

          if babyseat >= r-babyseat [
              let d1 ((xcor - dx1) ^ 2 +(ycor - dy1) ^ 2) ^ (0.5)
              let d2 ((dx2 - dx1) ^ 2 +(dy2 - dy1) ^ 2) ^ (0.5)
              let d (d1 + d2)

              if ((timer + d1 / 10) < request-live-time)[                              ;;check car can arrive request position within request live time

                  let info-distance-request []                                    ;; foemat info-...
                  set info-distance-request lput rId info-distance-request
                  set info-distance-request lput d info-distance-request          ;;[request-id distance request-position-x request-position-y destination-x destination-y]
                  set info-distance-request lput dx1 info-distance-request
                  set info-distance-request lput dy1 info-distance-request
                  set info-distance-request lput dx2 info-distance-request
                  set info-distance-request lput dy2 info-distance-request

                  set no-sort lput info-distance-request no-sort
              ]
          ]

       ]

     set i (i + 1)
  ]

  set list-sort sort-by [item 1 ?1 < item 1 ?2] no-sort
  report list-sort
end

to negotiation [ list-cars-all-pb ]                                                     ;;negotiation between cars  ;;car procedure   ;;should call after fill-possibilities

  let decision-no-format []
  let final-decision []
  let now-I-am myId

  if(length list-cars-all-pb > 0)[                                       ;;remove self all-possibilities

      let len length list-cars-all-pb
      let i 0
      while [i < len] [

        let carId item 0 (item i list-cars-all-pb)
        if(now-I-am = carId)[
          set list-cars-all-pb remove-item i list-cars-all-pb
          set i len                                                      ;;break
        ]

        set i (i + 1)
      ]
  ]


  ;;to do compare and decide to responce which request
  if(length list-cars-all-pb > 0)[

     let list-equal []
     let mark 0

     let list-pb item 1 all-possibilities

     if(length list-pb > 0)[

        let pre-deci item 0 list-pb

        let k length list-cars-all-pb
        let i 0

        while [i < k] [

          let list-your-all-pb item i list-cars-all-pb

          let my-r-Id item 0 pre-deci
          let my-distance item 1 pre-deci

          let your-car-Id item 0 list-your-all-pb
          let your-list-pb item 1 list-your-all-pb
          if (length your-list-pb > 0)[
             let your-first-pb item 0 your-list-pb

             let your-r-Id item 0 your-first-pb
             let your-distance item 1 your-first-pb
             if (my-r-Id = your-r-Id)[
                 if(my-distance > your-distance) [
                   set mark 1
                   set i k                                                           ;; to break the while loop
                 ]
                 if(my-distance = your-distance) [
                   set list-equal lput your-car-Id list-equal
                 ]
             ]
          ]
          set i (i + 1)
       ]

       if(mark = 0)[

          let elen length list-equal

          if(elen = 0)[                                                        ;;we take the pre-decision as decision
            set decision-no-format pre-deci
          ]

          if(elen > 0)[
            ;;if have another car as the same distance chose the less ID car
            set list-equal sort-by < list-equal
            if(myId < item 0 list-equal)[                                     ;;??myId is not a number??
              set decision-no-format pre-deci
            ]

          ]

      ]
        ;;if(mark = 1)[ ];;if get same r-Id and  distance, do nothing


      if(length list-cars-all-pb = 0)[                                           ;;chose the first in the list all-possibilities
        let all-decisions item 1 all-possibilities
        set decision-no-format item 0 all-decisions
      ]

      if(length decision-no-format > 0)[                     ;;if we have the decision
        set final-decision lput item 0 decision-no-format final-decision          ;;format decision-no-format
        set final-decision lput item 2 decision-no-format final-decision          ;;[r-Id distance r-x r-y d-x d-y]
        set final-decision lput item 3 decision-no-format final-decision          ;;format final-decision
        set final-decision lput item 4 decision-no-format final-decision          ;;[r-Id r-x r-y d-x d-y]
        set final-decision lput item 5 decision-no-format final-decision
        ;;should make decision with final-decision
        make-decision myId final-decision
     ]

   ]
 ]


end

to make-decision [car-Id decision]
   ask car-Id [
       set car-decision decision
       set isnego false
   ]

   let rId item 0 decision
   set list-dealt-rq lput rId list-dealt-rq

end

to delete-dealt-rq                              ;;observer procedure ; call before each negotiation

  ask cars [
     if (isavailable)[
       if(isnego)[
          if(length list-dealt-rq > 0)[
              foreach list-dealt-rq [                      ;;delete all dealt request in list

                 let list-pb item 1 all-possibilities
                 set all-possibilities []
                 set all-possibilities lput myId all-possibilities

                 let plen length list-pb
                 let i 0
                 while [i < plen][

                   let p item i list-pb

                   if(? = (item 0 p))[                    ;;if rquest-Id are same
                     set list-pb remove-item i list-pb
                     set plen (plen - 1)                  ;;length of list-pb - 1
                     set i (i - 1)                        ;;do not move
                   ]

                   set i (i + 1)
                 ]
                 set all-possibilities lput list-pb all-possibilities
              ]
          ]
       ]
     ]
  ]
end

to-report all-cars-pb

  let list-cars-all-pb []
  ask cars [
        if(isavailable = true)[                                            ;;if the car is available
           if(isnego = true)[set list-cars-all-pb lput all-possibilities list-cars-all-pb]
        ]
    ]
  report list-cars-all-pb
end





@#$#@#$#@
GRAPHICS-WINDOW
496
10
1221
496
27
17
13.0
1
10
1
1
1
0
1
1
1
-27
27
-17
17
0
0
1
ticks
30.0

INPUTBOX
181
15
336
75
initial_Nb_car
5
1
0
Number

BUTTON
21
169
87
202
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
8
15
163
75
initial_Nb_requests
15
1
0
Number

BUTTON
130
170
193
203
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

INPUTBOX
9
95
164
155
interval-recreate-requests
1
1
0
Number

PLOT
13
248
383
496
percentage of finished request
time
percentage
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"%finish-rq" 1.0 0 -2674135 true "" "plot (nb-fini-rq / nb-all-rq) * 100"
"nb-all" 1.0 0 -7500403 true "" ";plot nb-all-rq"
"nb-fini" 1.0 0 -955883 true "" ";plot nb-fini-rq"

SLIDER
183
93
468
126
percentage-request-with-babyseat
percentage-request-with-babyseat
0
100
20
0.5
1
NIL
HORIZONTAL

SLIDER
183
127
440
160
percentage-car-with-babyseat
percentage-car-with-babyseat
0
100
20
0.5
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
