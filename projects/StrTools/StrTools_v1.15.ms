macroScript StrTools category:"StrScripts"
(
---**** wirecolor tools
	struct vi_layers 
		(
		version = 1,
		man = LayerManager,
			fn getLayerList =
			(
			layers = #()
				for i = 0 to man.count do
				(
				l = man.getLayer i
					if l != undefined do
					(
					append layers l.name
					)
				)
			layers
			),
		fn getLayerNodes index =
		(
			if index <= man.count then
			(
			layer = man.getLayer index
				if layer != undefined then
				(
				layer.nodes &tempNodes
				return tempNodes
				)
			)else()
		)
		)
	fn randOffset k = (
		offset = [0,0,0]
		if k == 3 do (offset[1] = random 0.0 1.0; offset[2] = random 0.0 1.0; return offset)
		offset[k] = random 0.0 1.0
		return offset
	)

	fn calcPer val total =
	(
	ret = 100.0*val/total
	ret
	)
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
----Normal maps to vray normal maps
	local sioFile = dotNetClass "System.IO.File"
	fn getClassInstancesBy maxclass obj: = (if obj != unsupplied then (getClassInstances maxclass target:obj) else getClassInstances maxclass target:rootScene)
--//////////////////////////////////////////////////////////////////////////////
rollout roll_Geometry "Geometry and Shape"
(
	button btn_pivcust "P" pos:[140,0] width:20 height:20 toolTip:"Place pivot on object surface where you need it"
	button btn_pivbot "B" pos:[160,0] width:20 height:20 toolTip:"Place pivot on objects bottom"
	button btn_pivtop "T" pos:[180,0] width:20 height:20 toolTip:"Place pivot on objects top"
	button btn_pivcen "C" pos:[200,0] width:20 height:20 toolTip:"Place pivot in objects center"
	label lbl3 "Pivot placement" pos:[10,5] width:130 height:20
	----
	button btn_0 "0" pos:[140,20] width:20 height:20 toolTip:"Smooths all selected objects by 0"
	button btn_30 "30" pos:[160,20] width:20 height:20 toolTip:"Smooths all selected objects by 30"
	button btn_60 "60" pos:[180,20] width:20 height:20 toolTip:"Smooths all selected objects by 60"
	button btn_180 "180" pos:[200,20] width:20 height:20 toolTip:"Smooths all selected objects by 180"
	label lbl5 "Smooth objects for" pos:[10,22] width:100 height:20
	----
	button btn_weld "Vertex and normals" pos:[0,40] width:115 height:20 toolTip:"Fix geometry: vertex, unify normals and smoothing groops"
	button btn_edgeclean "Edge cleaner" pos:[115,40] width:115 height:20 toolTip:"Cleans edges on flat surfaces"
	----
	button btn_objrename "Rename" pos:[0,60] width:57.5 height:20 toolTip:"Rename all selected objects"
	editText txt_nname text:"Object" pos:[57.5,61.5] fieldWidth:52.5
	----
	button btn_eldetach "Detach" pos:[0,80] width:57.5 height:20 toolTip:"Detach all elements as separate objects"
	editText txt_dname text:"Element" pos:[57.5,81.5] fieldWidth:52.5
	----
	button btn_xformpoly "xForm O" pos:[115,60] width:57.5 height:20 toolTip:"Resets xForm on selected objects"
	button btn_xformspline "xForm S" pos:[115,80] width:57.5 height:20 toolTip:"Resets xForm on selected splines"
	----
	button btn_boxon "Box on" pos:[172.5,60] width:57.5 height:20 toolTip:"Display selected as box"
	button btn_boxoff "Box of" pos:[172.5,80] width:57.5 height:20 toolTip:"Display selected as object"
	----
	button btn_quadify "Quadify" pos:[57.5,100] width:57.5 height:20 toolTip:"Quadifies the selected mesh"
	button btn_insert "Insert" pos:[0,100] width:57.5 height:20 toolTip:"Insert edges and sets flow"
	---
	button btn_shell "Shell" pos:[115,100] width:57.5 height:20 toolTip:"Adds shell modifier to selected objects as instance"
	button btn_ffd2 "FFD2" pos:[172.5,100] width:57.5 height:20 toolTip:"Adds FFD 2x2x2 modifier to selected objects"

	on btn_ffd2 pressed do
	(
		undo on
		if selection.count==0 then messagebox "Select objects first." else
		(
			b = FFD_2x2x2 ()
			for obj in $selection do addmodifier obj (b)
		)
	)
----****
	on btn_shell pressed do
	(
		undo on
		if selection.count==0 then messagebox "Select objects first." else
		(
			b = Shell () 
			for obj in $selection do addmodifier obj (b)
		)
	)
----****
	on btn_pivcust pressed do
	(
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
		if selection.count==0 then
		(
			messagebox "Select objects first."
		)
		for i in Selection do
		(
			CenterPivot i
			i.pivot.z = i.min[3]
		)
		
	)
----****
	on btn_pivtop pressed do
	(
		undo on
		if selection.count==0 then
		(
			messagebox "Select objects first."
		)
		for i in Selection do
		(
			CenterPivot i
			i.pivot.z = i.max[3]
		)
	)
	on btn_pivcen pressed do
	(
		undo on
		if selection.count==0 then
		(
			messagebox "Select objects first."
		)
		for i in Selection do
		(
			CenterPivot i
			i.pivot = i.center
		)
	)
----****
	on btn_boxoff pressed do
	(
	undo on
	if selection.count==0 then
	(
		messagebox "Select objects first."
	)
	for o in Selection do
	(
		o.boxmode = off
	)
	)
----****
	on btn_boxon pressed do
	(
	undo on
	if selection.count==0 then
	(
		messagebox "Select objects first."
	)
	for o in selection do
	(
		o.boxmode = on
	)
	)
----****
	on btn_insert pressed do
	(
	undo on
	macros.run "PolyTools" "InsertLoop"
	macros.run "PolyTools" "SetFlow"
	)
----****
	on btn_quadify pressed do
	(
	selectedobjs = selection as array

	undo on
	for o in selectedobjs do
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
	if selection.count==0 then
	(
		messagebox "Select objects first."
	)
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
		subobjectLevel = 0
		clearSelection()
	)
----****
	)
	on btn_xformpoly pressed do
	(
	undo on
	if selection.count==0 then
	(
		messagebox "Select objects first."
	)
	for o in selection do
	(
	if( isKindOf o GeometryClass ) then -- only in geometry
		DoResetXform = true
		objarray = getCurrentSelection()
	for obj in objarray do (
		select obj
	if DoResetXform then (ResetXForm obj)
		macros.run "Modifier Stack" "Convert_to_Poly"
	)	
	)
	)
----****
	on btn_xformspline pressed do
	(
	undo on
	if selection.count==0 then
	(
		messagebox "Select splines first."
	)
	for o in selection do
	(
		resetxform $;
		macros.run "Modifier Stack" "Convert_to_Spline"
	)
	)
----****
	on btn_0 pressed do
	(
	undo on
		fn autoSmooth tresh: = if selection.count == 0 then (messageBox "Select Some Objects!" title:"Warning" beep:off) else
		(
			local poAS = polyop.setFaceSmoothGroup
			local moAS = meshop.autosmooth
			for o in selection where isKindOf o GeometryClass and not isKindOf o Targetobject do
			(
				if o.modifiers.count != 0 then addModifier o (smooth autosmooth:true threshold:tresh preventIndirect:true) else
				(
					case classof o of (
						(Editable_Poly): (poAS o o.faces tresh add:false)
						(Editable_Mesh): (moAS o o.faces tresh ; update o)
					)
				)
			)
		)
		autoSmooth tresh:0
	)
----****
	on btn_30 pressed do
	(
	undo on
		modPanel.addModToSelection (smooth ()) ui:on

		fn autoSmooth tresh: = if selection.count == 0 then (messageBox "Select objects first." title:"Warning" beep:off) else
		(
			local poAS = polyop.setFaceSmoothGroup
			local moAS = meshop.autosmooth
			for o in selection where isKindOf o GeometryClass and not isKindOf o Targetobject do
			(
				if o.modifiers.count != 0 then addModifier o (smooth autosmooth:true preventIndirect:true threshold:tresh) else
				(
					case classof o of (
						(Editable_Poly): (poAS o o.faces tresh add:false)
						(Editable_Mesh): (moAS o o.faces tresh ; update o)
					)
				)
			)
		)
		autoSmooth tresh:30
		macros.run "Modifier Stack" "Convert_to_Poly"
	)
----****
	on btn_60 pressed do
	(
	undo on
		modPanel.addModToSelection (smooth ()) ui:on
		fn autoSmooth tresh: = if selection.count == 0 then (messageBox "Select objects first." title:"Warning" beep:off) else
		(
			local poAS = polyop.setFaceSmoothGroup
			local moAS = meshop.autosmooth
			for o in selection where isKindOf o GeometryClass and not isKindOf o Targetobject do
			(
				if o.modifiers.count != 0 then addModifier o (smooth autosmooth:true threshold:tresh preventIndirect:true) else
				(
					case classof o of (
						(Editable_Poly): (poAS o o.faces tresh add:false)
						(Editable_Mesh): (moAS o o.faces tresh ; update o)
					)
				)
			)
		)
		autoSmooth tresh:60
		macros.run "Modifier Stack" "Convert_to_Poly"
	)
----****
	on btn_180 pressed do
	(
	undo on
		modPanel.addModToSelection (smooth ()) ui:on
		fn autoSmooth tresh: = if selection.count == 0 then (messageBox "Select objects first." title:"Warning" beep:off) else
		(
			local poAS = polyop.setFaceSmoothGroup
			local moAS = meshop.autosmooth
			for o in selection where isKindOf o GeometryClass and not isKindOf o Targetobject do
			(
				if o.modifiers.count != 0 then addModifier o (smooth autosmooth:true threshold:tresh preventIndirect:true) else
				(
					case classof o of (
						(Editable_Poly): (poAS o o.faces tresh add:false)
						(Editable_Mesh): (moAS o o.faces tresh ; update o)
					)
				)
			)
		)
		autoSmooth tresh:180
		macros.run "Modifier Stack" "Convert_to_Poly"
	)
----****
	on btn_eldetach pressed do
	(
		local n_name = txt_dname.text
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
----****
	on btn_weld pressed do
	(
		for o in selection do (  
		convertTo o editable_poly
		addmodifier o (vertex_weld threshold:0.01)
		addmodifier o (smooth autosmooth:true threshold:30)
		collapseStack o
		)
	)
	
)
--//////////////////////////////////////////////////////////////////////////////
rollout roll_Selections "Selections and Modifications" 
(
	button btn_allProxy "Proxies" pos:[63,10] width:57.5 height:20 tooltip:"Select all VRay Proxies in scene"
	button btn_proxybox "B" pos:[140,10] width:20 height:20 tooltip:"Display selected proxies as box"
	button btn_proxyfaces "F" pos:[160,10] width:20 height:20 tooltip:"Display selected proxies as faces"
	button btn_proxypoint "P" pos:[180,10] width:20 height:20 tooltip:"Display selected proxies as point"
	button btn_proxymesh "M" pos:[200,10] width:20 height:20 tooltip:"(VRay 3.1 and up) Display selected proxies as mesh"

	button btn_allHelpers "Helpers" pos:[0,10] width:57.5 height:20 tooltip:"Select all Helpers in scene"
	button btn_allGeometry "Geometry" pos:[0,30] width:57.5 height:20 tooltip:"Select all Geometry in scene"
	button btn_allSplines "Splines" pos:[0,50] width:57.5 height:20 tooltip:"Select all Splines and Shapes in scene"

	button btn_allCameras "Cameras" pos:[63,30] width:57.5 height:20 tooltip:"Select all Cameras in scene"
	dropdownlist drop_cameras "" items:#("Neutral", "Daylight", "D75", "D65", "D55", "D50") pos:[120,30] width:60 tooltip:"Sets white balance on selected VRay Physical Cameras"
	dropdownlist drop_camtarget "" items:#("on", "off") pos:[180,30] width:40 tooltip:"Sets on or off target on selected VRay Physical Cameras"
	
	button btn_allLights "Lights" pos:[63,50] width:57.5 height:20 tooltip:"Select all Lights in scene"
	dropdownlist drop_lightson "" items:#("on", "off") pos:[180,50] width:40 tooltip:"Turn on or off selected VRay Lights"
	colorpicker clr_lights "" color:[165,255,255] pos:[116,51] width:25 height:19 tooltip:"Sets the color of selected VRay Lights"
	dropdownlist drop_lightsub "" items:#("8", "12", "16", "24", "32") pos:[140,50] width:40 tooltip:"Turn on or off selected VRay Lights"

----****
	on btn_allHelpers pressed do
	(
		select (for h in helpers where h.category == #standard collect h)
	)
----****
	on btn_allLights pressed do
	(
		select (for l in lights collect l)
	)
-----****
	on drop_lightson selected i do
	(
		for l in selection where classOf l == VRayLight do
		(
			case drop_lightson.selection of
			(
			1: l.on = on
			2: l.on = off
			)
		)
	)
----****
	on drop_lightsub selected i do
	(
		for l in selection where classOf l == VRayLight do
		(
			case drop_lightsub.selection of
			(
			1: l.subdivs = 8
			2:	l.subdivs = 12
			3:	l.subdivs = 16
			4:	l.subdivs = 24
			5:	l.subdivs = 32
			)
		)
	)
----****
	on clr_lights changed new_col do
	(
		for l in selection where classOf l == VRayLight do
		(
			l.color = new_col
		)
	)
----****
	on btn_allCameras pressed do
	(
		select (for c in cameras collect c)
	)
----****
	on drop_cameras selected i do
	(
		for c in selection  where classof c == VRayPhysicalCamera do
		(
			c.whitebalance_preset = drop_cameras.selection
		)
	)
----****
	on drop_camtarget selected i do
	(
		for c in selection  where classof c == VRayPhysicalCamera do
		(
			case drop_camtarget.selection of
			(
			1: c.targeted = on
			2: c.targeted = off
			)
		)
	)
----****
	on btn_allSplines pressed do
	(
		select (for s in shapes where s.category == #splines collect s)
		SetSelectFilter 3
		actionMan.executeAction 0 "40021"
	)
----****
	on btn_allGeometry pressed do
	(
		select(for o in geometry where classOf o != VRayProxy collect o)
	)
----****
	on btn_allproxy pressed do
	(
		select (for o in objects where classOf o == VRayProxy collect o)
	)
----****
	on btn_proxybox pressed do
	(
		for p in selection where classOf p == VRayProxy do
		(
			p.display = 0
		)
	)
----****
	on btn_proxyfaces pressed do
	(
		for p in selection where classOf p == VRayProxy do
		(
			p.display = 3
		)
	)
----****
	on btn_proxypoint pressed do
	(
		for p in selection where classOf p == VRayProxy do
		(
			p.display = 2
		)
	)
----****
	on btn_proxymesh pressed do
	(
		for p in selection where classOf p == VRayProxy do
		(
			p.display = 4
		)
	)
)
--//////////////////////////////////////////////////////////////////////////////
rollout roll_Materials "Materials and Mapping"
(

---****
	checkbox cb_on "Override Gamma :" across:2 align:#left enabled:((maxVersion())[1] >= 16000) pos:[-200,10] visible:false
	spinner spn_gamma "" range:[-10,10,1.0] width:70 enabled:off pos:[-200,10] visible:false
	radiobuttons rb1 "" labels:#("VrayNormalMap", "NormalMap") columns:2 pos:[-200,10] visible:false

	button btn_uvwbox "Box" pos:[0,10] width:38 height:20 tooltip:"Applies an instanced UVW Box mapping on selected objects (600x600)"
	button btn_uvwplane "Plane" pos:[38.5,10] width:38 height:20 tooltip:"Applies an instanced UVW Plane mapping on selected objects (600x600)"
	spinner spn_uvwsize "" range:[1,99999,600] pos:[76,12] fieldWidth:50 toolTip:"Size of UVW"
	
	radiobuttons UVaxis labels:#("U","V","UV") default:3 visible:false
	button btn_vrayslap"xSlap" pos:[188,10] width:38 height:20 tooltip:"Random xform on elements. It requires UV cordinates."
	button btn_uvwxform "xForm" pos:[150,10] width:38 height:20 tooltip:"Applies UVW xForm modifier on selected objects"

	
	button btn_normalmap "Convert NormalMaps" pos:[0,30] width:115 height:20 tooltip:"Convert NormalMap to VrayNormalMap"
	radiobuttons rb2 "" labels:#("Selected", "All") columns:2 pos:[125,35] width:115 tooltip:"Convert NormalMap to VRayNormalMap on selected objects or all objects in scene"

	button btn_matdel "Remove" pos:[0,50] width:75.5 height:20 tooltip:"Removes materials on selected objects"
	button btn_vraymat "VRayMat" pos:[76,50] width:75.5 height:20 tooltip:"Selects all objects with VRayMat"
	
	button btn_mat "Material_Wire" width:75.5 pos:[0,70] tooltip:"Random wirecolor by material"
	button btn_rand "Random_Wire"  width:75.5 pos:[76,70] tooltip:"Random wirecolor"
	checkbox chk_ifSel "Selected"  width:75.5 pos:[155,73] tooltip:"Only selected is affected"

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
					if chk_ifSel.state == true then(
					if o.isSelected == True then(o.wirecolor = mw)
					)else(
					o.wirecolor = mw)
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
			if chk_ifSel.state == true then(
			if o.isSelected == true then(o.wirecolor = randColour())
			)else(
			o.wirecolor = randColour()
			)
			)catch()
			m += 1
		)
	)
---**** xform element random
	on btn_vrayslap pressed do
	(
		for o in selection do
		(
		modPanel.addModToSelection (Unwrap_UVW ()) ui:on
		if selection.count == 1 and (try($.unwrapuvw)catch(undefined)) != undefined  do (
		local moduvw = selection[1].modifiers[#unwrap_uvw]
		local vcnt=moduvw.unwrap.numbervertices()
		moduvw.unwrap.selectVertices #{1..vcnt}

		local vertelemarray=#()
		for i=1 to vcnt do vertelemarray[i]=0
		local elem=0
		modPanel.setCurrentObject moduvw
		subobjectlevel = 1
		for v=1 to vcnt do
		(
			if(vertelemarray[v]==0)then
			(
				moduvw.unwrap.selectVertices #{v}
				moduvw.unwrap2.SelectElement()
				elem+=1
				elemverts=moduvw.unwrap.getselectedvertices()

				for i in elemverts do
				(
					vertelemarray[i]=elem
				)
			)
		)
		subobjectlevel = 0
		local elemarray=#()
		for e=1 to elem do
		(
			local notFound = true
			for v=1 to vertelemarray.count while notFound do
			(
				if vertelemarray[v]==e then
				(
					elemarray[e]=v
					notFound = false
				)
			)
		)
		modPanel.setCurrentObject moduvw
		subobjectlevel = 1
		for i=1 to elemarray.count do
		(
			moduvw.unwrap.selectVertices #{elemarray[i]}
			moduvw.unwrap2.SelectElement()
			elemverts=moduvw.unwrap.getselectedvertices()
			koe = [0,0,0]

			offset = randOffset UVaxis.state
			for v in elemverts do
			(
				uvwpos = moduvw.unwrap.getVertexPosition 0 v
				uvwpos += offset
				moduvw.unwrap.setVertexPosition 0 v uvwpos
			)
		)
		subobjectlevel = 0
	)
		)
		modPanel.addModToSelection (UVW_Xform ()) ui:on
	)
----****
	on btn_vraymat pressed do
	(
		actionMan.executeAction 0 "40043"  -- Selection: Select None
		select (for v in objects where classOf v.material == VRayMtl collect v)
	)
----****
	on btn_uvwbox pressed do
	(
		undo on
		if selection.count==0 then messagebox "Select objects first." else
		(
			b = uvwmap() 
			b.maptype = 4
			b.length = spn_uvwsize.value
			b.width = spn_uvwsize.value
			b.height = spn_uvwsize.value
			for obj in $selection do addmodifier obj (b)
		)
	)
----****
	on btn_uvwplane pressed do
	(
		undo on
		if selection.count==0 then messagebox "Select objects first." else
		(
			b = uvwmap() 
			b.maptype = 0
			b.length = spn_uvwsize.value
			b.width = spn_uvwsize.value
			for obj in $selection do addmodifier obj (b)
		)
	)
----****
	on btn_uvwxform pressed do
	(
		undo on
		if selection.count==0 then messagebox "Select objects first." else
		(
			modPanel.addModToSelection (UVW_Xform ()) ui:on
		)
	)
----****
	on btn_matdel pressed do
	(
		undo on
		if selection.count==0 then messagebox "Select objects first." else
		(
			$.material = NULL
		)
	)
----****
on btn_normalmap pressed do
	(
		if scenematerials.count != 0 do
		(
			node = if rb1.state == 1 then dataPair a:VRayNormalMap b:Normal_Bump else dataPair a:Normal_Bump b:VRayNormalMap
			array = #()
			if rb2.state == 2 then array = getClassInstancesBy node.b else
			(
				if selection.count > 0 do
				(
					for o in selection where o.mat != undefined do join array (getClassInstancesBy node.b obj:o.mat)
					array = makeUniqueArray array
				)
			)
			if array.count > 0 do
			(
				with undo off for map in array do
				(
					e = node.a name:(map.name) normal_map:(map.normal_map)
					for mtl in refs.dependents map where isKindOf mtl material do 
					(
						if isKindOf mtl VRayMtl then mtl.texmap_bump = e else
						(
							bitarray = getClassInstancesBy VRayMtl obj:mtl
							for m in bitarray do m.texmap_bump = e
						)
					)
				) ; free array ; freeSceneBitmaps()
			)
		)
	)
	)
--//////////////////////////////////////////////////////////////////////////////
rollout roll_Tools "Tools"
(
	button btn_gamma "2.2 Gamma" pos:[0,10] width:75.5 height:20 tooltip:"Applies 2.2 Gamma workflow"
	button btn_Sun "Sun" pos:[77,10] width:38.5 height:20 toolTip:"Creates mutant VRaySun and VRaySky"
	spinner sp_defuse "D" range:[1,102,3] pos:[120,12] fieldWidth:30 toolTip:"Difusion of the sun"
	spinner sp_warm "W" range:[2,20,3] pos:[170,12] fieldWidth:30 toolTip:"Warmness os the sun"
	
	button btn_Layers "Layers" pos:[0,30] width:75.5 height:20 tooltip:"Creates layers for architectural visualisation scene"
	button btn_layerclean "Clean" pos:[76,30] width:38.5 height:20 tooltip:"Cleans empty layers in layer editor"
----****
on btn_layerclean pressed do
	(
		(LayerManager.getLayer 0).current = true
		for i = (LayerManager.count-1) to 1 by -1 do
		LayerManager.deleteLayerByName (LayerManager.getlayer i).name
	)
----****
on btn_Layers pressed do
	(
		LayerManager.newLayerFromName "#Camera_01"
		LayerManager.newLayerFromName "#Camera_02"
		LayerManager.newLayerFromName "#Camera_03"
		LayerManager.newLayerFromName "#Camera_04"
		
		LayerManager.newLayerFromName ".Plants_Grass"
		LayerManager.newLayerFromName ".Plants_Bushes"
		LayerManager.newLayerFromName ".Plants_Trees"
		LayerManager.newLayerFromName ".Plants_Hedge"
		LayerManager.newLayerFromName ".Street"
		LayerManager.newLayerFromName ".Street_Buildings"
		LayerManager.newLayerFromName ".Street_Fittings"
		LayerManager.newLayerFromName ".Street_Fittings"
		
		LayerManager.newLayerFromName "Ext_Walls"
		LayerManager.newLayerFromName "Ext_Facade"
		LayerManager.newLayerFromName "Ext_Furniture"
		LayerManager.newLayerFromName "Ext_Ceilings"
		LayerManager.newLayerFromName "Ext_Floors"
		LayerManager.newLayerFromName "Ext_Doors"
		LayerManager.newLayerFromName "Ext_Railings"
		LayerManager.newLayerFromName "Ext_Railings_Glass"
		LayerManager.newLayerFromName "Ext_Roof_Flat"
		LayerManager.newLayerFromName "Ext_Roof_Tiles"
		LayerManager.newLayerFromName "Ext_Roof_Constr"
		LayerManager.newLayerFromName "Ext_Collumns"
		LayerManager.newLayerFromName "Ext_Sunblinds"
		LayerManager.newLayerFromName "Ext_Stairs"
		LayerManager.newLayerFromName "Ext_Panels"
		
		LayerManager.newLayerFromName "Win_Glass"
		LayerManager.newLayerFromName "Win_Frames"
		LayerManager.newLayerFromName "Win_Rails"
		LayerManager.newLayerFromName "Win_Shutters"
		LayerManager.newLayerFromName "Win_Metal_Sheets"

		LayerManager.newLayerFromName "Int_Ceilings"
		LayerManager.newLayerFromName "Int_Floors"
		LayerManager.newLayerFromName "Int_Walls"
		LayerManager.newLayerFromName "Int_Furniture"
		LayerManager.newLayerFromName "Int_Curtains"
		LayerManager.newLayerFromName "Int_Glass"
		LayerManager.newLayerFromName "Int_Doors"
		LayerManager.newLayerFromName "Int_Collumns"
		LayerManager.newLayerFromName "Int_Stairs"
		
		LayerManager.newLayerFromName "Hidden"
	)
----****
	on btn_Sun pressed do 
	(
		mapSky = VRaySky name:"Sky"
		meditMaterials[24] = mapSky
		
		sunDome = VRayLight \
		pos:(point3 0 0 0) \
		intensityAt:100 \
		select:true \
		webfile:"{00000000-0000-0000-0000-000000000000}" \
		on:on \
		texmap_on:on \
		texmap_locktodome:0 \
		dome_spherical:on \
		dome_affect_alpha:on \
		multiplier:1 \
		affect_specualr:on \
		affect_reflections:on \
		subdivs:12 \
		castShadows:on \
		invisible:on \
		DoubleSided:off \
		noDecay:off \
		skylightPortal:off \
		storeWithIrradMap:off \
		affect_diffuse:on \
		castShadows:on \
		rgb:(color 255 255 255) \
		rgbFilter:(color 255 255 255) \
		intensity:540 \
		kelvin:6500 \
		type:1 \
		useKelvin:on \
		intensityType:0 \
		originalintensity:1500 \
		useMultiplier:off \
		shiftColorWhenDimming:off \
		useFarAttenuation:off \
		displayFarAttenuationGizmo:off \
		startFarAttenuation:80 \
		endFarAttenuation:200 \
		contrast:0 \
		softenDiffuseEdge:0 \
		projector:off \
		ambientOnly:off \
		targetDistance:240 \
		light_length:122 \
		light_Width:61 \
		light_Radius:13 \
		atmosShadows:off \
		atmosOpacity:100 \
		atmosColorAmt:100 \
		shadowMultiplier:1 \
		shadowColorMapEnable:off \
		shadowColor:(color 0 0 0) \
		lightAffectsShadow:off \
		useGlobalShadowSettings:off \
		hotspot:30 \
		falloff:60 \
		showCone:off \
		xRotation:0 \
		yRotation:0 \
		zRotation:0
		objID = amax (for o in objects collect o.inode.handle) 
		select (maxOps.getNodeByHandle objID)
		$.texmap = mapSky
		$.name = uniquename "Sun.Str.Target "
		
	targetObj = point pos:[0,0,0] radius:50 name:"Sun.Target " size:0
	sunObj = vraysun pos:(point3 5000 -5000 5000) \
		enabled:on \
		invisible:off \
		affect_diffuse:on \
		affect_diffuse:on \
		affect_specular:on \
		cast_atmospheric_shadows:on \
		turbidity:3 \
		ozone:0.35 \
		intensity_multiplier:1 \
		size_multiplier:3 \
		shadow_subdivs:12 \
		shadow_bias:0.2 \
		photon_emit_radius:50
		objID = amax (for o in objects collect o.inode.handle) 
		select (maxOps.getNodeByHandle objID)
		$.name = uniquename "Sun.S "
		$.size_multiplier = sp_defuse.value
		$.turbidity = sp_warm.value
		
		targetObj.lookat = sunObj
		targetObj.parent = sunDome
		setTransformLockFlags targetObj #all
		
		mapSky.manual_sun_node = on
		mapSky.sun_node = sunObj
	 )
----****
		on btn_gamma pressed do
	(
		fileInGamma = 2.2
		fileOutGamma = 2.2
		IDisplayGamma.colorCorrectionMode = #gamma -- enable Gamma
		IDisplayGamma.gamma = 2.2
	)
)
--//////////////////////////////////////////////////////////////////////////////
rollout roll_Info "Info"
(
	label lbl_info "StrScipts. v1.15" pos:[10,7]
	hyperlink hyp_don "Donate" pos:[180,7] address:"https://www.paypal.com/cgi-bin/webscr?cmd=_xclick&business=strale%2ecom%40hotmail%2ecom&lc=RS&item_name=StrTools&amount=5%2e00&currency_code=EUR&button_subtype=services&no_note=0&tax_rate=0%2e000&shipping=0%2e00&bn=PP%2dBuyNowBF%3abtn_buynowCC_LG%2egif%3aNonHostedGuest"
)
--//////////////////////////////////////////////////////////////////////////////
	roll_StrTools = newRolloutFLoater "Str_Tools" 240 510
	addRollout roll_Geometry roll_StrTools
	addRollout roll_Selections roll_StrTools
	addRollout roll_Materials roll_StrTools
	addRollout roll_Tools roll_StrTools
	addRollout roll_Info roll_StrTools
)