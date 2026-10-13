--macroScript StrTools category:"StrScripts"

(
	global roll_strTools
	
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
		oldName = node.name
		local act = on
		local element = polyop.getElementsUsingFace
		local detach = polyop.detachfaces
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
	global collectedOldFiles = #()
	global collectedNewFiles = #()

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

		undo off
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
		undo on

		return targetObj
	)

	-- Global Quotes Array
	global quotes = #(
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
		"Opportunities don't happen. You create them.",
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
		"Believe you can and you're halfway there.",
		"Whatever you are, be a good one.",
		"The best way to predict the future is to create it.",
		"Do not go where the path may lead, go instead where there is no path and leave a trail.",
		"Keep going. Be all in.",
		"Don't watch the clock; do what it does. Keep going.",
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
		"Push yourself, because no one else is going to do it for you.",
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

	/* Function: mapfiles/addmap */
	mapfiles = #()
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
		pObj = 0
		cObj = 0
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
		pObj = 0
		cObj = 0
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
		col = (color (random 0 255) (random 0 255) (random 0 255))
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
			undo on
			for m in selection do
			(
				convertToMesh m
				meshOp.weldVertsByThreshold m.mesh m.mesh.verts 0.0001
				convertToPoly m
			)
		)

		on btn_unormal pressed do
		(
			undo on
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

		on btn_vertexSel pressed do
		(
			undo on
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

		on btn_Smooth pressed do
		(
			undo on
			max create mode
			fn aSmooth tresh: = ( addModifier selection (smooth autosmooth:true preventIndirect:true threshold:tresh) )
			aSmooth tresh:sp_smooth.value
			for o in selection where isKindOf o GeometryClass and not isKindOf o Targetobject do
			(
				maxOps.CollapseNode o off
			)
		)

		on btn_dnormal pressed do
		(
			undo on
			max create mode
			if selection.count != 0 do
			(
				rNormals = Normalmodifier unify:true flip:true
				for o in selection where isKindOf o GeometryClass and not isKindOf o Targetobject do
				(
					addmodifier o rNormals
					addmodifier o rNormals
					maxOps.CollapseNode o off
				)
			)
		)

		on btn_dnormal rightclick do
		(
			undo on
			if selection.count != 0 do
			(
				eNormals = modPanel.addModToSelection (Edit_Normals ())
				for o in selection where isKindOf o GeometryClass and not isKindOf o Targetobject do ( eNormals )
			)
		)

		on btn_ffd2 pressed do ( undo on if selection.count!=0 do modPanel.addModToSelection (FFD_2x2x2 ()) ui:on )
		on btn_ffd3 pressed do ( undo on if selection.count!=0 do modPanel.addModToSelection (FFD_3x3x3 ()) ui:on )
		on btn_ffd4 pressed do ( undo on if selection.count!=0 do modPanel.addModToSelection (FFD_4x4x4 ()) ui:on )

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
			undo on
			local obj
			local pp = pickpoint snap:#3d
			if (classof pp == Point3) do
			(
				local rr1 = mapScreenToWorldRay mouse.pos
				local sc = selection.center
				local scmin = selection.min.z
				local rr2 = ray rr1.pos rr1.dir
				local r2 = undefined

				for o in $* do
				(
					r2 = intersectray o rr2
					if (r2 != undefined) do ( obj=o; exit )
				)
			)
			if r2 != undefined do ( obj.pivot = r2.pos; select obj )
		)

		-- Pivot Operations
		on btn_pivcen pressed do
		(
			undo on
			for i in selection do (local obj = i; CenterPivot obj)
			redrawViews()
		)
		on btn_pivbot pressed do
		(
			undo on
			for i in selection do (local obj = i; CenterPivot obj; obj.pivot = [obj.pivot.x, obj.pivot.y, obj.min.z])
			redrawViews()
		)
		on btn_pivtop pressed do
		(
			undo on
			for i in selection do (local obj = i; CenterPivot obj; obj.pivot = [obj.pivot.x, obj.pivot.y, obj.max.z])
			redrawViews()
		)
		on btn_pivzero pressed do
		(
			undo on
			for i in selection do (local obj = i; obj.pivot = [0,0,0])
			redrawViews()
		)

		on btn_boxon pressed do ( undo on $.boxmode = on )
		on btn_boxon rightclick do ( undo on $.boxmode = off )

		on btn_insert pressed do
		(
			undo on
			if selected != 0 do
			(
				macros.run "PolyTools" "InsertLoop"
				macros.run "PolyTools" "SetFlow"
			)
		)

		on btn_quadify pressed do
		(
			selectedobjs = selection as array
			undo on
			max create mode
			for o in selectedobjs where isKindOf o GeometryClass do
			(
				select o
				macros.run "Modifier Stack" "Convert_to_Poly"
				PolyToolsModeling.Quadrify off off
				clearSelection()
			)
		)

		on btn_edgeclean pressed do
		(
			selectedobjs = selection as array
			undo on
			if selection.count != 0 do
			(
				for o in selectedobjs do 
				(
					select o
					macros.run "Modifier Stack" "Convert_to_Poly"
					actionMan.executeAction 369982487 "40005" -- Border Level
					subobjectLevel = 3
					actionMan.executeAction 0 "40021"
					o.EditablePoly.SetSelection #Edge ((polyOp.getOpenEdges o) as bitarray)
					actionMan.executeAction 369982487 "40004"
					subobjectLevel = 2
					actionMan.executeAction 0 "40044"
					o.EditablePoly.Remove ()
					actionMan.executeAction 369982487 "40006" -- Face Level
					subobjectLevel = 4
					actionMan.executeAction 0 "40021"
					o.EditablePoly.SetSelection #Face ((polyOp.getFaceSelection o) as bitarray)
					o.EditablePoly.retriangulate 1
				)
				macros.run "Modifier Stack" "Convert_to_Poly"
			)
		)

		on btn_xform pressed do
		(
			undo on
			if selection.count != 0 do
			(
				for o in Selection do( resetxform o; maxOps.CollapseNode o off )
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
			undo on
			for obj in selection do ( obj.name = uniquename txt_nname.text )
		)
	)

	-- =================================================================================
	-- ROLLOUT 2: SELECTIONS
	-- =================================================================================
	rollout roll_Selections "Selections"
	(
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
		fn PopulateListBox =
		(
			-- Reset Listbox Selection and Scene Selection
			lb.selection = 0
			clearselection ()

			case dd_selections.selected of
			(
				"Proxy":
				(
					local o = for o in geometry where classOf o == VRayProxy or classOf o == CProxy collect o.name
					local SortNames = sort (o)
					lb.items = o
				)

				"Lights":
				(
					local o = for o in lights collect o.name
					local SortNames = sort (o)
					lb.items = o
				)

				"Cameras":
				(
					local o = for o in cameras collect o.name
					local SortNames = sort (o)
					lb.items = o
				)

				"Geometry":
				(
					-- Exclude Proxy objects
					local o = for o in geometry where classOf o != VRayProxy and classOf o !=CProxy collect o.name
					local SortNames = sort (o)
					lb.items = o
				)

				"Scene":
				(
					local o = for o in objects collect o.name
					local SortNames = sort (o)
					lb.items = o
				)

				"Splines":
				(
					local o = for o in shapes collect o.name
					local SortNames = sort (o)
					lb.items = o
				)

				"Helpers":
				(
					local o = for o in helpers collect o.name
					local SortNames = sort (o)
					lb.items = o
				)

				"Obj-ID":
				(
					fn oCompare el1 el2 = (return (el1 as integer) - (el2 as integer))
					local oIDs = for oID in objects collect oID.gbufferchannel as string
					local uniqueSortedIDs = makeUniqueArray (sort oIDs)
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
			undo on
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
			actionMan.executeAction 0 "40021"
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
			actionMan.executeAction 0 "40021"
			max select all
			SetSelectFilter 1
		)
		on btn_allLights rightclick do ( select (for l in lights collect l) )

		on btn_allCameras pressed do
		(
			SetSelectFilter 5
			actionMan.executeAction 0 "40021"
			max select all
			SetSelectFilter 1
		)
		on btn_allCameras rightclick do ( select (for c in cameras collect c) )

		on btn_allSplines pressed do
		(
			SetSelectFilter 3
			actionMan.executeAction 0 "40021"
			max select all
			SetSelectFilter 1
		)
		on btn_allSplines rightclick do ( select (for s in shapes collect s) )

		on btn_allGeometry pressed do
		(
			SetSelectFilter 2
			actionMan.executeAction 0 "40021"
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
					local sArray = #()
					for i in (lb.selection as array) do
					(
						for o in objects where try(o.material.name == lb.items[i])catch(false) do append sArray o
					)
					select sArray
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
						local sArray = #()
						for i in (lb.selection as array) do
						(
							for o in objects where (o.gbufferchannel == lb.items[i] as integer) do append sArray o
						)
						select sArray
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
				local sArray = #()
				for i in (lb.selection as array) do
				(
					for o in objects where try(o.material.name == lb.items[i])catch(false) do append sArray o
				)
				select sArray
			)
			else
			(
				if dd_selections.selected == "Obj-ID" then
				(
					local sArray = #()
					for i in (lb.selection as array) do
					(
						for o in objects where (o.gbufferchannel == lb.items[i] as integer) do append sArray o
					)
					select sArray
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
		button btn_attach "sAttach" pos:[120,50] width:60 height:20 tooltip:"Right click to Attach all selected into single object."

		spinner sp_oID "ID" range:[0,999,0] pos:[2,92] fieldWidth:27 toolTip:"Assign ID to selected." type:#integer
		button btnMotivate "Motivation" pos:[60,90] width:60 height:20 tooltip:"Get motivated!"
		
		button btn_flattenX "X" pos:[120,90] width:20 height:20 tooltip:"Flatten selected on X axis"
		button btn_flattenY "Y" pos:[140,90] width:20 height:20 tooltip:"Flatten selected on Y axis"
		button btn_flattenZ "Z" pos:[160,90] width:20 height:20 tooltip:"Flatten selected on Z axis"
		
		-- --- Event Handlers ---
		fn showRandomQuote =
		(
			randomIndex = random 1 quotes.count
			messageBox quotes[randomIndex] title:"Motivation!"
		)
		
		on btnMotivate pressed do
		(
			showRandomQuote()
		)
	
		on btnObjPick picked obj do
		(
			if obj != undefined do
			(
				global pObj = obj
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
							instanceReplace i pObj
							
							i.name = uniquename btnObjPick.text
							i.mat  = pObj.mat
							
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
			undo on
			for o in selection do ( o.gbufferchannel = sp_oID.value )
		)

		fn toggleMatOverrides =
		(
			max create mode
			actionMan.executeAction 0 "63545"   -- material on
		)

		fn toggleMatOverridesOff =
		(
			max create mode
			actionMan.executeAction 0 "63544"   -- material off
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
				gCollect = for o in selection where
				(
					superClassOf o == geometryClass
				) collect o
				
				if gCollect.count < 2 then
				(
					messageBox "Select at least 2 geometry objects."
					return false
				)
				
				-- choose first object as base
				baseObj = gCollect[1]
				
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

		-- Random Move
		on btn_rnd_move pressed do
		(
			undo "Random Move" on
			(
				local objectsToModify = #()
				for obj in selection as array do
				(
					local effectiveObj = obj
					if isGroupMember obj do effectiveObj = obj.parent
					
					if (not isKindOf effectiveObj TargetObject) and \
					   (not isKindOf effectiveObj Helper or isGroupHead effectiveObj) do
					(
						appendIfUnique objectsToModify effectiveObj
					)
				)

				for obj in objectsToModify do
				(
					local newx = random -sp_x.value sp_x.value
					local newy = random -sp_y.value sp_y.value
					local newz = random -sp_z.value sp_z.value
					
					obj.transform = transmatrix [newx,newy,newz] * obj.transform
				)
			)
			redrawViews()
		)

		on btn_rnd_move rightclick do
		(
			undo "Random Move Absolute" on
			(
				local objectsToModify = #()
				for obj in selection as array do
				(
					local effectiveObj = obj
					if isGroupMember obj do effectiveObj = obj.parent
					
					if (not isKindOf effectiveObj TargetObject) and \
					   (not isKindOf effectiveObj Helper or isGroupHead effectiveObj) do
					(
						appendIfUnique objectsToModify effectiveObj
					)
				)
				
				for obj in objectsToModify do
				(
					local newx = random -sp_x.value sp_x.value
					local newy = random -sp_y.value sp_y.value
					local newz = random -sp_z.value sp_z.value
					move obj [newx,newy,newz]
				)
			)
			redrawViews()
		)

		-- Random Rotate
		on btn_rnd_rotate pressed do
		(
			undo "Random Rotate" on
			(
				local objectsToModify = #()
				for obj in selection as array do
				(
					local effectiveObj = obj
					if isGroupMember obj do effectiveObj = obj.parent
					
					if (not isKindOf effectiveObj TargetObject) and \
					   (not isKindOf effectiveObj Helper or isGroupHead effectiveObj) do
					(
						appendIfUnique objectsToModify effectiveObj
					)
				)

				for obj in objectsToModify do
				(
					local newx = random -sp_x.value sp_x.value
					local newy = random -sp_y.value sp_y.value
					local newz = random -sp_z.value sp_z.value
					
					obj.transform = rotateXMatrix newx * obj.transform
					obj.transform = rotateYMatrix newy * obj.transform
					obj.transform = rotateZMatrix newz * obj.transform
				)
			)
			redrawViews()
		)

		on btn_rnd_rotate rightclick do
		(
			undo "Random Rotate Euler" on
			(
				local objectsToModify = #()
				for obj in selection as array do
				(
					local effectiveObj = obj
					if isGroupMember obj do effectiveObj = obj.parent
					
					if (not isKindOf effectiveObj TargetObject) and \
					   (not isKindOf effectiveObj Helper or isGroupHead effectiveObj) do
					(
						appendIfUnique objectsToModify effectiveObj
					)
				)

				for obj in objectsToModify do
				(
					local newx = random -sp_x.value sp_x.value
					local newy = random -sp_y.value sp_y.value
					local newz = random -sp_z.value sp_z.value
					rotate obj (eulerangles newx newy newz)
				)
			)
			redrawViews()
		)

		-- Random Scale
		on btn_rnd_scale pressed do
		(
			undo "Random Scale" on
			(
				local objectsToModify = #()
				for obj in selection as array do
				(
					local effectiveObj = obj
					if isGroupMember obj do effectiveObj = obj.parent
					
					if (not isKindOf effectiveObj TargetObject) and \
					   (not isKindOf effectiveObj Helper or isGroupHead effectiveObj) do
					(
						appendIfUnique objectsToModify effectiveObj
					)
				)

				for obj in objectsToModify do
				(
					local scN = random sp_x.value sp_y.value * 0.01
					obj.scale = [scN,scN,scN]
				)
			)
			redrawViews()
		)
		
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
					catch ()
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
		-- --- UI Controls ---
		-- Hidden controls
		spinner spn_gamma "" range:[-10,10,1.0] width:70 enabled:off pos:[-200,10] visible:false
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
		dropDownList drop_MatReset items:#("matSlot","Corona", "VRay") pos:[120,30] width:60 tooltip:"Reset material slot."
		
		button btn_Collector "Collector" pos:[120,70] width:60 height:20 toolTip:"Left-click: Collect all scene assets into 'assets' folder.\nRight-click: Relink assets to collected copies(Under construction)."

		-- --- Event Handlers ---

		on roll_materials open do
		(
			global nFolder = "C:\\"
			global arrAll = 0
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
			try(ATSOps.Visible = true) catch()
			try(ATSOps.Refresh()) catch()
			try(ATSOps.GetFiles &fileList) catch()

			collectedOldFiles = #()
			collectedNewFiles = #()
			local copyCount = 0
			local renamedCount = 0
			local skippedCount = 0

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

						try(copyFile src finalPath) catch()
						copyCount += 1

						append collectedOldFiles src
						append collectedNewFiles finalPath
					)
				)
				else skippedCount += 1
			)

			local msg = "Asset Collection Complete:\n\n" +
				"Files Processed: " + (fileList.count as string) + "\n" +
				"Copied: " + (copyCount as string) + "\n" +
				"Renamed: " + (renamedCount as string) + "\n" +
				"Skipped: " + (skippedCount as string)

			messageBox msg title:"Asset Collector"
		)

		-- Relink Assets (Right Click)
		on btn_Collector rightClick do
		(
			if collectedOldFiles.count == 0 or collectedNewFiles.count == 0 then
			(
				messageBox "No collected assets found. Please collect assets first." title:"Nothing to Relink"
				return()
			)

			local total = collectedOldFiles.count
			local relinked = 0

			progressStart "Relinking assets..." total:total
			for i = 1 to total do
			(
				relinked += relinkSceneAssets collectedOldFiles[i] collectedNewFiles[i]
				progressUpdate i
			)
			progressEnd()

			try(ATSOps.Refresh()) catch()
			try(redrawViews()) catch()

			messageBox ("Relinking Complete:\n\nTotal relinked: " + (relinked as string)) title:"Asset Collector"
		)

		on drop_MatReset selected sel do
		(
			undo on
			actionMan.executeAction 0 "50048"
			if drop_MatReset.selected=="Corona" then
			(
				for i = 1 to 24 do ( meditmaterials[i] = CoronaMtl(); meditMaterials[i].name = ("CoronaMtl_" + i as string) )
			)
			if drop_MatReset.selected=="VRay" then
			(
				for i = 1 to 24 do ( meditmaterials[i] = VRayMtl(); meditMaterials[i].name = ("VRayMtl_" + i as string) )
			)	
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
			undo on
			if selection.count==1 then
			(
				macros.run "Modifier Stack" "Convert_to_Poly"
				actionMan.executeAction 369982487 "40006"
				subobjectLevel = 4
				actionMan.executeAction 0 "40043"
				$.EditablePoly.SetSelection #Face #{}
				subobjectLevel = 0
				modPanel.setCurrentObject $.baseObject
				modPanel.addModToSelection (Uvwmap ()) ui:on
				$.modifiers[#UVW_Map].maptype = 4
				maxOps.CollapseNode $ off
				modPanel.addModToSelection (Unwrap_UVW ()) ui:on
				subobjectLevel = 3
				actionMan.executeAction 0 "40021"
				actionMan.executeAction 2077580866 "40047" -- Flatten Map
				modPanel.addModToSelection (Edit_Poly ()) ui:on
				subobjectLevel = 4
				actionMan.executeAction 0 "40043"
				$.modifiers[#Edit_Poly].SetSelection #Face #{}
				subobjectLevel = 0
				modPanel.addModToSelection (UVW_Xform ()) ui:on
			)
			else()
		)
		
		on btn_rxfObj pressed do
		(
			undo on
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
				rotationValue = 0 
				
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
		on btn_rxfObj rightclick do
		(
			max create mode
			undo off
				(
					if checkSingleGeometrySelected() then
					(
						local uTile = random -1.0 1.0
						local vTile = random -1.0 1.0
						local possibleAngles = #(45, 90, 135, 180, 225, 270, 315)
						local randomIndex = random 1 possibleAngles.count
						z = getCurrentSelection()
						outtaSel = #()
						for k in z do
						(
							oldObj = detachElements k
							setOfElements = $ElementDetached*  as array
							for i in setOfElements do
							(
								randomIndex = random 1 possibleAngles.count
								b = uvw_Xform ()
								addModifier i b
								i.modifiers[#UVW_Xform].u_offset = uTile
								i.modifiers[#UVW_Xform].v_offset = vTile
								case drop_rotate.selected of (
									"0": i.modifiers[#UVW_Xform].Rotation_Angle = (0)
									"45": i.modifiers[#UVW_Xform].Rotation_Angle = 45 * (random 1 8)
									"90": i.modifiers[#UVW_Xform].Rotation_Angle = 90 * (random 1 4)
									"180": i.modifiers[#UVW_Xform].Rotation_Angle = 180 * (random 1 2)
									"360": i.modifiers[#UVW_Xform].Rotation_Angle = (random 0 360)
									
									"45/90": i.modifiers[#UVW_Xform].Rotation_Angle = possibleAngles[randomIndex]
									default: i.modifiers[#UVW_Xform].Rotation_Angle = #()
								)
								collapseStack i
							)
							a = attachElements setOfElements oldObj
							append outtaSel a
						)
						select outtaSel
					)
					else(
						messageBox "Please select exactly ONE geometry object to use this option." title:"StrTools"

						)
				)
		)
		on btn_displ pressed do
		(
			item=VRayMtl; for n in (getclassinstances item) do n.texmap_displacement_on=false
			item=CoronaMtl; for n in (getclassinstances item) do n.texmapOnDisplacement = off
		)
		on btn_displ rightclick do
		(
			item=VRayMtl; for n in (getclassinstances item) do n.texmap_displacement_on=true
			item=CoronaMtl; for n in (getclassinstances item) do n.texmapOnDisplacement = on
		)
		
		on btn_mat pressed do
		(
			m = 1
			tot = sceneMaterials.count
			for s in sceneMaterials do(
				mw = randColour()
				for o in (refs.Dependents s) do(
					if SuperClassOf o == GeometryClass then( try(o.wirecolor = mw)catch() )
				)
				m += 1
			)
		)
		on btn_mat rightclick do
		(
			m = 1
			tot = sceneMaterials.count
			for s in sceneMaterials do(
				mw = randColour()
				for o in (refs.Dependents s) do(
					if SuperClassOf o == GeometryClass then( try( if o.isSelected == True then(o.wirecolor = mw) )catch() )
				)
				m += 1
			)
		)

		on btn_rand pressed do
		(
			m = 1 
			tot = objects.count
			for o in objects do( try(o.wirecolor = randColour())catch(); m += 1 )
		)
		on btn_rand rightclick do
		(
			m = 1 
			tot = objects.count
			for o in selection do( try(o.wirecolor = randColour())catch(); m += 1 )
		)

		on btn_uvwxform pressed do
		(
			undo on
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

		on btn_matdel pressed do
		(
			undo on
			if selection.count != 0 do ( $.material = NULL )
		)
	)

	-- =================================================================================
	-- ROLLOUT 5: TOOLS
	-- =================================================================================
	rollout roll_Tools "Tools"
	(
		-- --- UI Controls ---
		-- Utility Buttons
		button btn_gamma "2.2 Gamma" pos:[0,10] width:60 height:20 tooltip:"Applies 2.2 Gamma workflow."
		button btn_Layers "Layers" pos:[60,10] width:60 height:20 tooltip:"Creates basic layers for architectural visualisation.\nRight click to remove empy layers."
		button btn_cleaner "Cleaner" pos:[120,10] width:60 height:20 tooltip:"Fixes V-Ray Material clamping, deletes unused plugin references, etc."
		
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
		
		button btn_vSun "VSun" pos:[60,70] width:30 height:20 toolTip:"Creates mutant VRaySun with Dome."
		button btn_cSun "CSun" pos:[90,70] width:30 height:20 toolTip:"Creates Corona Sun and Corona Sky as envirement."
		button btn_close "X" pos:[120,70] width:30 height:20 tooltip:"Close script."
		button btn_region "R" pos:[150,70] width:30 height:20 tooltip:"Set region."

		-- Auto-Save Controls
		checkbox cb_autoSave "" pos:[60,94] width:15 tooltip:"If checked autosave will occure when timer gets to 0."
		label lbl_min "0" pos:[75,94] width:15
		label lbl_sec "0" pos:[90,94] width:15
		dropdownlist drop_minutes "" items:#("0","15","30","45","60") pos:[105,90] width:55 tooltip:"Quiet countdown file save reminder."
		button btn_save "+" pos:[160,90] width:20 height:20 tooltip:"Incremental Save."
		
		-- Timer and Event Variables
		local tickSec = 59
		local tickMin = 30
		timer clock "testClock" interval:1000 active:false
				
		-- --- Event Handlers ---

		on btn_close pressed do
		(
			try(cui.UnRegisterDialogBar roll_StrTools)catch()
			try(closeRolloutfloater roll_StrTools) catch()
		)
		
		on drop_minutes selected sel do
		(
			tickSec = 60
			tickMin=drop_minutes.selected as integer -1
			clock.active=true
			if drop_minutes.selected == "0" then
			(
				clock.active=false
				lbl_sec.text = 0 as string
				lbl_min.text = 0 as string
			)
		)

		on clock tick do
		(
			tickSec -= 1
			if tickSec == 0 then
			(
				tickSec = 59
				tickMin = tickMin-1
			)
			if tickMin <= -1 then
			(
				if cb_autoSave.checked then ( actionMan.executeAction 0 "40006" )
				tickMin=drop_minutes.selected as integer -1
			)
			lbl_sec.text = tickSec as string
			lbl_min.text = tickMin as string
		)

		on btn_region pressed do
		(
			displaySafeFrames = true
			EditRenderRegion.EditRegion()
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
				messageBox "Nothing selected to copy." title:"StrTools"
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
				messageBox "Nothing selected to copy." title:"StrTools"
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
				mergemaxfile clipFile
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
			pSize = sp_pixels.value as integer
			
			-- Define aspect ratios (Width/Height)
			aspect_ratios = #( \
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
			
			selected_ratio_name = drop_paper.selected
			ratio_index = finditem aspect_ratios selected_ratio_name
			
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
			LayerData = #(
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
				layerName = layerDetails[1]
				colorR = layerDetails[2]
				colorG = layerDetails[3]
				colorB = layerDetails[4]
				layer = LayerManager.getLayerFromName layerName
				if layer == undefined then ( layer = LayerManager.newLayerFromName layerName )
				layer.wireColor = (color colorR colorG colorB)
			)
			
		)

		on btn_vSun pressed do 
		(
			sunObj = vraysun pos:(point3 3000 -3000 3000)
			targetObj = vraylight pos:(point3 0 0 0)
			targetObj.lookat = sunObj
			---select targetObj
			targetObj.type = 1
			targetObj.dome_spherical = on
			targetObj.dome_affect_alpha = off
			targetObj.on = off
			targetObj.on = on
			targetObj.castShadows = off
			targetObj.castShadows = on
			targetObj.DoubleSided = off
			targetObj.invisible = off
			targetObj.noDecay = off
			targetObj.skylightPortal = off
			targetObj.storeWithIrradMap = off
			targetObj.affect_diffuse = off
			targetObj.affect_diffuse = on
			targetObj.affect_specualr = off
			targetObj.affect_specualr = on
			targetObj.affect_reflections = on
			targetObj.multiplier = 1
			targetObj.texmap_locktodome = 1
			targetObj.texmap = VRaySky ()
			select sunObj
		 )

		on btn_cSun pressed do 
		(
			sunObj = CoronaSun pos:(point3 3000 -3000 3000)
			targetObj = dummy pos:(point3 0 0 0)
			targetObj.lookat = sunObj
			
			sunObj.targeted = off
			sunObj.targeted = on
			sunObj.pos=[5000,-5000,5000]
			sunObj.colormode = 2
			sunObj.intensity = 1
			sunObj.sizeMultiplier = 1
			
			environmentMap = CoronaSky ()
			
			select sunObj
		 )

		on btn_gamma pressed do
		(
			fileInGamma = 2.2
			fileOutGamma = 2.2
			IDisplayGamma.colorCorrectionMode = #gamma
			IDisplayGamma.gamma = 2.2
		)
	)

	-- =================================================================================
	-- ROLLOUT 6: INFO
	-- =================================================================================
	rollout roll_Info "Info" rolledUp:true
	(
		label lbl_info "StrScipts, 2025." pos:[10,7]
		hyperlink bU "v2.88" pos:[150,7] address:"http://www.scriptspot.com/3ds-max/scripts/strtools" color:black visitedcolor:black hoverColor:red
		label donate "Donate:" pos:[10,27]
		hyperlink b5 "-5-" pos:[55,27] address:"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=J53LJ6S2GS4EE" color:green visitedcolor:green hoverColor:red
		hyperlink b10 "-10-" pos:[75,27] address:"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=G483RJTJJXVJE" color:green visitedcolor:green hoverColor:red
		hyperlink b20 "-20-" pos:[100,27] address:"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=QJRYKBKT3QAK6" color:green visitedcolor:green hoverColor:red
	)

	-- =================================================================================
	-- INITIALIZATION AND DOCKING
	-- =================================================================================
	try(cui.UnRegisterDialogBar roll_StrTools)catch()
	try(closeRolloutfloater roll_StrTools) catch()
	roll_StrTools = newRolloutFLoater "StrTools" 200 950

	cui.RegisterDialogBar roll_StrTools minSize:1 maxSize:-1 style:#(#cui_dock_left, #cui_dock_right, #cui_floatable)
	cui.dockDialogBar roll_StrTools #cui_dock_right
	
	addRollout roll_Geometry roll_StrTools 
	addRollout roll_Selections roll_StrTools
	addRollout roll_Modify roll_StrTools
	addRollout roll_Materials roll_StrTools
	addRollout roll_Tools roll_StrTools
	addRollout roll_Info roll_StrTools
)