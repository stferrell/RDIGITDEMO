000100211015**free
000200240425
000300211026// This program uses systools.httpgetclob api to request the api.weather.gov alerts
000400211026// for the requested state. It is a work in progress to demo.
000401260427// Add a comment for eGit demo
000402260428// And another one
000500240425
000600240425ctl-opt dftactgrp(*no) actgrp('RDI') option( *srcstmt: *nodebugio: *noxref ) ccsid(*CHAR:37);
000700211021
000800211117dcl-c API_WEATHER_GOV 'https://api.weather.gov/alerts/active?area=';
000900211117dcl-c DFTSTATE 'MN';
001000220816// SQL state empty flag
001100220816dcl-c EMPTY '00000';
001200220816dcl-c LF X'25';
001300211117dcl-c NEW_STATE 'Enter a new state, or check back later for events in your state.';
001400211117dcl-c NO_EVENTS_FOUND 'No events found for your state';
001500211117dcl-c SPACE X'40';
001600211117dcl-c SPLAT X'5C';
001700211025
001800211025// This is the file defintion for demo5ds and it's indata area
001900211025dcl-f demo5ds workstn indds(inDS) sfile(SFLREC:EVRRN) usropn;
002000211110
002100230905// Ones like this mess with iDoc. Need to fix this! (IE, delete this comment.)
002200211110dcl-pi *n;
002300211110  pState char(2);
002400211110end-pi;
002500211025
002600211117/copy demos,demo5inds
002700211025
002800211020// Get our program name
002900211020dcl-ds pgmDS psds qualified;
003000211020  ProgramName *proc;
003100211020end-ds;
003200211020
003300211015// This is a program call to SYSTOOLS.HTTPGETCLOB to the NOA weather service
003400211015// API https://api.weather.gov/alerts/active?area=MN
003500211019// It will dsply the alerts for FLDSTATE
003600211015
003700211015dcl-ds alerts qualified;
003800211015  event    varchar(256);
003900211015  headline varchar(1024);
004000211015  desc     varchar(1024);
004100211015END-DS;
004200211019
004300211021dcl-ds alertArray likeds(alerts) dim(100);
004400211021dcl-s api char(128);
004500211019dcl-s SBSTATE like(FLDSTATE);
004600211015dcl-s len int(10);
004700211019dcl-s index  int(10);
004800211018dcl-s evSize int(10);
004900211022dcl-s nSize  int(10);
005000211018dcl-s tempVar like(alerts.desc);
005100211021dcl-s STATE char(14) CTDATA Dim(50);
005200211021dcl-s ABBR  char(2)  CTDATA Dim(50);
005300250529dcl-s indicator   int(10);
005400211015
005500211021// Initialize
005600211110initialize();
005700211021
005800211021// Set our subfile state
005900211022initSubfileData();
006000211019
006100211020// Load the array with weather events
006200211020loadData();
006300211021
006400211021// Clear the subfile here
006500211021clearSubfile();
006600211018
006700211021// Load the subfile data now
006800211021loadSubfile();
006900211018
007000250529// Set our *IN03 off so our loop works below
007100250529setupExit();
007200211021
007300211108// Start of our main program loop. We will
007400211108mainProcess();
007500211018
007600211021// Clean up by closing the screen file if it's open
007700211021cleanup();
007800211021
007900211015return;
008000211015
008100211020
008200211020// --------------------------------------------------
008300211020// Procedure name: loadData
008400211020// Purpose:        Load the array with weather events
008500211020// Returns:
008600211020// --------------------------------------------------
008700211020dcl-proc loadData;
008800230426  // Local fields
008900211021  index = 0;
009000211021  clear alertArray;
009100211020
009200211020  // Load the array with weather events
009300211020  // 'https://api.weather.gov/alerts/active?area=CO'
009400211110  Exec Sql
009500250529    Declare WeatherEvents Cursor For
009600211021
009700211110      Select X.Event,
009800211110             X.Headline,
009900211110             X.Desc
010000211110        From Json_Table (Systools.Httpgetclob(:Api, Null), '$.features[*]' Columns (
010100211110           Event Char(256) Path '$.properties.event',
010200211110           Headline Char(1024) Path '$.properties.headline',
010300211110           Desc Char(1024) Path '$.properties.description')) As X;
010400211020
010500211110  Exec Sql
010600250529    Open WeatherEvents;
010700211020
010800211110  Exec Sql
010900250529    Fetch Next From WeatherEvents
011000211110      Into :Alerts;
011100211020
011200230426
011300220816  dow SQLSTATE = EMPTY;
011400211020    index = index+1;
011500211022    alertArray(index).event    = alerts.event;
011600211021    alertArray(index).headline = alerts.headline;
011700211022    alertArray(index).desc     = alerts.desc;
011800211110    Exec Sql
011900250529      Fetch Next From WeatherEvents
012000211110        Into :Alerts;
012100211123  enddo;
012200240524
012300240524
012400211110  Exec Sql
012500250529    Close WeatherEvents;
012600211020
012700211020  return;
012800211020end-proc;
012900211021
013000211021// --------------------------------------------------
013100211021// Procedure name: loadSubfile
013200211021// Purpose:        Load the subfile data now
013300211021// Returns:
013400211021// --------------------------------------------------
013500211021dcl-proc loadSubfile;
013600211021  // Local fields
013700211021  index = 0;
013800250827
013900250827  // Set our new max records
014000250827  EVMXREC = len;
014100250827
014200211021  // Load the subfile data now
014300211021  dow (index < len);
014400211021    index = index + 1;
014500211022    EVRRN    = index;
014600211022    EVHEADLN = %subst(alertArray(index).headline: 1: nSize);
014700211022    tempVar  = %subst(alertArray(index).desc: 1 : evSize);
014800211021    // Replace all <cr><lf> with spaces
014900211025    tempVar  = %Xlate(LF:SPACE:tempVar);
015000211021    // Now replace * with spaces
015100211022    tempVar  = %Xlate(SPLAT:SPACE:tempVar);
015200211022    // Now trim
015300211022    EVDESC   = %trim(tempVar);
015400211021    write SFLREC;
015500211021  enddo;
015600211021
015700211021  inDs.dsplay = (len > 0);
015800211022  // If we are empty let the user know
015900211022  if (inDs.dsplay = *off);
016000211022    EVRRN = 1;
016100250827    EVMXREC = 1;
016200211026    EVHEADLN = NO_EVENTS_FOUND;
016300211026    EVDESC   = NEW_STATE;
016400211022    write SFLREC;
016500211022    inDs.dsplay = *on;
016600211022  endif;
016700211021
016800211021  return;
016900211021end-proc;
017000211021
017100211021// --------------------------------------------------
017200211022// Procedure name: initSubfileData
017300211021// Purpose:        Set our subfile state
017400211021// Returns:
017500211021// --------------------------------------------------
017600211022dcl-proc initSubfileData;
017700211021  // Local fields
017800211021
017900211021  // Set our subfile state
018000211021  SBSTATE = FLDSTATE;
018100250529  indicator = %lookup(FLDSTATE: ABBR);
018200250529  if (indicator > 0);
018300250529    SFSTATE = STATE(indicator);
018400211021  endif;
018500211021  api = '' + API_WEATHER_GOV + SBSTATE + '';
018600211021
018700211021  return;
018800211025end-proc;
018900211021
019000211021// --------------------------------------------------
019100211021// Procedure name: clearSubfile
019200211021// Purpose:        Load the subfile here
019300211021// Returns:
019400211021// --------------------------------------------------
019500211021dcl-proc clearSubfile;
019600211021  // Local fields
019700211021
019800211021  // Load the subfile here
019900211021  inDS.dspctl = *off;
020000211021  inDS.dsplay = *off;
020100211021  write SFLCTRL;
020200211021  inDS.dspctl = *on;
020300211021  len = index;
020400211022
020500211021  return;
020600211021end-proc;
020700211021
020800211021// --------------------------------------------------
020900211021// Procedure name: init
021000211021// Purpose:        Initialize
021100211021// Returns:
021200211021// --------------------------------------------------
021300211110dcl-proc initialize;
021400211021  // Local fields
021500211021
021600211021  // Initialize
021700211021  // Open the display file
021800211021  open demo5ds;
021900211021
022000211021  // Clear the sql control area
022100211021  clear SQLCA;
022200211021
022300211021  // One time settings
022400211021  PGMNAME  = pgmDS.ProgramName;
022500211110  if (pState = '  ');
022600211110    pState = DFTSTATE;
022700211110  endif;
022800211110
022900211110  FLDSTATE = pState;
023000211022  nSize  = %len(EVHEADLN);
023100211022  evSize = %len(EVDESC);
023200211021
023300211021  return;
023400211021end-proc;
023500211021
023600211021// --------------------------------------------------
023700211021// Procedure name: cleanup
023800211021// Purpose:        Clean up by closing the screen file if it's open
023900211021// Returns:
024000211021// --------------------------------------------------
024100211021dcl-proc cleanup;
024200211021  // Local fields
024300211021
024400211021  // Clean up by closing the screen file if it's open
024500211021  if %open(demo5ds);
024600211021    close demo5ds;
024700211021  endif;
024800211021
024900211021  return;
025000211021end-proc;
025100211108
025200211108// --------------------------------------------------
025300211108// Procedure name: mainProcess
025400211108// Purpose:        Start of our main program loop. We will
025500211108// Returns:
025600211108// --------------------------------------------------
025700211108dcl-proc mainProcess;
025800211108  // Local fields
025900211108
026000211108  // Start of our main program loop. We will
026100211108  // loop until *IN03 - exit is encounted.
026200211108  dow (inDS.exit = *off);
026300211108    write FOOTER;
026400211108    exfmt SFLCTRL;
026500211108    if (inDS.refresh = *on OR FLDSTATE <> SBSTATE);
026600211108      // Set our subfile state
026700211108      initSubfileData();
026800211108      // Reload data here
026900211108      loadData();
027000211108
027100211108      // Clear the subfile here
027200211108      clearSubfile();
027300211108
027400211108      // Load the subfile data now
027500211108      loadSubfile();
027600211108
027700211108    endif;
027800211108  enddo;
027900211108
028000211108  return;
028100211108end-proc;
028200250529
028300250529// --------------------------------------------------
028400250529// Procedure name: setupExit
028500250529// Purpose:        Set our *IN03 off so our loop works below
028600250529// Returns:
028700250529// --------------------------------------------------
028800250529dcl-proc setupExit;
028900250529  // Local fields
029000250529
029100250529  // Set our *IN03 off so our loop works below
029200250529  inDS.exit = *off;
029300250529
029400250529  return;
029500250529end-proc;
029600250529
029700250529**CTDATA STATE
029800211019Alabama
029900211019Alaska
030000211019Arizona
030100211019Arkansas
030200211019California
030300211019Colorado
030400211019Conneticut
030500211019Delaware
030600211019Florida
030700211019Georgia
030800211019Hawaii
030900211019Idaho
031000211019Illinois
031100211019Indiana
031200211019Iowa
031300211019Kansas
031400211019Kentucky
031500211019Louisiana
031600211019Maine
031700211019Maryland
031800211019Massachusetts
031900250529Michigan
032000211019Minnesota
032100211019Mississippi
032200211019Missouri
032300211019Montana
032400211019Nebraska
032500211019Nevada
032600211019New Hampshire
032700211019New Jersey
032800211019New Mexico
032900211019New York
033000211019North Carolina
033100211019North Dakota
033200211019Ohio
033300211019Oklahoma
033400211019Oregon
033500211019Pennsylvania
033600211019Rhode Island
033700211019South Carolina
033800211019South Dakota
033900211019Tennessee
034000211019Texas
034100211019Utah
034200211019Vermont
034300211019Virginia
034400211019Washington
034500211019West Virginia
034600211019Wisconsin
034700211019Wyoming
034800211019**CTDATA ABBR
034900211019AL
035000211019AK
035100211019AZ
035200211019AR
035300211019CA
035400211019CO
035500211019CT
035600211019DE
035700211019FL
035800211019GA
035900211019HI
036000211019ID
036100211019IL
036200211019IN
036300211019IA
036400211019KS
036500211019KY
036600211019LA
036700211019ME
036800211019MD
036900211019MA
037000250529MI
037100211019MN
037200211019MS
037300211019MO
037400211019MT
037500211019NE
037600211019NV
037700211019NH
037800211019NJ
037900211019NM
038000211019NY
038100211019NC
038200211019ND
038300211019OH
038400211019OK
038500211019OR
038600211019PA
038700211019RI
038800211019SC
038900211019SD
039000211019TN
039100211019TX
039200211019UT
039300211019VT
039400211019VA
039500211019WA
039600211019WV
039700211019WI
039800211019WY
