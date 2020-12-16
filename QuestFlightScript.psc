Scriptname FWR:QuestFlightScript extends Quest

Group Flight_Variables
	int Property iTimeHop Auto
	int Property iCSRMode Auto
	{Type of CSR interaction}
	int Property iCSRCount Auto
	{Tracks number of controls pressed by player}
	int Property iCSRControl Auto
	{Designated control to be pressed}
	int Property iMaxControls Auto
	{Number of available controls to choose from}
	int Property iFlightSpeed Auto
	float Property fFlightTime Auto
	float Property fFuelSpent Auto
	float Property fShakeAmount Auto
EndGroup

Group Flight_Event_Variables
	int Property iCSREvent Auto
	int[] Property iProtocolVortexWinds Auto
	int[] Property iProtocolGravLens Auto
	int[] Property iProtocolMonoTurb Auto
	int[] Property iProtocolJunkCluster Auto
	int[] Property iProtocolTimeEddy Auto
	int[] Property iProtocolCourseDrift Auto
	int[] Property iProtocolChrononSpike Auto
	int[] Property iProtocolFaunaAttack Auto
	int[] Property iProtocolArtronCloud Auto
	int[] Property iProtocolSubTunnel Auto
	int[] Property iProtocolHuonStream Auto
EndGroup

Group Flight_Combat_Variables
	int Property iCSREnemy Auto
	int Property iCSRAction Auto
	int Property iCSREnemyAction Auto
	bool Property bPlayerTurn Auto
	bool Property bPlayerEvade Auto
	Ship Property Enemy Auto
	Ship[] Property EnemyTemplates Auto
EndGroup

Group Resources
	Sound Property fwrSoundTardisLaunch Auto Const
	Sound Property fwrSoundTardisLaunchFast Auto Const
	Sound Property fwrSoundTardisLaunchFail Auto Const
	Sound Property fwrSoundTardisLand Auto Const
	Sound Property fwrSoundTardisLandFast Auto Const
	Sound Property fwrSoundTardisFlight Auto Const
	Sound Property fwrSoundTardisFlightStable Auto Const
	Sound Property fwrSoundTardisCrash Auto Const
	Sound Property UITerminalPasswordGood Auto Const
	Sound Property UITerminalPasswordBad Auto Const
	Sound Property fwrSoundFXVortexWinds Auto Const
	Sound Property fwrSoundFXGravityLens Auto Const
	Sound Property fwrSoundFXSonar Auto Const
	Sound Property fwrSoundFXTimeEddy Auto Const
	Sound Property fwrSoundFXChronon Auto Const
	Sound Property fwrSoundFXVortisaur Auto Const
	Sound Property fwrSoundFXAlertAlarm Auto Const
	Sound Property OBJTurretAlarmAlert Auto Const
	Sound Property OBJScannerRadiationVault Auto Const
	Sound Property OBJStealthBoyActivate Auto Const
	Sound Property QSTUFOCrashExplosion Auto Const
	Sound Property fwrSoundElectricalArcCharge Auto Const
	Explosion Property fwrExplosionTardisShock Auto Const
	Explosion Property fwrExplosionTardisSpark Auto Const
	Explosion Property fwrExplosionTardisCrash Auto Const
	Explosion Property fwrExplosionVortexWinds Auto Const
	Explosion Property TeleportFXExplosion Auto Const
	Explosion Property fwrExplosionElectrical Auto Const
	ActorValue Property fwrCSRControl Auto Const
	ImageSpaceModifier Property fwrImodTurbulence Auto Const
	ImageSpaceModifier Property fwrImodTimeEddy Auto Const
	EffectShader[] Property CSRShaders Auto Const
	EffectShader[] Property CSRCombatShaders Auto Const
	MiscObject[] Property JunkItems Auto Const
	Keyword Property fwrKywdControlCSR Auto Const
	GlobalVariable Property GameHour Auto
EndGroup

Struct Ship
	String Name
	int Shields
	int Health
	int Level
EndStruct

;Timer Enumerators
int iTimerFlight = 1
int iTimerFXShake = 2
int iTimerFXFadeLoop = 3
int iTimerFXSpark = 4

;Damage Type Enumerator
int iDamageWear = 0
int iDamageMajor = 1
int iDamageMinor = 2
int iDamageEvent = 3
int iDamageCombat = 4
int iDamageCrash = 5

;Sound Loop Vars
int SoundLoopID = 0
float fSoundLoopVolume = 1.0

CustomEvent CSRUpdate
CustomEvent FlightUpdate

FWR:QuestSystemScript Property fwrQuestSystems Auto Const
FWR:QuestThemeScript Property fwrQuestTheme Auto Const
FWR:QuestLocationScript Property fwrQuestLocs Auto Const

; Send Flight Start/Stop Event for In Flight Anims (Rotor)
Function SendFlightUpdate()
	var[] args = new var[1]
	args[0] = Self.GetState() as var
	Self.SendCustomEvent("FlightUpdate", args)
EndFunction

; Show/Hide CSR Control Shader
Function SendCSRUpdate(bool bCSRActive, int iMode, int iControl)
	var[] args = new var[3]
	args[0] = bCSRActive
	args[1] = iMode
	args[2] = iControl
	Self.SendCustomEvent("CSRUpdate", args)
EndFunction

State Grounded
	Function Launch()
		Debug.Notification("ERROR: Capsule Grounded")
		Game.ShakeCamera(Game.GetPlayer(), 0.25, 5)
		int s = fwrSoundTardisLaunchFail.Play(fwrQuestTheme.ConsoleMarker)
	EndFunction
EndState

Auto State AtRest
	Event OnBeginState(String asOldState)
		Self.SendFlightUpdate()
	EndEvent

	Function Launch()
		Self.GoToState("Launching")
	EndFunction
EndState

State Launching
	Event OnBeginState(String asOldState)
		Self.SendFlightUpdate()
		int s = fwrSoundTardisLaunch.Play(fwrQuestTheme.ConsoleMarker)
		Game.ShakeCamera(Game.GetPlayer(), 0.5, 5)
		Self.StartTimer(4.5, iTimerFlight)
	EndEvent

	Event OnEndState(String asNewState)

	EndEvent

	Event OnTimer(int aiTimerID)
		if (aiTimerID == iTimerFlight)
			if (fwrQuestSystems.bAutopilot && !fwrQuestSystems.bFastReturn)
				Self.GoToState("InFlightAutopilot")
			elseif (fwrQuestSystems.bFastReturn)
				iFlightSpeed = 2
				fFlightTime = 60 as float
				fFuelSpent = 10 as float
				Self.GoToState("InFlightFastReturn")
			else
				Self.GoToState("InFlight")
			endif
			Self.StartTimer(0.01, iTimerFXShake)
			Self.StartTimer(10 - iFlightSpeed as float * 2.5, iTimerFlight)
		endif
	EndEvent
EndState

State InFlight
	Event OnBeginState(String asOldState)
		Self.SendFlightUpdate()
		if (asOldState == "Launching" || asOldState == "InFlightAutopilot")
			SoundLoopID = fwrSoundTardisFlight.Play(fwrQuestTheme.ConsoleMarker)
			Self.StartCSR()
		endif
	EndEvent

	Event OnTimer(int aiTimerID)
		if (aiTimerID == iTimerFlight)
			fFlightTime += 10 - iFlightSpeed as float * 2.5
			fFuelSpent += 0.4 + iFlightSpeed as Float * 0.4
			float fFlightLimit = (60 - (iFlightSpeed * 15)) as float
			if (fFlightTime >= (fFlightLimit)) ;Flight Complete, Start Landing
				if (fwrQuestSystems.iFuel - fFuelSpent as int > 0)
					Self.GoToState("Landing")
				else
					Debug.Notification("WARNING: Artron Banks Depleted")
					Self.StartCrash()
				endif
			else ;Flight not complete, start new CSR
				Self.StartCSR()
			endif
			Self.StartTimer(10 - iFlightSpeed as float * 2.5, iTimerFlight)
		elseif (aiTimerID == iTimerFXShake)
			fShakeAmount = 0.05 + (0.1 * (iFlightSpeed + 1) as float)
			Game.ShakeCamera(Game.GetPlayer(), fShakeAmount, 2)
			Self.StartTimer(1 as float, iTimerFXShake)
		endif
	EndEvent

	Function StartCSR()
		int iHadsLimit = 3 - (1 * fwrQuestSystems.iHads)
		int iSelection = 0

		if (iHadsLimit == 1)
			iSelection = 1
		elseif (iHadsLimit == 2)
			iSelection = Utility.RandomInt(1,2)
		elseif (iHadsLimit == 3)
			iSelection = Math.Min(Utility.RandomInt(1, iHadsLimit), Utility.RandomInt(1, iHadsLimit)) as int
		endif

		if (iSelection == 1)
			Self.GoToState("InFlightInput")
		elseif (iSelection == 2)
			Self.GoToState("InFlightEvent")
		elseif (iSelection == 3)
			int s = OBJTurretAlarmAlert.Play(fwrQuestTheme.ConsoleMarker)
			Debug.Notification("Combat Engaged: Hostile Detected")
			Self.GoToState("InFlightCombat")
		endif
	EndFunction

	Function ToggleAutopilot()
		Sound.StopInstance(SoundLoopID)
		fwrQuestSystems.bAutopilot = true
		Debug.Notification("Autopilot Engaged")
		Self.GoToState("InFlightAutopilot")
	EndFunction

	Function StartCrash()
		Self.CancelTimer(iTimerFlight)
		Self.GoToState("Crashing")
	EndFunction
EndState

State InFlightAutopilot
	Event OnBeginState(String asOldState)
		Self.SendFlightUpdate()
		SoundLoopID = fwrSoundTardisFlightStable.Play(fwrQuestTheme.ConsoleMarker)
	EndEvent

	Event OnTimer(int aiTimerID)
		if (aiTimerID == iTimerFlight)
			fFlightTime += 10 - iFlightSpeed as float * 2.5
			fFuelSpent += 0.4 + iFlightSpeed as Float * 0.4
			float fFlightLimit = (60 - (iFlightSpeed * 15)) as float
			if (fFlightTime >= (fFlightLimit)) ;Flight Complete, Start Landing
				if (fwrQuestSystems.iFuel - fFuelSpent as int > 0)
					Self.GoToState("Landing")
				else
					Debug.Notification("WARNING: Artron Banks Depleted")
					Self.StartCrash()
				endif
			endif
			Self.StartTimer(10 - iFlightSpeed as float * 2.5, iTimerFlight)
		endif
	EndEvent

	Function ToggleAutopilot()
		Sound.StopInstance(SoundLoopID)
		fwrQuestSystems.bAutopilot = false
		Debug.Notification("Autopilot Disengaged")
		Self.GoToState("InFlight")
		Self.StartTimer(0.01, iTimerFXShake)
	EndFunction

	Function StartCrash()
		Self.CancelTimer(iTimerFlight)
		Self.GoToState("Crashing")
	EndFunction
EndState

State InFlightFastReturn
	Event OnBeginState(String asOldState)
		Self.SendFlightUpdate()
		SoundLoopID = fwrSoundTardisFlight.Play(fwrQuestTheme.ConsoleMarker)
	EndEvent

	Event OnTimer(int aiTimerID)
		if (aiTimerID == iTimerFlight)
			float fFlightLimit = (60 - (iFlightSpeed * 15)) as float
			if (fFlightTime >= (fFlightLimit)) ;Flight Complete, Start Landing
				if (fwrQuestSystems.iFuel - fFuelSpent as int > 0)
					Self.GoToState("Landing")
				else
					Debug.Notification("WARNING: Artron Banks Depleted")
					Self.StartCrash()
				endif
			endif
			Self.StartTimer(10 - iFlightSpeed as float * 2.5, iTimerFlight)
		elseif (aiTimerID == iTimerFXShake)
			fShakeAmount = 0.05 + (0.1 * (iFlightSpeed + 1) as float)
			Self.RandomSpark()
			Game.ShakeCamera(Game.GetPlayer(), fShakeAmount, 2)
			Self.StartTimer(1 as float, iTimerFXShake)
		endif
	EndEvent

	Function ToggleAutopilot()
		Debug.Notification("Autopilot Malfunction")
	EndFunction

	Function StartCrash()
		Self.CancelTimer(iTimerFlight)
		Self.GoToState("Crashing")
	EndFunction
EndState

State InFlightInput
	Event OnBeginState(String asOldState)
		Self.SendFlightUpdate()
		Self.StartCSR()
	EndEvent

	Event OnTimer(int aiTimerID)
		if (aiTimerID == iTimerFlight)
			fFlightTime += 10 - iFlightSpeed as float * 2.5
			fFuelSpent += 0.4 + iFlightSpeed as Float * 0.4
			fwrQuestSystems.ApplyDamage(iDamageMinor)
			Self.RandomSpark()
			Self.SendCSRUpdate(false, iCSRMode, iCSRControl)
			Self.GoToState("InFlight")
			Self.StartTimer(10 - iFlightSpeed as float * 2.5, iTimerFlight)
		elseif (aiTimerID == iTimerFXShake)
			fShakeAmount = 0.05 + (0.1 * (iFlightSpeed + 1) as float)
			Game.ShakeCamera(Game.GetPlayer(), fShakeAmount, 2)
			Self.StartTimer(1 as float, iTimerFXShake)
		endif
	EndEvent

	Function StartCSR()
		iCSRMode = 1
		iCSRControl = Utility.RandomInt(1, iMaxControls)
		Self.SendCSRUpdate(true, iCSRMode, iCSRControl)
	EndFunction

	Function TriggerCSR()
		Self.SendCSRUpdate(false, iCSRMode, iCSRControl)
		Self.GoToState("InFlight")
	EndFunction

	Function StartCrash()
		Self.CancelTimer(iTimerFlight)
		Self.GoToState("Crashing")
	EndFunction

	Function ToggleAutopilot()
		Debug.Notification("Autopilot Malfunction")
	EndFunction

	Event OnEndState(String asNewState)
		Self.SendCSRUpdate(false, iCSRMode, iCSRControl)
		iCSRMode = 0
		iCSRControl = 0
	EndEvent
EndState

State InFlightEvent
	Event OnBeginState(String asOldState)
		Self.SendFlightUpdate()
		Self.StartCSR()
	EndEvent

	Event OnTimer(int aiTimerID)
		if (aiTimerID == iTimerFlight)
			fFlightTime += 10 - iFlightSpeed as float * 2.5
			fFuelSpent += 0.4 + iFlightSpeed as Float * 0.4
			Self.SendCSRUpdate(false, iCSRMode, iCSRControl)
			Self.EndFlightEvent(iCSREvent, false)
			if (Self.GetState() == "InFlightEvent")
				Self.StartTimer(10 - iFlightSpeed as float * 2.5, iTimerFlight)
				Self.GoToState("InFlight")
			elseif (Self.GetState() == "InFlight") ; Prevent race condition between player activation / event fail getting stuck in infinite loop
				Self.StartTimer(10 - iFlightSpeed as float * 2.5, iTimerFlight)
			endif
		elseif (aiTimerID == iTimerFXShake)
			if (iCSREvent == 3)
				fShakeAmount = 1
				fwrImodTurbulence.Apply(1)
			elseif (iCSREvent == 5)
				fShakeAmount = 1
				fwrImodTimeEddy.Apply(1)
			else
				fShakeAmount = 0.05 + (0.1 * (iFlightSpeed + 1) as float)
			endif
			Game.ShakeCamera(Game.GetPlayer(), fShakeAmount, 2)
			Self.StartTimer(1 as float, iTimerFXShake)
		endif
	EndEvent

	Function StartCSR()
		iCSRMode = 2
		iCSRCount = 0
		iCSREvent = Utility.RandomInt(1,11)
		int[] iProtocol = Self.GetProtocol(iCSREvent)
		iCSRControl = iProtocol[iCSRCount]
		Self.StartFlightEvent(iCSREvent)
		Self.SendCSRUpdate(true, iCSRMode, iCSRControl)
	EndFunction

	Function TriggerCSR()
		Self.SendCSRUpdate(false, iCSRMode, iCSRControl)
		int[] iProtocol = Self.GetProtocol(iCSREvent)
		iCSRCount += 1
		Utility.Wait(0.1)
		if (iCSRCount < iProtocol.length)
			iCSRControl = iProtocol[iCSRCount]
			Self.SendCSRUpdate(true, iCSRMode, iCSRControl)
		else
			Self.EndFlightEvent(iCSREvent, true)
			Self.GoToState("InFlight")
		endif
	EndFunction

	Function StartCrash()
		Self.CancelTimer(iTimerFlight)
		Self.GoToState("Crashing")
	EndFunction

	Function ToggleAutopilot()
		Debug.Notification("Autopilot Malfunction")
	EndFunction

	Event OnEndState(String asNewState)
		Self.SendCSRUpdate(false, iCSRMode, iCSRControl)
		iCSRMode = 0
		iCSRControl = 0
		iCSREvent = 0
		iCSRCount = 0
	EndEvent
EndState

State InFlightCombat
	Event OnBeginState(String asOldState)
		Self.SendFlightUpdate()
		Self.StartCSR()
	EndEvent

	Event OnTimer(int aiTimerID)
		if (aiTimerID == iTimerFlight)
			if ((bPlayerTurn == false && iCSRCount >= 3) || (bPlayerTurn == true))
				Self.SendCSRUpdate(false, iCSRMode, iCSRControl)
				bPlayerTurn = false
				iCSRCount = 0
				iCSRControl = 0
				iCSRAction = 0
				if (Enemy.Health <= 0)
					Game.RewardPlayerXP(Enemy.Level * 100, true)
					Self.GoToState("InFlight")
				else
					Self.EnemyTurn()
				endif
			else
				if (Enemy.Shields >= 100 && Enemy.Health > 25)
					iCSREnemyAction = 1
				elseif (Enemy.Shields < 100 && Enemy.Health > 25)
					iCSREnemyAction = Utility.RandomInt(1,2)
				elseif (Enemy.Shields < 100 && Enemy.Health < 25)
					iCSREnemyAction = Utility.RandomInt(1,3)
				else
					iCSREnemyAction = Utility.RandomInt(1,3)
				endif

				String msg = ""
				if (iCSREnemyAction == 1)
					msg = "Charging Weapons"
				elseif (iCSREnemyAction == 2)
					msg = "Calibrating Shields"
				elseif (iCSREnemyAction == 3)
					msg = "Prepping Engines"
				endif

				Debug.Notification("COMBAT: Hostile " + msg)
				bPlayerTurn = true
				iCSRAction = 0
				Self.SendCSRUpdate(true, iCSRMode, iCSRControl)
			endif
			Self.StartTimer(10 - iFlightSpeed as float * 2.5, iTimerFlight)
		elseif (aiTimerID == iTimerFXShake)
			fShakeAmount = 0.05 + (0.1 * (iFlightSpeed + 1) as float)
			Game.ShakeCamera(Game.GetPlayer(), fShakeAmount, 2)
			Self.StartTimer(1 as float, iTimerFXShake)
		endif
	EndEvent

	Function StartCSR()
		iCSRMode = 3
		iCSRCount = 0
		iCSRControl = 0
		iCSREnemy = Utility.RandomInt(1, EnemyTemplates.length)
		Enemy.Name = EnemyTemplates[iCSREnemy - 1].Name
		Enemy.Shields = EnemyTemplates[iCSREnemy - 1].Shields
		Enemy.Health = EnemyTemplates[iCSREnemy - 1].Health
		Enemy.Level = Utility.RandomInt(1,fwrQuestSystems.sDefense.Lvl)
		bPlayerTurn = true
		iCSREnemyAction = 1
		Self.SendCSRUpdate(true, iCSRMode, iCSRControl)
	EndFunction

	Function TriggerCSR()
		if (bPlayerTurn)
			Self.SendCSRUpdate(false, iCSRMode, iCSRControl)
			iCSRCount += 1
			Utility.Wait(0.1)
			if (iCSRCount < 3)
				iCSRControl = Utility.RandomInt(1, iMaxControls)
				Self.SendCSRUpdate(bPlayerTurn, iCSRMode, iCSRControl)
			else
				bPlayerTurn = false
				iCSRControl = 0
				if (iCSRAction == 1)	; Attack
					if (fwrQuestSystems.sDefense.Destroyed == false)
						int s = fwrSoundElectricalArcCharge.Play(fwrQuestTheme.ConsoleMarker)
						int iDamage = Utility.RandomInt(5 * fwrQuestSystems.sDefense.Lvl, 5 * fwrQuestSystems.sDefense.Lvl + 20)
						if (Enemy.Shields - iDamage < 0)
							Enemy.Health -= (iDamage - Enemy.Shields)
							Enemy.Shields = 0
						else
							Enemy.Shields -= iDamage
						endif
					else
						Debug.Notification("ERROR: System Malfunction")
					endif
				elseif (iCSRAction == 2)	; Defend
					if (fwrQuestSystems.sVitality.Destroyed == false)
						int s = OBJScannerRadiationVault.Play(fwrQuestTheme.ConsoleMarker)
						int iBoost = Utility.RandomInt(5 * fwrQuestSystems.sVitality.Lvl, 5 * fwrQuestSystems.sVitality.Lvl + 20)
						fwrQuestSystems.iShields = Math.Min(100, fwrQuestSystems.iShields + iBoost) as int
					else
						Debug.Notification("ERROR: System Malfunction")
					endif
				elseif (iCSRAction == 3)	; Scan
					if (fwrQuestSystems.sComms.Destroyed == false)
						string msg = ""
						if (fwrQuestSystems.sComms.Lvl == 1)
							msg = Enemy.Name
						elseif (fwrQuestSystems.sComms.Lvl == 2)
							msg = Enemy.Name + "\nShields: " + Enemy.Shields + "%"
						elseif (fwrQuestSystems.sComms.Lvl == 3)
							msg = Enemy.Name + "\nShields: " + Enemy.Shields + "%\nHull: " + Enemy.Health + "%"
						endif
						Debug.Notification(msg)
						int s = fwrSoundFXSonar.Play(fwrQuestTheme.ConsoleMarker)
					else
						Debug.Notification("ERROR: System Malfunction")
					endif
				elseif (iCSRAction == 4) ; Disengage
					if (Utility.RandomInt(0, 99) >= (Enemy.Level * 25))
						int s = fwrSoundTardisLaunchFast.Play(fwrQuestTheme.ConsoleMarker)
						fwrQuestSystems.ApplyDamage(iDamageMinor)
						Self.GoToState("InFlight")
					else
						Debug.Notification("COMBAT: Disengage Failed")
					endif
				elseif (iCSRAction == 5)	; Phase Shift
					if (Utility.RandomInt(0,99) >= (50))
						int s = OBJStealthBoyActivate.Play(fwrQuestTheme.ConsoleMarker)
						bPlayerEvade = true
					else
						Debug.Notification("COMBAT: Phase Shift Ineffective")
					endif
				endif
				iCSRAction = 0
			endif
		endif
	EndFunction

	Function StartCrash()
		Self.CancelTimer(iTimerFlight)
		Self.GoToState("Crashing")
	EndFunction

	Function ToggleAutopilot()
		Debug.Notification("Autopilot Malfunction")
	EndFunction

	Event OnEndState(String asNewState)
		Self.SendCSRUpdate(false, iCSRMode, iCSRControl)
		iCSRMode = 0
		iCSRControl = 0
		iCSREnemy = 0
		iCSRCount = 0
		iCSRAction = 0
		iCSREnemyAction = 0
		bPlayerTurn = false
		bPlayerEvade = false
	EndEvent
EndState

State Landing
	Event OnBeginState(String asOldState)
		Self.SendFlightUpdate()
		Self.StartTimer(0, iTimerFXFadeLoop)
		Self.StartTimer(4.5, iTimerFlight)
		Self.CancelTimer(iTimerFXShake)
		Game.ShakeCamera(Game.GetPlayer(), 0.5, 8)
		int s = fwrSoundTardisLand.Play(fwrQuestTheme.ConsoleMarker)
	EndEvent

	Event OnTimer(int aiTimerID)
		if (aiTimerID == iTimerFlight)
			fwrQuestSystems.ApplyDamage(iDamageWear)
			Self.GoToState("Landed")
		elseif (aiTimerID == iTimerFXFadeLoop)
			fSoundLoopVolume -= 0.1
			if (fSoundLoopVolume > 0 as float && SoundLoopID != 0)
				Sound.SetInstanceVolume(SoundLoopID, fSoundLoopVolume)
				Self.StartTimer(0.2, iTimerFXFadeLoop)
			elseif (SoundLoopID != 0)
				Sound.StopInstance(SoundLoopID)
				SoundLoopID = 0
			endif
		endif
	EndEvent
EndState

State Crashing
	Event OnBeginState(String asOldState)
		Self.SendFlightUpdate()
		fFlightTime = 0 as float
		fShakeAmount = 0.4
		Self.StartTimer(1 as float, iTimerFlight)
		Self.StartTimer(1 as float, iTimerFXFadeLoop)
		if (asOldState == "InFlightAutopilot")
			Self.StartTimer(0, iTimerFXShake)
		endif
		int s = fwrSoundTardisCrash.Play(fwrQuestTheme.ConsoleMarker)
	EndEvent

	Event OnTimer(int aiTimerID)
		if (aiTimerID == iTimerFlight)
			fFlightTime += 1 as float
			if (fFlightTime < 19)
				if (fFlightTime == 1)
					Self.StartCSR()
				endif
				Self.StartTimer(1 as float, iTimerFlight)
			else
				if (iCSRCount < 6)
					fwrQuestTheme.ConsoleMarker.PlaceAtMe(fwrExplosionTardisCrash, 1, False, False, True)
					fwrQuestSystems.ApplyDamage(iDamageMajor)
					fwrQuestSystems.ApplyDamage(iDamageCrash)
					fwrQuestLocs.Zigzag(true)
					iTimeHop = Utility.RandomInt(0,23)
				else
					fwrQuestSystems.ApplyDamage(iDamageWear)
				endif
				Self.GoToState("Landed")
			endif
		elseif (aiTimerID == iTimerFXShake)
			if (iCSRCount < 6)
				if (fFlightTime < 19)
					Self.RandomSpark()
				endif
				fShakeAmount = 0.4 + (fFlightTime * 0.05)
			else
				fShakeAmount = 0.2 as float
			endif
			Game.ShakeCamera(Game.GetPlayer(), fShakeAmount, 2)
			Self.StartTimer(1 as float, iTimerFXShake)
		elseif (aiTimerID == iTimerFXFadeLoop)
			fSoundLoopVolume -= 0.1
			if (fSoundLoopVolume > 0 as float && SoundLoopID != 0)
				Sound.SetInstanceVolume(SoundLoopID, fSoundLoopVolume)
				Self.StartTimer(0.2, iTimerFXFadeLoop)
			elseif (SoundLoopID != 0)
				Sound.StopInstance(SoundLoopID)
				SoundLoopID = 0
			endif
		endif
	EndEvent

	Function StartCSR()
		iCSRMode = 2
		iCSRControl = Utility.RandomInt(1, iMaxControls)
		iCSRCount = 0
		Self.SendCSRUpdate(true, iCSRMode, iCSRControl)
	EndFunction

	Function TriggerCSR()
		;Hide CSR Shader
		Self.SendCSRUpdate(false, iCSRMode, iCSRControl)
		iCSRCount += 1
		Utility.Wait(0.1)
		if (iCSRCount < 6)
			iCSRControl = Utility.RandomInt(1, iMaxControls)
			Self.SendCSRUpdate(true, iCSRMode, iCSRControl)
		endif
	EndFunction

	Function ToggleAutopilot()
		Debug.Notification("Autopilot Malfunction")
	EndFunction

	Event OnEndState(String asNewState)
		Self.SendCSRUpdate(false, iCSRMode, iCSRControl)
		iCSRMode = 0
		iCSRControl = 0
		iCSRCount = 0
	EndEvent
EndState

State Landed
	Event OnBeginState(String asOldState)
		fwrQuestSystems.iFuel = Math.Max(0 as float, (fwrQuestSystems.iFuel - fFuelSpent as int) as float) as int

		fwrQuestTheme.bChangeExterior = (fwrQuestTheme.bRandomize || fwrQuestTheme.bChangeExterior)

		if (fwrQuestLocs.NextLocation != fwrQuestLocs.CurrentLocation)
			fwrQuestTheme.Exterior.Shell.MoveTo(fwrQuestLocs.NextLocation.Marker, 0, 0, 0, True)
			if (fwrQuestLocs.NextLocation == fwrQuestLocs.LastLocation && fwrQuestSystems.bFastReturn)
				fwrQuestLocs.LastLocation = None
				fwrQuestSystems.bFastReturn = false
			else
				fwrQuestLocs.LastLocation = fwrQuestLocs.CurrentLocation
			endif
			fwrQuestLocs.CurrentLocation = fwrQuestLocs.NextLocation
			if (fwrQuestLocs.CurrentLocation.Discovered == 0)
				fwrQuestLocs.SetDiscovered(fwrQuestLocs.CurrentLocation.ID, 1)
			endif
		endif

		if (fwrQuestSystems.bHomingBeacon)
			fwrQuestSystems.HomingBeaconTransmitter.GetReference().MoveTo(fwrQuestTheme.Exterior.Shell)
		endif

		if (iTimeHop != -1)
			GameHour.SetValueInt(iTimeHop)
		endif

		Self.GoToState("AtRest")
	EndEvent

	Event OnEndState(String asNewState)
		iTimeHop = -1
		fShakeAmount = 0 as float
		fSoundLoopVolume = 1.0
		fFuelSpent = 0 as float
		fFlightTime = 0 as float
	EndEvent
EndState

Function StartFlightEvent(int iEvent)
	if (iEvent == 1)
		int s = fwrSoundFXVortexWinds.Play(Game.GetPlayer())
		Debug.Notification("ALERT: Vortex Winds Approaching")
	elseif (iEvent == 2)
		int s = fwrSoundFXGravityLens.Play(Game.GetPlayer())
		int iRand = Utility.RandomInt(1,9)
		Debug.Notification("ALERT: Omega " + iRand + " Gravity Lens Identified")
	elseif (iEvent == 3)
		Debug.Notification("ALERT: Traversing Monopole Turbulence")
	elseif (iEvent == 4)
		int s = fwrSoundFXSonar.Play(Game.GetPlayer())
		Debug.Notification("ALERT: Junk Cluster Detected")
	elseif (iEvent == 5)	
		int s = fwrSoundFXTimeEddy.Play(Game.GetPlayer())
		Debug.Notification("ALERT: Time Eddy In Proximity")
	elseif (iEvent == 6)
		Debug.Notification("ALERT: TARDIS Course Drifting")
	elseif (iEvent == 7)
		int s =  fwrSoundFXChronon.Play(Game.GetPlayer())
		Debug.Notification("ALERT: Chronon Spike Imminent")
	elseif (iEvent == 8)
		int s = fwrSoundFXVortisaur.Play(Game.GetPlayer())
		Debug.Notification("ALERT: Vortisaur Targeting Capsule")
	elseif (iEvent == 9)
		int s = fwrSoundFXAlertAlarm.Play(fwrQuestTheme.ConsoleMarker)
		Debug.Notification("ALERT: Artron Cloud Identified")
	elseif (iEvent == 10)
		int s = fwrSoundFXAlertAlarm.Play(fwrQuestTheme.ConsoleMarker)
		Debug.Notification("ALERT: Substrate Tunnel Forming")
	elseif (iEvent == 11)
		int s = fwrSoundFXAlertAlarm.Play(fwrQuestTheme.ConsoleMarker)
		Debug.Notification("ALERT: Entering Huon Stream")
	endif
EndFunction

Function EndFlightEvent(int iEvent, bool Result)
	if (Result)
		if (iEvent == 1)
			Debug.Notification("INFO: Cruising Vortex Winds")
			fFlightTime += 10
		elseif (iEvent == 2)
			Debug.Notification("INFO: Gravity Lens Circum-Navigated")
		elseif (iEvent == 3)
			Debug.Notification("INFO: Turbulence Subsiding")
			fwrImodTurbulence.Remove()
		elseif (iEvent == 4)
			Debug.Notification("INFO: Junk Cluster Materialising")
			int s = fwrSoundTardisLandFast.Play(fwrQuestTheme.ConsoleMarker)
			fwrQuestTheme.EntranceMarker.PlaceAtMe(JunkItems[Utility.RandomInt(0, JunkItems.length)] as Form, 1, False, False, True)
			fwrQuestTheme.EntranceMarker.PlaceAtMe(JunkItems[Utility.RandomInt(0, JunkItems.length)] as Form, 1, False, False, True)
			fwrQuestTheme.EntranceMarker.PlaceAtMe(JunkItems[Utility.RandomInt(0, JunkItems.length)] as Form, 1, False, False, True)
		elseif (iEvent == 5)
			Debug.Notification("INFO: Time Eddy Deteriorating")
			fwrImodTimeEddy.Remove()
		elseif (iEvent == 6)
			Debug.Notification("INFO: Course Corrected")
		elseif (iEvent == 7)
			Debug.Notification("INFO: Chronon Spike Collapsing")
		elseif (iEvent == 8)
			Debug.Notification("INFO: Repelling Vortisaur")
		elseif (iEvent == 9)
			Debug.Notification("INFO: Replenishing Artron Reserves")
			fwrQuestSystems.iFuel = Math.Min(100, fwrQuestSystems.iFuel + Utility.RandomInt(5,15)) as int
		elseif (iEvent == 10)
			Debug.Notification("INFO: Restoring Plasmic Shell")
			fwrQuestSystems.iShell = Math.Min(100, fwrQuestSystems.iShell + Utility.RandomInt(5,15)) as int
			fwrQuestSystems.VitalsCheck()
		elseif (iEvent == 11)
			Debug.Notification("INFO: Boosting Shield Output")
			fwrQuestSystems.iShields = Math.Min(100, fwrQuestSystems.iShields + Utility.RandomInt(5,15)) as int
		endif
	else
		if (iEvent == 1)
			Debug.Notification("WARNING: Vortex Wind Surge")
			fwrQuestTheme.ConsoleMarker.PlaceAtMe(fwrExplosionVortexWinds)
			fwrQuestSystems.ApplyDamage(iDamageMinor)
		elseif (iEvent == 2)
			Debug.Notification("WARNING: Orbiting Gravity Lens")
			fwrQuestSystems.ApplyDamage(iDamageMinor)
			fFlightTime = 0
		elseif (iEvent == 3)
			Debug.Notification("WARNING: Engines Stalling")
			fwrQuestSystems.ApplyDamage(iDamageMinor)
			fwrQuestSystems.iFuel = Math.Max(0, fwrQuestSystems.iFuel - Utility.RandomInt(5,10)) as int
			fwrImodTurbulence.Remove()
		elseif (iEvent == 4)
			Debug.Notification("WARNING: Junk Cluster Impact")
			Self.RandomExplosion()
			fwrQuestSystems.ApplyDamage(iDamageEvent)
		elseif (iEvent == 5)
			Debug.Notification("WARNING: Time Eddy Enveloping Capsule")
			fwrQuestSystems.ApplyDamage(iDamageMajor)
			Self.RandomExplosion()
			fwrImodTimeEddy.Remove()
		elseif (iEvent == 6)
			Debug.Notification("WARNING: Course Randomised")
			fwrQuestLocs.Zigzag(true)
		elseif (iEvent == 7)
			Debug.Notification("WARNING: Absorbing Chronon Spike")
			Self.RandomExplosion()
			Self.StartCrash()
		elseif (iEvent == 8)
			Debug.Notification("WARNING: Vortisaur Attacking Shell")
			fwrQuestSystems.ApplyDamage(iDamageEvent)
			Self.RandomExplosion()
		elseif (iEvent == 9)
			Debug.Notification("INFO: Passing Artron Cloud")
		elseif (iEvent == 10)
			Debug.Notification("INFO: Exiting Substrate Tunnel")
		elseif (iEvent == 11)
			Debug.Notification("INFO: Surfing Huon Stream")
		endif
	endif
EndFunction

int[] Function GetProtocol(int iEvent)
	if (iEvent == 1)
		return iProtocolVortexWinds
	elseif (iEvent == 2)
		return iProtocolGravLens
	elseif (iEvent == 3)
		return iProtocolMonoTurb
	elseif (iEvent == 4)
		return iProtocolJunkCluster
	elseif (iEvent == 5)
		return iProtocolTimeEddy
	elseif (iEvent == 6)
		return iProtocolCourseDrift
	elseif (iEvent == 7)
		return iProtocolChrononSpike
	elseif (iEvent == 8)
		return iProtocolFaunaAttack
	elseif (iEvent == 9)
		return iProtocolArtronCloud
	elseif (iEvent == 10)
		return iProtocolSubTunnel
	elseif (iEvent == 11)
		return iProtocolHuonStream
	endif
EndFunction

Function EnemyTurn()
	if (iCSREnemyAction == 1)
		int s = QSTUFOCrashExplosion.Play(Game.GetPlayer())
		if (bPlayerEvade || (iFlightSpeed + 1) * 25 >= Utility.RandomInt(0, 99))
			Debug.Notification("COMBAT: Evading Enemy Fire")
			bPlayerEvade = false
		else
			Debug.Notification("COMBAT: Hostile Attacking")
			fwrQuestSystems.ApplyDamage(iDamageMinor)
			fwrQuestSystems.ApplyDamage(iDamageCombat)
			Self.RandomExplosion()
		endif
	elseif (iCSREnemyAction == 2)
		Debug.Notification("COMBAT: Hostile Boosting Defenses")
		int iBoost = Utility.RandomInt(5 * Enemy.Level, 5 * Enemy.Level + 20)
		Enemy.Shields = Math.Min(100, Enemy.Shields + iBoost) as int
	elseif (iCSREnemyAction == 3)
		if (Utility.RandomInt(0, 99) >= (fwrQuestSystems.sDefense.Lvl * 25))
			Debug.Notification("COMBAT: Hostile Fled")
			Self.GoToState("InFlight")
		else
			Debug.Notification("COMBAT: Hostile Escape Failed")
		endif
	endif
EndFunction

Function ToggleAutopilot()
	fwrQuestSystems.bAutopilot = !fwrQuestSystems.bAutopilot
	if (fwrQuestSystems.bAutopilot)
		Debug.Notification("Autopilot Engaged")
	else
		Debug.Notification("Autopilot Disengaged")
	endif
EndFunction

Function RandomExplosion()
	ObjectReference[] Controls = fwrQuestTheme.ConsoleMarker.FindAllReferencesWithKeyword(fwrKywdControlCSR as Form, 300 as float)
	ObjectReference Ctrl = Controls[Utility.RandomInt(0, Controls.length - 1)]
	Controls[Utility.RandomInt(0, Controls.length - 1)].PlaceAtMe(fwrExplosionElectrical, 1, False, False, True)
	Game.ShakeCamera(Game.GetPlayer(), 1, 2)
EndFunction

Function RandomSpark()
	ObjectReference[] Controls = fwrQuestTheme.ConsoleMarker.FindAllReferencesWithKeyword(fwrKywdControlCSR as Form, 300 as float)
	ObjectReference Ctrl = Controls[Utility.RandomInt(0, Controls.length - 1)]
	Ctrl.PlaceAtMe(fwrExplosionTardisSpark, 1, False, False, True)
	Game.ShakeCamera(Game.GetPlayer(), fShakeAmount, 2)
EndFunction

;Empty state function definitions
Function Launch()

EndFunction

Function StartCSR()

EndFunction

Function TriggerCSR()

EndFunction

Function StartCrash()

EndFunction