extensions [bitmap]

breed [crops crop]
breed [dividers divider]
breed [owners owner]
breed [scorecards scorecard]
breed [actives active]

patches-own [depleteTurns restoreTurns player choice previousChoice currentScore currentBonus currentESBump currentYield currentPenalty scoreWho gooseWho cropWho taps usingPlayer playerAccess playerScore ]
scorecards-own [identity playerNumber]
actives-own [playerNumber]



globals [numPlayers 
  playerHHID
  playerShortNames
  playerNames 
  playerNameLengths
  playerDomains 
  playerScores
  playerTurnSequence
  playerCurrentActive
  playerCurrentScores
  playerCurrentBonus
  playerCurrentESBump
  playerCurrentYield
  playerInfoTracker
  playerThinkTimes
  playerCurrentFarm
  midX midY 
  playerPosition
  choiceColors
  grayedChoiceColors
  confirmedChoiceColors
  inactiveChoiceColors
  monitoredColor
  ownerColors
  confirmChoice
  centerPatches
  roundScorePatches
  inGame
  gameName
  currentRound
  minNumRounds
  maxNumRounds

  maxFarm
  turnSequenceMode
  currentInfoScreen
  confirmButton
  confirmPixLoc
  yieldText
  yieldPixLoc
  penaltiesText
  penaltiesPixLoc 
  esBumpText
  esBumpPixLoc
  gooseBonusText
  gooseBonusPixLoc
  scoreText
  scorePixLoc
  totalScoreText
  totalScorePixLoc
  prevRoundText
  prevRoundPixLoc
  roundText
  roundPixLoc
  langSuffix
  fontSize
  roundStartTimes
  inputFileLabels
  parsedInput
  currentSessionParameters
 
  currentIDList



  maxYieldHigh
  maxYieldLow
  forestYieldBump
  forestYieldNeighborhood
  forestRestoreBump
  turnsDeplete
  turnsRestore
  
  forestYield
  forestSubsidy
  restoredSubsidyOnlyFlag
  
  
  farmX
  farmY
  numRounds
  farmYieldHigh
  farmYieldLow


  




  aggBonus

 


  showMoves
 
  gameTag
  appendDateTime
  
  randomSubsidy
  completedGamesIDs
  
  gameOrdering
  gameCount
  policyTreatment
        ]

to startup
  hubnet-reset
  file-close
  clear-output
  
  output-print (word "Starting Session") 
  
  set playerNames (list)
  set playerShortNames (list)
  set playerHHID (list)
  set playerPosition (list)
  set playerThinkTimes (list)
  set numPlayers 0
  set choiceColors [34 34]
  set grayedChoiceColors [39 39]
  set confirmedChoiceColors [32 32]
  set inactiveChoiceColors [32 32]
  set ownerColors [15 65 85 135]
  set monitoredColor 15

  ;;SAROBIDY - this is the game ordering
  set gameOrdering shuffle ["T2" "T3" "T5"]
  set gameOrdering fput "P" gameOrdering
   
  output-print (word "The game ordering for this session: ") 
  output-print (word gameOrdering) 
  set gameCount -1
  
  
  ;;SAROBIDY - this is the range of the subsidy, set at startup.  the syntax is:  item (random [NUMBER OF LEVELS]) (list [THE DIFFERENT LEVELS])
  set randomSubsidy item (random 3) (list 3 5 7)
  output-print (word "Random subsidy for this session: " randomSubsidy) 
  
  ;;SAROBIDY - Set the range of rounds here
  set minNumRounds 8
  set maxNumRounds 12
  
 
  set inGame 0

  set-default-shape scorecards "blank"
  set-default-shape dividers "line"
  set-default-shape owners "empty-square"

  clear-ticks
  clear-patches
  clear-turtles
  clear-drawing
  
end



to set-new-game


  if (gameCount >  length gameOrdering) 
  [user-message "No more games specified.  To start new session, please first clear settings by clicking 'Launch Broadcast'"
    stop]
    
  if (inGame = 1) 
  [user-message "Current game is not complete.  Please continue current game.  Otherwise, to start new session, please first clear settings by clicking 'Launch Broadcast'"
    stop]
  
 
   

  if (length playerNames != 4)
  [user-message "Need 4 Players!"
    stop]

  
  if inGame = 1 [end-game]  ;; just to save any previous game, in case it didn't get ended properly
   
   
     clear-patches
  clear-turtles
  clear-drawing
  clear-all-plots 
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
  ;;SAROBIDY - Set GAME-SPECIFIC parameters here - these would be sliders in the master copy
  
  set gameCount (gameCount + 1)
  
  set farmX 3
  set farmY 3
  ;;set numRounds 8
  rand-num-rounds
  
  set farmYieldHigh 8
  set farmYieldLow 3
  set forestYield 0
  set maxYieldHigh 18
  set maxYieldLow 10
  set maxFarm 9

  set forestYieldBump 2
  set forestRestoreBump 0
  set forestYieldNeighborhood 1
  
  set turnsDeplete 2
  set turnsRestore 2
  
  set playerTurnSequence [1 2 2 3]
  set turnSequenceMode 1 ;; 0 means keep it fixed, 1 means shuffle the ordering 1 to 4, 2 means randomly select a sequence from 1-4 for each player (with possibly several players at once)
  
  set aggBonus 0
  set forestSubsidy 1

  set restoredSubsidyOnlyFlag 1
  
  set showMoves "atEndTurn"  ;; either atEndTurn or onConfirm

  set appendDateTime true
  set playerCurrentActive (list 0 0 0 0)
  set playerCurrentFarm (list 0 0 0 0)
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;SAROBIDY - Now any adjustments for the particular treatment we are in
  
  ;;Here, treatments are as follows:
  ;; "Practice"
  ;; "T1 - Baseline No Communication"
  ;; "T2 - Baseline With Communication"
  ;; "T3 - Random Subsidy"
  ;; "T5 - Subsidy + Agglomeration Bonus"
  
  set policyTreatment item gameCount gameOrdering
  
   ask patches [set playerAccess (list -99)]  ;; just so it's defined everywhere
  ask patches with [pxcor >= 0] [
  ifelse (pxcor < midX and pycor < midY) [set playerAccess (list 1)]
    [ifelse (pxcor > midX and pycor < midY) [set playerAccess (list 2)]
      [ifelse (pxcor > midX and pycor > midY) [set playerAccess (list 3)]
        [set playerAccess (list 4)]
     ]
   ]  
  ]
  
  if policyTreatment = "P" [
    set numRounds 3
    set gameTag "P"
    output-print (word "This game - Practice") 
  ]
  
  
  
  if policyTreatment = "T1" [
    set gameTag "T1"
    output-print (word "This game - T1 - Indiv rights w/o subsidy") 
      ]
  
  
  
  if policyTreatment = "T2" [
    
    set gameTag "T2"
    set forestSubsidy randomSubsidy
    output-print (word "Habitat Subsidy: " forestSubsidy) 
    set gameTag "T3"
        output-print (word "This game - T2 - Indiv rights w/ subsidy") 
      ]
  
  
  
  if policyTreatment = "T3" [
     set gameTag "T3"
    ask patches with [pxcor >= 0] [
    ifelse (pxcor < midX and pycor < midY) [set playerAccess (list 1 2 3 4)]
     [ifelse (pxcor > midX and pycor < midY) [set playerAccess (list 1 2 3 4)]
       [ifelse (pxcor > midX and pycor > midY) [set playerAccess (list 1 2 3 4)]
        [set playerAccess (list 1 2 3 4)]
      ]
    ]  
  ]
        output-print (word "This game - T3 - Common access w/0 subsidy") 
  ]
  
  
  if policyTreatment = "T4" [
    set forestSubsidy randomSubsidy
    output-print (word "Habitat Subsidy: " forestSubsidy) 
    set gameTag "T4"
     ask patches with [pxcor >= 0] [
    ifelse (pxcor < midX and pycor < midY) [set playerAccess (list 1 2 3 4)]
     [ifelse (pxcor > midX and pycor < midY) [set playerAccess (list 1 2 3 4)]
       [ifelse (pxcor > midX and pycor > midY) [set playerAccess (list 1 2 3 4)]
        [set playerAccess (list 1 2 3 4)]
      ]
    ]  
  ]
        output-print (word "This game - T4 - Common access w/ subsidy") 
  ]
  
  
  if policyTreatment = "T5" [
    set forestSubsidy randomSubsidy
    output-print (word "Habitat Subsidy: " forestSubsidy) 
    set aggBonus 1
    output-print (word "Agglomeration Bonus: " aggBonus) 
        output-print (word "This game - T5 - Subsidy + Agglomeration Bonus") 
    set gameTag "T5"
  ]

    
  ;;;;;;;;;;;;;;;;;;
  ;; Make game file
  let tempDate date-and-time
  foreach [2 5 8 12 15 18 22] [set tempDate replace-item ? tempDate "_"]
  set gameName (word gameTag "_" (item 0 playerNames) "_" (item 1 playerNames) "_" (item 2 playerNames) "_" (item 3 playerNames) (ifelse-value appendDateTime [word "_" tempDate ] [""]) ".csv" )
  carefully [file-delete gameName file-open gameName] [file-open gameName]
  
  ;;Initialize game file
  file-print word "Player 1 Name: " (item 0 playerShortNames)
  file-print word "Player 2 Name: " (item 1 playerShortNames)
  file-print word "Player 3 Name: " (item 2 playerShortNames)
  file-print word "Player 4 Name: " (item 3 playerShortNames)
  file-print word "Player 1 HHID: " (item 0 playerHHID)
  file-print word "Player 2 HHID: " (item 1 playerHHID)
  file-print word "Player 3 HHID: " (item 2 playerHHID)
  file-print word "Player 4 HHID: " (item 3 playerHHID)
  file-print ""
  
  file-print word "Game Tag: " (gameTag)
  file-print word "Farm X: " (farmX) 
  file-print word "Farm Y: " (farmY)
  file-print word "Number of Rounds: " (numRounds)
  
  ;;FILL IN WITH ALL FINAL VARIABLES BEFORE USING
 
  file-print word "Farm Yield High: " (farmYieldHigh)
  file-print word "Farm Yield Low: " (farmYieldLow)
  file-print word "Forest Yield: " (forestYield)  
  file-print word "Max Yield High: " (maxYieldHigh)
  file-print word "Max Yield Low: " (maxYieldLow)
  file-print word "Max Farm: " (maxFarm)
 
  file-print word "Forest Yield Bump: " (forestYieldBump)  
  file-print word "Forest Restore Bump: " (forestRestoreBump)  
  file-print word "Forest Yield Neighborhood: " (forestYieldNeighborhood)  
  

  file-print word "Turns to Deplete: " (turnsDeplete)  
  file-print word "Turns to Restore : " (turnsRestore)  
  file-print word "Player Turn Sequence Mode : " (turnSequenceMode)  
  
  file-print word "Agg Bonus: " (aggBonus)  
  file-print word "Forest Subsidy : " (forestSubsidy)  
  file-print word "Restored Subsidy Flag: " (restoredSubsidyOnlyFlag)  
 
  file-print word "Show Moves: " (showMoves)
  file-print ""

  
   ask scorecards [die ]
   
  if language = "English" [ set langSuffix "en"]
  if language = "French" [ set langSuffix "fr"]

    
  set fontSize 50 ;; this is just a reference, it DOES NOT SET FONT SIZE.  change this if you change the size of the fonts in the view, this is used to help align player names

  
  
  ;; set in-game variables to initial settings
  set confirmChoice (list 0 0 0 0)
  set playerScores (list 0 0 0 0)
  set playerCurrentScores (list 0 0 0 0)
  set playerCurrentYield (list 0 0 0 0)
  set playerCurrentBonus (list 0 0 0 0)
  set playerCurrentESBump (list 0 0 0 0)
  set playerInfoTracker (list 0 0 0 0)
  set playerThinkTimes (list 0 0 0 0)
  set roundStartTimes (list)
  set inGame 1
  set currentRound 1
  set currentInfoScreen 0

  
  set playerNameLengths (list 0 0 0 0)
  foreach playerShortNames [
   set playerNameLengths replace-item (position ? playerShortNames) playerNameLengths (length ?) 
  ]
  
  ;;Whatever size the world is, there is a buffer of 5 patches across on the left side that is used for game information
  resize-world -5 (farmX * 2 - 1) 0 (farmY * 2 - 1) ;; use the spaces -5 through -1 to display information about game
  
  ;;get farm size from world size
  set midX (max-pxcor - 0) / 2
  set midY (max-pycor - 0) / 2
 
  ;;assign domain to players
  ;;ask patches with [pxcor >= 0] [
  ;;  ifelse (pxcor < midX and pycor < midY) [set player 1]
  ;;   [ifelse (pxcor > midX and pycor < midY) [set player 2]
  ;;     [ifelse (pxcor > midX and pycor > midY) [set player 3]
  ;;      [set player 4]
  ;;    ]
  ;;  ]  
  ;;]
  
  ;;SAROBIDY this is where we assign the allowed users to squares.  the code below walks through quadrants, but it needn't necessarily.  adding the number X after the word 'list' below will add player X to the list of players that can access that square
  ;;ask patches [set playerAccess (list -99)]  ;; just so it's defined everywhere
  ;;ask patches with [pxcor >= 0] [
  ;;  ifelse (pxcor < midX and pycor < midY) [set playerAccess (list 1 2)]
  ;;   [ifelse (pxcor > midX and pycor < midY) [set playerAccess (list 2)]
  ;;     [ifelse (pxcor > midX and pycor > midY) [set playerAccess (list 3)]
  ;;      [set playerAccess (list 4)]
  ;;    ]
  ;;  ]  
  ;;]
  
    
  ;;The following code fixes the locations and sizes of the in-game text.  It was optimized to an 11 x 6 box with a patch size of 112 pixels, for use with a Dell Venue 8 as a client.
  ;;The structure of the location variables is [xmin ymin width height].  They have been 'converted' to scale with a changing patch size and world size, but this is not widely tested
  let yConvertPatch (farmY / 3)  ;;scaling vertical measures based on the currently optimized size of 6
  let xyConvertPatchPixel (patch-size / 112)  ;; scaling vertical and horizontal measures based on currently optimized patch size of 112
  
  
  set confirmPixLoc (list (20 * xyConvertPatchPixel) (20 * yConvertPatch * xyConvertPatchPixel) (200 * xyConvertPatchPixel) (125 * yConvertPatch * xyConvertPatchPixel))
  set yieldPixLoc (list (25 * xyConvertPatchPixel) (295 * yConvertPatch * xyConvertPatchPixel) (350 * xyConvertPatchPixel) (70 * yConvertPatch * xyConvertPatchPixel))
  set esBumpPixLoc (list (25 * xyConvertPatchPixel) (365 * yConvertPatch * xyConvertPatchPixel) (350 * xyConvertPatchPixel) (70 * yConvertPatch * xyConvertPatchPixel))
  set gooseBonusPixLoc (list (25 * xyConvertPatchPixel) (435 * yConvertPatch * xyConvertPatchPixel) (350 * xyConvertPatchPixel) (70 * yConvertPatch * xyConvertPatchPixel))
  set scorePixLoc (list (25 * xyConvertPatchPixel) (510 * yConvertPatch * xyConvertPatchPixel) (350 * xyConvertPatchPixel) (70 * yConvertPatch * xyConvertPatchPixel))
  set totalScorePixLoc (list (25 * xyConvertPatchPixel) (585 * yConvertPatch * xyConvertPatchPixel) (350 * xyConvertPatchPixel) (70 * yConvertPatch * xyConvertPatchPixel))
  set prevRoundPixLoc (list (10 * xyConvertPatchPixel) (220 * yConvertPatch * xyConvertPatchPixel) (350 * xyConvertPatchPixel) (70 * yConvertPatch * xyConvertPatchPixel))
  set roundPixLoc (list (250 * xyConvertPatchPixel)  (30 * yConvertPatch * xyConvertPatchPixel) (175 * xyConvertPatchPixel) (70 * yConvertPatch * xyConvertPatchPixel))
  
  set confirmButton bitmap:import (word "./image_label/confirm_" langSuffix ".png")
  set yieldText bitmap:import (word "./image_label/yield_" langSuffix ".png")
  set gooseBonusText bitmap:import (word "./image_label/gooseBonus_" langSuffix ".png") 
  set esBumpText bitmap:import (word "./image_label/esBump_" langSuffix ".png")
  set scoreText bitmap:import (word "./image_label/score_" langSuffix ".png")
  set totalScoreText bitmap:import (word "./image_label/totalScore_" langSuffix ".png")
  set prevRoundText bitmap:import (word "./image_label/prevRound_" langSuffix ".png")
  set roundText bitmap:import (word "./image_label/round_" langSuffix ".png")

               
  bitmap:copy-to-drawing (bitmap:scaled confirmButton (item 2 confirmPixLoc) (item 3 confirmPixLoc)) (item 0 confirmPixLoc) (item 1 confirmPixLoc)
  bitmap:copy-to-drawing (bitmap:scaled yieldText (item 2 yieldPixLoc) (item 3 yieldPixLoc)) (item 0 yieldPixLoc) (item 1 yieldPixLoc)
  bitmap:copy-to-drawing (bitmap:scaled gooseBonusText (item 2 gooseBonusPixLoc) (item 3 gooseBonusPixLoc)) (item 0 gooseBonusPixLoc) (item 1 gooseBonusPixLoc)
  bitmap:copy-to-drawing (bitmap:scaled esBumpText (item 2 esBumpPixLoc) (item 3 esBumpPixLoc)) (item 0 esBumpPixLoc) (item 1 esBumpPixLoc)
  bitmap:copy-to-drawing (bitmap:scaled scoreText (item 2 scorePixLoc) (item 3 scorePixLoc)) (item 0 scorePixLoc) (item 1 scorePixLoc)
  bitmap:copy-to-drawing (bitmap:scaled totalScoreText (item 2 totalScorePixLoc) (item 3 totalScorePixLoc)) (item 0 totalScorePixLoc) (item 1 totalScorePixLoc)
  bitmap:copy-to-drawing (bitmap:scaled prevRoundText (item 2 prevRoundPixLoc) (item 3 prevRoundPixLoc)) (item 0 prevRoundPixLoc) (item 1 prevRoundPixLoc)
  bitmap:copy-to-drawing (bitmap:scaled roundText (item 2 roundPixLoc) (item 3 roundPixLoc)) (item 0 roundPixLoc) (item 1 roundPixLoc)
    
  ;;set centerPatches (patch-set patch (floor midX / 2) (floor midY / 2) patch (floor 3 * midX / 2) (floor midY / 2)  patch (floor midX / 2) (floor 3 * midY / 2) patch (floor 3 * midX / 2) (floor 3 * midY / 2))
  set roundScorePatches (patch-set patch (floor midX - 1) (ceiling midY) patch (floor midX) (ceiling midY)  patch (floor midX + 1) (ceiling midY) patch (floor midX + 2) (ceiling midY))

 ask patch (floor midX - 1) (ceiling midY) [set playerScore 1]
 ask patch (floor midX) (ceiling midY) [set playerScore 2]
 ask patch (floor midX + 1) (ceiling midY) [set playerScore 3]
 ask patch (floor midX + 2) (ceiling midY) [set playerScore 4]
  
  ;;lay out the agents that will provide score information.  These too are optimized to a Dell Venue 8, with farm size 3 and 3, patch size 112, and may need adjustments if changes are made             
  create-scorecards 1 [setxy -1.5 max-pycor + 0.23 set label currentRound set identity "currentRound" set label-color yellow]
  create-scorecards 1 [setxy -1.75 (max-pycor - 2.11  * yConvertPatch) set label 0 set identity "yield"]
  create-scorecards 1 [setxy -1.75 (max-pycor - 2.82  * yConvertPatch) set label 0 set identity "esbump"]
  create-scorecards 1 [setxy -1.75 (max-pycor - 3.43  * yConvertPatch) set label 0 set identity "bonus"]
  create-scorecards 1 [setxy -1.75 (max-pycor - 4.05 * yConvertPatch) set label 0 set identity "currentScore"]
  create-scorecards 1 [setxy -1.5 (max-pycor - 4.75 * yConvertPatch) set label 0 set identity "totalScore" set label-color red]
  ;;create-scorecards 1 [setxy (midX / 2 - 0.75 + (item 0 playerNameLengths * fontSize / patch-size / 4)) midY / 2 set identity "playerName" set playerNumber 1 set label-color black]
  ;;create-scorecards 1 [setxy (3 * midX / 2 - 0.25 + (item 1 playerNameLengths * fontSize / patch-size / 4)) midY / 2 set identity "playerName" set playerNumber 2 set label-color black]
  ;;create-scorecards 1 [setxy (3 * midX / 2  - 0.25 + (item 2 playerNameLengths * fontSize / patch-size / 4)) (3 * midY / 2) + 0.5 set identity "playerName" set playerNumber 3 set label-color black]
  ;;create-scorecards 1 [setxy (midX / 2 - 0.75  + (item 3 playerNameLengths * fontSize / patch-size / 4)) (3 * midY / 2) + 0.5 set identity "playerName" set playerNumber 4 set label-color black]
  
  
  create-scorecards 1 [setxy -2.1 (max-pycor - 2.4  * yConvertPatch) set label "" set shape "crop-base" set identity "yieldIcon" set size 0.5]
  create-scorecards 1 [setxy -2 (max-pycor - 3.75  * yConvertPatch) set label "" set shape "add-money" set identity "subsIcon" set size 0.6]
  create-scorecards 1 [setxy -2 (max-pycor - 3.15 * yConvertPatch) set label "" set shape "non-crop" set identity "esIcon" set size 0.6]

 create-actives 1 [setxy -2.75 max-pycor - 0.75 set shape "empty-square" set size 0.5 set playerNumber 1 set color item 0 ownerColors]
 create-actives 1 [setxy -2.25 max-pycor - 0.75 set shape "empty-square" set size 0.5 set playerNumber 2 set color item 1 ownerColors]
 create-actives 1 [setxy -1.75 max-pycor - 0.75 set shape "empty-square" set size 0.5 set playerNumber 3 set color item 2 ownerColors]
 create-actives 1 [setxy -1.25 max-pycor - 0.75 set shape "empty-square" set size 0.5 set playerNumber 4 set color item 3 ownerColors]
 
  ask patches with [pxcor >= 0] [set choice 0 set previousChoice 0
    set pcolor item choice choiceColors
    set depleteTurns turnsDeplete
    set restoreTurns 0
    sprout-scorecards 1 [let currentWho who ask patch-here [set scoreWho currentWho] setxy (xcor - .1) (ycor ) set label-color black set identity "currentAndFinalScore"]
    sprout-scorecards 1 [let currentWho who ask patch-here [set gooseWho currentWho] setxy (xcor - .1) (ycor + .45) set label-color 104 set identity "timeCount"]
 
    sprout-crops 1 [let currentWho who ask patch-here [set cropWho currentWho] update-crop-image]
    sprout-owners 1 [set color red set hidden? true]
    ]
   
  
       
  ;;Add dividers between players
  let currentX 0
  let currentY 0
  while [currentY < max-pycor] [
    set currentX 0
    while [currentX < max-pxcor] [
      create-dividers 1 [setxy currentX  currentY + 0.5 facexy xcor - 1 ycor set color gray ]
    set currentX currentX + 1  
    ]
    create-dividers 1 [setxy currentX  currentY + 0.5 facexy xcor - 1 ycor set color gray ]
    set currentY currentY + 1    
  ]
  
  set currentX 0
  set currentY 0
  while [currentX < max-pxcor] [
    set currentY 0
    while [currentY < max-pycor] [
    create-dividers 1 [setxy currentX + 0.5 currentY facexy xcor ycor - 1 set color gray ]
    set currentY currentY + 1  
    ]
    create-dividers 1 [setxy currentX + 0.5 currentY facexy xcor ycor - 1 set color gray ]
    set currentX currentX + 1
    
  ]
  
  
  
  ;;Send overrides to clients for displays
  gray-out-others
  

  file-print (word "Land Ownership:")
  file-print ""
  
  ;; write landscape to file
  let currentRow max-pycor
  while [currentRow >= 0] [
    let currentColumn 0
    while [currentColumn < max-pxcor] [
      ;;print (word currentColumn currentRow)
      
      ask (patch currentColumn currentRow) [file-write (word "(" playerAccess ")")] 
      set currentColumn currentColumn + 1
    ]
    ask patch currentColumn currentRow [file-print (word "(" playerAccess ")") ]
    set currentRow currentRow - 1 
  ]
  file-print ""
  
  set roundStartTimes lput date-and-time roundStartTimes
  file-print word "Game Start Time: " item (currentRound - 1) roundStartTimes 
  file-print  ""
  

  update-turn-indicators
  update-turn-order
  reset-active
    
end


to listen
  
  while [hubnet-message-waiting?] [
    hubnet-fetch-message    
    ifelse hubnet-enter-message?[
      
      ifelse (member? hubnet-message-source playerNames) [ 
        ;; pre-existing player whose connection cut out
        let newMessage word hubnet-message-source " is back."
        hubnet-broadcast-message newMessage
        
        let currentMessagePosition (position hubnet-message-source playerNames);  0 to 3
        let currentPlayer currentMessagePosition + 1
        send-game-info currentMessagePosition
        if (currentInfoScreen = 1) [
          
          ask scorecards with [identity = "playerName"] [
            hubnet-send-override (item (position currentPlayer playerPosition) playerNames) self "label" [""] 
          ]
          ask patches [
            ;; if ? = player [
            hubnet-clear-override  (item (position currentPlayer playerPosition) playerNames) self "pcolor" 
            ask crops-here [hubnet-clear-override  (item (position currentPlayer playerPosition) playerNames) self "shape"  ]
            ask owners-here [hubnet-clear-override  (item (position currentPlayer playerPosition) playerNames) self "hidden?"  ]
            ;; ]
          ] ;; end ask patches 
          
         stop 
        ]

        
        gray-out-others 
        if (showMoves = "onConfirm" and currentInfoScreen = 0)[
          reveal-confirm
        ]  
        if item currentMessagePosition confirmChoice = 1 [
          ask patches [
            if member? currentPlayer playerAccess [
            ;;if currentPlayer = player [          
              hubnet-send-override  (item (position currentPlayer playerPosition) playerNames) self "pcolor" [item choice confirmedChoiceColors]
            ]
          ]  
        ] 
      ] ;; end previous player re-entering code
      
      
      [ if (length playerNames < 4) [;; new player
        let tempName hubnet-message-source
        let hasHHID position "_" tempName
        let tempID []
        ifelse hasHHID != false [
          set tempID substring tempName (hasHHID + 1) (length tempName)
          set tempName substring tempName 0 hasHHID
          ] [
          set tempID 0
          ]
        set playerShortNames lput tempName playerShortNames
        set playerNames lput hubnet-message-source playerNames
        set playerHHID lput tempID playerHHID
        set numPlayers numPlayers + 1
        set playerPosition lput numPlayers playerPosition
      ]
      ]  ;; end new player code
      
      
    ] ;; end ifelse enter
    
    
    [
      ifelse hubnet-exit-message?
      [
        let newMessage word hubnet-message-source " has left.  Waiting."
        hubnet-broadcast-message newMessage
      ] ;; end ifexit
      
      
      [if inGame = 1 [
        
        let currentMessagePosition (position hubnet-message-source playerNames);  0 to 3
        
        if currentMessagePosition != false [
        let currentPlayer (currentMessagePosition + 1); 1 to 4
        
        if hubnet-message-tag = "View" [
          
          let xPixel ((item 0 hubnet-message) - min-pxcor + 0.5) * patch-size
          let yPixel (max-pycor + 0.5 - (item 1 hubnet-message)) * patch-size
          let xPixMin item 0 confirmPixLoc
          let xPixMax item 0 confirmPixLoc + item 2 confirmPixLoc
          let yPixMin item 1 confirmPixLoc
          let yPixMax item 1 confirmPixLoc + item 3 confirmPixLoc
          ifelse xPixel > xPixMin and xPixel < xPixMax and yPixel > yPixMin and yPixel < yPixMax and (item currentMessagePosition playerCurrentActive = 1) [  ;; player with active turn "clicked"  confirm 
            confirm currentPlayer currentMessagePosition
          ] [ ;; it's not confirm but could be a land change
          ask patches with [pxcor = (round item 0 hubnet-message) and pycor = (round item 1 hubnet-message)][
              if member? currentPlayer playerAccess and item (currentPlayer - 1) confirmChoice = 0 and (item currentMessagePosition playerCurrentActive = 1) [
              ;;if currentPlayer = player and item (player - 1) confirmChoice = 0 [  ;;only change color if it's in the players domain and choices not confirmed
              
              ifelse currentPlayer = usingPlayer and choice = 1 [  ;; the square has been previously selected as this person's farm
                set choice new-choice choice
                set usingPlayer -99   
                
                let farmCount (item currentMessagePosition playerCurrentFarm)  
                set playerCurrentFarm (replace-item currentMessagePosition playerCurrentFarm (farmCount - 1)  )     
              ] [
              
              ifelse choice = 1 [  ;; the square has been previously selected by SOMEONE ELSE as a farm
                
                ;; don't do anything
              ] [
              ;;it is a forest, so if they are below the max, take it as their farm.  otherwise ignore message
              
              let farmCount (item currentMessagePosition playerCurrentFarm)  
              if farmCount < maxFarm [
                set choice new-choice choice
                set usingPlayer currentPlayer  
                set playerCurrentFarm (replace-item currentMessagePosition playerCurrentFarm (farmCount + 1))   
              ]           
              
              ]
              
              ]

                
                set taps taps + 1
                update-crop-image 
              ]
            ]
            ]
        ] ;; end ifelse view
        ] 
      ] 
      ]
    ] 
  ]
  
  
end

to reveal-confirm
 
  ask patches with [pxcor >= 0] [
    foreach playerAccess [
      let tempPlayer ?
    if item (tempPlayer - 1) confirmChoice = 1 [   
    ;;if item (player - 1) confirmChoice = 1 [    
      foreach playerPosition [
        if ? != tempPlayer [
        ;;if ? != player [
          hubnet-send-override  (item (position ? playerPosition) playerNames) self "pcolor" [item choice confirmedChoiceColors]
          ask crops-here [
            hubnet-clear-override  (item (position ? playerPosition) playerNames) self "shape" 
          ]
          ask owners-here [
             hubnet-clear-override  (item (position ? playerPosition) playerNames) self "hidden?" 
           ]
        ]
      ]    
    ]
  ]
  ]
end

to confirm [currentPlayer currentMessagePosition]
 
 if currentInfoScreen > 0 [stop]  ;if we aren't actively in a round, this shouldn't do anything, just exit
 
  set confirmChoice replace-item currentMessagePosition confirmChoice 1
  set playerThinkTimes replace-item currentMessagePosition playerThinkTimes date-and-time
  
  update-active currentPlayer
  
  ask patches with [pxcor >= 0] [
    if member? currentPlayer playerAccess [
      ;;if currentPlayer = player [
      
      hubnet-send-override  (item (position currentPlayer playerPosition) playerNames) self "pcolor" [item choice confirmedChoiceColors]
      if showMoves = "onConfirm" [
        reveal-confirm
      ]
    ]
  ]
  if sum confirmChoice = 4 [ ;; we've completed the turn  
    
    file-print (word "Round " currentRound " Choices")
    file-print ""
    
    ;; write landscape to file
    let currentRow max-pycor
    while [currentRow >= 0] [
      let currentColumn 0
      while [currentColumn < max-pxcor] [
        ;;print (word currentColumn currentRow)
        
        ask (patch currentColumn currentRow) [file-write choice] 
        set currentColumn currentColumn + 1
      ]
      ask patch currentColumn currentRow [file-print (word " " choice)]
      set currentRow currentRow - 1 
    ]
    file-print ""
      
    file-print (word "Round " currentRound " Users")
    file-print ""
    
    ;; write landscape to file
    set currentRow max-pycor
    while [currentRow >= 0] [
      let currentColumn 0
      while [currentColumn < max-pxcor] [
        ;;print (word currentColumn currentRow)
        
        ask (patch currentColumn currentRow) [file-write usingPlayer] 
        set currentColumn currentColumn + 1
      ]
      ask patch currentColumn currentRow [file-print (word " " usingPlayer)]
      set currentRow currentRow - 1 
    ]
    file-print ""
      
    file-print (word "Round " currentRound " Taps")
    file-print ""
    
    ;; write landscape to file
    set currentRow max-pycor
    while [currentRow >= 0] [
      let currentColumn 0
      while [currentColumn < max-pxcor] [
        ;;print (word currentColumn currentRow)
        
        ask (patch currentColumn currentRow) [file-write taps set taps 0] 
        set currentColumn currentColumn + 1
      ]
      ask patch currentColumn currentRow [file-print (word " " taps) set taps 0]
      set currentRow currentRow - 1 
    ]
    file-print ""
    
    file-print (word "Player Turn Order " currentRound ": " playerTurnSequence)
    file-print (word "Player 1 Confirm Time Round " currentRound ": " (item 0 playerThinkTimes))
    file-print (word "Player 2 Confirm Time Round " currentRound ": " (item 1 playerThinkTimes))
    file-print (word "Player 3 Confirm Time Round " currentRound ": " (item 2 playerThinkTimes))
    file-print (word "Player 4 Confirm Time Round " currentRound ": " (item 3 playerThinkTimes))
    file-print ""
     
    update-turn-order

    ;; calculate score
    calculate-score
      
    foreach playerPosition [
      ask scorecards with [identity = "playerName"] [
       hubnet-send-override (item (position ? playerPosition) playerNames) self "label" [""] 
      ]
      ask patches [
        ;; if ? = player [
        hubnet-clear-override  (item (position ? playerPosition) playerNames) self "pcolor" 
        ask crops-here [hubnet-clear-override  (item (position ? playerPosition) playerNames) self "shape" ]
        ask owners-here [hubnet-clear-override  (item (position ? playerPosition) playerNames) self "hidden?" ]
        ask scorecards-here [hubnet-clear-override (item (position ? playerPosition) playerNames) self "label"  ]
        ;; ]
      ] ;; end ask patches 
    ] ;; end foreach player
    
    set currentInfoScreen 1

  ] ;; end if completed turn
  
end

to update-turn-order
  
  
    ;;update turn order for next turn if appropriate
    if turnSequenceMode = 1 [
      
      set playerTurnSequence shuffle [1 2 3 4]
      
    ]
    if turnSequenceMode = 2 [
      
      set playerTurnSequence (list ceiling (random-float 4) ceiling (random-float 4) ceiling (random-float 4) ceiling (random-float 4))
    ]
    
    
end

to-report new-choice [currentChoice]
  
  set currentChoice currentChoice + 1
  if (currentChoice = 2) [set currentChoice 0]

 
  report currentChoice
end

to end-game
  set inGame 0
  file-close
  
  file-open "completedGames.csv"
  file-print gameName
  file-close
end

to clear-board
  set currentRound 0
  ask patches with [pxcor >= 0] [
    set pcolor item choice confirmedChoiceColors
  ]
  ask roundScorePatches [
    foreach playerPosition [
      ask scorecards with [identity = "playerName"] [
        hubnet-clear-override (item (position ? playerPosition) playerNames) self "label" 
      ]
    ]
    ;;ask scorecards-here with [identity = "playerName"] [ set label "" ] 
    ask scorecards-here with [identity = "currentAndFinalScore"] [
      let myScore (item (playerScore - 1) playerScores) 
      set label myScore ;; this only makes sense when domains are defined for one player only
      set label-color black ;;(item (playerScore - 1) ownerColors)
      ask owners-here [set color item ([playerScore - 1] of patch-here) ownerColors set hidden? false]
    ]
    ask scorecards-here with [identity = "playerName" and playerNumber = 1][set label ""]
    ask scorecards-here with [identity = "playerName" and playerNumber = 2][set label ""]
    ask scorecards-here with [identity = "playerName" and playerNumber = 3][set label ""]
    ask scorecards-here with [identity = "playerName" and playerNumber = 4][set label ""]


  ]
  ask crops [die]
  ;ask owners [die]
end


to rand-num-rounds
  set numRounds (random (maxNumRounds - minNumRounds)) + minNumRounds
end

to calculate-score
  
  ;; 0: vegetation
  ;; 1: farm
  
  ask patches [
    
    set currentYield 0 

    set currentPenalty 0
    set currentScore 0
    set currentBonus 0
    set currentESBump 0
    
    
    if choice = 0 [set currentYield forestYield]
    if choice = 1 [
      if-else depleteTurns > 0 [
        set currentYield farmYieldHigh
      ] [ 
      set currentYield farmYieldLow
      ]
      
    ]
    
    
  ] ;; end ask patches set yields
   

  ;; set changes in yield due to habitat effects
  ask patches with [pxcor >= 0] [
    if choice = 0 and restoreTurns = 0 [
      let myX pxcor
      let myY pycor
      let vegNeighbors patches with [(pxcor <= (myX + forestYieldNeighborhood)) and (pxcor >= (myX - forestYieldNeighborhood)) and pycor <= myY + forestYieldNeighborhood and (pycor >= (myY - forestYieldNeighborhood)) and choice = 1]
      
      ;;let vegNeighbors  (patch-set patch-at (myX + 1) (myY) patch-at (myX - 1) (myY) patch-at (myX) (myY + 1) patch-at (myX - 1) (myY) )
      ;;set vegNeighbors vegNeighbors with [choice = 1]
      
      ask vegNeighbors [set currentESBump currentESBump + forestYieldBump] 
      
    ]
  ] ;; end ask patches set habitat benefits

  ;; assign subsidy
  ask patches with [pxcor >= 0] [
    let subsidyShare forestSubsidy / (length playerAccess)
      if (choice = 0 and restoredSubsidyOnlyFlag * restoreTurns = 0) [ set currentBonus subsidyShare ]
  ]
        

  
  
  if (policyTreatment = "T5") [
    
    ask patches with[pxcor >= 0] [
      if choice = 0 and restoredSubsidyOnlyFlag * restoreTurns = 0 [
        let myX pxcor
        let myY pycor
        let aggNeighbors count patches with [(pxcor = (myX + 1))  and (pycor = (myY))  and choice = 0 and pxcor >= 0 and restoredSubsidyOnlyFlag * restoreTurns = 0]
        set aggNeighbors aggNeighbors + count patches with [(pxcor = (myX - 1))  and (pycor = (myY))  and choice = 0 and pxcor >= 0 and restoredSubsidyOnlyFlag * restoreTurns = 0]
        set aggNeighbors aggNeighbors + count patches with [(pxcor = (myX))  and (pycor = (myY - 1))  and choice = 0 and pxcor >= 0 and restoredSubsidyOnlyFlag * restoreTurns = 0]
        set aggNeighbors aggNeighbors + count patches with [(pxcor = (myX))  and (pycor = (myY + 1))  and choice = 0 and pxcor >= 0 and restoredSubsidyOnlyFlag * restoreTurns = 0]

        set currentBonus currentBonus + (aggNeighbors * aggBonus / (length playerAccess))
      ]
    ]  
  ]
  
  
  

  ask patches with [pxcor >= 0] [
    
    ;;worst case for yields less damages should be 0
    set currentYield max list currentYield 0
    
    ;;best case for yields is max yield
    let currentMaxYield 0
    ifelse restoreTurns = 0 [set currentMaxYield maxYieldHigh] [set currentMaxYield maxYieldLow]
    set currentYield min list currentYield currentMaxYield
    set currentESBump min list currentESBump (currentMaxYield - currentYield)
    
  
    
    ;set currentYield round currentYield
    ;set currentPenalty round currentPenalty

    ;set currentBonus round currentBonus
    
    set currentScore (currentYield + currentBonus + currentESBump)
    set currentScore max list currentScore 0
    ask scorecard scoreWho [set label currentScore]

  ]
  
  file-print (word "Round " currentRound " Scoring Summary:")
  file-print ""
  
  foreach playerPosition [
    let tempYields (sum [currentYield] of patches with [usingPlayer = ? and pxcor >= 0])
    
    let landPatches patches with [pxcor >= 0]
    let tempBonuses (sum [currentBonus] of landPatches with [member? ? playerAccess])
    
    let tempESBump (sum [currentESBump] of patches with [usingPlayer = ? and pxcor >= 0])
    
    let tempScore round (tempYields + tempBonuses + tempESBump)
    
    set playerCurrentScores replace-item (? - 1) playerCurrentScores tempScore
    set playerCurrentYield replace-item (? - 1) playerCurrentYield tempYields
    set playerCurrentBonus replace-item (? - 1) playerCurrentBonus tempBonuses
    set playerCurrentESBump replace-item (? - 1) playerCurrentESBump tempESBump
    set playerScores replace-item (? - 1) playerScores (item (? - 1) playerScores + tempScore)
    file-print (word "Player " ? ": Yields " tempYields ", Bonuses " tempBonuses ", ES Bump " tempESBump ", Round Score " tempScore ", Total Score " (item (? - 1) playerScores))
  ]

  file-print ""
end

to send-game-info [currentPosition]
  
  ask scorecards with [identity = "yield"]  [hubnet-send-override (item currentPosition playerNames) self "label" [(item currentPosition playercurrentYield)] ]
  ask scorecards with [identity = "bonus"]  [hubnet-send-override (item currentPosition playerNames) self "label" [(item currentPosition playerCurrentBonus)] ]
  ask scorecards with [identity = "esbump"]  [hubnet-send-override (item currentPosition playerNames) self "label" [(item currentPosition playerCurrentESBump)] ]
  ask scorecards with [identity = "currentScore"]  [hubnet-send-override (item currentPosition playerNames) self "label" [(item currentPosition playerCurrentScores)] ]
  ask scorecards with [identity = "totalScore"]  [hubnet-send-override (item currentPosition playerNames) self "label" [(item currentPosition playerScores)] ]
       
end

to clear-information
  
  if sum confirmChoice = 4 [ ;; only do anything if we are at the end of the round
  ifelse  currentInfoScreen  = 1 [ 
    
    
    ;; clear first info screen, load next
    set currentInfoScreen 2
    ask scorecards with [xcor > -1] [
      set label ""
    ] 
     
     ask owners [set hidden? true]
     
    ask roundScorePatches [
    ;;  let myScore (item (player - 1) playerCurrentScores)    ;;NEED TO REMOVE BEFORE FINISHED!!!!!!
    ;;  ask scorecards-here with [identity = "currentAndFinalScore"] [
    ;;    set label "";; myScore  ;; this only makes sense in games where each player has a quadrant
    ;;  ]
    ;;]
      ask scorecards-here with [identity = "currentAndFinalScore"] [
        let myScore (item (playerScore - 1) playerCurrentScores) 
        set label myScore ;; this only makes sense when domains are defined for one player only
        set label-color black ;;(item (playerScore - 1) ownerColors)
        ask owners-here [set color item ([playerScore - 1] of patch-here) ownerColors set hidden? false]
      ]
    ]
   
       foreach (playerPosition) [
      send-game-info (? - 1)
    ]
        
  ] 
  [ ;; clear 2nd info screen, move into next round
    
    ask roundScorePatches [
      ask scorecards-here [
        set label ""
        ask owners-here [set hidden? true]
      ]
    ]
    
    if inGame = 1 [ ;; haven't ended the game
 
    
  
    
    ;; let player modify screen again...
    set confirmChoice (list 0 0 0 0)
    set currentInfoScreen 0
    
    
    ;;update any other variables
    ifelse currentRound < numRounds [
      set currentRound currentRound + 1
      ask scorecards with [identity = "currentRound"] [set label currentRound] 
      ask patches with [pxcor >= 0] [set previousChoice choice]
      update-patch-status

      update-turn-indicators
      set roundStartTimes lput date-and-time roundStartTimes
      file-print (word "Round " currentRound " Start Time: " item (currentRound - 1) roundStartTimes)
      file-print  ""
      
      
      
    ] [
    end-game
    clear-board
    ]
   
   
    ;;Establish starting conditions for round
   
    ;;SAROBIDY -  USE THIS LINE TO MAKE ROUNDS INDEPENDENT (ALWAYS DEFAULT TO VEGETATION)
    ;;ask patches with [pxcor >= 0] [set choice 0 update-crop-image]
    

    
    ] 
    
     gray-out-others
     reset-active

  ]
  ]
                
end


to update-crop-image
  set pcolor item choice choiceColors
  ask crops-here [
    ifelse choice = 0 [
      set shape "non-crop"
      
      ask owners-here [set hidden? true]
    ] [
      
      set shape "crop-base"
      
      ask owners-here [set color item ([usingPlayer - 1] of patch-here) ownerColors set hidden? false]
    ] 
     
    
  ]
  
  
  ask scorecards-here with [identity = "timeCount"] [

    ifelse choice = 0 [
      ifelse restoreTurns > 0 [
        set label restoreTurns
      ] [
      set label ""
      ]
    ] [
    ;;ifelse depleteTurns > 0 [
      set label depleteTurns
    ;;] [
    ;;set label ""
    ;;]
    
    ] 
    
    set label-color 104
    
      ]  
  

end
to gray-out-others
  
  foreach playerPosition [
    ask patches with [pxcor >= 0] [
      hubnet-clear-override  (item (position ? playerPosition) playerNames) self "pcolor" 
      ask crops-here [hubnet-clear-override  (item (position ? playerPosition) playerNames) self "shape" ]
      ask owners-here [hubnet-clear-override  (item (position ? playerPosition) playerNames) self "hidden?" ]
      if not member? ? playerAccess [
      ;;if ? != player [
        hubnet-send-override  (item (position ? playerPosition) playerNames) self "pcolor" [item previousChoice grayedChoiceColors]
        
 
        ask owners-here [
          
            hubnet-send-override  (item (position ? playerPosition) playerNames) self "hidden?" [true]         
        ]
        
        ask crops-here [
          ifelse previousChoice = 0 [
            hubnet-send-override  (item (position ? playerPosition) playerNames) self "shape" ["non-crop"]
          ] [
          
          hubnet-send-override  (item (position ? playerPosition) playerNames) self "shape" ["crop-base"]           
          ]         
        ]     
      ]
    ]
    ask scorecards with [identity = "playerName"] [
      if ? != playerNumber [
        hubnet-send-override  (item (position ? playerPosition) playerNames) self "label" [(item (position playerNumber playerPosition) playerShortNames)] 
      ]
    ]
    ask scorecards with [identity = "timeCount"] [
      if not member? ? playerAccess [
      ;;if ? != player [
        hubnet-send-override  (item (position ? playerPosition) playerNames) self "label" [""]
      ]      
    ] 
  ]
  
end

to update-patch-status
  
  ask patches with [pxcor >= 0] [
    
    ifelse choice = 0 [ ;; vegetation
      
      let myX pxcor
      let myY pycor
      let vegNeighbors count patches with [(pxcor = (myX + 1))  and (pycor = (myY))  and choice = 0]
      set vegNeighbors vegNeighbors + count patches with [(pxcor = (myX - 1))  and (pycor = (myY))  and choice = 0]
      set vegNeighbors vegNeighbors + count patches with [(pxcor = (myX))  and (pycor = (myY - 1))  and choice = 0]
      set vegNeighbors vegNeighbors + count patches with [(pxcor = (myX))  and (pycor = (myY + 1))  and choice = 0]
      
      set restoreTurns (max list 0 (restoreTurns - 1))
      set restoreTurns (max list 0 (restoreTurns - floor(vegNeighbors * forestRestoreBump)))
      
      if restoreTurns = 0 [
        set depleteTurns  turnsDeplete 
      ]
    ] [  ;; farmland
    
    
    
    
    set depleteTurns (max list 0 (depleteTurns - 1))
     
     if depleteTurns = 0 [
      set restoreTurns turnsRestore 
     ]
    
    ]
    
    update-crop-image
  ]
  
  
end

to reset-active
  
  let currentSequence 0
  set playerCurrentActive (list 0 0 0 0)
  while [not (member? 1 playerCurrentActive) and currentSequence < 5] [
    
    set currentSequence currentSequence + 1
    foreach playerPosition [
      if (item (? - 1) playerTurnSequence = currentSequence) [
        set playerCurrentActive replace-item (? - 1) playerCurrentActive 1
      ] 
    ]
    
  ]
  
  update-turn-indicators
  
  update-colors

end

to update-active [currentPlayer]
  
  let currentSequence item (currentPlayer - 1) playerTurnSequence
  
  ;;if there are no other players in this current step, advance; otherwise just set this player inactive
  set playerCurrentActive replace-item (currentPlayer - 1) playerCurrentActive 0
  while [not (member? 1 playerCurrentActive) and currentSequence < 5] [
  
  set currentSequence currentSequence + 1
  foreach playerPosition [
    if (item (? - 1) playerTurnSequence = currentSequence) [
      set playerCurrentActive replace-item (? - 1) playerCurrentActive 1
    ] 
  ]
  
  ]
  
  update-turn-indicators

  update-colors
    
end

to update-turn-indicators
  
  foreach playerPosition [
   ask actives with [playerNumber = ?] [
    ifelse item (? - 1) playerCurrentActive = 0 [
      set shape "empty-square"
    ] [
    set shape "square"
    ]
   ] 
    
  ]
    
end

to update-colors
  ask patches with [pxcor >= 0] [
    foreach playerPosition [
      
      if member? (?) playerAccess [     ;;update this square for this player, because they have access rights to it
        
        ifelse (item (? - 1) confirmChoice = 1) [ ;; set to confirmed colors
          hubnet-send-override  (item (position (?) playerPosition) playerNames) self "pcolor" [item choice confirmedChoiceColors]
          
        ] [ ifelse (item (? - 1) playerCurrentActive = 0) [ ;; set to non-confirmed, not-active colors
          
          hubnet-send-override  (item (position (?) playerPosition) playerNames) self "pcolor" [item choice inactiveChoiceColors]
        ] [
        hubnet-send-override  (item (position (?) playerPosition) playerNames) self "pcolor" [item choice choiceColors]
        ]
        
        ]
        if showMoves = "onConfirm" [
          reveal-confirm
        ]
      ]
      
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
386
10
1628
713
5
-1
112.0
1
40
1
1
1
0
0
0
1
-5
5
0
5
0
0
1
ticks
30.0

BUTTON
13
17
125
76
Launch Broadcast
startup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
137
17
242
77
Listen Clients
listen
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
15
130
197
163
Clear Information Screen
clear-information
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
273
18
379
63
language
language
"English" "French"
0

BUTTON
14
84
111
117
Start game
set-new-game
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
20
415
365
710
12

@#$#@#$#@
## WHAT IS IT?

NonCropShare is a 4-player coordination game, framed around the provision of insect-based ecosystem services

## HOW IT WORKS

For each square in a player's grid, the player chooses among 4 actions, each with its own costs and benefits:

> 1. Do nothing - costs nothing, and yields baseYield
> 2. Plant non-crop habitat - costs nothing, yields nothing, but gives a bonus to cropped squares in a moore neighborhood of some radius around it
> 3. Do light, targeted spraying - carries a small cost, and brings a small boost to yields in the square
> 4. Do heavy spraying - carries a cost, and brings a big benefit to the square, at the cost of canceling out any non-crop habitat bonuses in and around the square

Depending on the values assigned to yields, costs, and benefits, different equilibria will exist.

## GAME VERSIONS AND PROTOCOLS

Sample game protocols (for framing the game and instructing participants) are available at http://www.ifpri.org/biosight/noncropsharegame.  This site also hosts a stand-alone version of the game in which game parameters can be manipulated from the user interface.  This version of the game is intended for use by enumerators and relies on an input file for game session parameters.

## GAME PARAMETERS

**language:** Select the language for game variables.  For any change to take effect, one client must exit and re-enter (again, the same peculiarity of the bitmap extension).

**gameTag:** Particular tag for game files to indicate particular parts of the experiment.  Right now set for P (practice), 1, 2, or 3


**appendDateTime:** Whether a date and time is appended to the game file name (basically prevents game files from overwriting).

**showMoves:** Whether the decisions of the other players are made visible to players i) when the decision is made, or ii) only at the end of each turn.

**farmX:** Number of grid cells for each farm in the X direction.

**farmY:** Number of grid cells for each farm in the Y direction.

**numRounds:** Number of rounds in the game.

**Randomize numRounds:** When clicked, will randomize the length of the game.  This can be of value to avoid expectations on when the game ends, and any kind of end-of-game play artifacts.

**baseYield:** Yield of the base (no action) choice

**maxYield:** Maximum yield possible for each crop

**heavySprayBlockNeighborhood:** The radius (moore neighborhood) around each heavy-spray cell in which non-crop habitat bonuses are canceled.

**nchYield:** The yield from any non-crop habitat cell.  These aren't crops, so a good interpretation here is a subsidy awarded for each cell set aside as non-crop habitat.

**Randomize nchYield:** When clicked, will randomize the yield (subsidy) of the non-crop habitat.  This is here for experiments that vary subsidy levels.

**nchBoost:** Value of the bonus that non-crop habitat gives to the grid cells around it.

**nchNeighborhood:** The radius (moore neighborhood) around each non-crop habitat cell that receive a bonus.

**lightSprayBoost:** The yield boost gained in the current cell by doing light spraying.

**lightSprayCost:** The cost incurred by choosing light spraying.

**heavySprayBoost:** The yield boost gained in the current cell by doing heavy spraying.

**heavySprayCost:** The cost incurred by choosing heavy spraying.


## GAME START INSTRUCTIONS 

> 1. Log all of your tablets onto the same network.  If you are in the field using a portable router, this is likely to be the only available wifi network.

> 2. Open the game file on your host tablet.  Zoom out until it fits in your screen

> 3. If necessary, change the language setting on the host.

> 4. Click ‘Launch Broadcast’.  This will reset the software, as well as read in the file containing all game settings.  

> 5. Select ‘Mirror 2D view on clients’ on the Hubnet Control Center.  

> 6. Click ‘Listen Clients’ on the main screen.  This tells your tablet to listen for the actions of the client computers.  If there ever are any errors generated by Netlogo, this will turn off.  Make sure you turn it back on after clearing the error.

> 7. Open Hubnet on all of the client computers.  Enter the player names in the client computers, in the form ‘PlayerName_HHID’.   

> 8. If the game being broadcast shows up in the list, select it.  Otherwise, manually type in the server address (shown in ‘Hubnet Control Center’.  With the HooToo Tripmate routers, it should be of the form 10.10.10.X.

> 9. Click ‘Enter’ on each client.

> 10. Back on the host tablet, click ‘Start Game’.  

** A small bug – once you start *EACH* new game, you must have one client exit and re-enter.  For some reason the image files do not load initially, but will load on all client computers once a player has exited and re-entered.  Be sure not to change the player name or number when they re-enter.

Within each game, you will have the responsibility of clearing information screens between rounds once farmers have viewed the score screens:

> 1. At the end of each turn, once players have seen the numbers on their screens and are ready to move on, click ‘Clear Between-round Information Screen’ to advance to the sum scores for each player

> 2. Once players are ready to continue to the next round, click ‘Clear Between-round Information Screen’ again.

> 3. At the end of the game, click through ‘Clear Between-round Information Screen’ until the numbers disappear, to make sure the game file gets saved

## ADAPTING THE GAME

NonCropShare can be customized to different geometries, but caution should be exercised to ensure that the visualization has been correctly adapted.

Additionally, the rules for scoring in the current game are specific to the insect-based ecosystem service application of NonCropShare.  Any rules of interest can be coded in the 'calculate-score' procedure.

## NETLOGO FEATURES

NonCropShare exploits the use of the bitmap extension, agent labeling, and hubnet overrides to get around the limitations of NetLogo's visualization capacities.

In the hubnet client, all actual buttons are avoided.  Instead, the world is extended, with patches to the right of the origin capturing elements of the game play, and patches to the left of the origin being used only to display game messages.

Language support is achieved by porting all in-game text to bitmap images that are loaded into the view.  The location of these images is optimized to a Dell Venue 8 Pro tablet, and will likely need some care if re-sized (it is necessary to think in both patch space and pixel space to place them correctly).  Scores are updated to the labels of invisible agents, whose values are overridden differently for each client.

## CREDITS AND REFERENCES

Earlier and current versions of NonCropShare are available at http://www.ifpri.org/book-735/biosight/noncropsharegame

Please cite any use of NonCropShare as:

Andrew Bell; Zhang, Wei; Bianchi, Felix; and vander Werf, Wopke (2013). NonCropShare – a coordination game for provision of insect-based ecosystem services. IFPRI Biosight Program. http://www.ifpri.org/biosight/noncropsharegame
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

add-money
false
0
Rectangle -10899396 true false 45 75 225 180
Rectangle -16777216 false false 45 75 225 180
Rectangle -10899396 true false 60 90 240 195
Rectangle -16777216 false false 60 90 240 195
Rectangle -10899396 true false 75 105 255 210
Rectangle -16777216 false false 75 105 255 210
Circle -1 true false 123 115 85
Polygon -10899396 true false 141 165 165 188 171 168 191 134 184 134 166 167 162 182 155 163

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

blank
true
0

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

crop-base
false
0
Polygon -10899396 true false 240 285 285 225 285 165
Polygon -10899396 true false 225 285 210 135 180 75 180 240
Polygon -10899396 true false 225 105 240 105 240 285 225 285
Polygon -10899396 true false 90 270 45 60 45 210
Polygon -10899396 true false 105 270 165 180 165 90 120 180
Polygon -10899396 true false 90 60 90 285 105 285 105 60
Circle -1184463 true false 54 54 42
Circle -1184463 true false 99 69 42
Circle -1184463 true false 54 99 42
Circle -1184463 true false 99 114 42
Circle -1184463 true false 54 144 42
Circle -1184463 true false 99 159 42
Circle -1184463 true false 54 189 42
Circle -1184463 true false 84 24 42
Circle -1184463 true false 234 99 42
Circle -1184463 true false 189 114 42
Circle -1184463 true false 204 69 42
Circle -1184463 true false 234 144 42
Circle -1184463 true false 189 159 42
Circle -1184463 true false 234 189 42
Circle -1184463 true false 189 204 42

crop-spray-heavy
false
0
Polygon -10899396 true false 240 285 285 225 285 165
Polygon -10899396 true false 225 285 210 135 180 75 180 240
Polygon -10899396 true false 225 105 240 105 240 285 225 285
Polygon -10899396 true false 90 270 45 60 45 210
Polygon -10899396 true false 105 270 165 180 165 90 120 180
Polygon -10899396 true false 90 60 90 285 105 285 105 60
Circle -1184463 true false 54 54 42
Circle -1184463 true false 99 69 42
Circle -1184463 true false 54 99 42
Circle -1184463 true false 99 114 42
Circle -1184463 true false 54 144 42
Circle -1184463 true false 99 159 42
Circle -1184463 true false 54 189 42
Circle -1184463 true false 84 24 42
Circle -1184463 true false 234 99 42
Circle -1184463 true false 189 114 42
Circle -1184463 true false 204 69 42
Circle -1184463 true false 234 144 42
Circle -1184463 true false 189 159 42
Circle -1184463 true false 234 189 42
Circle -1184463 true false 189 204 42
Circle -2674135 true false 15 135 30
Circle -2674135 true false 45 105 30
Circle -2674135 true false 90 90 30
Circle -2674135 true false 90 180 30
Circle -2674135 true false 180 30 30
Circle -2674135 true false 45 165 30
Circle -2674135 true false 135 15 30
Circle -2674135 true false 255 135 30
Circle -2674135 true false 180 90 30
Circle -2674135 true false 135 195 30
Circle -2674135 true false 45 60 30
Circle -2674135 true false 60 210 30
Circle -2674135 true false 225 165 30
Circle -2674135 true false 90 30 30
Circle -2674135 true false 75 135 30
Circle -2674135 true false 90 240 30
Circle -2674135 true false 135 75 30
Circle -2674135 true false 225 105 30
Circle -2674135 true false 135 135 30
Circle -2674135 true false 195 135 30
Circle -2674135 true false 210 210 30
Circle -2674135 true false 180 180 30
Circle -2674135 true false 225 60 30
Circle -2674135 true false 180 240 30
Circle -2674135 true false 135 255 30

crop-spray-light
false
0
Polygon -10899396 true false 240 285 285 225 285 165
Polygon -10899396 true false 225 285 210 135 180 75 180 240
Polygon -10899396 true false 225 105 240 105 240 285 225 285
Polygon -10899396 true false 90 270 45 60 45 210
Polygon -10899396 true false 105 270 165 180 165 90 120 180
Polygon -10899396 true false 90 60 90 285 105 285 105 60
Circle -1184463 true false 54 54 42
Circle -1184463 true false 99 69 42
Circle -1184463 true false 54 99 42
Circle -1184463 true false 99 114 42
Circle -1184463 true false 54 144 42
Circle -1184463 true false 99 159 42
Circle -1184463 true false 54 189 42
Circle -1184463 true false 84 24 42
Circle -1184463 true false 234 99 42
Circle -1184463 true false 189 114 42
Circle -1184463 true false 204 69 42
Circle -1184463 true false 234 144 42
Circle -1184463 true false 189 159 42
Circle -1184463 true false 234 189 42
Circle -1184463 true false 189 204 42
Circle -2674135 true false 90 90 30
Circle -2674135 true false 90 180 30
Circle -2674135 true false 135 195 30
Circle -2674135 true false 180 90 30
Circle -2674135 true false 135 75 30
Circle -2674135 true false 195 135 30
Circle -2674135 true false 135 135 30
Circle -2674135 true false 75 135 30
Circle -2674135 true false 180 180 30

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

elephant
false
2
Polygon -7500403 true false 70 102 83 92 135 94 163 99 173 139 169 168 121 175 84 179 68 164 63 138 66 117 71 101
Polygon -7500403 true false 81 155 60 211 78 211 95 166 104 208 121 208 109 154
Polygon -7500403 true false 169 148 185 209 167 210 155 161 152 208 137 208 145 148
Circle -7500403 true false 161 78 45
Polygon -7500403 true false 185 119 160 133 161 109
Polygon -7500403 true false 204 99 225 139 221 156 212 154 215 140 193 110
Circle -1 true false 181 91 14
Circle -16777216 true false 188 97 4
Polygon -7500403 true false 183 84 176 61 159 58 138 69 135 80 136 110 153 128 173 108
Line -16777216 false 134 92 140 115
Line -16777216 false 140 117 154 126
Line -16777216 false 157 126 164 95

empty-square
false
0
Polygon -7500403 true true 0 0 0 300 300 300 300 0 15 0 15 15 285 15 285 285 15 285 15 15 15 0

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

farm-cheat
false
0
Rectangle -10899396 true false 0 150 300 300
Circle -16777216 true false 167 68 12
Polygon -13840069 true false 225 225 240 30 240 210
Polygon -13840069 true false 240 210 225 30 225 165
Polygon -13840069 true false 270 195 255 45 255 150
Polygon -13840069 true false 255 210 285 15 270 195
Polygon -13840069 true false 105 270 105 15 90 225
Polygon -13840069 true false 105 270 135 90 90 225
Polygon -13840069 true false 163 277 163 22 178 22 178 277
Circle -1184463 true false 141 19 30
Circle -1184463 true false 170 40 30
Circle -1184463 true false 141 58 30
Circle -1184463 true false 170 78 30
Circle -1184463 true false 143 98 30
Circle -1184463 true false 169 120 30
Circle -1184463 true false 142 139 30
Circle -1184463 true false 169 159 30
Circle -1184463 true false 144 181 30
Circle -1184463 true false 172 198 30
Polygon -13840069 true false 169 251 124 5 143 208
Polygon -13840069 true false 223 199 215 90 189 217
Polygon -13840069 true false 175 258 226 193 171 229
Polygon -13840069 true false 58 277 58 22 73 22 73 277
Circle -1184463 true false 66 19 30
Circle -1184463 true false 39 42 30
Circle -1184463 true false 66 64 30
Circle -1184463 true false 38 84 30
Circle -1184463 true false 60 111 30
Circle -1184463 true false 42 144 30
Polygon -13840069 true false 74 244 7 99 64 164
Polygon -13840069 true false 74 244 109 29 64 164
Polygon -2674135 true false 0 0 0 300 300 300 300 0 15 0 15 15 285 15 285 285 15 285 15 45 15 0
Polygon -2674135 true false 285 0 0 285 15 300 300 15

farm-cull
false
1
Polygon -1184463 true false 45 210 30 135
Line -16777216 false 45 15 45 270
Line -16777216 false 45 270 30 285
Line -16777216 false 45 270 60 285
Line -16777216 false 105 15 105 255
Line -16777216 false 105 255 90 270
Line -16777216 false 105 255 120 270
Line -16777216 false 195 30 195 270
Line -16777216 false 195 270 180 285
Line -16777216 false 195 270 210 285
Line -16777216 false 255 15 255 225
Line -16777216 false 255 225 240 240
Line -16777216 false 255 225 270 240
Polygon -10899396 true false 38 89 19 65 33 78 36 69 46 59 49 72 44 80 56 69
Polygon -10899396 true false 50 153 31 129 45 142 48 133 58 123 61 136 56 144 68 133
Polygon -10899396 true false 40 212 21 188 35 201 38 192 48 182 51 195 46 203 58 192
Polygon -10899396 true false 110 220 91 196 105 209 108 200 118 190 121 203 116 211 128 200
Polygon -10899396 true false 101 136 82 112 96 125 99 116 109 106 112 119 107 127 119 116
Polygon -10899396 true false 109 55 90 31 104 44 107 35 117 25 120 38 115 46 127 35
Polygon -10899396 true false 189 143 170 119 184 132 187 123 197 113 200 126 195 134 207 123
Polygon -10899396 true false 200 82 181 58 195 71 198 62 208 52 211 65 206 73 218 62
Polygon -10899396 true false 199 247 180 223 194 236 197 227 207 217 210 230 205 238 217 227
Polygon -10899396 true false 203 184 184 160 198 173 201 164 211 154 214 167 209 175 221 164
Polygon -10899396 true false 260 105 241 81 255 94 258 85 268 75 271 88 266 96 278 85
Polygon -10899396 true false 263 202 244 178 258 191 261 182 271 172 274 185 269 193 281 182
Polygon -10899396 true false 251 45 232 21 246 34 249 25 259 15 262 28 257 36 269 25
Polygon -7500403 true false 30 180 30 120 105 135 285 135 285 150 165 150 165 165 105 165 30 195

farm-land
false
0
Polygon -1184463 true false 45 210 30 135
Line -16777216 false 45 15 45 270
Line -16777216 false 45 270 30 285
Line -16777216 false 45 270 60 285
Line -16777216 false 105 15 105 255
Line -16777216 false 105 255 90 270
Line -16777216 false 105 255 120 270
Line -16777216 false 195 30 195 270
Line -16777216 false 195 270 180 285
Line -16777216 false 195 270 210 285
Line -16777216 false 255 15 255 225
Line -16777216 false 255 225 240 240
Line -16777216 false 255 225 270 240
Polygon -10899396 true false 38 89 19 65 33 78 36 69 46 59 49 72 44 80 56 69
Polygon -10899396 true false 50 153 31 129 45 142 48 133 58 123 61 136 56 144 68 133
Polygon -10899396 true false 40 212 21 188 35 201 38 192 48 182 51 195 46 203 58 192
Polygon -10899396 true false 110 220 91 196 105 209 108 200 118 190 121 203 116 211 128 200
Polygon -10899396 true false 101 136 82 112 96 125 99 116 109 106 112 119 107 127 119 116
Polygon -10899396 true false 109 55 90 31 104 44 107 35 117 25 120 38 115 46 127 35
Polygon -10899396 true false 189 143 170 119 184 132 187 123 197 113 200 126 195 134 207 123
Polygon -10899396 true false 200 82 181 58 195 71 198 62 208 52 211 65 206 73 218 62
Polygon -10899396 true false 199 247 180 223 194 236 197 227 207 217 210 230 205 238 217 227
Polygon -10899396 true false 203 184 184 160 198 173 201 164 211 154 214 167 209 175 221 164
Polygon -10899396 true false 260 105 241 81 255 94 258 85 268 75 271 88 266 96 278 85
Polygon -10899396 true false 263 202 244 178 258 191 261 182 271 172 274 185 269 193 281 182
Polygon -10899396 true false 251 45 232 21 246 34 249 25 259 15 262 28 257 36 269 25

farm-scare
false
0
Polygon -1184463 true false 45 210 30 135
Line -16777216 false 45 15 45 270
Line -16777216 false 45 270 30 285
Line -16777216 false 45 270 60 285
Line -16777216 false 105 15 105 255
Line -16777216 false 105 255 90 270
Line -16777216 false 105 255 120 270
Line -16777216 false 195 30 195 270
Line -16777216 false 195 270 180 285
Line -16777216 false 195 270 210 285
Line -16777216 false 255 15 255 225
Line -16777216 false 255 225 240 240
Line -16777216 false 255 225 270 240
Polygon -10899396 true false 38 89 19 65 33 78 36 69 46 59 49 72 44 80 56 69
Polygon -10899396 true false 50 153 31 129 45 142 48 133 58 123 61 136 56 144 68 133
Polygon -10899396 true false 40 212 21 188 35 201 38 192 48 182 51 195 46 203 58 192
Polygon -10899396 true false 110 220 91 196 105 209 108 200 118 190 121 203 116 211 128 200
Polygon -10899396 true false 101 136 82 112 96 125 99 116 109 106 112 119 107 127 119 116
Polygon -10899396 true false 109 55 90 31 104 44 107 35 117 25 120 38 115 46 127 35
Polygon -10899396 true false 189 143 170 119 184 132 187 123 197 113 200 126 195 134 207 123
Polygon -10899396 true false 200 82 181 58 195 71 198 62 208 52 211 65 206 73 218 62
Polygon -10899396 true false 199 247 180 223 194 236 197 227 207 217 210 230 205 238 217 227
Polygon -10899396 true false 203 184 184 160 198 173 201 164 211 154 214 167 209 175 221 164
Polygon -10899396 true false 260 105 241 81 255 94 258 85 268 75 271 88 266 96 278 85
Polygon -10899396 true false 263 202 244 178 258 191 261 182 271 172 274 185 269 193 281 182
Polygon -10899396 true false 251 45 232 21 246 34 249 25 259 15 262 28 257 36 269 25
Polygon -2674135 true false 60 120 60 180 120 195 165 240 165 60 120 105
Polygon -2674135 true false 178 74 256 24 256 36 179 83
Polygon -2674135 true false 184 105 252 91 252 108 185 115
Polygon -2674135 true false 187 154 253 159 253 173 188 164
Polygon -2674135 true false 191 207 254 229 254 243 189 213

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

goose
false
1
Polygon -16777216 true false 112 149 113 213 103 214 136 228 127 218 136 218 132 212 152 212 117 206 115 151
Polygon -16777216 true false 180 60 225 75 180 90
Circle -1 true false 144 54 42
Polygon -1 true false 163 81 163 141 103 186 58 171 43 141 73 126 133 126 163 81
Circle -16777216 true false 167 68 12
Polygon -16777216 true false 96 168 97 232 87 233 120 247 111 237 120 237 116 231 136 231 101 225 99 170
Polygon -7500403 true false 131 134 71 164 26 149 11 119 86 119

goose-brown
false
1
Polygon -6459832 true false 112 149 113 213 103 214 136 228 127 218 136 218 132 212 152 212 117 206 115 151
Polygon -6459832 true false 180 60 225 75 180 90
Circle -1 true false 144 54 42
Polygon -1 true false 163 81 163 141 103 186 58 171 43 141 73 126 133 126 163 81
Circle -16777216 true false 167 68 12
Polygon -6459832 true false 96 168 97 232 87 233 120 247 111 237 120 237 116 231 136 231 101 225 99 170
Polygon -7500403 true false 131 134 71 164 26 149 11 119 86 119

goose-cheat
false
0
Rectangle -10899396 true false 0 150 300 300
Polygon -6459832 true false 112 149 113 213 103 214 136 228 127 218 136 218 132 212 152 212 117 206 115 151
Polygon -6459832 true false 180 60 225 75 180 90
Circle -1 true false 144 54 42
Polygon -1 true false 163 81 163 141 103 186 58 171 43 141 73 126 133 126 163 81
Circle -16777216 true false 167 68 12
Polygon -6459832 true false 96 168 97 232 87 233 120 247 111 237 120 237 116 231 136 231 101 225 99 170
Polygon -13840069 true false 225 225 240 30 240 210
Polygon -13840069 true false 240 210 225 30 225 165
Polygon -13840069 true false 270 195 255 45 255 150
Polygon -13840069 true false 255 210 285 15 270 195
Polygon -13840069 true false 225 255 210 105 210 210
Polygon -13840069 true false 285 255 285 90 270 210
Polygon -13840069 true false 255 270 255 15 240 225
Polygon -13840069 true false 30 240 30 -15 15 195
Polygon -13840069 true false 30 225 60 45 15 180
Polygon -6459832 true false 131 134 71 164 26 149 11 119 86 119
Polygon -2674135 true false 15 0 15 285 285 285 285 15 15 15 15 0 300 0 300 300 0 300 0 0

goose-habitat
false
0
Polygon -13840069 true false 225 225 240 30 240 210
Polygon -13840069 true false 240 210 225 30 225 165
Polygon -13840069 true false 270 195 255 45 255 150
Polygon -13840069 true false 255 210 285 15 270 195
Polygon -13840069 true false 225 270 210 120 210 225
Polygon -13840069 true false 285 255 285 90 270 210
Polygon -13840069 true false 255 270 255 15 240 225
Polygon -13840069 true false 45 45 24 26 40 35 32 21 48 13 49 31 67 7 67 25 54 35 84 36 54 43
Polygon -13840069 true false 157 199 136 180 152 189 144 175 160 167 161 185 179 161 179 179 166 189 196 190 166 197
Polygon -13840069 true false 72 241 51 222 67 231 59 217 75 209 76 227 94 203 94 221 81 231 111 232 81 239
Polygon -13840069 true false 72 196 51 177 67 186 59 172 75 164 76 182 94 158 94 176 81 186 111 187 81 194
Polygon -13840069 true false 122 151 101 132 117 141 109 127 125 119 126 137 144 113 144 131 131 141 161 142 131 149
Polygon -13840069 true false 163 64 142 45 158 54 150 40 166 32 167 50 185 26 185 44 172 54 202 55 172 62
Circle -10899396 true false 24 84 42
Circle -10899396 true false 90 90 30
Circle -10899396 true false 75 45 30
Polygon -16777216 false false 60 120 45 135 45 150 60 135 60 150 75 120 90 150 90 135 105 135 90 120
Circle -10899396 true false 41 56 67

goose-habitat-cheat
false
0
Polygon -2674135 true false 225 225 240 30 240 210
Polygon -2674135 true false 240 210 225 30 225 165
Polygon -2674135 true false 270 195 255 45 255 150
Polygon -2674135 true false 255 210 285 15 270 195
Polygon -2674135 true false 225 270 210 120 210 225
Polygon -2674135 true false 285 255 285 90 270 210
Polygon -2674135 true false 255 270 255 15 240 225
Polygon -2674135 true false 45 45 24 26 40 35 32 21 48 13 49 31 67 7 67 25 54 35 84 36 54 43
Polygon -2674135 true false 157 199 136 180 152 189 144 175 160 167 161 185 179 161 179 179 166 189 196 190 166 197
Polygon -2674135 true false 72 241 51 222 67 231 59 217 75 209 76 227 94 203 94 221 81 231 111 232 81 239
Polygon -2674135 true false 72 196 51 177 67 186 59 172 75 164 76 182 94 158 94 176 81 186 111 187 81 194
Polygon -2674135 true false 122 151 101 132 117 141 109 127 125 119 126 137 144 113 144 131 131 141 161 142 131 149
Polygon -2674135 true false 163 64 142 45 158 54 150 40 166 32 167 50 185 26 185 44 172 54 202 55 172 62

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

non-crop
false
0
Polygon -6459832 true false 180 255 120 195 135 195 165 225 135 135 150 150 165 210 195 105 210 120 180 195 210 165 210 180 180 210
Polygon -6459832 true false 60 210 105 255 75 120 60 120 90 225 60 195
Circle -10899396 true false 26 86 67
Circle -10899396 true false 116 101 67
Circle -10899396 true false 163 58 92
Circle -10899396 true false 45 180 30
Circle -10899396 true false 99 159 42
Circle -10899396 true false 195 150 30
Circle -10899396 true false 146 176 67
Polygon -13840069 true false 135 255 105 45 75 30 105 105 135 255
Polygon -13840069 true false 255 240 270 60 240 30 240 240
Polygon -13840069 true false 135 255 45 60 30 45 120 240
Polygon -13840069 true false 135 255 45 15 60 15 120 210
Polygon -6459832 true false 195 105 165 30 180 90 135 75 180 105
Circle -10899396 true false 144 9 42
Circle -10899396 true false 120 60 30

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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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

take-money
false
0
Rectangle -2674135 true false 45 75 225 180
Rectangle -16777216 false false 45 75 225 180
Rectangle -2674135 true false 60 90 240 195
Rectangle -16777216 false false 60 90 240 195
Rectangle -2674135 true false 75 105 255 210
Rectangle -16777216 false false 75 105 255 210
Circle -1 true false 123 115 85
Polygon -2674135 true false 141 137 148 137 189 178 179 178
Polygon -2674135 true false 179 140 169 140 143 178 148 178

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
4
10
1255
681
0
0
0
1
1
1
1
1
0
1
1
1
-5
5
0
5

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
1
@#$#@#$#@
