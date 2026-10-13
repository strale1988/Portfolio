(
	global roll_strTools
	
---**** sAttach
fn sAttach objArr =
(
j = 1
count = objArr.count
macros.run "Modifier Stack" "Convert_to_Mesh"

undo off
(
	while objArr.count > 1 do
	(
		oSel=(getcurrentselection()).count
		progressUpdate (100.0*1/oSel)
			
		if classof objArr[j] != Editable_Mesh then converttomesh objArr[j]
		attach objArr[j] objArr[j+1]
		deleteItem objArr (j+1)
		j += 1
		if (j + 1) > objArr.count then j = 1
	)
)
	return objArr[1]
)

---**** mapfiles
		mapfiles = #()
		fn addmap mapfile =
		(
			local mapfileN = mapfile as name
			local index = finditem mapfiles mapfileN
			if index == 0 do append mapfiles mapfileN
		)
		enumeratefiles addmap
		sort mapfiles
		
---*** backface cull
	fn backfaceCullOff objs =
(
    pObj = 0
    cObj = 0
    for obj in selection do (
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
    for obj in selection do (
        pObj += 1
		format "turn backface cull off for: %\n" obj
		obj.backfaceCull = false
		cObj += 1
    )
    format "% objects processed.\n" pObj
    format "% objects changed.\n" cObj
)
---**** materials on off
	fn offShowInViewport theMat =
(
	if (numSubMtls = getNumSubMtls theMat) != 0 then
		for i = 1 to numSubMtls do
			offShowInViewport (getSubMtl theMat i)
	else
	(
		theMat.showInViewport = true
	)
)
	fn onShowInViewport theMat =
(
	if (numSubMtls = getNumSubMtls theMat) != 0 then
		for i = 1 to numSubMtls do
			offShowInViewport (getSubMtl theMat i)
	else
	(
		theMat.showInViewport = false
	)
)
---**** material collection

---**** wirecolors
	fn randColour =
	(
	col = (color (random 0 255) (random 0 255) (random 0 255))
	col
	)
----Detach by elements
	local start_objs = objects as array
	fn detach_elems obj base_name = 
		(
		if convertToPoly obj != undefined do (
			while polyOp.getNumFaces obj != 0 do (
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
--//////////////////////////////////////////////////////////////////////////////
	
rollout roll_Geometry "Geometry and Shape"
(
	button btn_Smooth "Smooth" pos:[0,10] width:60 height:20 toolTip:"Smooth selected for:"
	spinner sp_Smooth "" range:[0,180,30] pos:[58,12] fieldWidth:50 toolTip:"Smooth selected for the input value." type:#integer
	
	button btn_pivcust "P" pos:[40,70] width:20 height:20 toolTip:"Place pivot on object surface where you need it."
	button btn_pivtop "T" pos:[0,70] width:20 height:20 toolTip:"Place selected objects pivots on top."
	button btn_pivbot "B" pos:[0,90] width:20 height:20 toolTip:"Place selected objects on bottom."
	button btn_pivcen "C" pos:[20,70] width:20 height:40 toolTip:"Place selected objects pivots in center."
	button btn_pivzero "Z" pos:[40,90] width:20 height:20 toolTip:"Place selected objects pivots on 0 (xyz zero)."

	button btn_oWeld "oWeld" pos:[120,50] width:60 height:20 toolTip:"Weld vertices on selected objects."
	button btn_unormal "uNormals" pos:[120,70] width:60 height:20 toolTip:"Unify normals on selected objects."
	button btn_edgeclean "eClean" pos:[60,70] width:60 height:20 toolTip:"Deletes edges on flat surfaces. It leaves only borders and edges which are must have."
	button btn_dnormal "dNorm" pos:[120,30] width:60 height:20 toolTip:"Fixes muddy faces(Resets normals.). Right click to add Edit Normal modifier."
	button btn_vertexSel "vSelect" pos:[120,10] width:60 height:20 toolTip:"Select vertices that uses only two edges. Converts selected objects to editable poly and makes vertex selected."
	
	button btn_objrename "Rename" pos:[0,50] width:60 height:20 toolTip:"Rename all selected."
	editText txt_nname text:"Object/Detach_Name" pos:[-3,31.5] fieldWidth:118 type:"New name of all selected/detached." 
	button btn_eldetach "Detach" pos:[60,50] width:60 height:20 toolTip:"Detach all elements in selected objects."
	
	button btn_xform "xForms" pos:[120,90] width:60 height:20 toolTip:"Resets xForm on selected objects and splines."

	button btn_boxon "Box on/off" pos:[120,110] width:60 height:20 toolTip:"Display selected as box. Right click to disable box display"
	button btn_backFace "BFC on/off" pos:[120,130] width:60 height:20 toolTip:"Display selected Backface Cull. Right click to disable selected Backface Cull."
	
	
	button btn_quadify "Quadify" pos:[0,110] width:60 height:20 toolTip:"Quadifies the selected mesh."
	button btn_insert "Insert" pos:[0,130] width:60 height:20 toolTip:"Insert edges and sets flow on selected edges normal."
	button btn_epoly "EditPoly" pos:[60,90] width:60 height:20 toolTip:"Adds edit poly modifier."

	button btn_shell "Shell" pos:[60,110] width:60 height:20 toolTip:"Adds shell modifier to selected objects as instance."
	button btn_ffd2 "f2" pos:[60,130] width:20 height:20 toolTip:"Adds FFD 2x2x2 modifier to selected object/faces for quick modification."
	button btn_ffd3 "f3" pos:[80,130] width:20 height:20 toolTip:"Adds FFD 2x2x2 modifier to selected object/faces for quick modification."
	button btn_ffd4 "f4" pos:[100,130] width:20 height:20 toolTip:"Adds FFD 2x2x2 modifier to selected object/faces for quick modification."

	on btn_backFace pressed do
	(
		undo on
		backfaceCullOff $*
	)
	on btn_backFace rightclick do
	(
		undo on
		backfaceCullOn $*
	)
	
	on btn_epoly pressed do
	(
		undo on
		modPanel.addModToSelection (Edit_Poly ()) ui:on
	)
	----****
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
----****
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
					(with redraw off ( nMesh m ); redrawViews();  update m
					) else  ()
				convertToPoly m
			)
		)
		nFace  uNormals selection
	)
----****
	on btn_vertexSel pressed do
	(
		undo on
		if selection.count == 0 then () else
		(
		macros.run "Modifier Stack" "Convert_to_Poly"
		for o in selection do
		(
			fn VerticesSel obj =
			(	
				obj.selectedverts = (for i in 1 to obj.numverts where obj.GetVertexEdgeCount i == 2 collect i)
			)
			VerticesSel o
			subobjectLevel = 1
		)
		)
	)
----****
	on btn_Smooth pressed do
	(
		undo on
		max create mode
		fn aSmooth tresh: = 
		(
		addModifier selection (smooth autosmooth:true preventIndirect:true threshold:tresh) 
		)
		aSmooth tresh:sp_smooth.value
		for o in selection where isKindOf o GeometryClass and not isKindOf o Targetobject do
		(
			maxOps.CollapseNode o off
		)

	)
----****
	on btn_dnormal pressed do
	(
		undo on
		max create mode
		if selection.count == 0 then () else
		rNormals = Normalmodifier unify:true flip:true
		for o in selection where isKindOf o GeometryClass and not isKindOf o Targetobject do
		(
			addmodifier o rNormals
			addmodifier o rNormals
			maxOps.CollapseNode o off
		)
	)
----****
	on btn_dnormal rightclick do
	(
		undo on
		if selection.count == 0 then () else
		
		eNormals = modPanel.addModToSelection (Edit_Normals ())
		for o in selection where isKindOf o GeometryClass and not isKindOf o Targetobject do
		(
			eNormals
		)
	)
----****
	on btn_ffd2 pressed do
	(
		undo on
		if selection.count==0 then () else
		modPanel.addModToSelection (FFD_2x2x2 ()) ui:on
	)
	on btn_ffd3 pressed do
	(
		undo on
		if selection.count==0 then () else
		modPanel.addModToSelection (FFD_3x3x3 ()) ui:on
	)
	on btn_ffd4 pressed do
	(
		undo on
		if selection.count==0 then () else
		modPanel.addModToSelection (FFD_4x4x4 ()) ui:on
	)
----****
	on btn_shell pressed do
	(
		undo on
		max create mode
		if selection.count==0 then () else
		(
			s = Shell () 
			for obj in $selection do addmodifier obj (s)
			redrawViews() 	
		)
		max modify mode
	)
----****
	on btn_pivcust pressed do
	(
		undo on
		local obj
		local pp=pickpoint snap:#3d
		if (classof pp==Point3)
		do
		(
		local rr1=mapScreenToWorldRay mouse.pos
		local sc=selection.center
		local scmin=selection.min.z
		local rr2=ray rr1.pos rr1.dir
		local r2=undefined

		for o in $* do
		(
		r2=intersectray o rr2
		if (r2!=undefined)
		do
		(
			obj=o
			exit
		)
		)
		)
		if r2!=undefined do
		(
			obj.pivot=r2.pos
			select obj
		)
	)
----****
	on btn_pivbot pressed do
	(
		undo on
		for i in Selection do
		(
			CenterPivot i
			i.pivot.z = i.min[3]
		)
		redrawViews()
	)
----****
	on btn_pivtop pressed do
	(
		undo on
		for i in Selection do
		(
			CenterPivot i
			i.pivot.z = i.max[3]
		)
		redrawViews()
	)
	----****
	on btn_pivzero pressed do
	(
		undo on
		for i in Selection do
		(
			CenterPivot i
			i.pivot = [0,0,0]
		)
		redrawViews()
	)
----****
	on btn_pivcen pressed do
	(
		undo on
		for i in Selection do
		(
			CenterPivot i
			i.pivot = i.center
		)
		redrawViews()
	)
----****
	on btn_boxon pressed do
	(
		undo on
		$.boxmode = on
	)
	on btn_boxon rightclick do
	(
		undo on
		$.boxmode = off
	)
----****
	on btn_insert pressed do
	(
		undo on
		if selected !=0 then
		(
			macros.run "PolyTools" "InsertLoop"
			macros.run "PolyTools" "SetFlow"
		)
		else ()
	)
----****
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
----****
	on btn_edgeclean pressed do
	(
		selectedobjs = selection as array
		undo on
		if selection.count==0 then () 
		for o in selectedobjs do 
		(
			select o
			macros.run "Modifier Stack" "Convert_to_Poly"
			actionMan.executeAction 369982487 "40005" -- Editable Poly: Border Level
			subobjectLevel = 3
			actionMan.executeAction 0 "40021"
			o.EditablePoly.SetSelection #Edge ((polyOp.getOpenEdges o) as bitarray)
			actionMan.executeAction 369982487 "40004"
			subobjectLevel = 2
			actionMan.executeAction 0 "40044"
			o.EditablePoly.Remove ()
			actionMan.executeAction 369982487 "40006"  -- Editable Poly: Face Level
			subobjectLevel = 4
			actionMan.executeAction 0 "40021"
			o.EditablePoly.SetSelection #Face ((polyOp.getFaceSelection o) as bitarray)
			o.EditablePoly.retriangulate 1
		)
		macros.run "Modifier Stack" "Convert_to_Poly"
	)
----****
	on btn_xform pressed do
	(
		undo on
		if selection.count == 0 then () else
		(
			for o in Selection  do(
				resetxform o;
				maxOps.CollapseNode o off
			)
		)
	)

----****
	on btn_eldetach pressed do
	(
		local n_name = txt_nname.text
		local n_objs = for obj in selection where superClassOf obj == geometryClass collect obj
		for obj in n_objs do detach_elems obj n_name
	)
----****
	on btn_objrename pressed do
	(
		undo on
		for obj in selection do
		(
		obj.name = uniquename txt_nname.text
		)
	)

)
--//////////////////////////////////////////////////////////////////////////////
rollout roll_Selections "Selections"
(
	dropdownlist dd_selections items:#("Scene", "Proxy", "Lights", "Cameras", "Geometry","Splines","Helpers","Obj-ID", "Materials") width:70 height:20 pos:[0,10] tooltip:"Right click to refresh the list."
	checkbutton ch_Interactive "Interactive" pos:[110,10] checked:true tooltip:"Interactive selection." width:70
	button btn_Select "Select" pos:[70,10] width:40 tooltip:"Select objects selected in the list."
	MultiListBox  lb pos:[0,34] width:140 height:11

	button btn_allProxy "Proxy" pos:[140,63] width:40 height:20 tooltip:"Select all Proxies in scene."
	button btn_allLights "Light" pos:[140,83] width:40 height:20 tooltip:"Select all Lights in viewport. Right click to select all Lights in scene."
	button btn_allCameras "Cam" pos:[140,103] width:40 height:20 tooltip:"Select all Cameras in viewport. Right click to select all Cameras in scene."
	button btn_allGeometry "Geo" pos:[140,123] width:40 height:20 tooltip:"Select all Geometry in viewport. Right click to select all Geometry in scene."
	button btn_allSplines "Spline" pos:[140,143] width:40 height:20 tooltip:"Select all Splines and Shapes in viewport. Right click to select all Splines in scene."
	button btn_allHelpers "Helper" pos:[140,163] width:40 height:20 tooltip:"Select all Helpers in viewport. Right click to select all Helpers in scene."
	button btn_noMat "nMat" pos:[140,33] width:40 height:20 tooltip:"Selects all objects without materials."

	----****
	on btn_noMat pressed do
	(
		select (for g in geometry where g.material==undefined collect g)
	)
---****
	on roll_Selections open do
	(
		btn_Select.enabled = false
	)
-----*****SELECTIONS BUTTON
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
----****
	on btn_allLights pressed do
	(
		SetSelectFilter 4
		actionMan.executeAction 0 "40021"
		max select all
		SetSelectFilter 1
	)
	on btn_allLights rightclick do
	(
		select (for l in lights collect l)
	)
----****
	on btn_allCameras pressed do
	(
		SetSelectFilter 5
		actionMan.executeAction 0 "40021"
		max select all
		SetSelectFilter 1
	)
	on btn_allCameras rightclick do
	(
		select (for c in cameras collect c)
	)
----****
	on btn_allSplines pressed do
	(
		SetSelectFilter 3
		actionMan.executeAction 0 "40021"
		max select all
		SetSelectFilter 1
	)
	on btn_allSplines rightclick do
	(
		select (for s in shapes collect s)
	)
----****
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
----****
	on btn_allproxy pressed do
	(
		select (for o in objects where classOf o == VRayProxy or  classOf o == CProxy collect o)
	)
-----*****	SELECTIONS BUTTON

	on ch_Interactive changed state do
	(
		if state == off then
			btn_Select.enabled = true
		else
		btn_Select.enabled = false
	)
----------*********
	on dd_selections rightclick do
	(
lb.selection = 0
		clearselection ()
		if dd_selections.selected == "Proxy" then
		(
			o = for o in geometry where classOf o == VRayProxy or  classOf o == CProxy collect o.name
			SortNames = sort (o)
			lb.items = o
		)
		if dd_selections.selected == "Lights" then
		(
			o = for o in lights collect o.name
			SortNames = sort (o)
			lb.items = o
		)
		if dd_selections.selected == "Cameras" then
		(
			o = for o in cameras collect o.name
			SortNames = sort (o)
			lb.items = o
		)
		if dd_selections.selected == "Geometry" then
		(
			o = for o in geometry where classOf o != VRayProxy and classOf o !=CProxy collect o.name
			SortNames = sort (o)
			lb.items = o
		)
		if dd_selections.selected == "Scene" then
		(
			o = for o in objects collect o.name
			SortNames = sort (o)
			lb.items = o
		)
		if dd_selections.selected == "Splines" then
		(
			o = for o in shapes collect o.name
			SortNames = sort (o)
			lb.items = o
		)
		if dd_selections.selected == "Helpers" then
		(
			o = for o in helpers collect o.name
			SortNames = sort (o)
			lb.items = o
		)
		if dd_selections.selected == "Obj-ID" then
		(
			fn oCompare el1 el2 = (return (el1 as integer) - (el2 as integer))

			oIDs = for oID in objects collect oID.gbufferchannel as string
			local oArr = oIDs
			qsort oIDs oCompare
			lb.items = makeUniqueArray oArr
		)
		if dd_selections.selected == "Materials" then
		(
			matNames = #()
			for aMtlType in material.classes do 
			(
				for aMtl in (getClassInstances aMtlType processAllAnimatables:true) do
				(
					if (findItem sceneMaterials aMtl) != 0 do (append matNames aMtl)
				)
			)
			matUsed = for m in matNames collect m.name
			sort matUsed
			
			lb.items = matUsed

		)
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
		else
		(
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
--------------************
	on dd_selections selected sel do
	(
		lb.selection = 0
		clearselection ()
		if dd_selections.selected == "Proxy" then
		(
			o = for o in geometry where classOf o == VRayProxy or  classOf o == CProxy collect o.name
			SortNames = sort (o)
			lb.items = o
		)
		if dd_selections.selected == "Lights" then
		(
			o = for o in lights collect o.name
			SortNames = sort (o)
			lb.items = o
		)
		if dd_selections.selected == "Cameras" then
		(
			o = for o in cameras collect o.name
			SortNames = sort (o)
			lb.items = o
		)
		if dd_selections.selected == "Geometry" then
		(
			o = for o in geometry where classOf o != VRayProxy and classOf o !=CProxy collect o.name
			SortNames = sort (o)
			lb.items = o
		)
		if dd_selections.selected == "Scene" then
		(
			o = for o in objects collect o.name
			SortNames = sort (o)
			lb.items = o
		)
		if dd_selections.selected == "Splines" then
		(
			o = for o in shapes collect o.name
			SortNames = sort (o)
			lb.items = o
		)
		if dd_selections.selected == "Helpers" then
		(
			o = for o in helpers collect o.name
			SortNames = sort (o)
			lb.items = o
		)
		if dd_selections.selected == "Obj-ID" then
		(
			fn oCompare el1 el2 = (return (el1 as integer) - (el2 as integer))

			oIDs = for oID in objects collect oID.gbufferchannel as string
			local oArr = oIDs
			qsort oIDs oCompare
			lb.items = makeUniqueArray oArr
		)
		if dd_selections.selected == "Materials" then
		(
			matNames = #()
			for aMtlType in material.classes do 
			(
				for aMtl in (getClassInstances aMtlType processAllAnimatables:true) do
				(
					if (findItem sceneMaterials aMtl) != 0 do (append matNames aMtl)
				)
			)
			matUsed = for m in matNames collect m.name
			sort matUsed
			
			lb.items = matUsed

		)
	)	
)
--//////////////////////////////////////////////////////////////////////////////
rollout roll_Modify "Modifications" 
(
	button btn_proxycloud "C" pos:[120,30] width:20 height:20 tooltip:"Display selected proxies as Point Cloud (Corona) and Faces (Vray)."
	button btn_proxybox "B" pos:[140,30] width:20 height:20 tooltip:"Display selected proxies as Box."
	button btn_proxymesh "M" pos:[160,30] width:20 height:20 tooltip:"Display selected proxies as mesh."

	button btn_OnOff "LC On/Off" pos:[60,10] width:60 height:20 tooltip:"Turn on or Right click off selected Lights (VRay and Corona) and camera targets (VRayPhisical and Physical)."

	spinner sp_kelvin "" range:[110,30000,6500] pos:[118,12] fieldWidth:50 toolTip:"Change selected Lights temperature and Cameras white balance."
	
	button btn_lock "Lock" pos:[60,50] width:60 height:20 tooltip:"Lock selected. Right click to unlock. (If locking camera or sun, it will also lock their target)."
	button btn_matonoff "vMaterial" pos:[60,30] width:60 height:20 tooltip:"Show materials in viewport. Right click to hide."

	spinner sp_x "X" range:[0,9999,0] pos:[0,12] fieldWidth:40 toolTip:"Randomness on X axis. Minimun % for scale"
	spinner sp_y "Y" range:[0,9999,0] pos:[0,32] fieldWidth:40 toolTip:"Randomness on Y axis. Maximum % for scale"
	spinner sp_z "Z" range:[0,9999,0] pos:[0,52] fieldWidth:40 toolTip:"Randomness on Z axis."

	button btn_rnd_move "M" pos:[0,70] width:20 height:20 tooltip:"Randomize positions of selected objects based on input numbers on LOCAL axys. Right click to use WORLD axys. (Groups are ignored, each selected in group will be randimized)"
	button btn_rnd_rotate "R" pos:[20,70] width:20 height:20 tooltip:"Randomize rotations of selected based on input numbers on LOCAL axys. Right click to use WORLD axys. (Groups are ignored, each selected in group will be randimized)"
	button btn_rnd_scale "S" pos:[40,70] width:20 height:20 tooltip:"Randomize scale in percentages of selected on LOCAL axys. X input=Minimum, Y input=Maximum. (Groups are ignored, each selected in group will be randimized)"
		
	button btn_attach "sAttach" pos:[120,50] width:60 height:20 tooltip:"Right click (for safety reasons) to Attach all selected into single object. More objects=slower. *Tested only on 3ds max 2016."
	
	spinner sp_oID "ID" range:[0,999,0] pos:[2,92] fieldWidth:27 toolTip:"Assign ID to selected." type:#integer

	button btn_flattenX "X" pos:[120,90] width:20 height:20 tooltip:"Flatten selected on X axis"
	button btn_flattenY "Y" pos:[140,90] width:20 height:20 tooltip:"Flatten selected on X axis"
	button btn_flattenZ "Z" pos:[160,90] width:20 height:20 tooltip:"Flatten selected on X axis"
	
	pickbutton btnObjPick "Instancer" pos:[60,70] width:120 height:20.5 tooltip:"Pick object from scene for instancing. Right click to replace selected objects with the picked one."
	
	button btn_sRandom "%" pos:[60,90] width:20 height:20 tooltip:"Random select objects in selection. *Tested only on 3ds max 2016."
	spinner sp_rnd "" range:[0,100,50] pos:[78,92] fieldWidth:29 toolTip:"Percentage to select." type:#integer
	
----****RANDOM SELECTION
	on btn_sRandom pressed do
	(
	undo on
		cArray = for o in selection where classof o != TargetObject collect o
		sArray = #()
		sPerc = sp_rnd.value
		nDelete = (sPerc / 100.0 * cArray.count) as integer
		while sArray.count < nDelete do
		(
		  nPerc = random 1 cArray.count
		  if findItem sArray cArray[nPerc] == 0 do
			append sArray cArray[nPerc]
		)
		select sArray
	)
----****
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
		undo on
		if btnObjPick.text != "Instancer" then
		(
			progressStart "Instancing..."
			InstanceMgr.MakeObjectsUnique selection #individual
			objSelc = selection.count
			for i in selection do 
			(
				objSelc = objSelc-1
				instanceReplace i pObj
				i.name = uniquename btnObjPick.text
				i.mat = pObj.mat
				progressUpdate (100.0*1/objSelc)
			)
			progressEnd()
			btnObjPick.text = "Instancer"
		)
	)
---***
	on sp_oID changed val do
	(
		undo on
		for o in selection do
		(
			o.gbufferchannel = sp_oID.value
		)
	)
---****
	on btn_matonoff pressed do
	(
		undo on
		max create mode
		actionMan.executeAction 0 "63545"
	)
	on btn_matonoff rightclick do
	(
		undo on
		max create mode
		actionMan.executeAction 0 "63544"
	)	
---****
	on btn_flattenX pressed do
	(
		undo on
		selection.scale.x = 0
	)
	on btn_flattenY pressed do
	(
		undo on
		selection.scale.y = 0
	)
	on btn_flattenZ pressed do
	(
		undo on
		selection.scale.z = 0
	)
---****
	on btn_attach rightclick do
	(
		undo off
		max modify mode
		progressStart "Attaching selected objects... "
		explodeGroup  selection

		gCollect = for o in selection where superClassOf o == geometryClass and classOf o != VRayProxy and classOf o !=CProxy and classOf o !=Lights collect o
		select gCollect
		
		sAttach gCollect
		
		update selection[1]
		progressEnd()
	)
----****
	on btn_rnd_move pressed do
	(
		undo on
		for m in selection where not isKindOf m Targetobject and not isKindOf m Helper do
		(
			posx=sp_x.value
			newx=(random -posx posx)
			
			posy=sp_y.value
			newy=(random -posy posy)
			
			posz=sp_z.value
			newz=(random -posz posz)
			
			m.transform = (transmatrix [newx,newy,newz]) * m.transform
		)
		redrawViews()
	)
	on btn_rnd_move rightclick do
	(
		undo on
		for m in selection where not isKindOf m Targetobject and not isKindOf m Helper do
		(
			posx=sp_x.value
			newx=(random -posx posx)
			
			posy=sp_y.value
			newy=(random -posy posy)
			
			posz=sp_z.value
			newz=(random -posz posz)
			
			move m  [newx,newy,newz]
		)
		redrawViews()
	)

	on btn_rnd_rotate pressed do
	(
		undo on
		for r in selection where not isKindOf r Targetobject and not isKindOf r Helper do
		(
			posx=sp_x.value
			newx=(random -posx posx)

			posy=sp_y.value
			newy=(random -posy posy)

			posz=sp_z.value
			newz=(random -posz posz)
			
			r.transform = (rotateXmatrix newx) * r.transform
			r.transform = (rotateYmatrix newy) * r.transform
			r.transform = (rotateZmatrix newz) * r.transform
		)
		redrawViews()
	)
	on btn_rnd_rotate rightclick do
	(
		undo on
		for r in selection where not isKindOf r Targetobject and not isKindOf r Helper do
		(
			posx=sp_x.value
			newx=(random -posx posx)

			posy=sp_y.value
			newy=(random -posy posy)

			posz=sp_z.value
			newz=(random -posz posz)
			
			rotate r (eulerangles  (newx)  (newy) (newz))
		)
		redrawViews()
	)
	
	on btn_rnd_scale pressed do
	(
		undo on
		for s in selection where not isKindOf s Targetobject and not isKindOf s Helper do
		(
			sc1=sp_x.value
			sc2=sp_y.value
			
			scN=(random sc1 sc2)*0.01
			
			s.scale = [scN,scN,scN]
		)
		redrawViews()
	)
	
	on chk_uniform changed theState do
	(
		if theState == true then
		(
		sp_y.enabled = false
		sp_z.enabled = false
		)
		else
		(
		sp_y.enabled = true
		sp_z.enabled = true
		)
	)

-----****
	on btn_OnOff pressed do
	(
		undo on
		for l in selection  where classOf l == VRayLight or classOf l==CoronaLight do
		(
			l.on = on
		)
		for l in selection  where classOf l == CoronaSun do
		(
			l.on = on
		)
		for l in selection  where classOf l == Physical do
		(
			l.targeted = on
		)
		for l in selection  where classOf l == VRayPhysicalCamera do
		(
			l.targeted = on
		)
	)
	on btn_OnOff rightclick do
	(
		undo on
		for l in selection  where classOf l == VRayLight or classOf l==CoronaLight do
		(
			l.on = off
		)
		for l in selection  where classOf l == CoronaSun do
		(
			l.on = off
		)
		for l in selection  where classOf l == Physical do
		(
			l.targeted = off
		)
		for l in selection  where classOf l == VRayPhysicalCamera do
		(
			l.targeted = off
		)
	)
	
----****
on sp_kelvin changed val do
	(
		for k in selection where classOf k == VRayLight do
		(
			k.color_mode = 1
			k.color_temperature = val
		)
		for k in selection where classOf k == CoronaLight do
		(
			k.colorMode = 1
			k.blackbodyTemp = val
		)
		for k in selection where classOf k == CoronaSun do
		(
			k.colorMode = 1
			k.blackbodyTemperature = val
		)
		for k in selection where classOf k==Physical do
		(
			k.white_balance_type = 1
			k.white_balance_kelvin = val
		)
		for k in selection where classOf k==VRayPhysicalCamera do
		(
			k.whiteBalance_preset = 7
			k.temperature = val
		)
		
	)
----****
on btn_lock pressed do
	(
	if selection.count == 0 then () else
		(
			setTransformLockFlags selection #all
			macros.run "Lights and Cameras" "Camera_SelectTarget"
			setTransformLockFlags selection #all
			macros.run "Selection" "SelectCameraFromTarget"
			setTransformLockFlags selection #all
		)
	)
on btn_lock rightclick do
	(
	if selection.count == 0 then () else
		(
			setTransformLockFlags selection #none
			macros.run "Lights and Cameras" "Camera_SelectTarget"
			setTransformLockFlags selection #none
			macros.run "Selection" "SelectCameraFromTarget"
			setTransformLockFlags selection #none
		)
	)
----****
	on btn_proxycloud pressed do
	(
		max create mode
		sArray = selection.count
		for p in selection where classOf p == cProxy do
		(
			sArray = sArray - 1
			p.previzType = 2
		)
		for p in selection where classOf p == VRayProxy do
		(
			sArray = sArray - 1
			p.display = 3
		)
	)
----****
	on btn_proxybox pressed do
	(
		max create mode
		sArray = selection.count
		for p in selection where classOf p == VRayProxy do
		(
			sArray = sArray - 1
			p.display = 0
		)
		for p in selection where classOf p == cProxy do
		(
			sArray = sArray - 1
			p.previzType = 0
		)

	)
----****
	on btn_proxymesh pressed do
	(
		max create mode
		sArray = selection.count
		for p in selection where classOf p == VRayProxy do
		(
			sArray = sArray - 1
			p.display = 4
		)
		for p in selection where classOf p == cProxy do
		(
			sArray = sArray - 1
			p.previzType = 3
		)
	)
)
--//////////////////////////////////////////////////////////////////////////////
rollout roll_Materials "Materials and Mapping"
(
	spinner spn_gamma "" range:[-10,10,1.0] width:70 enabled:off pos:[-200,10] visible:false
	radiobuttons rb1 "" labels:#("VrayNormalMap", "NormalMap") columns:2 pos:[-200,10] visible:false

	button btn_uvwbox "B" pos:[60,10] width:20 height:20 tooltip:"Box mapping on selected objects."
	button btn_uvwplane "P" pos:[80,10] width:20 height:20 tooltip:"Plane mapping on selected objects."
	button btn_Cylind "C" pos:[100,10] width:20 height:20 tooltip:"Cylindrical mapping on selected objects."

	spinner spn_uvwsize "" range:[1,99999,600] pos:[-2,12] fieldWidth:50 toolTip:"Size of UVW."
	
	radiobuttons UVaxis labels:#("U","V","UV") default:3 visible:false
	button btn_uvwxform "xF" pos:[160,50] width:20 height:20 tooltip:"Applies UVW xForm modifier on selected objects."

	button btn_matdel "mRemove" pos:[0,70] width:60 height:20 tooltip:"Removes materials on selected objects."
	button btn_displ "dDisplace" pos:[60,70] width:60 height:20 tooltip:"Disables displacement on all applied materials. Right click enables displacement on all applied materials."
	
	button btn_mat "Mat Wire" pos:[0,30] width:60 height:20 tooltip:"Random wirecolor by material for all object in scene. Right click for selection."
	button btn_rand "Rnd Wire" pos:[60,30] width:60 height:20 tooltip:"Random wirecolors for all object in scene. Right click for selection."
	
	button btn_rxfObj "xObjects" pos:[0,50] width:60 height:20 tooltip:"Random UV offset on selected objects. If angle is selected, UV will be rotated by selected angle. If faces are selected in objects randomization will occur only on selected faces. Deselect faces if you want randomization for entire object."
	dropdownlist drop_rotate "" items:#("0", "45", "90", "180", "360", "45/90", "90/180") pos:[60,50] width:60 tooltip:"UVW xForm rotations: [0=no rotation] [45=rotates by 45, 135, 225, 315] [90=rotates by 90, 270] [180=rotates by 180] [360=rotates randomly] [45/90=rotates by 45, 90, 135...]"
	spinner spn_rxMch "" range:[1,999,1] pos:[118,52] fieldWidth:30 toolTip:"Map Channel." type:#integer

	button btn_rxfElem "Autoflat" pos:[120,10] width:60 height:20 tooltip:"Quick Unwrap on selected object. More faces in object=slower!"
	
	dropDownList drop_MatReset items:#("matSlot","Corona", "VRay") pos:[120,30] width:60 tooltip:"Reset material slot."
	
	button btn_Collector "Collector" pos:[120,70] width:60 height:20 tooltip:"Collect all your assets into one folder. Missing files will be ignored."
on roll_materials open do
(
	global nFolder = "C:\\"
	global arrAll = 0
)
	on btn_Collector pressed do
	(
		max create mode
		undo off
		disableSceneRedraw
		suspendEditing
		
		ATSOps.Refresh()

		mapfiles = #()
		fn addmap mapfile =
			(
				local mapfileN = mapfile as name
				local index = finditem mapfiles mapfileN
				if index == 0 do append mapfiles mapfileN
			)
		enumeratefiles addmap
		sort mapfiles

		if mapfiles.count == 0 then
			(
				progressEnd()
			)
		else
			(
				arrRepath = mapfiles.count
				
				dFolder = getSavePath caption:"Select where to collect."
				nFolder = dFolder + "\\"
				
				for i in mapfiles do
				(
					fExt = (getFilenameType i) as string
					
					fPath = 	getFilenamePath i
					fName = filenameFromPath i
					oFile = fPath + fName
					
					arrRepath = arrRepath - 1
					progressStart (fName)
					progressUpdate (100.0*1/(arrRepath as integer))
					
					nFile = nFolder + fName
					copyFile oFile nFile
				)
				progressEnd()
			)
	)

---*****	
	on drop_MatReset selected sel do
	(
		undo on
		actionMan.executeAction 0 "50048"  -- Tools: Material Editor Toggle
		if drop_MatReset.selected=="Corona" then
		(
			for i = 1 to 24 do 
			(
				meditmaterials[i] = CoronaMtl()
				meditMaterials[i].name = ("CoronaMtl_" + i as string)
			)
		)
		if drop_MatReset.selected=="VRay" then
		(mm
			for i = 1 to 24 do 
			(
				meditmaterials[i] = VRayMtl()
				meditMaterials[i].name = ("VRayMtl_" + i as string)
			)
		)	
	)

---***
	on btn_Cylind pressed do
	(
		undo on
		max create mode
		if selection.count==0 then () else
		(
			if selection.count ==1 then
			(
				for o in selection do
				(
				modPanel.addModToSelection (Uvwmap ()) ui:on
				o.modifiers[#UVW_Map].maptype = 1
				o.modifiers[#UVW_Map].length = spn_uvwsize.value
				o.modifiers[#UVW_Map].width = spn_uvwsize.value
				o.modifiers[#UVW_Map].height = spn_uvwsize.value
				)
			)
			else
			(	
				b = uvwmap() 
				b.maptype = 1
				b.length = spn_uvwsize.value
				b.width = spn_uvwsize.value
				b.height = spn_uvwsize.value
				for obj in $selection do addmodifier obj (b)
			)
		)
		max modify mode
	)
----****
	on btn_uvwbox pressed do
	(
		undo on
		max create mode
		if selection.count==0 then () else
		(
			if selection.count ==1 then
			(
				for o in selection do
				(
				modPanel.addModToSelection (Uvwmap ()) ui:on
				o.modifiers[#UVW_Map].maptype = 4
				o.modifiers[#UVW_Map].length = spn_uvwsize.value
				o.modifiers[#UVW_Map].width = spn_uvwsize.value
				o.modifiers[#UVW_Map].height = spn_uvwsize.value
				)
			)
			else
			(	
				b = uvwmap() 
				b.maptype = 4
				b.length = spn_uvwsize.value
				b.width = spn_uvwsize.value
				b.height = spn_uvwsize.value
				for obj in $selection do addmodifier obj (b)
			)
		)
		max modify mode
	)
----****
	on btn_uvwplane pressed do
	(
		undo on
		max create mode
		if selection.count==0 then() else
		(
			if selection.count ==1 then
			(
				for o in selection do
				(
				modPanel.addModToSelection (Uvwmap ()) ui:on
				o.modifiers[#UVW_Map].maptype = 0
				o.modifiers[#UVW_Map].length = spn_uvwsize.value
				o.modifiers[#UVW_Map].width = spn_uvwsize.value
				)
			)
			else
			(	
				b = uvwmap() 
				b.maptype = 0
				b.length = spn_uvwsize.value
				b.width = spn_uvwsize.value
				b.height = spn_uvwsize.value
				for obj in $selection do addmodifier obj (b)
			)
		)
		max modify mode
	)
----****
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
			actionMan.executeAction 0 "40021"  -- Selection: Select All
			actionMan.executeAction 2077580866 "40047"  -- All Commands: Flatten Map Dialog
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
		if selection.count==0 then () else
		(
			if drop_rotate.selected=="0" then
			(
				for o in selection do
				(
					x = UVW_Xform() 
					uTile=(random -1.0 1.0)
					vTile=(random -1.0 1.0)
					x.Map_Channel = spn_rxMch.value
					x.U_Offset = uTile
					x.V_Offset = vTile
					addmodifier o (x)
				)
			)
			if drop_rotate.selected=="45" then
			(
				for o in selection do
				(
					x = UVW_Xform() 
					uTile=(random -1.0 1.0)
					vTile=(random -1.0 1.0)
					
					a = #(45, 135, 225, 315)
					r = a[random 1 4]
					x.Map_Channel = spn_rxMch.value
					x.U_Offset = uTile
					x.V_Offset = vTile
					x.Rotation_Angle = r
					addmodifier o (x)
				)
			)
			if drop_rotate.selected=="90" then
			(
				for o in selection do
				(
					x = UVW_Xform() 
					uTile=(random -1.0 1.0)
					vTile=(random -1.0 1.0)
					
					a = #(90, 270)
					r = a[random 1 2]
					x.Map_Channel = spn_rxMch.value
					x.U_Offset = uTile
					x.V_Offset = vTile
					x.Rotation_Angle = r
					addmodifier o (x)
				)
			)
			if drop_rotate.selected=="180" then
			(
				for o in selection do
				(
					x = UVW_Xform() 
					uTile=(random -1.0 1.0)
					vTile=(random -1.0 1.0)
					
					a = #(0, 180)
					r = a[random 1 2]
					x.Map_Channel = spn_rxMch.value
					x.U_Offset = uTile
					x.V_Offset = vTile
					x.Rotation_Angle = r
					addmodifier o (x)
				)
			)
			if drop_rotate.selected=="360" then
			(
				for o in selection do
				(
					x = UVW_Xform() 
					uTile=(random -1.0 1.0)
					vTile=(random -1.0 1.0)
					x.Map_Channel = spn_rxMch.value
					x.U_Offset = uTile
					x.V_Offset = vTile
					x.Rotation_Angle = (random 0 360)
					addmodifier o (x)
				)
			)
			if drop_rotate.selected=="45/90" then
			(
				for o in selection do
				(
					x = UVW_Xform() 
					uTile=(random -1.0 1.0)
					vTile=(random -1.0 1.0)

					a = #(45, 90, 135, 180, 225, 270, 315, 360)
					r = a[random 1 8]
					x.Map_Channel = spn_rxMch.value
					x.U_Offset = uTile
					x.V_Offset = vTile
					x.Rotation_Angle = r
					addmodifier o (x)
				)
			)
			if drop_rotate.selected=="90/180" then
			(
				for o in selection do
				(
					x = UVW_Xform() 
					uTile=(random -1.0 1.0)
					vTile=(random -1.0 1.0)

					a = #(90, 270, 180)
					r = a[random 1 3]
					x.Map_Channel = spn_rxMch.value
					x.U_Offset = uTile
					x.V_Offset = vTile
					x.Rotation_Angle = r
					addmodifier o (x)
				)
			)
			macros.run "Modifier Stack" "Convert_to_Poly"
		)
		
	)
---***
	on btn_displ pressed do
	(
		item=VRayMtl
		for n in (getclassinstances item) do n.texmap_displacement_on=false
		item=CoronaMtl
		for n in (getclassinstances item) do n.texmapOnDisplacement = off
	)
	on btn_displ rightclick do
	(
		item=VRayMtl
		for n in (getclassinstances item) do n.texmap_displacement_on=true
		item=CoronaMtl
		for n in (getclassinstances item) do n.texmapOnDisplacement = on
	)
	
---***
	on btn_mat pressed do
	(
		m = 1
		tot = sceneMaterials.count
		for s in sceneMaterials do(
			mw = randColour()
			for o in (refs.Dependents s) do(
				if SuperClassOf o == GeometryClass then(
					try(
					o.wirecolor = mw
					)catch()
				)
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
				if SuperClassOf o == GeometryClass then(
					try(
					if o.isSelected == True then(o.wirecolor = mw)
					)catch()
				)
			)
			m += 1
		)
	)

----****
	on btn_rand pressed do
	(
		m = 1 
		tot = objects.count
		for o in objects do(
			try(
			o.wirecolor = randColour()
			)catch()
			m += 1
		)
	)
	on btn_rand rightclick do
	(
		m = 1 
		tot = objects.count
		for o in selection do(
			try(
			o.wirecolor = randColour()
			)catch()
			m += 1
		)
	)
----****

	on btn_uvwxform pressed do
	(
		undo on
		max create mode
		if selection.count==0 then () else
		(
			xf=UVW_Xform()
			xf.Map_Channel = spn_rxMch.value
			for obj in $selection do addmodifier obj (xf)
		)
		max modify mode
	)
----****
	on btn_matdel pressed do
	(
		undo on
		if selection.count==0 then ()
		else
		(
			$.material = NULL
		)
	)
----***
	)
--//////////////////////////////////////////////////////////////////////////////
rollout roll_Tools "Tools"
(
	button btn_gamma "2.2 Gamma" pos:[0,10] width:60 height:20 tooltip:"Applies 2.2 Gamma workflow."
	button btn_vSun "VSun" pos:[60,50] width:30 height:20 toolTip:"Creates mutant VRaySun with Dome."
	button btn_cSun "CSun" pos:[90,50] width:30 height:20 toolTip:"Creates Corona Sun and Corona Sky as envirement."
	
	button btn_Layers "Layers" pos:[60,10] width:60 height:20 tooltip:"Creates layers for architectural visualisation scene. E=Exterior, I=Interior, W=Windows. Right click to remove empy layers."
	button btn_cleaner "I'm Dirty!" pos:[120,10] width:60 height:20 tooltip:"Cleans empty layers, garbage, trackview nodes, fixes large file size problem, removing retimers..."
	dropdownlist drop_paper "" items:#(\
		"Select Paper Size",\
		"A0-A4 Paper",\
		"4:3(SDTV)",\
		"3:2(DSLR, 35mm)",\
		"5:3(16mm)",\
		"16:10(Widescreen)",\
		"16:9(HDTV)",\
		"1.85:1(Cinema Film)",\
		"2.35:1(CinemaScope)",\
		"2.76:1(Ultra Panavision 70)"\
		) pos:[76,30] width:105 tooltip:"Popular aspect ratios for output size." 
	checkbox cb_portrait pos:[62,33] width:12 tooltip:"Portrait mode for selected aspect ratio."
	spinner sp_pixels "" range:[1,32768,1920] pos:[0,32] fieldWidth:48 toolTip:"Set image resolution in pixels, the largest side." type:#integer

	button btn_copy "Copy" pos:[0,50] width:60 height:20 tooltip:"Copy (Save) selected for merging into another 3ds Max application."
	button btn_paste "Paste" pos:[0,70] width:60 height:20 tooltip:"Paste (Merges) previously Copied selection into exact position."
	button btn_save "+" pos:[160,70] width:20 height:20 tooltip:"Incremental Save."
	button btn_region "R" pos:[160,50] width:20 height:20 tooltip:"Set region."
	button btn_close "X" pos:[140,50] width:20 height:20 tooltip:"Close script."

	dropdownlist drop_minutes "" items:#("0","15","30","45","60") pos:[120,70] width:40 tooltip:"Quiet cuntown file save reminder. Select time in minutes. 0=no cuntdown"
	
	label lbl_sec "0" pos:[100,74] width:15
	label lbl_min "0" pos:[85,74] width:15
	
	checkbox cb_autoSave "" pos:[62,74] width:15 tooltip:"If checked autosave will occure when timer gets to 0. No ESC will work here."

	local tickSec = 59
	local tickMin = 30

	timer clock "testClock" interval:1000 active:false
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
		if cb_autoSave.checked then
		(
			actionMan.executeAction 0 "40006"
		)
		tickMin=drop_minutes.selected as integer -1
	)
	
	lbl_sec.text = tickSec as string
	lbl_min.text = tickMin as string
)
---***
on btn_region pressed do
(
	displaySafeFrames = true
	EditRenderRegion.EditRegion()
)
---***
on btn_save pressed do
(
    if maxFileName != "" then
	(
        max saveplus
    ) else checkForSave()
)
---***
on btn_copy pressed do
(
	if $ != undefined do
	saveNodes $ (getdir #autoback+"\mergefile.max")
)
on btn_paste pressed do
(
	mergemaxfile (getdir #autoback+"\mergefile.max") #select
)
----****
on drop_paper selected sel do
(
	renderSceneDialog.close()
	completeRedraw()
	pSize = sp_pixels.value as integer
	
	if drop_paper.selected=="5:3(16mm)" then
	(
		if cb_portrait.checked then
		(
			renderWidth = (pSize/1.666)
			renderHeight = pSize
		)
		else
		(
			renderWidth =pSize
			renderHeight = (pSize/1.666)
		)
	)
		if drop_paper.selected=="4:3(SDTV)" then
	(
		if cb_portrait.checked then
		(
			renderWidth = (pSize/1.333)
			renderHeight = pSize
		)
		else
		(
			renderWidth =pSize
			renderHeight = (pSize/1.333)
		)	
	)
		if drop_paper.selected=="3:2(DSLR, 35mm)" then
	(
		if cb_portrait.checked then
		(
			renderWidth = ceil (pSize/1.5)
			renderHeight = pSize
		)
		else
		(
			renderWidth = pSize
			renderHeight = ceil (pSize/1.5)
		)
	)
		if drop_paper.selected=="16:10(Widescreen)" then
	(
		if cb_portrait.checked then
		(
			renderWidth = ceil (pSize/1.6)
			renderHeight = pSize
		)
		else
		(
			renderWidth = pSize
			renderHeight = ceil (pSize/1.6)
		)
	)
		if drop_paper.selected=="16:9(HDTV)" then
	(
		if cb_portrait.checked then
		(
			renderWidth = ceil (pSize/1.778)
			renderHeight = pSize
		)
		else
		(
			renderWidth = pSize
			renderHeight = ceil (pSize/1.778)
		)
	)
		if drop_paper.selected=="1.85:1(Cinema Film)" then
	(
		if cb_portrait.checked then
		(
			renderWidth = ceil (pSize/1.85)
			renderHeight = pSize
		)
		else
		(
			renderWidth = pSize
			renderHeight = ceil (pSize/1.85)
		)
	)
		if drop_paper.selected=="2.35:1(CinemaScope)" then
	(
		if cb_portrait.checked then
		(
			renderWidth = ceil (pSize/2.35)
			renderHeight = pSize
		)
		else
		(
			renderWidth = pSize
			renderHeight = ceil (pSize/2.35)
		)
	)
		if drop_paper.selected=="A0-A4 Paper" then
	(
		if cb_portrait.checked then
		(
			renderWidth = ceil (pSize/1.414)
			renderHeight = pSize
		)
		else
		(
			renderWidth = pSize
			renderHeight  = ceil (pSize/1.414)
		)
	)
		if drop_paper.selected=="2.76:1(Ultra Panavision 70)" then
	(
		if cb_portrait.checked then
		(
			renderWidth = ceil (pSize/2.76)
			renderHeight = pSize
		)
		else
		(
			renderWidth = pSize
			renderHeight  = ceil (pSize/2.76)
		)
	)

	renderSceneDialog.update()
	if not displaysafeframes do displaysafeframes = true
	redrawViews()
)
----****
on btn_cleaner pressed do
	(	
		try
		(
			t=trackviewnodes;n=t[#Retimer_Manager];deleteTrackViewController t n.controller
			t=trackviewnodes;n=t[#Max_MotionClip_Manager];deleteTrackViewController t n.controller
			t=trackviewnodes;n=t[#Anim_Layer_Control_Manager];deleteTrackViewController t n.controller
			
			gc()
			print "Cleaned"
		)
		catch ("")
		
		freescenebitmaps()
		
		---***
		fn autocount =
		(
		local nCount = 0
		for mtl in getclassinstances vraymtl where mtl.option_clampTextures != true do nCount += 1
		nCount
		)
		
		fn clean =
		(
		for mtl in getclassinstances vraymtl where mtl.option_clampTextures != true do mtl.option_clampTextures = true
		)
		
	)
----****
	on btn_Layers rightclick do
	(
		(layerManager.getLayer 0).current = true
		
		for nLayer = layerManager.count to 2 by -1 do
		(
		local layer = layerManager.getLayer (nLayer - 1)
		
		local lNodes = undefined
		layer.nodes &lNodes
			
		if lNodes.count == 0 do layerManager.deleteLayerByName layer.name
		)
	)
on btn_Layers pressed do
	(
		LayerManager.newLayerFromName "#Cameras"
		LayerManager.newLayerFromName "#Lighting.Cam_01"
		LayerManager.newLayerFromName "#Lighting.Cam_02"
		LayerManager.newLayerFromName "#Lighting.Cam_03"
		LayerManager.newLayerFromName "#Lighting.Cam_04"
		LayerManager.newLayerFromName "#Lighting.Cam_05"
		
		LayerManager.newLayerFromName ".Scenery.Grass"
		LayerManager.newLayerFromName ".Scenery.Bushes"
		LayerManager.newLayerFromName ".Scenery.Trees"
		LayerManager.newLayerFromName ".Scenery.Gravel"
		
		LayerManager.newLayerFromName "_Street"
		LayerManager.newLayerFromName "_Street.Details"
		
		LayerManager.newLayerFromName "E_Walls"
		LayerManager.newLayerFromName "E_Facade"
		LayerManager.newLayerFromName "E_Ceilings"
		LayerManager.newLayerFromName "E_Floors"
		LayerManager.newLayerFromName "E_Doors"
		LayerManager.newLayerFromName "E_Railings"
		LayerManager.newLayerFromName "E_Railings.Glass"
		LayerManager.newLayerFromName "E_Roof.Flat"
		LayerManager.newLayerFromName "E_Roof.Tiles"
		LayerManager.newLayerFromName "E_Roof.Constr"
		LayerManager.newLayerFromName "E_Roof.Gutters"
		LayerManager.newLayerFromName "E_Collumns"
		LayerManager.newLayerFromName "E_Sunblinds"
		LayerManager.newLayerFromName "E_Stairs"
		LayerManager.newLayerFromName "E_Sunblinds"
		LayerManager.newLayerFromName "W_Glass"
		LayerManager.newLayerFromName "W_Frames"
		LayerManager.newLayerFromName "W_Shutters"
		
		LayerManager.newLayerFromName "I_Ceilings"
		LayerManager.newLayerFromName "I_Floors"
		LayerManager.newLayerFromName "I_Walls"
		LayerManager.newLayerFromName "I_Furniture"
		LayerManager.newLayerFromName "I_Curtains"
		LayerManager.newLayerFromName "I_Glass"
		LayerManager.newLayerFromName "I_Doors"
		LayerManager.newLayerFromName "I_Collumns"
		LayerManager.newLayerFromName "I_Stairs"
	)
----****
	on btn_vSun pressed do 
	(
		sunObj = vraysun pos:(point3 3000 -3000 3000)
		targetObj = vraylight pos:(point3 0 0 0)
		targetObj.lookat = sunObj
		
		select targetObj
		$.type = 1
		$.dome_spherical = on
		$.dome_affect_alpha = off
		$.on = off
		$.on = on
		$.castShadows = off
		$.castShadows = on
		$.DoubleSided = off
		$.invisible = off
		$.noDecay = off
		$.skylightPortal = off
		$.storeWithIrradMap = off
		$.affect_diffuse = off
		$.affect_diffuse = on
		$.affect_specualr = off
		$.affect_specualr = on
		$.affect_reflections = on
		$.multiplier = 1
		$.texmap_locktodome = 1
		$.texmap = VRaySky ()
		
		select sunObj

	 )
----****
	on btn_cSun pressed do 
	(
		sunObj = CoronaSun pos:(point3 3000 -3000 3000)
		targetObj = dummy pos:(point3 0 0 0)
		targetObj.lookat = sunObj
		select sunObj

		$.targeted = off
		$.targeted = on
		$.pos=[5000,-5000,5000]
		$.colormode = 2
		$.intensity = 1
		$.sizeMultiplier = 1
		environmentMap = CoronaSky ()
	 )
----****
	on btn_gamma pressed do
	(
		fileInGamma = 2.2
		fileOutGamma = 2.2
		IDisplayGamma.colorCorrectionMode = #gamma
		IDisplayGamma.gamma = 2.2
	)
)
--//////////////////////////////////////////////////////////////////////////////

rollout roll_Info "Info"
(
	label lbl_info "StrScipts, 2016." pos:[10,7]
	hyperlink bU "v2.27" pos:[150,7] address: \
	"http://www.scriptspot.com/3ds-max/scripts/strtools" color:black visitedcolor:black hoverColor:red
	
	label donate "Donate:" pos:[10,27]

		hyperlink b5 "-5-" pos:[55,27] address: \
	"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=J53LJ6S2GS4EE" color:green visitedcolor:green hoverColor:red
		hyperlink b10 "-10-" pos:[75,27] address: \
	"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=G483RJTJJXVJE" color:green visitedcolor:green hoverColor:red
		hyperlink b20 "-20-" pos:[100,27] address: \
	"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=QJRYKBKT3QAK6" color:green visitedcolor:green hoverColor:red

)
--//////////////////////////////////////////////////////////////////////////////

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
