-- StrTools v2.958
--macroScript StrTools category:"StrScripts"

(
	global roll_strTools
	global StrTools_version = "2.958" -- single place for the version number (Info rollout, installer message)

	-- =================================================================================
	-- AUTO INSTALL (drag & drop onto a viewport)
	-- Copies this script as StrTools.ms (+ the preset .mat if it sits next to it) into
	-- <userScripts>\StrScripts\ and drops a small loader into the startup folder.
	-- =================================================================================
	global StrTools_installDir = (getDir #userScripts) + "\\StrScripts\\"
	global StrTools_srcDir = ""

	-- logs a caught error to the Listener with some context:  catch ( strLogErr "what failed" (getCurrentException()) )
	fn strLogErr ctx err = ( format "[StrTools] %: %\n" ctx err )

	-- every actionMan call goes through here: the numeric IDs can change between Max versions,
	-- so a bad ID now logs to the Listener instead of failing silently / halting the handler
	fn strExecAction table id =
	(
		try( actionMan.executeAction table id )
		catch ( strLogErr ("actionMan " + (table as string) + " " + id) (getCurrentException()) )
	)

	-- light-weight message for "nothing selected"-type hints: status bar + Listener, no popup to click away
	fn strNotify msg =
	(
		try( displayTempPrompt msg 4000 ) catch( undefined )
		format "[StrTools] %\n" msg
	)

	fn strCopyOver src dst =
	(
		if doesFileExist dst do try(deleteFile dst)catch(strLogErr "could not delete old file" (getCurrentException()))
		copyFile src dst
	)

	-- default quotes: written to StrTools_Data\quotes.txt only when that file does not exist yet
	fn strQuoteSeed =
	(
		#(
		"Believe you can and you're halfway there.",
		"Success is not final, failure is not fatal: It is the courage to continue that counts.",
		"Do something today that your future self will thank you for.",
		"Don't watch the clock; do what it does. Keep going.",
		"The only way to do great work is to love what you do.",
		"Dream big and dare to fail.",
		"Act as if what you do makes a difference. It does.",
		"Keep your face always toward the sunshine and shadows will fall behind you.",
		"With the new day comes new strength and new thoughts.",
		"Quality is not an act, it is a habit.",
		"Turn your wounds into wisdom.",
		"The harder you work for something, the greater you'll feel when you achieve it.",
		"Don't stop when you're tired. Stop when you're done.",
		"Little by little, one travels far.",
		"Success usually comes to those who are too busy to be looking for it.",
		"Opportunities don't happen. You create them.",
		"Don't wait for opportunity. Create it.",
		"Great things never come from comfort zones.",
		"Push yourself, because no one else is going to do it for you.",
		"Sometimes later becomes never. Do it now.",
		"Your limitation it's only your imagination.",
		"Dream it. Wish it. Do it.",
		"Great minds discuss ideas; average minds discuss events; small minds discuss people.",
		"The best time to plant a tree was 20 years ago. The second best time is now.",
		"An investment in knowledge pays the best interest.",
		"Do what you can, with what you have, where you are.",
		"Your time is limited, so don't waste it living someone else's life.",
		"Fall seven times and stand up eight.",
		"The secret of getting ahead is getting started.",
		"The harder the battle, the sweeter the victory.",
		"Don't be afraid to give up the good to go for the great.",
		"If you want something you've never had, you must be willing to do something you've never done.",
		"Do not wait to strike till the iron is hot; but make it hot by striking.",
		"Great things are done by a series of small things brought together.",
		"Success is walking from failure to failure with no loss of enthusiasm.",
		"Your passion is waiting for your courage to catch up.",
		"Magic is believing in yourself. If you can make that happen, you can make anything happen.",
		"Everything you ve ever wanted is on the other side of fear.",
		"Success is not in what you have, but who you are.",
		"Try not to become a person of success, but rather try to become a person of value.",
		"Some people want it to happen, some wish it would happen, others make it happen.",
		"Don't let yesterday take up too much of today.",
		"Believe in yourself, take on your challenges, dig deep within yourself to conquer fears.",
		"Act as if it were impossible to fail.",
		"Don't count the days, make the days count.",
		"Success is not the key to happiness. Happiness is the key to success.",
		"The future depends on what you do today.",
		"What you get by achieving your goals is not as important as what you become by achieving your goals.",
		"Whatever you are, be a good one.",
		"The best way to predict the future is to create it.",
		"Do not go where the path may lead, go instead where there is no path and leave a trail.",
		"Keep going. Be all in.",
		"The only limit to our realization of tomorrow is our doubts of today.",
		"Success is liking yourself, liking what you do, and liking how you do it.",
		"Everything you can imagine is real.",
		"Start where you are. Use what you have. Do what you can.",
		"The difference between ordinary and extraordinary is that little extra.",
		"Success seems to be connected with action. Successful people keep moving.",
		"The man who has confidence in himself gains the confidence of others.",
		"You are never too old to set another goal or to dream a new dream.",
		"Believe in your infinite potential. Your only limitations are those you set upon yourself.",
		"Motivation is what gets you started. Habit is what keeps you going.",
		"If you genuinely want something, don't wait for it   teach yourself to act.",
		"Don't be pushed around by the fears in your mind. Be led by the dreams in your heart.",
		"The best revenge is massive success.",
		"Do what you love and the money will follow.",
		"Success is the sum of small efforts repeated day-in and day-out.",
		"The only way to achieve the impossible is to believe it is possible.",
		"Don't limit your challenges. Challenge your limits.",
		"Everything you want is out there waiting for you to ask. Everything you want also wants you. But you have to take action to get it.",
		"Hardships often prepare ordinary people for an extraordinary destiny.",
		"Success is not for the lazy.",
		"Success is no accident. It is hard work, perseverance, learning, studying, sacrifice and most of all, love of what you are doing.",
		"Don't let the fear of losing be greater than the excitement of winning.",
		"Nothing will work unless you do.",
		"The key to success is to focus on goals, not obstacles.",
		"The difference between who you are and who you want to be is what you do.",
		"You don't have to be great to start, but you have to start to be great.",
		"Don't wait for the perfect moment. Take the moment and make it perfect.",
		"Action is the foundational key to all success.",
		"Success isn't overnight. It's when every day you get a little better than the day before. It adds up.",
		"Don't be afraid to start over. It's a chance to build something better.",
		"The best way to get started is to quit talking and begin doing.",
		"Success is the progressive realization of a worthy goal or ideal.",
		"Make each day your masterpiece.",
		"The harder you work, the luckier you get.",
		"Small daily improvements over time lead to stunning results.",
		"Discipline is the bridge between goals and accomplishment.",
		"Success is achieved and maintained by those who try and keep trying.",
		"The expert in anything was once a beginner.",
		"Don't wait. The time will never be just right.",
		"Do not let what you cannot do interfere with what you can do.",
		"Success is not measured by money or power but by the positive difference you make in others' lives.",
		"Every render starts as a blank viewport   fill it with something worth seeing.",
		"A 3D artist doesn t just create scenes; they build worlds.",
		"Your polygons may be small, but your vision can be huge.",
		"The beauty of 3D: if it doesn t exist, you can make it.",
		"A good render is 10% tools and 90% patience.",
		"Every successful artist was once confused by UVs.",
		"Trust the process. Even clay looks ugly at the beginning.",
		"One more tweak can be dangerous but also magical.",
		"Perfection is impossible. Believability is enough.",
		"Your style is formed by the shortcuts you no longer need.",
		"Architects draw buildings. ArchViz artists bring them to life.",
		"If a space feels real, then you ve already succeeded.",
		"Light is your paint. The scene is your canvas.",
		"People don t buy architecture   they buy the feeling of being there.",
		"A clean render sells more dreams than a thousand blueprints.",
		"When you show a client their future, make it beautiful.",
		"Good ArchViz doesn t shout. It whispers  home .",
		"Details tell stories. Shadows tell emotions.",
		"You re not making images   you re shaping imagination.",
		"A realistic render starts with a believable light.",
		"If it looks good in the viewport, it will look terrible in the render.",
		"3D rule #1: If it shouldn t move, it will. If it should move, it won t.",
		" Just a small revision  is never a small revision.",
		"Autosave is faster than my reactions.",
		"The client wants it  more realistic  but also  less realistic. ",
		"I don t make mistakes. I create new features accidentally.",
		"Render time: where hope goes to die.",
		"If it worked yesterday, it won t today.",
		"Deleting half the scene is a valid problem-solving strategy.",
		"Nothing cures insomnia like launching a long render.",
		"Block first, polish later.",
		"Your workflow is a tool   sharpen it.",
		"A messy scene is a creative mind at work.",
		"Start with clarity. Finish with detail.",
		"Creativity grows when fear shrinks.",
		"Every experiment teaches something.",
		"Don t chase perfect   chase progress.",
		"The best artists fail faster.",
		"Creativity is patience disguised as passion.",
		"Deadlines shape masterpieces.",
		"The only limit is the number of crashes you can endure.",
		"Simulation is 90% waiting and 10% praying.",
		"Proceduralism: because manual labor is for mortals.",
		"Your node graph reflects your mental state.",
		"Shading is basically convincing the computer that lies are truth.",
		"If you re not breaking something, you re not learning.",
		"The best pipeline is the one that keeps you sane.",
		"Topology is therapy.",
		"Noise textures are the universe s handwriting.",
		"Optimization is an invisible art.",
		"Render your vision.",
		"Trust the light.",
		"More depth. Less noise.",
		"Small tweaks. Big difference.",
		"Let your art breathe.",
		"Details matter.",
		"Shape the impossible.",
		"Make something beautiful today.",
		"Art lives in the shadows.",
		"Your next render is your best one."
		)
	)

	-- makes sure <install>\StrTools_Data\quotes.txt exists (never overwrites an existing/edited file)
	fn strEnsureQuotes =
	(
		local dst = StrTools_installDir + "StrTools_Data\\quotes.txt"
		if not (doesFileExist dst) do
		(
			try
			(
				makeDir (StrTools_installDir + "StrTools_Data\\") all:true
				local f = createFile dst
				format "%\n" "# StrTools motivation quotes - one quote per line. Lines starting with # and empty lines are ignored." to:f
				format "%\n" "# Edit freely: the Motivation button reads this file every time it is pressed." to:f
				for q in (strQuoteSeed()) do format "%\n" q to:f
				close f
				format "[StrTools] created default quotes file: %\n" dst
			)
			catch ( format "[StrTools] could not create quotes file: %\n" (getCurrentException()) )
		)
		dst
	)

	fn strAutoInstall =
	(
		local srcFile = getThisScriptFilename()
		if srcFile != undefined and srcFile != "" do
		(
			StrTools_srcDir = getFilenamePath srcFile
			-- already running from the install folder (e.g. via the startup loader): nothing to do
			if not (pathConfig.pathsResolveEquivalent StrTools_srcDir StrTools_installDir) do
			(
				try
				(
					makeDir StrTools_installDir all:true
					local ok = strCopyOver srcFile (StrTools_installDir + "StrTools.ms")

					local presetSrc = StrTools_srcDir + "StrArchviz_MatPresets.mat"
					local presetMsg = "not found next to the script (copy it into the install folder manually)"
					if doesFileExist presetSrc then
					(
						strCopyOver presetSrc (StrTools_installDir + "StrArchviz_MatPresets.mat")
						presetMsg = "copied"
					)
					else if doesFileExist (StrTools_installDir + "StrArchviz_MatPresets.mat") do presetMsg = "kept existing copy"

					-- StrTools_Data folder (quotes.txt, ...)
					local dataSrc = StrTools_srcDir + "StrTools_Data\\"
					local dataDst = StrTools_installDir + "StrTools_Data\\"
					local dataMsg = "not found next to the script (copy the StrTools_Data folder into the install folder manually)"
					if doesDirectoryExist dataSrc then
					(
						makeDir dataDst all:true
						local nData = 0
						for df in (getFiles (dataSrc + "*.*")) do
						(
							strCopyOver df (dataDst + (filenameFromPath df))
							nData += 1
						)
						dataMsg = "copied (" + (nData as string) + " files)"
					)
					else
					(
						-- no StrTools_Data next to the script: create the folder + a default quotes.txt (an existing one is kept)
						local hadQuotes = doesFileExist (dataDst + "quotes.txt")
						strEnsureQuotes()
						dataMsg = if hadQuotes then "kept existing copy" else "created with default quotes.txt"
					)

					-- loader in the startup folder
					local loaderPath = (getDir #userStartupScripts) + "\\StrTools_loader.ms"
					local f = createFile loaderPath
					format "%\n" "-- StrTools loader (auto-generated)" to:f
					format "%\n" ("try(fileIn @\"" + StrTools_installDir + "StrTools.ms\")catch(print (getCurrentException()))") to:f
					close f

					messageBox ("StrTools v" + StrTools_version + " installed.\n\nScript: " + StrTools_installDir + "StrTools.ms" + (if ok then "" else "  (COPY FAILED)") + \
						"\nPreset: " + presetMsg + "\nData: " + dataMsg + "\nLoader: " + loaderPath + "\n\nIt will load automatically on the next 3ds Max start.") title:"StrTools"
				)
				catch ( format "[StrTools] install failed: %\n" (getCurrentException()) )
			)
		)
	)
	strAutoInstall()
	strEnsureQuotes() -- also covers starts from the install folder (loader), where the installer is skipped

	-- =================================================================================
	-- SETTINGS (StrTools_Settings.ini in the install folder)
	-- =================================================================================
	global StrTools_settingsFile = StrTools_installDir + "StrTools_Settings.ini"

	fn strSettingGet sec key def =
	(
		local v = ""
		try( if doesFileExist StrTools_settingsFile do v = getINISetting StrTools_settingsFile sec key )
		catch ( strLogErr ("could not read setting " + sec + "/" + key) (getCurrentException()) )
		if v == "" then def else v
	)

	fn strSettingSet sec key val =
	(
		try
		(
			makeDir StrTools_installDir all:true
			setINISetting StrTools_settingsFile sec key (val as string)
		)
		catch ( strLogErr ("could not save setting " + sec + "/" + key) (getCurrentException()) )
	)

	-- rolled-up state of a rollout as saved last time (def = "true"/"false" when nothing saved yet)
	fn strRolledUp name def = ( (strSettingGet "Rollouts" name def) == "true" )
	
	-- =================================================================================
	-- GLOBAL UTILITY FUNCTIONS
	-- =================================================================================

	fn checkSingleGeometrySelected =
	(
		-- The most direct way to perform this check.
		-- It returns the boolean result of two conditions combined by 'and':
		-- 1. The selection count is exactly 1.
		-- 2. The single selected object is a GeometryClass.
		(selection.count == 1) and (isKindOf selection[1] GeometryClass)
	)
	-- Randomize By Element: inspired by klydes script
	--Detacher
	fn detachElements node delit:on= 
		(
		convertToPoly node
		local oldName = node.name
		local act = on
		local element = polyop.getElementsUsingFace
		local detach = polyop.detachfaces
		local elem, obj -- were leaking as globals
		while node.numfaces > 0 and act do
			(
			elem = element node 1
			act = detach node elem delete:on asnode:on name:"ElementDetached"
			if act do 
				(
				obj = objects[objects.count]
				if not delit do obj.parent = node
				)
			)
		return node
		)

	--Attacher	
	fn attachElements setOfElements oldObj= 
	(
		local counter = setOfElements.count
		for i in 1 to counter do
		(
			polyop.attach  oldObj setOfElements[i] 
		)
		return oldObj
	)
	-- Helper: Pad 2 digits
	fn pad2 n = if n < 10 then ("0" + (n as string)) else (n as string)

	-- Helper: Unique filename with timestamp
	fn getTimestampUniqueName dir originalName =
	(
		local base = getFilenameFile originalName
		local ext  = getFilenameType originalName

		local t = localTime
		local stamp = (t.year as string) + pad2 t.month + pad2 t.day + "_" +
					  pad2 t.hour + pad2 t.minute + pad2 t.second

		local newName = base + "_" + stamp + ext
		local full
		if matchPattern dir pattern:"*\\*" then
			full = dir + newName
		else
			full = dir + "\\" + newName

		local i = 1
		while doesFileExist full do
		(
			newName = base + "_" + stamp + "_" + (i as string) + ext
			if matchPattern dir pattern:"*\\*" then
				full = dir + newName
			else
				full = dir + "\\" + newName
			i += 1
		)
		return full
	)

	-- Helper: Normalize paths
	fn normalizePath p =
	(
		if p == undefined then return ""
		local np = substituteString p "/" "\\"
		np = trimLeft np
		np = trimRight np
		toLower np
	)

	fn pathsEqual p1 p2 =
	(
		normalizePath p1 == normalizePath p2
	)

	-- Robust recursive relinker
	fn relinkMapRecursive map oldPath newPath =
	(
		local relinked = 0
		if map == undefined then return 0

		-- Print every map being checked
		if isProperty map #filename and map.filename != undefined then
			format "Checking map: % - oldPath: %\n" map.filename oldPath

		-- Standard / V-Ray / Corona bitmap
		if (isProperty map #filename) and (map.filename != undefined) and pathsEqual map.filename oldPath do
		(
			map.filename = newPath
			relinked += 1
			format "Relinked map: % -> %\n" oldPath newPath
		)

		-- Physical Material maps
		if (classOf map == PhysicalMaterial) then
		(
			local props = getPropNames map
			for p in props where matchPattern (p as string) pattern:"*Map" do
			(
				if isProperty map p then
					relinked += relinkMapRecursive (getProperty map p) oldPath newPath
			)
		)

		-- Layered / generic submaps
		if isProperty map #maps then
		(
			for i = 1 to map.maps.count do
				relinked += relinkMapRecursive map.maps[i] oldPath newPath
			)

		return relinked
	)

	fn relinkSceneAssets oldPath newPath =
	(
		local totalRelinked = 0
		format "\nRelinking assets for: % -> %\n" oldPath newPath

		-- All scene materials
		for m in sceneMaterials do
			totalRelinked += relinkMapRecursive m oldPath newPath

		-- Object-assigned materials
		for obj in geometry where obj.material != undefined do
			totalRelinked += relinkMapRecursive obj.material oldPath newPath

		format "Total relinked for this file: %\n" totalRelinked
		return totalRelinked
	)

	-- Globals to store asset lists
	global StrTools_collectedOld = #()
	global StrTools_collectedNew = #()

	/* Function: sAttach
		Description: Attaches an array of objects into a single Editable Poly.
		Note: Uses polyOp.attach for O(N) efficiency.
	*/
	fn sAttach objArr =
	(
		local targetObj = undefined
		local progressValue = 0.0
		local currentObj = undefined

		if objArr.count < 2 do ( return objArr[1] )

		-- Convert the first object (the target) to Editable_Poly once
		targetObj = objArr[1]
		convertTo targetObj Editable_Poly

		with undo off
		(
			with redraw off
			(
				for i = 2 to objArr.count do
				(
					currentObj = objArr[i]
					
					-- Calculate progress percentage
					progressValue = (i - 1) as float / (objArr.count - 1) * 100.0
					progressUpdate progressValue
					
					-- polyOp.attach is much faster. delete:true handles cleanup.
					polyOp.attach targetObj currentObj delete:true
				)
			)
		)
		return targetObj
	)

	-- =================================================================================
	-- CORONA MATERIAL PRESET + COPYMAT / PASTEMAT (used by Materials and Mapping)
	-- =================================================================================
	global CMC_clip = undefined -- #(material, uvwModifierCopies, sourceName)
	global CMC_presetFile = "StrArchviz_MatPresets.mat"
	global CMC_presetMtl = "CoronaPhysical_New"

	fn cmcLog s = format "[StrTools] %\n" s

	-- sets the first existing property from names
	fn cmcSetFirstProp obj names val =
	(
		local done = false
		for n in names while not done do
			if isProperty obj n do ( setProperty obj n val; done = true )
		if not done do cmcLog ("no property found for " + (classOf obj as string) + ": tried " + (names as string))
		done
	)

	fn cmcSetRoughMode mtl glossMode =
		cmcSetFirstProp mtl #(#roughnessMode, #baseRoughnessMode, #roughnessGlossMode) (if glossMode then 1 else 0)

	-- random unique material name (scene materials + editor slots)
	fn cmcNameInUse nm =
		((for m in scenematerials where m.name == nm collect m).count > 0) or ((for m in meditMaterials where m.name == nm collect m).count > 0)

	fn cmcRandomName =
	(
		local nm = "StrArchviz_" + ((random 1000 9999) as string)
		while cmcNameInUse nm do nm = "StrArchviz_" + ((random 1000 9999) as string)
		nm
	)

	-- "Browse Images for Input" prompt killer (empty bitmaps in the preset can trigger it in Slate)
	fn cmcKillBrowseDlg =
	(
		local hwnd = DialogMonitorOPS.GetWindowHandle()
		local t = UIAccessor.GetWindowText hwnd
		if t != undefined and (matchPattern t pattern:"Browse Images*") do UIAccessor.CloseDialog hwnd
		true
	)

	fn cmcStartKiller =
	(
		DialogMonitorOPS.UnRegisterNotification id:#coronaMtlKill
		DialogMonitorOPS.RegisterNotification cmcKillBrowseDlg id:#coronaMtlKill
		DialogMonitorOPS.Enabled = true
	)

	fn cmcStopKiller =
	(
		DialogMonitorOPS.Enabled = false
		DialogMonitorOPS.UnRegisterNotification id:#coronaMtlKill
	)

	-- walk material tree by properties
	fn cmcCollectTree obj depth items depths =
	(
		append items obj
		append depths depth
		for p in (getPropNames obj) do
		(
			local val = undefined
			try(val = getProperty obj p)catch(val = undefined) -- some props cannot be read; expected
			if val != undefined and (isKindOf val textureMap) and (findItem items val) == 0 do
				cmcCollectTree val (depth + 1) items depths
		)
	)

	fn cmcGetSlateView =
	(
		if not sme.IsOpen() do sme.Open()
		local v = sme.GetView sme.activeView
		if v == undefined do ( sme.CreateView "StrArchviz"; v = sme.GetView sme.activeView )
		v
	)

	-- below the lowest existing node so new materials never overlap old ones
	fn cmcGetYOffset v =
	(
		local yOff = 0
		try
		(
			local n = v.GetNumNodes()
			if n > 0 do
			(
				local maxY = -1e9
				for i = 1 to n do ( local p = (v.GetNode i).position; if p.y > maxY do maxY = p.y )
				yOff = maxY + 700
			)
		)
		catch ( strLogErr "could not measure scene extents" (getCurrentException()) )
		yOff
	)

	fn cmcAddTreeToSlate mtl =
	(
		local v = cmcGetSlateView()
		local yOff = cmcGetYOffset v
		local items = #()
		local depths = #()
		cmcCollectTree mtl 0 items depths
		for i = 1 to items.count do v.CreateNode items[i] [800 - depths[i] * 350, yOff + (i - 1) * 140]
		v.ZoomExtents()
	)

	-- looks in the install folder first, then next to the script, then user scripts / scripts folders
	fn cmcFindPresetFile =
	(
		local dirs = #(StrTools_installDir, StrTools_srcDir, (getDir #userScripts + "\\"), (getDir #scripts + "\\"))
		local found = undefined
		for d in dirs while found == undefined do
			if d != "" and doesFileExist (d + CMC_presetFile) do found = d + CMC_presetFile
		found
	)

	-- load the default material from the collection as a fresh copy
	fn cmcLoadPreset mtlName =
	(
		local m = undefined
		local path = cmcFindPresetFile()
		if path == undefined then
		(
			local msg = "Preset collection not found: " + CMC_presetFile + "\nLooked in:\n" + StrTools_installDir + "\nPut the .mat there (or next to the script and drag the script again)."
			cmcLog msg
			messageBox msg title:"StrTools"
		)
		else
		(
			cmcLog ("loading: " + path)
			try
			(
				local lib = loadTempMaterialLibrary path
				if lib != undefined do
				(
					for i = 1 to lib.count while m == undefined do
						if lib[i].name == mtlName do m = lib[i]
					if m == undefined do
					(
						local msg = "Material '" + mtlName + "' not found in " + CMC_presetFile + "\nFound: " + ((for i = 1 to lib.count collect lib[i].name) as string)
						cmcLog msg
						messageBox msg title:"StrTools"
					)
				)
			)
			catch ( local err = getCurrentException(); cmcLog ("preset load failed: " + err); messageBox err title:"StrTools: preset load failed" )
		)
		m
	)

	fn cmcMakeMaterial glossMode =
	(
		local m = cmcLoadPreset CMC_presetMtl
		if m != undefined do
		(
			m.name = cmcRandomName()
			cmcSetRoughMode m glossMode
			meditMaterials[activeMeditSlot] = m
			cmcStartKiller()
			try(cmcAddTreeToSlate m)
			catch(cmcLog ("slate error: " + (getCurrentException())))
			cmcStopKiller()
		)
		m
	)

	-- =================================================================================
	-- MatFromTex: TEXTURE FOLDER / TEXTURE FILE -> MATERIAL (preset: StrArchviz_Poliigon)
	-- =================================================================================
	global CMC_poliigonMtl = "StrArchviz_Poliigon"
	global CMC_lastDir = (strSettingGet "MatFromTex" "lastDir" "")
	if CMC_lastDir != "" and not (doesDirectoryExist CMC_lastDir) do CMC_lastDir = ""

	fn plgGetFiles dir =
	(
		local r = #()
		for ext in #("jpg", "jpeg", "png", "tif", "tiff", "exr", "tga", "bmp") do
			for f in (getFiles (dir + "*." + ext)) do appendIfUnique r f
		r
	)

	-- every texture file in the folder AND all of its subfolders (any name, any depth up to 6)
	fn plgCollectFiles root =
	(
		local rt = root
		if (substring rt rt.count 1) != "\\" do rt += "\\"
		local found = #()
		local queue = #(#(rt, 0))
		local qi = 1
		while qi <= queue.count and found.count < 20000 do
		(
			local d = queue[qi][1]
			local depth = queue[qi][2]
			for f in (plgGetFiles d) do appendIfUnique found f
			if depth < 6 do
				for sd in (getDirectories (d + "*")) do append queue #(sd, depth + 1)
			qi += 1
		)
		found
	)

	-- ---------------------------------------------------------------------------------
	-- TEXTURE NAME RECOGNITION
	-- kinds: 1 COL (diffuse/albedo/color), 2 DISP (displacement/height/bump), 3 NRM (normal),
	--        4 GLOSS, 6 ROUGHNESS (becomes kind 4 + rough flag), 5 other known map (spec, AO, ...: ignored)
	-- entries: #(WORD, kind, penalty). When a folder has several candidates the lowest penalty wins.
	-- A file with NO type word at all (ConcretePlates10.jpg) is treated as the diffuse/COL map.
	-- ---------------------------------------------------------------------------------
	global PLG_strong = #( \
		#("COL",1,0), #("COLOR",1,0), #("COLOUR",1,0), #("COLORMAP",1,0), #("COLOURMAP",1,0), #("DIFFUSE",1,0), #("DIFFUSEMAP",1,0), #("DIFFUSECOLOR",1,0), \
		#("DIFF",1,0), #("DIF",1,0), #("ALBEDO",1,0), #("ALBEDOMAP",1,0), #("ALB",1,0), #("BASECOLOR",1,0), #("BASECOLOUR",1,0), #("BASECOL",1,0), \
		#("DISP",2,0), #("DISPL",2,0), #("DISPLACE",2,0), #("DISPLACEMENT",2,0), #("DISPMAP",2,0), #("DISPLACEMENTMAP",2,0), #("DISP16",2,5), \
		#("HEIGHT",2,2), #("HEIGHTMAP",2,2), #("HGT",2,2), #("BUMP",2,3), #("BUMPMAP",2,3), #("BMP",2,3), \
		#("NRM",3,0), #("NORMAL",3,0), #("NORMALS",3,0), #("NORM",3,0), #("NRML",3,0), #("NORMALMAP",3,0), #("NORMALGL",3,0), #("NORMALOGL",3,0), \
		#("NRMGL",3,0), #("NORMALDX",3,1), #("NRMDX",3,1), #("NRM16",3,5), \
		#("GLOSS",4,0), #("GLOSSINESS",4,0), #("GLOSSY",4,0), #("GLOSSMAP",4,0), \
		#("ROUGH",6,0), #("ROUGHNESS",6,0), #("ROUGHMAP",6,0), #("RGH",6,0), \
		#("SPEC",5,0), #("SPECULAR",5,0), #("SPC",5,0), #("REFL",5,0), #("REFLECTION",5,0), #("REFLECT",5,0), #("METAL",5,0), #("METALNESS",5,0), \
		#("METALLIC",5,0), #("AO",5,0), #("OCC",5,0), #("OCCLUSION",5,0), #("AMBIENTOCCLUSION",5,0), #("OPACITY",5,0), #("ALPHA",5,0), #("MASK",5,0), \
		#("TRANSPARENCY",5,0), #("EMISSIVE",5,0), #("EMISSION",5,0), #("EMIT",5,0), #("SSS",5,0), #("TRANSLUCENCY",5,0), #("ORM",5,0), #("ARM",5,0), \
		#("CAVITY",5,0), #("CURVATURE",5,0) \
	)
	-- single letters / very short codes: only accepted as the LAST word of the name (brick_d, brick_n, brick_b ...)
	global PLG_weak = #( \
		#("D",1,0), #("BC",1,0), #("H",2,2), #("B",2,3), #("N",3,0), #("NM",3,0), #("R",6,0), #("G",4,0), #("S",5,0), #("M",5,0) \
	)
	-- type words glued to a number (ConcreteTiles_old_01bump, wall02normal), longest first
	global PLG_attach = #("DISPLACEMENT", "REFLECTION", "GLOSSINESS", "ROUGHNESS", "OCCLUSION", "SPECULAR", "METALNESS", "DIFFUSE", "OPACITY", "NORMAL", \
		"HEIGHT", "ALBEDO", "DISPL", "BUMP", "GLOSS", "ROUGH", "DISP", "DIFF", "SPEC", "COL", "NRM")
	-- words that carry no meaning for the material name
	global PLG_noise = #("HIRES", "LOWRES", "LORES", "MIDRES", "GL", "DX", "OGL", "OPENGL", "DIRECTX", "MAP", "TEX", "TEXTURE")

	fn plgIsDigits s =
	(
		local ok = s.count > 0
		for i = 1 to s.count while ok do
			if (findString "0123456789" (substring s i 1)) == undefined do ok = false
		ok
	)

	fn plgLookupTok w isLast =
	(
		local r = undefined
		for e in PLG_strong while r == undefined do
			if e[1] == w do r = e
		if r == undefined and isLast do
		(
			for e in PLG_weak while r == undefined do
				if e[1] == w do r = e
		)
		r
	)

	-- returns #(kind, assetKey, penalty, varNumber, hiresWord, isRough, assetName)
	-- kind 0 = not a texture (preview, thumbnail, ...), assetKey = upper-case name before the type word
	fn plgParseTex f =
	(
		local toks = #(), orig = #()
		for t in (filterString (getFilenameFile f) "_- ") do
		(
			local u = toUpper t
			local didSplit = false
			if u.count >= 4 and (plgLookupTok u true) == undefined do
			(
				for w in PLG_attach while not didSplit do
				(
					if u.count > w.count and (substring u (u.count - w.count + 1) -1) == w and (plgIsDigits (substring u (u.count - w.count) 1)) do
					(
						append toks (substring u 1 (u.count - w.count))
						append orig (substring t 1 (t.count - w.count))
						append toks w
						append orig w
						didSplit = true
					)
				)
			)
			if not didSplit do ( append toks u; append orig t )
		)

		local vr = 0, hires = false, pen = 0, ign = false
		local t2 = #(), d2 = #()
		for i = 1 to toks.count do
		(
			local u = toks[i]
			if u == "HIRES" then hires = true
			else if (findItem PLG_noise u) > 0 then ( if u == "DX" or u == "DIRECTX" do pen += 1 )
			else if (matchPattern u pattern:"VAR*") and ((u.count == 3) or (plgIsDigits (substring u 4 -1))) then
			(
				if u.count > 3 do vr = (substring u 4 -1) as integer
			)
			else if (u.count > 1) and ((substring u u.count 1) == "K") and (plgIsDigits (substring u 1 (u.count - 1))) then ( true ) -- 1K, 2K, 4K ...
			else if (matchPattern u pattern:"PREVIEW*") or (matchPattern u pattern:"THUMB*") or (matchPattern u pattern:"SPHERE*") or (matchPattern u pattern:"SWATCH*") or (u == "ICON") or (u == "SAMPLE") then ( ign = true )
			else ( append t2 u; append d2 orig[i] )
		)

		local kind = 0, cut = 0, tpen = 0, rough = false
		for i = t2.count to 1 by -1 while cut == 0 do
		(
			local e = plgLookupTok (t2[i]) (i == t2.count)
			if e != undefined do ( cut = i; kind = e[2]; tpen = e[3] )
		)

		local akey = "", nm = ""
		local upto = if cut > 0 then cut - 1 else t2.count
		for i = 1 to upto do
		(
			if akey != "" do ( akey += "_"; nm += "_" )
			akey += t2[i]
			nm += d2[i]
		)
		-- no type word anywhere = plain diffuse (lowest priority, an explicit COL/diffuse always wins)
		if cut == 0 then
		(
			kind = 1
			tpen = 500
			if t2.count == 0 do kind = 0
		)
		if kind == 6 do ( kind = 4; tpen += 1; rough = true )
		if ign do kind = 0
		#(kind, akey, tpen + pen, vr, hires, rough, nm)
	)

	-- asset key of one file ("" when it is not a texture map)
	fn plgAssetKey f =
	(
		local info = plgParseTex f
		if info[1] > 0 then info[2] else ""
	)

	-- parses every file once: #(#(file, info), ...)
	fn plgScan files = ( for f in files collect #(f, (plgParseTex f)) )

	-- returns #(COL, DISP, NRM, GLOSS) file paths (undefined when missing); lowest VAR number wins,
	-- HIRES folder / HIRES word preferred, then the lowest name penalty
	fn plgPickEntries entries =
	(
		local picks = #(undefined, undefined, undefined, undefined)
		local scores = #(1e9, 1e9, 1e9, 1e9)
		for en in entries do
		(
			local info = en[2]
			local k = info[1]
			if k >= 1 and k <= 4 do
			(
				local hires = info[5] or (matchPattern (toLower (getFilenamePath en[1])) pattern:"*\\hires\\*")
				local score = info[4] * 10 + info[3] + (if hires then 0 else 1)
				if score < scores[k] do ( scores[k] = score; picks[k] = en[1] )
			)
		)
		picks
	)

	-- joins the slot hops of a bitmap into one readable path (for logging)
	fn plgPathText hops =
	(
		local r = ""
		for i = 1 to hops.count do
		(
			if i > 1 do r += " > "
			r += hops[i]
		)
		r
	)

	-- collects every bitmap node in the material tree: #(parentObj, slotName, bitmapNode, hops)
	-- hops = one "slotName nodeName" entry per level, from the material down to the bitmap
	fn plgWalkBitmaps obj hops edges visited =
	(
		for p in (getPropNames obj) do
		(
			local val = undefined
			try(val = getProperty obj p)catch(val = undefined) -- some props cannot be read; expected
			if val != undefined and (isKindOf val textureMap) do
			(
				local nm = ""
				try(nm = val.name)catch(nm = "")
				local h2 = #()
				for h in hops do append h2 h
				append h2 ((p as string) + " " + nm)
				if isProperty val #filename do append edges #(obj, p, val, h2)
				if (findItem visited val) == 0 do ( append visited val; plgWalkBitmaps val h2 edges visited )
			)
		)
	)

	-- which texture a bitmap wants, decided by its OWN slot first (leaf), then upwards:
	-- returns #(kind, matchedHop); kind 1 COL, 2 DISP/bump, 3 NRM, 4 GLOSS, 0 unknown
	fn plgClassify hops =
	(
		local res = #(0, "")
		local i = hops.count
		while i >= 1 and res[1] == 0 do
		(
			local h = toLower hops[i]
			local k = 0
			if (matchPattern h pattern:"*normal*") or (matchPattern h pattern:"*nrm*") then k = 3
			else if (matchPattern h pattern:"*disp*") or (matchPattern h pattern:"*bump*") then k = 2
			else if (matchPattern h pattern:"*gloss*") or (matchPattern h pattern:"*rough*") then k = 4
			else if (matchPattern h pattern:"*diffuse*") or (matchPattern h pattern:"*albedo*") or (matchPattern h pattern:"*color*") or (matchPattern h pattern:"*basetexmap*") then k = 1
			if k > 0 do res = #(k, h)
			i -= 1
		)
		res
	)

	-- prefix: asset key, set when a single texture file was dropped. Only files of that same
	-- asset are used, and if fewer than 2 maps are found the search climbs up to 2 parent folders.
	-- Without a prefix (folder drop) the folder must contain ONE asset, otherwise a message lists them.
	fn cmcPoliigon root prefix:"" =
	(
		CMC_lastDir = root
		strSettingSet "MatFromTex" "lastDir" root
		local entries = #()
		local picks = #()
		local dir = root
		local lvl = 0
		while lvl <= 2 do
		(
			entries = plgScan (plgCollectFiles dir)
			if prefix != "" do entries = for en in entries where en[2][1] > 0 and en[2][2] == prefix collect en
			picks = plgPickEntries entries
			local nFound = 0
			for pk in picks where pk != undefined do nFound += 1
			if prefix == "" or nFound >= 2 do exit
			local up = dir
			if (substring up up.count 1) == "\\" do up = substring up 1 (up.count - 1)
			up = getFilenamePath up
			if up == "" or not (doesDirectoryExist up) do exit
			dir = up
			lvl += 1
		)
		-- folder drop: several different materials in there -> do not mix them, tell the user
		local multiMsg = ""
		if prefix == "" do
		(
			local keys = #(), counts = #()
			for en in entries do
			(
				local ak = en[2][2]
				if en[2][1] > 0 and ak != "" do
				(
					local ix = findItem keys ak
					if ix == 0 then ( append keys ak; append counts 1 ) else counts[ix] += 1
				)
			)
			if keys.count > 1 do
			(
				multiMsg = "This folder contains " + (keys.count as string) + " different textures:\n"
				for i = 1 to (amin keys.count 12) do multiMsg += "\n- " + keys[i] + "  (" + (counts[i] as string) + " files)"
				if keys.count > 12 do multiMsg += "\n- ..."
				multiMsg += "\n\nNothing was created, so the maps don't get mixed up.\nDrag ONE texture file of the material you want onto the MatFromTex button (its matching maps are picked automatically), or keep each material in its own folder."
			)
		)
		if multiMsg != "" then ( cmcLog ("MatFromTex: multiple textures in " + root); messageBox multiMsg title:"StrTools" )
		else if entries.count == 0 then messageBox ("No texture files found in:\n" + root + "\n(or any of its subfolders)") title:"StrTools"
		else
		(
			local firstPick = (for p in picks where p != undefined collect p)[1]
			-- GLOSS slot fed by a roughness map -> switch the material to roughness mode
			local isRough = false
			if picks[4] != undefined do isRough = (plgParseTex picks[4])[6]
			if firstPick == undefined then messageBox ("No COL / DISP / NRM / GLOSS textures recognised in:\n" + dir + "\n(or any of its subfolders)") title:"StrTools"
			else
			(
				local m = cmcLoadPreset CMC_poliigonMtl
				if m != undefined do
				(
					local nm = (plgParseTex firstPick)[7]
					if nm == "" do nm = last (filterString dir "\\")
					if nm == undefined or (cmcNameInUse nm) do nm = "MatFromTex_" + ((random 1000 9999) as string)
					m.name = nm
					cmcSetRoughMode m (not isRough) -- gloss maps = gloss mode, roughness maps = roughness mode

					local labels = #("COL", "DISP", "NRM", "GLOSS")
					if isRough do labels[4] = "ROUGH"
					local used = #(false, false, false, false)
					local edges = #()
					local bumpEdges = #()
					local dispNode = undefined
					local hops0 = #()
					local seen = #(m)
					plgWalkBitmaps m hops0 edges seen
					cmcLog ("MatFromTex: " + (entries.count as string) + " texture files scanned in " + dir + " (incl. subfolders)  |  bitmaps in preset: " + (edges.count as string))
					for ed in edges do cmcLog ("  bitmap slot: " + (plgPathText ed[4]))

					for ed in edges do
					(
						local cl = plgClassify ed[4]
						local k = cl[1]
						if k == 0 then cmcLog ("bitmap with no matching texture type: " + (plgPathText ed[4]))
						else if picks[k] != undefined do
						(
							try ( ed[3].filename = picks[k]; used[k] = true; cmcLog (labels[k] + " <- " + (substituteString picks[k] root "...") + "   [" + (plgPathText ed[4]) + "]") )
							catch ( cmcLog ("could not set " + labels[k] + " on [" + (plgPathText ed[4]) + "]: " + (getCurrentException())) )
							if k == 2 do
							(
								if matchPattern cl[2] pattern:"*disp*" then ( if dispNode == undefined do dispNode = ed[3] )
								else append bumpEdges ed
							)
						)
					)

					-- bump uses the displacement bitmap as an instance
					if dispNode != undefined do
						for ed in bumpEdges where ed[3] != dispNode do
						(
							try ( setProperty ed[1] ed[2] dispNode; cmcLog ("bump slot [" + (plgPathText ed[4]) + "] now instances the displacement bitmap") )
							catch ( cmcLog ("could not instance bump: " + (getCurrentException())) )
						)

					meditMaterials[activeMeditSlot] = m
					cmcStartKiller()
					try(cmcAddTreeToSlate m)
					catch(cmcLog ("slate error: " + (getCurrentException())))
					cmcStopKiller()

					local notes = ""
					for i = 1 to 4 do
					(
						if picks[i] == undefined then notes += "\n- No " + labels[i] + " texture found in the folder"
						else if not used[i] then notes += "\n- " + labels[i] + " texture found, but no matching bitmap slot in the preset"
					)
					if notes != "" do messageBox ("MatFromTex: " + m.name + notes + "\n\nSee the Listener for slot details.") title:"StrTools"
				)
			)
		)
	)

	-- runs the import and shows any error in a message box (not only in the Listener)
	fn plgRun root prefix:"" =
	(
		try(cmcPoliigon root prefix:prefix)
		catch ( local err = getCurrentException(); cmcLog ("MatFromTex error: " + err); messageBox ("MatFromTex failed:\n" + err) title:"StrTools" )
	)

	fn plgDragFx e =
	(
		local fx = dotNetClass "System.Windows.Forms.DragDropEffects"
		if e.Data.GetDataPresent (dotNetClass "System.Windows.Forms.DataFormats").FileDrop then e.Effect = fx.Copy else e.Effect = fx.None
	)

	fn cmcIsUvwMod m = (isKindOf m Uvwmap) or (isKindOf m Unwrap_UVW)

	fn cmcCopyMat =
	(
		if selection.count == 0 then strNotify "Select an object first."
		else
		(
			local obj = selection[1]
			local mods = #()
			-- bottom of the stack first, so pasting rebuilds the same order
			for i = obj.modifiers.count to 1 by -1 do
				if cmcIsUvwMod obj.modifiers[i] do append mods (copy obj.modifiers[i])
			CMC_clip = #(obj.material, mods, obj.name)
			cmcLog ("copied from " + obj.name + ": material " + (if obj.material != undefined then obj.material.name else "none") + ", " + (mods.count as string) + " UVW modifier(s)")
		)
	)

	fn cmcPasteMat =
	(
		if CMC_clip == undefined then strNotify "Nothing copied yet. Use CopyMat first."
		else if selection.count == 0 then strNotify "Select an object to paste onto."
		else
		(
			local n = 0
			undo "StrTools PasteMat" on
			(
				for obj in selection do
				(
					try
					(
						if CMC_clip[1] != undefined do obj.material = CMC_clip[1]
						if CMC_clip[2].count > 0 do
						(
							-- replace the target's existing UVW modifiers
							for i = obj.modifiers.count to 1 by -1 do
								if cmcIsUvwMod obj.modifiers[i] do deleteModifier obj i
							for m in CMC_clip[2] do addModifier obj (copy m)
						)
						n += 1
					)
					catch(cmcLog ("could not paste onto " + obj.name + ": " + (getCurrentException())))
				)
			)
			cmcLog ("pasted onto " + (n as string) + " object(s) from " + CMC_clip[3])
		)
	)

	-- =================================================================================
	-- DATA FILES: StrTools_Data folder (quotes.txt, ...) lives next to StrTools.ms
	-- =================================================================================
	-- full path of a file inside StrTools_Data (script folder first, then the install folder), undefined if missing
	fn strDataFile fileName =
	(
		local res = undefined
		for d in #(StrTools_srcDir, StrTools_installDir) while res == undefined do
			if d != undefined and d != "" and doesFileExist (d + "StrTools_Data\\" + fileName) do res = d + "StrTools_Data\\" + fileName
		res
	)

	-- one entry per non-empty line; lines starting with # are comments
	fn strReadLines path =
	(
		local r = #()
		local f = try(openFile path mode:"r")catch(undefined)
		if f != undefined do
		(
			local first = true
			while not (eof f) do
			(
				local ln = readLine f
				-- strip a UTF-8 BOM (Notepad adds one)
				if first and ln.count >= 3 and (bit.charAsInt ln[1]) == 239 and (bit.charAsInt ln[2]) == 187 and (bit.charAsInt ln[3]) == 191 do ln = substring ln 4 -1
				first = false
				ln = trimRight (trimLeft ln)
				if ln != "" and (substring ln 1 1) != "#" do append r ln
			)
			close f
		)
		r
	)

	/* Function: mapfiles/addmap */
	local mapfiles = #()
	fn addmap mapfile =
	(
		local mapfileN = mapfile as name
		local index = finditem mapfiles mapfileN
		if index == 0 do append mapfiles mapfileN
	)
	enumeratefiles addmap
	sort mapfiles
		
	/* Functions: Backface Culling */
	fn backfaceCullOff objs =
	(
		local pObj = 0
		local cObj = 0
		for obj in selection do 
		(
			pObj += 1
			format "turn backface cull off for: %\n" obj
			obj.backfaceCull = true
			cObj += 1
		)
		format "% objects processed.\n" pObj
		format "% objects changed.\n" cObj
	)

	fn backfaceCullOn objs =
	(
		local pObj = 0
		local cObj = 0
		for obj in selection do 
		(
			pObj += 1
			format "turn backface cull off for: %\n" obj
			obj.backfaceCull = false
			cObj += 1
		)
		format "% objects processed.\n" pObj
		format "% objects changed.\n" cObj
	)

	/* Functions: Viewport Material Display */
	fn setViewportShowOff theMat =
	(
		local subMtl = undefined
		if classof theMat == standardmaterial do theMat.showInViewport = false
		for i = 1 to getNumSubMtls theMat do
		(
			subMtl = getSubMtl theMat i
			if subMtl != undefined do setViewportShowOff subMtl 
		)
	)

	fn setViewportShowOn theMat =
	(
		local subMtl = undefined
		if classof theMat == standardmaterial do theMat.showInViewport = true
		for i = 1 to getNumSubMtls theMat do
		(
			subMtl = getSubMtl theMat i
			if subMtl != undefined do setViewportShowOn subMtl
		)
	)

	/* Functions: General Utilities */
	fn randColour =
	(
		local col = (color (random 0 255) (random 0 255) (random 0 255))
		col
	)
	
	local start_objs = objects as array
	
	fn detach_elems obj base_name = 
	(
		if convertToPoly obj != undefined do 
		(
			while polyOp.getNumFaces obj != 0 do 
			(
				local f_list = polyOp.getElementsUsingFace obj #{1}
				local elem = polyOp.detachFaces obj f_list asNode:true name:(uniqueName base_name)
			)
			delete obj
		)
	)
	
	fn reset_pivots coll = 
	(
		centerPivot coll
		worldAlignPivot coll
		resetXForm coll
		convertToPoly coll
	)


	-- =================================================================================
	-- ROLLOUT 1: GEOMETRY AND SHAPE
	-- =================================================================================
	rollout roll_Geometry "Geometry and Shape"
	(
		on rolledUp state do strSettingSet "Rollouts" "Geometry" state
		button btn_Smooth "Smooth" pos:[0,10] width:60 height:20 toolTip:"Smooth selected for:"
		spinner sp_Smooth "" range:[0,180,30] pos:[58,12] fieldWidth:50 toolTip:"Smooth selected for the input value." type:#integer

		button btn_objrename "Rename" pos:[0,50] width:60 height:20 toolTip:"Rename all selected."
		editText txt_nname text:"Object/Detach_Name" pos:[-3,31.5] fieldWidth:118 type:"New name of all selected/detached." 
		button btn_eldetach "Detach" pos:[60,50] width:60 height:20 toolTip:"Detach all elements in selected objects."

		-- Pivot Controls
		button btn_pivtop "T" pos:[0,70] width:20 height:20 toolTip:"Place selected objects pivots on top."
		button btn_pivcen "C" pos:[20,70] width:20 height:40 toolTip:"Place selected objects pivots in center."
		button btn_pivcust "P" pos:[40,70] width:20 height:20 toolTip:"Place pivot on object surface where you need it."
		button btn_pivbot "B" pos:[0,90] width:20 height:20 toolTip:"Place selected objects on bottom."
		button btn_pivzero "Z" pos:[40,90] width:20 height:20 toolTip:"Place selected objects pivots on 0 (xyz zero)."

		-- Mesh Cleanup Controls
		button btn_vertexSel "vSelect" pos:[120,10] width:60 height:20 toolTip:"Select vertices that uses only two edges.\nConverts selected objects to editable poly and makes vertex selected."
		button btn_dnormal "dNorm" pos:[120,30] width:60 height:20 toolTip:"Fixes muddy faces(Resets normals.).\nRight click to add Edit Normal modifier."
		button btn_oWeld "oWeld" pos:[120,50] width:60 height:20 toolTip:"Weld vertices on selected objects."
		button btn_unormal "uNormals" pos:[120,70] width:60 height:20 toolTip:"Unify normals on selected objects."
		button btn_xform "xForms" pos:[120,90] width:60 height:20 toolTip:"Resets xForm on selected objects and splines."
		button btn_edgeclean "eClean" pos:[60,70] width:60 height:20 toolTip:"Deletes edges on flat surfaces.\nIt leaves only borders and edges which are must have."

		-- Display Controls
		button btn_boxon "Box on/off" pos:[120,110] width:60 height:20 toolTip:"Display selected as box.\nRight click to disable box display"
		button btn_backFace "BFC on/off" pos:[120,130] width:60 height:20 toolTip:"Display selected Backface Cull.\nRight click to disable selected Backface Cull."
		
		-- Modeling Modifiers
		button btn_quadify "Quadify" pos:[0,110] width:60 height:20 toolTip:"Quadifies the selected mesh."
		button btn_insert "Insert" pos:[0,130] width:60 height:20 toolTip:"Insert edges and sets flow on selected edges normal."
		button btn_epoly "EditPoly" pos:[60,90] width:60 height:20 toolTip:"Adds edit poly modifier."
		button btn_shell "Shell" pos:[60,110] width:60 height:20 toolTip:"Adds shell modifier to selected objects as instance."
		
		-- FFD Modifiers
		button btn_ffd2 "f2" pos:[60,130] width:20 height:20 toolTip:"Adds FFD 2x2x2 modifier."
		button btn_ffd3 "f3" pos:[80,130] width:20 height:20 toolTip:"Adds FFD 3x3x3 modifier."
		button btn_ffd4 "f4" pos:[100,130] width:20 height:20 toolTip:"Adds FFD 4x4x4 modifier."

		-- --- Event Handlers ---

		on btn_backFace pressed do ( undo on backfaceCullOff $* )
		on btn_backFace rightclick do ( undo on backfaceCullOn $* )
		
		on btn_epoly pressed do ( undo on modPanel.addModToSelection (Edit_Poly ()) ui:on )
		
		on btn_oWeld pressed do
		(
			undo "Weld Vertices" on
			(
				with redraw off
				(
					for m in selection do
					(
						convertToMesh m
						meshOp.weldVertsByThreshold m.mesh m.mesh.verts 0.0001
						convertToPoly m
					)
				)
				redrawViews()
			)
		)

		on btn_unormal pressed do
		(
			undo "Unify Normals" on
			(
				fn uNormals obj = ( meshop.unifyNormals obj #{1..obj.numFaces} )
				fn nFace nMesh sel =
				(
					for m in sel do
					(
						convertToMesh m
						meshOp.weldVertsByThreshold m.mesh m.mesh.verts 0.0001
						if ( classof m.baseobject == Editable_Mesh ) then
						(
							with redraw off ( nMesh m )
							redrawViews();
							update m
						) else ()
						convertToPoly m
					)
				)
				nFace uNormals selection
			)
		)

		on btn_vertexSel pressed do
		(
			undo "Select Vertices" on
			(
				if selection.count != 0 do
				(
					macros.run "Modifier Stack" "Convert_to_Poly"
					for o in selection do
					(
						fn VerticesSel obj = ( obj.selectedverts = (for i in 1 to obj.numverts where obj.GetVertexEdgeCount i == 2 collect i) )
						VerticesSel o
						subobjectLevel = 1
					)
				)
			)
		)

		on btn_Smooth pressed do
		(
			undo "Smooth" on
			(
				max create mode
				fn aSmooth tresh: = ( addModifier selection (smooth autosmooth:true preventIndirect:true threshold:tresh) )
				aSmooth tresh:sp_smooth.value
				for o in selection where isKindOf o GeometryClass and not isKindOf o Targetobject do
				(
					maxOps.CollapseNode o off
				)
			)
		)

		on btn_dnormal pressed do
		(
			undo "Flip Normals" on
			(
				max create mode
				if selection.count != 0 do
				(
					local rNormals = Normalmodifier unify:true flip:true
					for o in selection where isKindOf o GeometryClass and not isKindOf o Targetobject do
					(
						addmodifier o rNormals
						addmodifier o rNormals
						maxOps.CollapseNode o off
					)
				)
			)
		)

		on btn_dnormal rightclick do
		(
			undo "Flip Normals" on
			(
				if selection.count != 0 do
				(
					local eNormals = modPanel.addModToSelection (Edit_Normals ())
					for o in selection where isKindOf o GeometryClass and not isKindOf o Targetobject do ( eNormals )
				)
			)
		)

		on btn_ffd2 pressed do ( undo "FFD 2x2x2" on if selection.count!=0 do modPanel.addModToSelection (FFD_2x2x2 ()) ui:on )
		on btn_ffd3 pressed do ( undo "FFD 3x3x3" on if selection.count!=0 do modPanel.addModToSelection (FFD_3x3x3 ()) ui:on )
		on btn_ffd4 pressed do ( undo "FFD 4x4x4" on if selection.count!=0 do modPanel.addModToSelection (FFD_4x4x4 ()) ui:on )

		-- Helper function for Shell modifier application
		fn applyModifierRecursively node modifier_instance =
		(
			if iskindof node GeometryClass and not iskindof node Light and not iskindof node Camera and not iskindof node Helper then
			(
				addModifier node modifier_instance
			)
			if iskindof node GroupHead then
			(
				for child in node.children do ( applyModifierRecursively child modifier_instance )
			)
		)

		on btn_shell pressed do
		(
			if selection.count == 0 then 
				messagebox "No objects are currently selected." title:"Shell Modifier Application"
			else
			(
				local initial_selection = selection as array
				with undo on
				(
					max modify mode 
					local shell_template = Shell()
					
					-- Apply recursively to all objects in stored selection
					for obj in initial_selection do ( applyModifierRecursively obj shell_template )
					
					redrawViews() 	
					
					-- Force selection refresh on modify panel
					local first_geo_object = undefined
					for obj in initial_selection do
					(
						if iskindof obj GeometryClass and not iskindof obj Light then
						(
							first_geo_object = obj
							exit
						)
					)
					if first_geo_object != undefined then
					(
						select first_geo_object
						modPanel.setCurrentObject first_geo_object 
					)
				) 
				select initial_selection
			)
		)

		on btn_pivcust pressed do
		(
			undo "Pivot To Click" on
			(
				local pp = pickpoint snap:#3d
				if (classof pp == Point3) do
				(
					local rr = mapScreenToWorldRay mouse.pos
					local bestObj = undefined
					local bestPos = undefined
					local bestDist = 1e30
					-- nearest object hit by the ray (was: first object in scene order)
					for o in geometry where not o.isHidden and not o.isFrozen do
					(
						local hit = intersectRay o rr
						if hit != undefined do
						(
							local d = distance rr.pos hit.pos
							if d < bestDist do ( bestDist = d; bestObj = o; bestPos = hit.pos )
						)
					)
					if bestObj != undefined do ( bestObj.pivot = bestPos; select bestObj )
				)
			)
		)

		-- Pivot Operations
		on btn_pivcen pressed do
		(
			undo "Pivot Center" on
			(
				with redraw off ( for i in selection do (local obj = i; CenterPivot obj) )
				redrawViews()
			)
		)
		on btn_pivbot pressed do
		(
			undo "Pivot Bottom" on
			(
				with redraw off ( for i in selection do (local obj = i; CenterPivot obj; obj.pivot = [obj.pivot.x, obj.pivot.y, obj.min.z]) )
				redrawViews()
			)
		)
		on btn_pivtop pressed do
		(
			undo "Pivot Top" on
			(
				with redraw off ( for i in selection do (local obj = i; CenterPivot obj; obj.pivot = [obj.pivot.x, obj.pivot.y, obj.max.z]) )
				redrawViews()
			)
		)
		on btn_pivzero pressed do
		(
			undo "Pivot To Zero" on
			(
				with redraw off ( for i in selection do (local obj = i; obj.pivot = [0,0,0]) )
				redrawViews()
			)
		)

		on btn_boxon pressed do ( undo "Box Mode On" on ( for o in selection do o.boxmode = on ) )
		on btn_boxon rightclick do ( undo "Box Mode Off" on ( for o in selection do o.boxmode = off ) )

		on btn_insert pressed do
		(
			undo "Insert Loop" on
			(
				if selection.count != 0 do
				(
					macros.run "PolyTools" "InsertLoop"
					macros.run "PolyTools" "SetFlow"
				)
			)
		)

		on btn_quadify pressed do
		(
			local selectedobjs = selection as array
			undo "Quadify" on
			(
				max create mode
				for o in selectedobjs where isKindOf o GeometryClass do
				(
					select o
					macros.run "Modifier Stack" "Convert_to_Poly"
					PolyToolsModeling.Quadrify off off
					clearSelection()
				)
			)
		)

		on btn_edgeclean pressed do
		(
			local selectedobjs = selection as array
			undo "Edge Clean" on
			(
				if selection.count != 0 do
				(
					for o in selectedobjs do 
					(
						select o
						macros.run "Modifier Stack" "Convert_to_Poly"
						strExecAction 369982487 "40005" -- Border Level
						subobjectLevel = 3
						strExecAction 0 "40021"
						o.EditablePoly.SetSelection #Edge ((polyOp.getOpenEdges o) as bitarray)
						strExecAction 369982487 "40004"
						subobjectLevel = 2
						strExecAction 0 "40044"
						o.EditablePoly.Remove ()
						strExecAction 369982487 "40006" -- Face Level
						subobjectLevel = 4
						strExecAction 0 "40021"
						o.EditablePoly.SetSelection #Face ((polyOp.getFaceSelection o) as bitarray)
						o.EditablePoly.retriangulate 1
					)
					macros.run "Modifier Stack" "Convert_to_Poly"
				)
			)
		)

		on btn_xform pressed do
		(
			undo "Reset XForm" on
			(
				if selection.count != 0 do
				(
					with redraw off ( for o in Selection do( resetxform o; maxOps.CollapseNode o off ) )
				)
			)
		)

		on btn_eldetach pressed do
		(
			local n_name = txt_nname.text
			local n_objs = for obj in selection where superClassOf obj == geometryClass collect obj
			for obj in n_objs do detach_elems obj n_name
		)

		on btn_objrename pressed do
		(
			undo "Rename Objects" on
			(
				with redraw off ( for obj in selection do ( obj.name = uniquename txt_nname.text ) )
			)
		)
	)

	-- =================================================================================
	-- ROLLOUT 2: SELECTIONS
	-- =================================================================================
	rollout roll_Selections "Selections"
	(
		on rolledUp state do strSettingSet "Rollouts" "Selections" state
		-- --- UI Controls ---
		dropdownlist dd_selections items:#("Scene", "Proxy", "Lights", "Cameras", "Geometry","Splines","Helpers","Obj-ID", "Materials", "Copy/Paste") width:70 height:20 pos:[0,10] tooltip:"Right click to refresh the list."
		checkbutton ch_Interactive "Interactive" pos:[110,10] checked:true tooltip:"Interactive selection." width:70
		button btn_Select "Select" pos:[70,10] width:40 tooltip:"Select objects selected in the list."
		
		MultiListBox lb pos:[0,34] width:180 height:11

		-- Quick Selection Buttons
		
		button btn_allLights "Light" pos:[0,190] width:40 height:20 tooltip:"Select all Lights in viewport.\nRight click to select all Lights in scene."
		button btn_allCameras "Cam" pos:[40,190] width:40 height:20 tooltip:"Select all Cameras in viewport.\nRight click to select all Cameras in scene."
		button btn_allGeometry "Geo" pos:[80,190] width:40 height:20 tooltip:"Select all Geometry in viewport.\nRight click to select all Geometry in scene."
		
		button btn_allProxy "Proxy" pos:[0,210] width:40 height:20 tooltip:"Select all Proxies in scene."
		button btn_allSplines "Spline" pos:[40,210] width:40 height:20 tooltip:"Select all Splines and Shapes in viewport.\nRight click to select all Splines in scene."
		button btn_allHelpers "Helper" pos:[80,210] width:40 height:20 tooltip:"Select all Helpers in viewport.\nRight click to select all Helpers in scene."
		
		button btn_noMat "NoMat" pos:[120,190] width:60 height:20 tooltip:"Selects all objects without materials."

		button btn_sRandom "%" pos:[120,210] width:20 height:20 tooltip:"Random select objects from current selection."
		spinner sp_rnd "" range:[0,100,100] pos:[138,212] fieldWidth:29 toolTip:"Percentage to select." type:#integer arrowHidden:true
		
		-- Dropdown and ListBox Logic
		fn strSortedNames arr = ( sort arr; arr )

		fn PopulateListBox =
		(
			-- Reset Listbox Selection and Scene Selection
			lb.selection = 0
			clearselection ()

			case dd_selections.selected of
			(
				"Proxy": ( lb.items = strSortedNames (for o in geometry where classOf o == VRayProxy or classOf o == CProxy collect o.name) )

				"Lights": ( lb.items = strSortedNames (for o in lights collect o.name) )

				"Cameras": ( lb.items = strSortedNames (for o in cameras collect o.name) )

				"Geometry": ( lb.items = strSortedNames (for o in geometry where classOf o != VRayProxy and classOf o !=CProxy collect o.name) )

				"Scene": ( lb.items = strSortedNames (for o in objects collect o.name) )

				"Splines": ( lb.items = strSortedNames (for o in shapes collect o.name) )

				"Helpers": ( lb.items = strSortedNames (for o in helpers collect o.name) )

				"Obj-ID":
				(
					fn oCompare el1 el2 = ( (el1 as integer) - (el2 as integer) )
					local oIDs = for oID in objects collect oID.gbufferchannel as string
					local uniqueSortedIDs = makeUniqueArray oIDs
					qsort uniqueSortedIDs oCompare -- numeric order (was text order: 1,10,2)
					lb.items = uniqueSortedIDs
				)

				"Materials":
				(
					local matNames = #()
					for aMtlType in material.classes do
					(
						for aMtl in (getClassInstances aMtlType processAllAnimatables:true) do
						(
							if (findItem sceneMaterials aMtl) != 0 do (append matNames aMtl)
						)
					)
					local matUsed = for m in matNames collect m.name
					sort matUsed
					lb.items = matUsed
				)

				"Copy/Paste":
				(
					local baseDir = (getdir #autoback)
					local baseName = "StrTools_mergefile"
					local searchPattern = baseDir + "\\" + baseName + "*"
					
					local fullPathList = getFiles searchPattern
					local fileNameList = #()

					for f in fullPathList do
					(
						append fileNameList (filenameFromPath f)
					)
					lb.items = fileNameList
					fileNameList
				)
			)
		) 
		
		-- Helper function to safely get the current selection
		fn getCurrentSelection =
		(
			local sel = #()
			for o in selection do append sel o
			return sel
		)
		
		-- --- Event Handlers ---
		
		fn doRandomSelection =
		(
			undo "Random Selection" on
			(
				local cArray = for o in selection where classof o != TargetObject collect o
				local sPerc = sp_rnd.value 
				
				if cArray.count > 0 and sPerc > 0 then
				(
					local sArray = #()
					local nSelect = (sPerc / 100.0 * cArray.count) as integer
					if nSelect > cArray.count then nSelect = cArray.count

					while sArray.count < nSelect do
					(
						local nRandomIndex = random 1 cArray.count
						if findItem sArray cArray[nRandomIndex] == 0 do 
							append sArray cArray[nRandomIndex]
					)
					select sArray
				)
				else 
				(
					select #() 
				)
			)
		)

		on sp_rnd entered do
		(
			-- Handles the Enter key press.
		)
		
		on btn_sRandom pressed do
		(
			doRandomSelection()
		)
		
		on btn_noMat pressed do
		(
			select (for g in geometry where g.material==undefined collect g)
		)

		on roll_Selections open do
		(
			btn_Select.enabled = false
		)

		-- Category Selection Helpers
		on btn_allHelpers pressed do
		(
			SetSelectFilter 6
			strExecAction 0 "40021"
			max select all
			SetSelectFilter 1
		)
		on btn_allHelpers rightclick do
		(
			select (for h in helpers where h.category == #standard or h != TargetObject collect h)
		)

		on btn_allLights pressed do
		(
			SetSelectFilter 4
			strExecAction 0 "40021"
			max select all
			SetSelectFilter 1
		)
		on btn_allLights rightclick do ( select (for l in lights collect l) )

		on btn_allCameras pressed do
		(
			SetSelectFilter 5
			strExecAction 0 "40021"
			max select all
			SetSelectFilter 1
		)
		on btn_allCameras rightclick do ( select (for c in cameras collect c) )

		on btn_allSplines pressed do
		(
			SetSelectFilter 3
			strExecAction 0 "40021"
			max select all
			SetSelectFilter 1
		)
		on btn_allSplines rightclick do ( select (for s in shapes collect s) )

		on btn_allGeometry pressed do
		(
			SetSelectFilter 2
			strExecAction 0 "40021"
			max select all
			SetSelectFilter 1
			select(for o in selection where classOf o != VRayProxy and classOf o !=CProxy collect o)
		)
		on btn_allGeometry rightclick do
		(
			select(for o in geometry where classOf o != VRayProxy and classOf o !=CProxy collect o)
		)

		on btn_allproxy pressed do
		(
			select (for o in objects where classOf o == VRayProxy or classOf o == CProxy collect o)
		)

		-- objects whose material name / object ID matches any picked list item (single pass over the scene)
		fn strObjectsForPickedItems mode =
		(
			local wanted = for i in (lb.selection as array) collect lb.items[i]
			local res = #()
			if mode == "Materials" then
			(
				for o in objects do
				(
					local mn = try(o.material.name)catch(undefined)
					if mn != undefined and (findItem wanted mn) > 0 do append res o
				)
			)
			else
			(
				local ids = for w in wanted collect (w as integer)
				for o in objects where (findItem ids o.gbufferchannel) > 0 do append res o
			)
			res
		)

		on ch_Interactive changed state do
		(
			if state == off then btn_Select.enabled = true else btn_Select.enabled = false
		)

		-- Dropdown Handlers
		on dd_selections rightclick do
		(
			PopulateListBox()
		)

		on dd_selections selected sel do
		(
			PopulateListBox()
		)
			
		on lb selected sel do
		(
			if ch_Interactive.checked then
			(
				if dd_selections.selected == "Materials" then
				(
					select (strObjectsForPickedItems "Materials")
				)
				
				if dd_selections.selected == "Copy/Paste" then
				(
					-- Store the CURRENT selection before the merge starts.
					local initialSelection = #()
					initialSelection = getCurrentSelection()

					local sArray = #() 
					
					progressStart "Merging selected files..."
					for i in (lb.selection as array) do
					(
						local filename = lb.items[i]
						local clipFile = pathConfig.appendPath (getdir #autoback) filename
						
						print clipFile
						
						local percent = (100.0 * i / lb.selection.count)
						progressUpdate percent
						if doesFileExist clipFile then
						(
							mergemaxfile clipFile #select #autoRenameDups #useMergedMtlDups
							
							-- Combine the new selection (the merged objects) with the initial selection.
							if initialSelection.count == 0 then
							(
								initialSelection = $
							)
							else
							(
								initialSelection = initialSelection + $
							)
						)
					)
					progressEnd()
					-- Final step: Set the scene selection to include ALL merged objects.
					select initialSelection
				)
				else
				(
					if dd_selections.selected == "Obj-ID" then
					(
						select (strObjectsForPickedItems "Obj-ID")
					)
					else
					(
						select (for o in lb.selection collect getnodebyname lb.items[o])
					)
				)
			)
		)

		on btn_Select pressed do
		(
			if dd_selections.selected == "Materials" then
			(
				select (strObjectsForPickedItems "Materials")
			)
			else
			(
				if dd_selections.selected == "Obj-ID" then
				(
					select (strObjectsForPickedItems "Obj-ID")
				)
				else
				(
					select (for o in lb.selection collect getnodebyname lb.items[o])
				)
			)
		)
	)

	-- =================================================================================
	-- ROLLOUT 3: MODIFICATIONS
	-- =================================================================================
	rollout roll_Modify "Modifications" 
	(
		on rolledUp state do strSettingSet "Rollouts" "Modify" state
		-- --- UI Controls ---
		-- Lights/Camera/Materials
		button btn_On "On" pos:[60,10] width:30 height:20 tooltip:"Enables all selected Lights, Cameras (Targeting), and Plugin objects (Forest Pack, TyFlow, etc.)."
		button btn_Off "Off" pos:[90,10] width:30 height:20 tooltip:"Disables all selected Lights, Cameras (Targeting), and Plugin objects (Forest Pack, TyFlow, etc.)."

		spinner sp_kelvin "" range:[110,30000,6500] pos:[118,12] fieldWidth:50 toolTip:"Change selected Lights temperature and Cameras white balance."
		button btn_matonoff "vMaterial" pos:[60,30] width:60 height:20 tooltip:"Left click to show materials in viewport.\nRight click to hide materials in viewport."
		button btn_lock "Lock" pos:[60,50] width:60 height:20 tooltip:"Left click to Lock selected objects.\nRight click to unlock selected objects.\n(If locking camera or sun, it will also lock their target)."

		-- Proxies
		button btn_proxycloud "C" pos:[120,30] width:20 height:20 tooltip:"Display selected proxies as Point Cloud (Corona) and Faces (Vray)."
		button btn_proxybox "B" pos:[140,30] width:20 height:20 tooltip:"Display selected proxies as Box."
		button btn_proxymesh "M" pos:[160,30] width:20 height:20 tooltip:"Display selected proxies as mesh."

		-- Randomization and Transform
		spinner sp_x "X" range:[0,9999,0] pos:[0,12] fieldWidth:40 toolTip:"Randomness on X axis.\nMinimun % for scale"
		spinner sp_y "Y" range:[0,9999,0] pos:[0,32] fieldWidth:40 toolTip:"Randomness on Y axis.\nMaximum % for scale"
		spinner sp_z "Z" range:[0,9999,0] pos:[0,52] fieldWidth:40 toolTip:"Randomness on Z axis."

		button btn_rnd_move "M" pos:[0,70] width:20 height:20 tooltip:"Randomize positions on LOCAL axes.\nRight click to use WORLD axes."
		button btn_rnd_rotate "R" pos:[20,70] width:20 height:20 tooltip:"Randomize rotations on LOCAL axes.\nRight click to use WORLD axes."
		button btn_rnd_scale "S" pos:[40,70] width:20 height:20 tooltip:"Randomize scale on LOCAL axes.\nX input=Minimum, Y input=Maximum."

		-- Utilities
		pickbutton btnObjPick "Instancer" pos:[60,70] width:120 height:20.5 tooltip:"Pick object for instancing.\nRight click to replace selected objects."
		local instObj = undefined -- object picked for instancing
		button btn_attach "sAttach" pos:[120,50] width:60 height:20 tooltip:"Right click to Attach all selected into single object."

		spinner sp_oID "ID" range:[0,999,0] pos:[2,92] fieldWidth:27 toolTip:"Assign ID to selected." type:#integer
		button btnMotivate "Motivation" pos:[60,90] width:60 height:20 tooltip:"Get motivated!"
		
		button btn_flattenX "X" pos:[120,90] width:20 height:20 tooltip:"Flatten selected on X axis"
		button btn_flattenY "Y" pos:[140,90] width:20 height:20 tooltip:"Flatten selected on Y axis"
		button btn_flattenZ "Z" pos:[160,90] width:20 height:20 tooltip:"Flatten selected on Z axis"
		
		-- --- Event Handlers ---
		fn showRandomQuote =
		(
			local qf = strDataFile "quotes.txt"
			if qf == undefined do ( strEnsureQuotes(); qf = strDataFile "quotes.txt" )
			local qs = if qf != undefined then (strReadLines qf) else #()
			if qs.count == 0 then messageBox ("No quotes found.\nPut a quotes.txt (one quote per line) in:\n" + StrTools_installDir + "StrTools_Data\\") title:"Motivation!"
			else messageBox (qs[(random 1 qs.count)]) title:"Motivation!"
		)
		
		on btnMotivate pressed do
		(
			showRandomQuote()
		)
	
		on btnObjPick picked obj do
		(
			if obj != undefined do
			(
				instObj = obj
				btnObjPick.text = obj.name
			)
		)

		on btnObjPick rightclick do
		(
			if btnObjPick.text != "Instancer" then
			(
				undo "Instancer Replace" on
				(
					local sel = selection as array
					local total = sel.count
					
					if total > 0 then
					(
						progressStart "Instancing Objects..."
						
						-- Make all selected objects unique so instanceReplace works properly
						InstanceMgr.MakeObjectsUnique sel #individual

						local idx = 0
						for i in sel do
						(
							idx += 1
							instanceReplace i instObj
							
							i.name = uniquename btnObjPick.text
							i.mat  = instObj.mat
							
							-- Correct progress bar calculation
							local percent = (100.0 * idx / total)
							progressUpdate percent
						)
						progressEnd()
					)
				)
				btnObjPick.text = "Instancer"
			)
		)

		on sp_oID changed val do
		(
			undo "Object ID" on
			(
				with redraw off ( for o in selection do ( o.gbufferchannel = sp_oID.value ) )
			)
		)

		fn toggleMatOverrides =
		(
			max create mode
			strExecAction 0 "63545"   -- material on
		)

		fn toggleMatOverridesOff =
		(
			max create mode
			strExecAction 0 "63544"   -- material off
		)

		on btn_matonoff pressed do undo "Material On" on toggleMatOverrides()
		on btn_matonoff rightclick do undo "Material Off" on toggleMatOverridesOff()

		on btn_flattenX pressed do ( undo on selection.scale.x = 0 )
		on btn_flattenY pressed do ( undo on selection.scale.y = 0 )
		on btn_flattenZ pressed do ( undo on selection.scale.z = 0 )

		on btn_attach rightclick do
		(
			undo "Attach Selected Objects" on
			(
				max modify mode
				
				-- explode possible groups
				explodeGroup selection
				
				-- filter valid geometry objects
				local gCollect = for o in selection where
				(
					superClassOf o == geometryClass
				) collect o
				
				if gCollect.count < 2 then
				(
					strNotify "Select at least 2 geometry objects."
					return false
				)
				
				-- choose first object as base
				local baseObj = gCollect[1]
				
				-- ensure base is Editable Poly Node
				if classOf baseObj != Editable_Poly do
					convertToPoly baseObj
				
				progressStart "Attaching objects..."
				
				local total = gCollect.count - 1
				local idx = 0
				
				for i = 2 to gCollect.count do
				(
					idx += 1
					local obj = gCollect[i]
					
					if obj != undefined do
					(
						-- ensure each incoming object is Editable Poly too
						if classOf obj != Editable_Poly do
							convertToPoly obj
						
						-- THIS is the crucial, reliable attach method
						polyop.attach baseObj obj deleteSource:true
						
						progressUpdate (idx as float / total * 100)
					)
				)
				progressEnd()
				select baseObj
				update baseObj
			)
		)

		-- the objects a random transform acts on: group members count as their group,
		-- target objects and non-group helpers are skipped
		fn strCollectTransformTargets =
		(
			local result = #()
			for obj in selection as array do
			(
				local effectiveObj = obj
				if isGroupMember obj do effectiveObj = obj.parent
				if (not isKindOf effectiveObj TargetObject) and \
				   (not isKindOf effectiveObj Helper or isGroupHead effectiveObj) do
				(
					appendIfUnique result effectiveObj
				)
			)
			result
		)

		-- one loop for all random transforms; each handler keeps its own undo label
		-- mode: #move #moveAbs #rotate #rotateEuler #scale
		fn strRandomTransformDo mode =
		(
			local objectsToModify = strCollectTransformTargets()
			with redraw off
			(
				for obj in objectsToModify do
				(
					case mode of
					(
						#scale:
						(
							local scN = random sp_x.value sp_y.value * 0.01
							obj.scale = [scN,scN,scN]
						)
						default:
						(
							local newx = random -sp_x.value sp_x.value
							local newy = random -sp_y.value sp_y.value
							local newz = random -sp_z.value sp_z.value
							case mode of
							(
								#move: obj.transform = transmatrix [newx,newy,newz] * obj.transform
								#moveAbs: move obj [newx,newy,newz]
								#rotate:
								(
									obj.transform = rotateXMatrix newx * obj.transform
									obj.transform = rotateYMatrix newy * obj.transform
									obj.transform = rotateZMatrix newz * obj.transform
								)
								#rotateEuler: rotate obj (eulerangles newx newy newz)
							)
						)
					)
				)
			)
			redrawViews()
		)

		on btn_rnd_move pressed do ( undo "Random Move" on ( strRandomTransformDo #move ) )
		on btn_rnd_move rightclick do ( undo "Random Move Absolute" on ( strRandomTransformDo #moveAbs ) )
		on btn_rnd_rotate pressed do ( undo "Random Rotate" on ( strRandomTransformDo #rotate ) )
		on btn_rnd_rotate rightclick do ( undo "Random Rotate Euler" on ( strRandomTransformDo #rotateEuler ) )
		on btn_rnd_scale pressed do ( undo "Random Scale" on ( strRandomTransformDo #scale ) )
		
		fn SetOnOffState state =
		(
			undo "Toggle State" on
			(
				-- Invert the state for properties like 'disabled' used by iToo plugins
				local disabledState = not state

				for o in selection do
				(
					try
					(
						----------------------------------------------------------
						-- 1. NATIVE LIGHTS & CAMERAS (Use .on or .targeted)
						----------------------------------------------------------
						-- V-Ray, Corona, Arnold, Standard Lights (Combined logic)
						if (classOf o == VRayLight or classOf o == VRayIES or classOf o == VRaySun or classOf o == VRayAmbientLight or classOf o == CoronaLight or classOf o == CoronaSun or classOf o == CoronaIES or classOf o == ArnoldLight or (superclassOf o == Light and hasProperty o "on")) do o.on = state
						
						-- Cameras (Targeting)
						if (classOf o == Physical or classOf o == VRayPhysicalCamera or classOf o == VRayDomeCamera or classOf o == CoronaCamera) do o.targeted = state

						----------------------------------------------------------
						-- 2. PLUGINS (Handle disabled/on/active)
						----------------------------------------------------------
						
						-- Forest Pack & RailClone (Uses the inverted 'disabled' property)
						if (classOf o == Forest_Pro or classOf o == RailClone_Pro) do 
						(
							if hasProperty o "disabled" do o.disabled = disabledState
						)
						
						-- TyFlow, Chaos Scatter, Anima (Use standard .on)
						if (classOf o == tyFlow or classOf o == ChaosScatter or classOf o == CScatter or classOf o == AnimaScene) do 
						(
							if hasProperty o "on" do o.on = state
						)
						
						----------------------------------------------------------
						-- 3. CLIPPERS (Use .enabled)
						----------------------------------------------------------
						if (classOf o == VRayClipper) do o.enabled = state
					)
					catch ( strLogErr ("On/Off state failed on " + o.name) (getCurrentException()) )
				)
			)
		)

		on btn_On pressed do SetOnOffState true
		on btn_Off pressed do SetOnOffState false

		on sp_kelvin changed val do
		(
			for k in selection where classOf k == VRayLight do ( k.color_mode = 1; k.color_temperature = val )
			for k in selection where classOf k == CoronaLight do ( k.colorMode = 1; k.blackbodyTemp = val )
			for k in selection where classOf k == CoronaSun do ( k.colorMode = 1; k.blackbodyTemperature = val )
			for k in selection where classOf k==Physical do ( k.white_balance_type = 1; k.white_balance_kelvin = val )
			for k in selection where classOf k==VRayPhysicalCamera do ( k.whiteBalance_preset = 7; k.temperature = val )
		)

		fn getSelectionWithTargets sel =
		(
			local result = for o in sel collect o
			for o in sel do
			(
				if isProperty o #target and o.target != undefined do
					appendIfUnique result o.target
			)
			result
		)

		fn toggleLock sel lockState =
		(
			if sel.count > 0 then
			(
				local objs = getSelectionWithTargets sel
				setTransformLockFlags objs lockState

				macros.run "Lights and Cameras" "Camera_SelectTarget"
				macros.run "Selection" "SelectCameraFromTarget"

				setTransformLockFlags objs lockState
			)
		)

		on btn_lock pressed do
		(
			toggleLock selection #all
		)

		on btn_lock rightclick do
		(
			toggleLock selection #none
		)

		fn setProxyDisplayMode obj mode =
		(
			/* mode: #cloud, #box, #mesh */
			case (classof obj) of
			(
				/* CHAOS / VRAY */
				VRayProxy:
				(
					case mode of
					(
						#cloud: obj.display = 3          -- full point cloud
						#mesh:  obj.display = 4          -- full mesh
						#box:   obj.display = 0          -- bounding box
					)
				)
				VRayProxy2:   -- newer VRayMesh
				(
					case mode of
					(
						#cloud: obj.previewType = 1      -- point cloud (similar)
						#mesh:  obj.previewType = 2      -- full mesh
						#box:   obj.previewType = 0      -- box
					)
				)
				/* CORONA */
				CoronaProxy:
				(
					case mode of
					(
						#cloud: obj.display = 3 -- if cloud unavailable this is closest
						#mesh:  obj.display = 2
						#box:   obj.display = 1
					)
				)
				/* ARNOLD */
				ArnoldStandin:
				(
					case mode of
					(
						#cloud: obj.display = 1          -- points (closest to cloud)
						#mesh:  obj.display = 2
						#box:   obj.display = 0
					)
				)
				/* REDSHIFT */
				RedshiftProxy:
				(
					case mode of
					(
						#cloud: obj.displayMode = 2      -- points mode
						#mesh:  obj.displayMode = 1
						#box:   obj.displayMode = 0
					)
				)
				/* FSTORM / OCTANE */
				fstormProxy:
				(
					case mode of
					(
						#cloud: obj.display = 2
						#mesh:  obj.display = 1
						#box:   obj.display = 0
					)
				)
				OctaneProxy:
				(
					case mode of
					(
						#cloud: obj.displayMode = 2
						#mesh:  obj.displayMode = 1
						#box:   obj.displayMode = 0
					)
				)
				/* YOUR cProxy */
				cProxy:
				(
					case mode of
					(
						#cloud: obj.previzType = 2
						#mesh:  obj.previzType = 3
						#box:   obj.previzType = 0
					)
				)
			)
		)

		fn applyToSelection mode =
		(
			max create mode
			for o in selection do setProxyDisplayMode o mode
		)

		on btn_proxycloud pressed do applyToSelection #cloud
		on btn_proxybox   pressed do applyToSelection #box
		on btn_proxymesh  pressed do applyToSelection #mesh
	)

	-- =================================================================================
	-- ROLLOUT 4: MATERIALS AND MAPPING
	-- =================================================================================
	rollout roll_Materials "Materials and Mapping"
	(
		on rolledUp state do strSettingSet "Rollouts" "Materials" state
		-- --- UI Controls ---
		-- Hidden controls
		radiobuttons rb1 "" labels:#("VrayNormalMap", "NormalMap") columns:2 pos:[-200,10] visible:false
		radiobuttons UVaxis labels:#("U","V","UV") default:3 visible:false

		-- UVW Mapping
		button btn_uvwbox "B" pos:[60,10] width:20 height:20 tooltip:"Box mapping on selected objects."
		button btn_uvwplane "P" pos:[80,10] width:20 height:20 tooltip:"Plane mapping on selected objects."
		button btn_Cylind "C" pos:[100,10] width:20 height:20 tooltip:"Cylindrical mapping on selected objects."
		spinner spn_uvwsize "" range:[1,99999,600] pos:[-2,12] fieldWidth:50 toolTip:"Size of UVW."
		
		-- UVW XForm / Unwrap
		button btn_rxfElem "Autoflat" pos:[120,10] width:60 height:20 tooltip:"Quick Unwrap on selected object.\nMore faces in object=slower!"
		button btn_rxfObj "xObjects" pos:[0,50] width:60 height:20 tooltip:"Random UV offset on selected objects.\nRight Click for the elements in selected objects\nIf angle is selected, UV will be rotated by selected angle.\nIf faces are selected in objects randomization will occur only on selected faces."
		button btn_uvwxform "xF" pos:[160,50] width:20 height:20 tooltip:"Applies UVW xForm modifier on selected objects."
		dropdownlist drop_rotate "" items:#("0", "45", "90", "180", "360", "45/90") pos:[60,50] width:60 tooltip:"UVW xForm rotations."
		spinner spn_rxMch "" range:[1,999,1] pos:[118,52] fieldWidth:30 toolTip:"Map Channel." type:#integer

		-- Material Tools
		button btn_matdel "mRemove" pos:[0,70] width:60 height:20 tooltip:"Removes materials on selected objects."
		button btn_displ "dDisplace" pos:[60,70] width:60 height:20 tooltip:"Disables displacement on all applied materials.\nRight click enables displacement."
		button btn_mat "Mat Wire" pos:[0,30] width:60 height:20 tooltip:"Random wirecolor by material for all object in scene.\nRight click for selection."
		button btn_rand "Rnd Wire" pos:[60,30] width:60 height:20 tooltip:"Random wirecolors for all object in scene.\nRight click for selection."
		
		button btn_Collector "Collector" pos:[120,70] width:60 height:20 toolTip:"Left-click: Collect all scene assets into 'assets' folder.\nRight-click: Relink assets to the collected copies (experimental)."

		-- Corona material preset / CopyMat / PasteMat
		button btn_cMtl "Corona Mtl" pos:[0,90] width:80 height:20 tooltip:"Loads the Corona Physical preset into the active slot and adds it to Slate.\nGloss: use glossiness instead of roughness."
		checkbox cb_gloss "Gloss" pos:[88,92] width:50 tooltip:"Glossiness mode instead of roughness."
		button btn_copyMat "CopyMat" pos:[0,130] width:90 height:20 tooltip:"Copies material and UVW modifiers (UVW Map / Unwrap) from the first selected object."
		button btn_pasteMat "PasteMat" pos:[90,130] width:90 height:20 tooltip:"Pastes copied material and UVW modifiers onto selected objects."
		dotNetControl btn_poliigon "System.Windows.Forms.Button" pos:[0,110] width:80 height:20
		local plgTip


		-- --- Event Handlers ---

		on roll_materials open do
		(
			-- MatFromTex button (dotNet so it can accept a dropped folder or texture), styled like the native buttons
			try
			(
				local dnC = dotNetClass "System.Drawing.Color"
				local bg = (colorMan.getColor #background) + [0.08, 0.08, 0.08]
				local fg = colorMan.getColor #text
				btn_poliigon.FlatStyle = (dotNetClass "System.Windows.Forms.FlatStyle").Flat
				btn_poliigon.BackColor = dnC.FromArgb ((amin 255 (bg.x * 255)) as integer) ((amin 255 (bg.y * 255)) as integer) ((amin 255 (bg.z * 255)) as integer)
				btn_poliigon.ForeColor = dnC.FromArgb ((fg.x * 255) as integer) ((fg.y * 255) as integer) ((fg.z * 255) as integer)
				btn_poliigon.FlatAppearance.BorderColor = dnC.FromArgb 90 90 90
			)
			catch ( strLogErr "MatFromTex button colours" (getCurrentException()) )
			btn_poliigon.Text = "MatFromTex"
			btn_poliigon.AllowDrop = true
			try ( btn_poliigon.Font = dotNetObject "System.Drawing.Font" "Tahoma" 8.0 ) catch ( strLogErr "MatFromTex button font" (getCurrentException()) )
			plgTip = dotNetObject "System.Windows.Forms.ToolTip"
			plgTip.SetToolTip btn_poliigon "Click: pick a texture folder (all subfolders are searched).\nOr drag a folder (one material) or a single texture onto this button.\nRecognises diffuse/albedo/COL (or no suffix), height/bump/displ, normal/nrm/nm and gloss/roughness names.\nBuilds the StrArchviz_Poliigon preset material from them."
		)

		-- Collect Assets (Left Click)
		on btn_Collector pressed do
		(
			if maxFilePath == "" or maxFileName == "" then
			(
				messageBox "Please save the scene first." title:"Scene Not Saved"
				return()
			)

			local scenePath = maxFilePath
			local destDir
			if matchPattern scenePath pattern:"*\\*" then
				destDir = scenePath + "assets\\"
			else
				destDir = scenePath + "\\assets\\"
			if not (doesDirectoryExist destDir) do makeDir destDir

			local fileList = #()
			try(ATSOps.Visible = true) catch ( strLogErr "Collector: ATSOps.Visible" (getCurrentException()) )
			try(ATSOps.Refresh()) catch ( strLogErr "Collector: ATSOps.Refresh" (getCurrentException()) )
			try(ATSOps.GetFiles &fileList) catch ( strLogErr "Collector: ATSOps.GetFiles" (getCurrentException()) )

			StrTools_collectedOld = #()
			StrTools_collectedNew = #()
			local copyCount = 0
			local renamedCount = 0
			local skippedCount = 0
			local failedCount = 0

			for src in fileList do
			(
				if src != undefined and src != "" and doesFileExist src and (filenameFromPath src != maxFileName) then
				(
					local fname = filenameFromPath src
					local intended = destDir + fname
					local finalPath = intended

					if pathConfig.pathsResolveEquivalent src intended then
						skippedCount += 1
					else
					(
						if doesFileExist intended then
						(
							finalPath = getTimestampUniqueName destDir fname
							renamedCount += 1
						)

						local copied = false
						try( copied = copyFile src finalPath ) catch ( strLogErr ("Collector: copy failed for " + src) (getCurrentException()) )
						if copied then
						(
							copyCount += 1
							append StrTools_collectedOld src
							append StrTools_collectedNew finalPath
						)
						else
						(
							failedCount += 1
							format "[StrTools] Collector: could not copy %\n" src
						)
					)
				)
				else skippedCount += 1
			)

			local msg = "Asset Collection Complete:\n\n" +
				"Files Processed: " + (fileList.count as string) + "\n" +
				"Copied: " + (copyCount as string) + "\n" +
				"Renamed: " + (renamedCount as string) + "\n" +
				"Skipped: " + (skippedCount as string)
			if failedCount > 0 do msg += "\nFailed: " + (failedCount as string) + " (see Listener for the file names)"

			messageBox msg title:"Asset Collector"
		)

		-- Relink Assets (Right Click)
		on btn_Collector rightClick do
		(
			if StrTools_collectedOld.count == 0 or StrTools_collectedNew.count == 0 then
			(
				messageBox "No collected assets found. Please collect assets first." title:"Nothing to Relink"
				return()
			)

			local total = StrTools_collectedOld.count
			local relinked = 0

			progressStart "Relinking assets..."
			for i = 1 to total do
			(
				relinked += relinkSceneAssets StrTools_collectedOld[i] StrTools_collectedNew[i]
				progressUpdate (100.0 * i / total)
			)
			progressEnd()

			try(ATSOps.Refresh()) catch ( strLogErr "Collector: ATSOps.Refresh after relink" (getCurrentException()) )
			redrawViews()

			messageBox ("Relinking Complete:\n\nTotal relinked: " + (relinked as string)) title:"Asset Collector"
		)

		on btn_Cylind pressed do
		(
			if selection.count == 0 then messagebox "No objects are currently selected." title:"UVW Cylindrical Map Application"
			else
			(
				with undo on
				(
					max create mode 
					local size_value = spn_uvwsize.value
					local uvw_template = UVWMap()
					uvw_template.maptype = 1 -- Cylindrical mapping
					uvw_template.length = size_value
					uvw_template.width  = size_value
					uvw_template.height = size_value 
					
					for obj in selection do
					(
						if (iskindof obj GeometryClass OR superClassOf obj == Shape) AND (not iskindof obj Light) AND (not iskindof obj Camera) then 
						( 
							addModifier obj uvw_template 
						)					)
				)
			)
		)

		on btn_uvwbox pressed do
		(
			if selection.count == 0 then messagebox "No objects are currently selected." title:"UVW Map Application"
			else
			(
				with undo on
				(
					max modify mode 
					local size_value = spn_uvwsize.value
					local uvw_template = UVWMap()
					uvw_template.maptype = 4 -- Box mapping
					uvw_template.length = size_value
					uvw_template.width  = size_value
					uvw_template.height = size_value
					for obj in selection do
					(
						if (iskindof obj GeometryClass OR superClassOf obj == Shape) AND (not iskindof obj Light) AND (not iskindof obj Camera) then 
						( 
							addModifier obj uvw_template 
						)					)
				)
			)
		)

		on btn_uvwplane pressed do
		(
			if selection.count == 0 then messagebox "No objects are currently selected." title:"UVW Plane Map Application"
			else
			(
				with undo on
				(
					max modify mode 
					local size_value = spn_uvwsize.value 
					local uvw_template = UVWMap()
					uvw_template.maptype = 0 -- Plane mapping
					uvw_template.length = size_value
					uvw_template.width  = size_value
					-- Height is omitted for plane mapping
					for obj in selection do
					(
						if (iskindof obj GeometryClass OR superClassOf obj == Shape) AND (not iskindof obj Light) AND (not iskindof obj Camera) then 
						( 
							addModifier obj uvw_template 
						)
					)
				)
			)
		)

		on btn_rxfElem pressed do
		(
			undo "Randomize UV By Element" on
			(
				if selection.count==1 then
				(
					macros.run "Modifier Stack" "Convert_to_Poly"
					strExecAction 369982487 "40006"
					subobjectLevel = 4
					strExecAction 0 "40043"
					$.EditablePoly.SetSelection #Face #{}
					subobjectLevel = 0
					modPanel.setCurrentObject $.baseObject
					modPanel.addModToSelection (Uvwmap ()) ui:on
					$.modifiers[#UVW_Map].maptype = 4
					maxOps.CollapseNode $ off
					modPanel.addModToSelection (Unwrap_UVW ()) ui:on
					subobjectLevel = 3
					strExecAction 0 "40021"
					strExecAction 2077580866 "40047" -- Flatten Map
					modPanel.addModToSelection (Edit_Poly ()) ui:on
					subobjectLevel = 4
					strExecAction 0 "40043"
					$.modifiers[#Edit_Poly].SetSelection #Face #{}
					subobjectLevel = 0
					modPanel.addModToSelection (UVW_Xform ()) ui:on
				)
				else()
			)
		)
		
		on btn_rxfObj pressed do
		(
			undo "Randomize UV By Object" on
			(
				max create mode
				local processedObjects = #()
				for item in selection do
				(
					if isKindOf item GroupHead then ( join processedObjects (item.children as array) )
					else if isKindOf item GeometryClass or isKindOf item EditablePoly or isKindOf item EditableMesh then ( append processedObjects item )
				)
			
				if processedObjects.count == 0 then ( return undefined )

				local mapChannel = spn_rxMch.value
				local rotationAngles = #()
				local rotationValue = 0

				case drop_rotate.selected of (
					"0": (rotationAngles = #())
					"45": (rotationAngles = #(45, 135, 225, 315))
					"90": (rotationAngles = #(90, 270))
					"180": (rotationAngles = #(0, 180))
					"360": (rotationAngles = #())
					"45/90": (rotationAngles = #(45, 90, 135, 180, 225, 270, 315))
					default: (rotationAngles = #())
				)

				for o in processedObjects do
				(
					local uTile = random -1.0 1.0
					local vTile = random -1.0 1.0
					local rotationValue = 0
				
					if drop_rotate.selected == "360" then ( rotationValue = random 0 360 ) 
					else if rotationAngles.count > 0 then ( rotationValue = rotationAngles[random 1 rotationAngles.count] )
				
					local xformMod = UVW_Xform()
					xformMod.Map_Channel = mapChannel
					xformMod.U_Offset = uTile
					xformMod.V_Offset = vTile
					xformMod.Rotation_Angle = rotationValue
				
					addmodifier o xformMod
					collapseStack o
				)
			)
		)
		-- Random UV offset/rotation per element, written straight into the map verts of the
		-- ONE object (no detach / modifier / collapse / re-attach per element, which was the slow part).
		-- Each element is rotated around its own UV centre, then shifted by a random offset.
		-- Returns the number of elements touched.
		fn strRandomizeUVByElement node ch =
		(
			convertToPoly node
			if not (polyop.getMapSupport node ch) then ( strNotify (node.name + " has no UVs on map channel " + (ch as string)); 0 )
			else
			(
				local possibleAngles = #(45, 90, 135, 180, 225, 270, 315)
				local mode = drop_rotate.selected
				local nFaces = polyop.getNumFaces node
				local faceDone = #{}
				local mvDone = #{} -- map verts already moved (an element that shares a map vert with an earlier one leaves it alone)
				local nElems = 0
				for f = 1 to nFaces do
				(
					if not faceDone[f] do
					(
						local elemFaces = polyop.getElementsUsingFace node f
						faceDone += elemFaces
						-- map verts of this element
						local mvs = #{}
						for ef in elemFaces do ( for mv in (polyop.getMapFace node ch ef) do mvs[mv] = true )
						mvs -= mvDone
						if mvs.numberSet > 0 do
						(
							mvDone += mvs
							local ids = mvs as array
							local pts = for mv in ids collect (polyop.getMapVert node ch mv)
							-- UV centre of the element
							local cu = 0.0
							local cv = 0.0
							for q in pts do ( cu += q.x; cv += q.y )
							cu /= pts.count
							cv /= pts.count
							local ang = case mode of
							(
								"45": 45 * (random 1 8)
								"90": 90 * (random 1 4)
								"180": 180 * (random 1 2)
								"360": (random 0 360)
								"45/90": possibleAngles[random 1 possibleAngles.count]
								default: 0
							)
							local ca = cos ang
							local sa = sin ang
							local uOff = random -1.0 1.0
							local vOff = random -1.0 1.0
							for k = 1 to ids.count do
							(
								local q = pts[k]
								local du = q.x - cu
								local dv = q.y - cv
								polyop.setMapVert node ch ids[k] [cu + ca * du - sa * dv + uOff, cv + sa * du + ca * dv + vOff, q.z]
							)
							nElems += 1
						)
					)
				)
				nElems
			)
		)

		on btn_rxfObj rightclick do
		(
			max create mode
			undo off
			(
				if checkSingleGeometrySelected() then
				(
					local obj = selection[1]
					local t0 = timeStamp()
					local n = 0
					with redraw off ( n = strRandomizeUVByElement obj 1 )
					redrawViews()
					format "[StrTools] randomized UVs on % elements of % in % s\n" n obj.name ((timeStamp() - t0) / 1000.0)
				)
				else
				(
					strNotify "Please select exactly ONE geometry object to use this option."
				)
			)
		)

		-- V-Ray / Corona may not be installed: look the classes up safely, skip the missing one
		fn strSetDisplacement state =
		(
			local vr = undefined
			local cr = undefined
			try( vr = VRayMtl ) catch( vr = undefined )
			try( cr = CoronaMtl ) catch( cr = undefined )
			if vr != undefined do
			(
				for n in (getClassInstances vr) do
				(
					try( n.texmap_displacement_on = state )
					catch ( strLogErr "VRayMtl displacement toggle" (getCurrentException()) )
				)
			)
			if cr != undefined do
			(
				for n in (getClassInstances cr) do
				(
					try( n.texmapOnDisplacement = state )
					catch ( strLogErr "CoronaMtl displacement toggle" (getCurrentException()) )
				)
			)
		)
		on btn_displ pressed do strSetDisplacement false
		on btn_displ rightclick do strSetDisplacement true

		-- one random colour per scene material, applied in a single pass over the nodes
		-- (replaces refs.Dependents per material, which crawls on big scenes)
		fn strWirecolorByMaterial nodes =
		(
			local mats = #()
			local cols = #()
			with redraw off
			(
				for o in nodes where (superClassOf o == GeometryClass) and o.material != undefined do
				(
					local idx = findItem mats o.material
					if idx == 0 do ( append mats o.material; append cols (randColour()); idx = mats.count )
					try( o.wirecolor = cols[idx] )
					catch ( strLogErr ("wirecolor failed on " + o.name) (getCurrentException()) )
				)
			)
			redrawViews()
		)

		fn strWirecolorRandom nodes =
		(
			with redraw off
			(
				for o in nodes do
				(
					try( o.wirecolor = randColour() )
					catch ( strLogErr ("wirecolor failed on " + o.name) (getCurrentException()) )
				)
			)
			redrawViews()
		)

		on btn_mat pressed do ( undo "Wirecolor By Material" on ( strWirecolorByMaterial (objects as array) ) )
		on btn_mat rightclick do ( undo "Wirecolor By Material (selected)" on ( strWirecolorByMaterial (selection as array) ) )
		on btn_rand pressed do ( undo "Random Wirecolor" on ( strWirecolorRandom (objects as array) ) )
		on btn_rand rightclick do ( undo "Random Wirecolor (selected)" on ( strWirecolorRandom (selection as array) ) )

		on btn_uvwxform pressed do
		(
			undo "Add UVW Xform" on
			(
				if selection.count == 0 then ( return undefined )
			
				local xf = UVW_Xform()
				xf.Map_Channel = spn_rxMch.value
			
				local processedObjects = #()
				for item in selection do
				(
					if isKindOf item GroupHead then ( join processedObjects (item.children as array) )
					else if isKindOf item GeometryClass or isKindOf item EditablePoly or isKindOf item EditableMesh then ( append processedObjects item )
				)

				for obj in processedObjects do (
					if isKindOf obj GeometryClass or isKindOf obj EditablePoly or isKindOf obj EditableMesh then ( addmodifier obj xf )
				)
				max modify mode
			)
		)

		on btn_matdel pressed do
		(
			undo "Delete Material" on
			(
				if selection.count != 0 do ( $.material = NULL )
			)
		)

		on btn_cMtl pressed do
		(
			local m = undefined
			try(m = cmcMakeMaterial cb_gloss.checked)
			catch ( local err = getCurrentException(); cmcLog ("error: " + err); messageBox err title:"StrTools error" )
			cmcStopKiller()
			if m != undefined do cmcLog ("done: " + m.name + " (" + (if cb_gloss.checked then "glossiness" else "roughness") + ")")
		)

		on btn_copyMat pressed do ( try(cmcCopyMat()) catch(cmcLog ("copy error: " + (getCurrentException()))) )

		on btn_pasteMat pressed do ( try(cmcPasteMat()) catch(cmcLog ("paste error: " + (getCurrentException()))) )

		on btn_poliigon Click s e do
		(
			local d = if CMC_lastDir != "" then (getSavePath caption:"Select texture folder" initialDir:CMC_lastDir) else (getSavePath caption:"Select texture folder")
			if d != undefined do plgRun d
		)

		on btn_poliigon DragEnter s e do plgDragFx e
		on btn_poliigon DragOver s e do plgDragFx e
		on btn_poliigon DragDrop s e do
		(
			local files = e.Data.GetData (dotNetClass "System.Windows.Forms.DataFormats").FileDrop
			local p = undefined
			-- Max may hand back a MAXScript array or a .NET string[]
			if files != undefined do
			(
				if classOf files == Array then ( if files.count > 0 do p = files[1] )
				else if files.Length > 0 do p = files.GetValue 0
			)
			if p != undefined do
			(
				local pre = ""
				if not (doesDirectoryExist p) do
				(
					-- a texture file was dropped: use its folder, limited to that texture's asset
					pre = plgAssetKey p
					p = getFilenamePath p
				)
				plgRun p prefix:pre
			)
		)
	)

	-- =================================================================================
	-- ROLLOUT 5: TOOLS
	-- =================================================================================
	rollout roll_Tools "Tools"
	(
		on rolledUp state do strSettingSet "Rollouts" "Tools" state
		-- --- UI Controls ---
		-- Utility Buttons
		button btn_Layers "Layers" pos:[0,10] width:90 height:20 tooltip:"Creates basic layers for architectural visualisation.\nRight click to remove empy layers."
		button btn_cleaner "Cleaner" pos:[90,10] width:90 height:20 tooltip:"Fixes V-Ray Material clamping, deletes unused plugin references, etc."
		
		-- Aspect Ratio Controls
		spinner sp_pixels "" range:[1,32768,1920] pos:[-2,32] fieldWidth:50 toolTip:"Set image resolution in pixels." type:#integer
		checkbox cb_portrait pos:[60,33] width:12 tooltip:"Portrait mode for selected aspect ratio."
		label lbl_size "Size / Orientation" pos:[75,33] width:90 height:16 align:#left tooltip:"Current fixed pixel size and orientation mode."
		dropdownlist drop_paper "" items:#(\
				"Select Aspect Ratio",\
				"1:1 (Square - Social)",\
				"5:4 (Social)",\
				"5:3 (16mm)",\
				"4:3 (SDTV)",\
				"3:2 (DSLR, 35mm)",\
				"16:10 (Widescreen)",\
				"16:9 (HDTV)",\
				"A0-A4 Paper",\
				"2:1 (Modern Cinema)",\
				"1.85:1 (Cinema Film)",\
				"2.35:1 (CinemaScope)",\
				"2.76:1 (Ultra Panavision 70)"\
				) pos:[0, 50] width:180 tooltip:"Popular aspect ratios for output size."

		-- Scene Tools
		button btn_copy "Copy" pos:[0,70] width:60 height:20 tooltip:"Copy (Save) selected for merging into another 3ds Max application."
		button btn_paste "Paste" pos:[0,90] width:60 height:20 tooltip:"Paste (Merges) last Copied selection into exact position."
		
		button btn_close "X" pos:[60,70] width:120 height:20 tooltip:"Close script."

		-- Auto-Save Controls
		checkbox cb_autoSave "" pos:[60,94] width:15 tooltip:"If checked autosave will occure when timer gets to 0."
		label lbl_min "0" pos:[75,94] width:15
		label lbl_sec "0" pos:[90,94] width:15
		dropdownlist drop_minutes "" items:#("0","15","30","45","60") pos:[105,90] width:55 tooltip:"Quiet countdown file save reminder."
		button btn_save "+" pos:[160,90] width:20 height:20 tooltip:"Incremental Save."
		
		-- Timer and Event Variables
		local nextSave = 0 -- timeStamp() (ms) when the countdown ends
		timer clock "testClock" interval:1000 active:false

		-- (re)starts the countdown from the minutes picked in the dropdown; 0 = off
		fn resetAutoSave =
		(
			local mins = drop_minutes.selected as integer
			if mins > 0 then
			(
				nextSave = timeStamp() + mins * 60000
				clock.active = true
			)
			else
			(
				clock.active = false
				lbl_min.text = "0"
				lbl_sec.text = "0"
			)
		)
				
		-- --- Event Handlers ---

		on roll_Tools open do
		(
			try
			(
				sp_pixels.value = (strSettingGet "Tools" "pixels" "1920") as integer
				cb_portrait.checked = ((strSettingGet "Tools" "portrait" "false") == "true")
				cb_autoSave.checked = ((strSettingGet "Tools" "autoSave" "false") == "true")
				local mi = (strSettingGet "Tools" "autoMinutes" "1") as integer
				if mi >= 1 and mi <= drop_minutes.items.count do
				(
					drop_minutes.selection = mi
					resetAutoSave()
				)
			)
			catch ( strLogErr "restoring Tools settings" (getCurrentException()) )
		)

		on sp_pixels changed val do strSettingSet "Tools" "pixels" val
		on cb_portrait changed state do strSettingSet "Tools" "portrait" state
		on cb_autoSave changed state do strSettingSet "Tools" "autoSave" state

		on btn_close pressed do
		(
			try(cui.UnRegisterDialogBar roll_StrTools)catch(undefined) -- not registered yet: expected
			try(closeRolloutfloater roll_StrTools) catch(undefined) -- not open yet: expected
		)
		
		on drop_minutes selected sel do
		(
			strSettingSet "Tools" "autoMinutes" sel
			resetAutoSave()
		)

		on clock tick do
		(
			local remain = (nextSave - timeStamp()) / 1000 -- seconds left
			if remain <= 0 then
			(
				if cb_autoSave.checked then
				(
					-- an unsaved scene would pop up a Save As dialog every cycle, so skip it
					if maxFileName != "" then
					(
						local needsSave = true
						try( needsSave = getSaveRequired() ) catch( needsSave = true )
						if needsSave then
						(
							format "[StrTools] autosave: %\n" (maxFilePath + maxFileName)
							strExecAction 0 "40006"
						)
					)
					else format "[StrTools] autosave skipped: the scene has no file name yet\n"
				)
				local mins = drop_minutes.selected as integer
				nextSave = timeStamp() + mins * 60000
				remain = mins * 60
			)
			lbl_min.text = ((remain / 60) as string)
			lbl_sec.text = (((mod remain 60) as integer) as string)
		)

		on btn_save pressed do
		(
			if maxFileName != "" then ( max saveplus ) else checkForSave()
		)

		-- VARIABLES
		local baseDir = getdir #autoback
		local baseName = "StrTools_mergefile" 
		local ext = ".max"
		local mainClipFile = baseDir + @"\" + baseName + ext
		
		-- COPY BUTTON (With History Shifting)
		on btn_copy pressed do
		(
			if selection.count == 0 then
			(
				strNotify "Nothing selected to copy."
			)
			else
			(
				-- HISTORY SHIFTING LOGIC:
				-- 1. Delete the oldest file (number 10) if it exists to make room
				local file10 = baseDir + @"\" + baseName + "_10" + ext
				if doesFileExist file10 do deleteFile file10

				-- 2. Loop backwards from 9 down to 1 to rename files
				for i = 9 to 1 by -1 do
				(
					local currentIdx = formattedPrint i format:"02d"
					local nextIdx = formattedPrint (i+1) format:"02d"
					
					local oldFile = baseDir + @"\" + baseName + "_" + currentIdx + ext
					local newFile = baseDir + @"\" + baseName + "_" + nextIdx + ext
					
					if doesFileExist oldFile do renameFile oldFile newFile
				)

				-- 3. Rename the current main file (if it exists) to _01
				local file01 = baseDir + @"\" + baseName + "_01" + ext
				if doesFileExist mainClipFile do renameFile mainClipFile file01

				-- SAVE NEW FILE
				saveNodes selection mainClipFile quiet:true
				print ("Saved: " + mainClipFile)
			)
		)

		on btn_copy rightclick do
		(
			if selection.count == 0 then
			(
				strNotify "Nothing selected to copy."
			)
			else
			(
				local autobackDir = (getDir #autoback)
				local defaultName = "Custom_Suffix_Name" + ext
				local defaultPath = autobackDir + @"\" + baseName + "_" + defaultName

				local newFullPath = getMAXSaveFileName \
									caption:"Enter Custom Save Name/Suffix (Autoback Folder)" \
									filename:defaultPath \
									types:("Max Scene (*" + ext + ")|*" + ext)
				
				if newFullPath != undefined and newFullPath != "" then
				(
					saveNodes selection newFullPath quiet:true
					print ("Saved (Custom to Autoback): " + newFullPath)
				)
				else
				(
					print "Custom copy cancelled by user."
				)
			)
		) 

		-- PASTE BUTTON
		on btn_paste pressed do
		(
			local clipFile = ((getdir #autoback) + @"\StrTools_mergefile.max")
	
			if doesFileExist clipFile then
			(
				mergemaxfile clipFile #select
				print "Merged Last Saved Selection."
			)
			else
			(
				print "Clipboard file not found. Did you use the Copy button first?"
			)
		)

		on drop_paper selected sel do
		(
			renderSceneDialog.close()
			completeRedraw()
			local pSize = sp_pixels.value as integer
			
			-- Define aspect ratios (Width/Height)
			local aspect_ratios = #( \
				"1:1 (Square - Social)", 1.0, \
				"5:4 (Social)", 1.25, \
				"5:3 (16mm)", 1.6666666666666666, \
				"4:3 (SDTV)", 1.3333333333333333, \
				"3:2 (DSLR, 35mm)", 1.5, \
				"16:10 (Widescreen)", 1.6, \
				"16:9 (HDTV)", 1.7777777777777777, \
				"A0-A4 Paper", 1.4142135623730951, \
				"2:1 (Modern Cinema)", 2.0, \
				"1.85:1 (Cinema Film)", 1.85, \
				"2.35:1 (CinemaScope)", 2.35, \
				"2.76:1 (Ultra Panavision 70)", 2.76 \
			)
			
			local selected_ratio_name = drop_paper.selected
			local ratio_index = finditem aspect_ratios selected_ratio_name
			
			local aspectRatio = 1.0 
			if ratio_index != 0 then ( aspectRatio = aspect_ratios[ratio_index + 1] )
			
			-- Apply size based on orientation
			if cb_portrait.checked then
			(
				renderWidth = ceil (pSize / aspectRatio)
				renderHeight = pSize
			)
			else
			(
				renderWidth = pSize
				renderHeight = ceil (pSize / aspectRatio)
			)
			
			renderSceneDialog.update()
			if not displaysafeframes do displaysafeframes = true 
			redrawViews()
		)

		on btn_cleaner pressed do
		(	
			fn cleanVrayMaterials =
			(
				local clampedCount = 0
				for mtl in getclassinstances VrayMtl where not mtl.option_clampTextures do	
				(
					mtl.option_clampTextures = true
					clampedCount += 1
				)
				clampedCount	
			)

			fn removeUnusedPlugins =
			(
				local deletedCount = sceneInventory.deleteMissingPluginEntries()
				deletedCount
			)

			local tvn = trackviewnodes
			local controllerNames = #(#Retimer_Manager, #Max_MotionClip_Manager, #Anim_Layer_Control_Manager)
			local trackviewCleaned = false
			local clampedResult = 0
			local pluginCleanedResult = 0
			local messageString = ""

			try
			(
				pluginCleanedResult = removeUnusedPlugins()
				
				for name in controllerNames do (
					local n = tvn[name]
					if n.controller != undefined do (
						deleteTrackViewController tvn n.controller
						trackviewCleaned = true
					)
				)
				
				gc()
				clampedResult = cleanVrayMaterials()
				print ("Cleanup: Core cleanup operations completed.")
			)
			catch ("")
			
			freescenebitmaps()
			
			messageString += "**Scene Cleanup Complete**\n\n"
			
			-- 1. Unused Plugin Entries
			messageString += "* **" + (pluginCleanedResult as string) + "** unused plugin entries removed (File size reduced).\n"
			
			-- 2. Hidden TrackView Controllers
			if trackviewCleaned then ( 
				messageString += "* Hidden TrackView Controllers removed.\n" 
			) else ( 
				messageString += "* Hidden TrackView Controllers: None found to remove.\n" 
			)

			-- 3. V-Ray Material Clamping
			messageString += "* **" + (clampedResult as string) + "** V-Ray Materials clamped ($clampTextures = True$).\n"
			
			-- 4. Memory/Bitmaps
			messageString += "* Memory and scene bitmaps released."
			
			messageBox messageString title:"Scene Cleaner Results"
		)

		on btn_Layers rightclick do
		(
			-- Local function to delete truly empty layers (no objects, no sub-layers)
			fn delete_empty_layers =
			(
				local counter = 0
				(layerManager.getLayer 0).current = true
			
				-- Iterate backward from the top layer
				for id = LayerManager.count - 1 to 1 by -1 do
				(
					local layer = LayerManager.getLayer id
					local contains_nodes = LayerManager.doesLayerHierarchyContainNodes layer.name
			
					if not contains_nodes then
					(
						local deleted = LayerManager.deleteLayerByName layer.name
						if deleted then counter += 1
					)
				)
				return counter
			)
			
			-- Execute the cleanup and display the result
			local layersCleaned = delete_empty_layers()
			
			if layersCleaned > 0 then (
				messageBox ("Cleaned **" + (layersCleaned as string) + "** empty layers (including their hierarchies).") title:"Layer Cleanup Complete"
			) else (
				messageBox "No empty layers or layer hierarchies were found to be deleted." title:"Layer Cleanup Complete"
			)
		)

		on btn_Layers pressed do
		(
			local LayerData = #(
				#("#Camera_01", 0, 0, 255),
				#("#Camera_02", 0, 0, 255),
				#("#Camera_03", 0, 0, 255),
				#("#Camera_04", 0, 0, 255),
				#("#Camera_05", 0, 0, 255),
				#("02_Lights", 255, 255, 0),
				#("03_Environment", 0, 255, 255),
				#("04_Architecture", 255, 0, 0),
				#("05_Site", 255, 128, 0),
				#("06_Props_Interior", 255, 0, 255),
				#("06_Props_Exterior", 255, 0, 255),
				#("07_Landscape", 0, 255, 0),
				#("08_People", 128, 0, 255),
				#("09_Vehicles", 128, 0, 255),
				#("10_Helpers", 255, 255, 255),
				#("11_Hide", 128, 128, 128)
			)
			
			for layerDetails in LayerData do
			(
				local layerName = layerDetails[1]
				local colorR = layerDetails[2]
				local colorG = layerDetails[3]
				local colorB = layerDetails[4]
				local layer = LayerManager.getLayerFromName layerName
				if layer == undefined then ( layer = LayerManager.newLayerFromName layerName )
				layer.wireColor = (color colorR colorG colorB)
			)
			
		)

	)

	-- =================================================================================
	-- ROLLOUT 6: INFO
	-- =================================================================================
	rollout roll_Info "Info" rolledUp:true
	(
		on rolledUp state do strSettingSet "Rollouts" "Info" state
		label lbl_info "StrScripts, 2025." pos:[10,7]
		hyperlink bU "v" pos:[150,7] address:"http://www.scriptspot.com/3ds-max/scripts/strtools" color:black visitedcolor:black hoverColor:red
		label donate "Donate:" pos:[10,27]
		hyperlink b5 "-5-" pos:[55,27] address:"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=J53LJ6S2GS4EE" color:green visitedcolor:green hoverColor:red
		hyperlink b10 "-10-" pos:[75,27] address:"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=G483RJTJJXVJE" color:green visitedcolor:green hoverColor:red
		hyperlink b20 "-20-" pos:[100,27] address:"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=QJRYKBKT3QAK6" color:green visitedcolor:green hoverColor:red
		-- (control captions must be literals, so the version is set here; the handler has to come AFTER the control it uses)
		on roll_Info open do bU.caption = ("v" + StrTools_version)
	)

	-- =================================================================================
	-- INITIALIZATION AND DOCKING
	-- =================================================================================
	try(cui.UnRegisterDialogBar roll_StrTools)catch(undefined) -- not registered yet: expected
	try(closeRolloutfloater roll_StrTools) catch(undefined) -- not open yet: expected
	roll_StrTools = newRolloutFLoater "StrTools" 200 950

	cui.RegisterDialogBar roll_StrTools minSize:1 maxSize:-1 style:#(#cui_dock_left, #cui_dock_right, #cui_floatable)
	cui.dockDialogBar roll_StrTools #cui_dock_right
	
	addRollout roll_Geometry roll_StrTools rolledUp:(strRolledUp "Geometry" "false")
	addRollout roll_Selections roll_StrTools rolledUp:(strRolledUp "Selections" "false")
	addRollout roll_Modify roll_StrTools rolledUp:(strRolledUp "Modify" "false")
	addRollout roll_Materials roll_StrTools rolledUp:(strRolledUp "Materials" "false")
	addRollout roll_Tools roll_StrTools rolledUp:(strRolledUp "Tools" "false")
	addRollout roll_Info roll_StrTools rolledUp:(strRolledUp "Info" "true")
)