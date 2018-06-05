(* handle-ein.sml
 *
 * This code is part of the Diderot Project (http://diderot-language.cs.uchicago.edu)
 *
 * COPYRIGHT (c) 2016 The University of Chicago
 * All rights reserved.
 *)

structure HandleEin : sig

    val expand : MidIR.var * Ein.ein * MidIR.var list -> MidIR.assignment list

  end = struct
   
    structure E = Ein
    structure SrcIR = HighIR
    structure DstIR = MidIR
    structure ScanE = ScanEin
    structure H = Helper
    val ll = H.ll
    val prntNewbies = H.prntNewbies

    val flagmatch = true

  fun single_pass newbies = 
     let
        (* **************** split phase ************* *)
        fun iter([], ys) = ys
         | iter(e1::es, ys) = let
                val (lhs, DstIR.EINAPP(e, a)) = e1
                val y1 = FloatEin.transform (lhs, e, a)
                in
                    iter(es, ys@y1)
             end
        val newbies = iter(newbies, [])
        val _ = prntNewbies(newbies, "\n\n\npost split")
        (*val _ = ScanE.readIR_Split(newbies)*)
        val _ = (String.concat["Number of pieces:",Int.toString(length(newbies))])

        (* **************** expand-fem ************* *)
        val _ =  print"\n\n\nbefore translating fields"
        val newbies = List.foldr (fn (e,acc)=>  translateField.transform(e)@acc ) []  newbies
        (*val _ = prntNewbies(newbies, "\n\n\npost transform fields")*)
        val _ = ScanE.readIR_Split(newbies)                
        in newbies end 
                
    fun expand (lhs, ein, args) = let
            val _ = print("\n\n   ***********\n")
            val _ = print(String.concat["\n\n   expand ***********\n:",MidIR.Var.name(lhs),"=", EinPP.toString(ein),"-",ll(args,0)])
            val sliceFlag = Controls.get Ctl.sliceFlag
            val fullSplitFlag = Controls.get Ctl.fullSplitFlag
            val replaceFlag = Controls.get Ctl.replaceFlag
            (* ************** distribute and push Summation*********** *)
            val ein' = EinSums.transform ein
            val newbie = (lhs, DstIR.EINAPP(ein', args))
            (* ************** Scan and rewrite *********** *)
            val readIR = Controls.get Ctl.readEin
            val _ = if(readIR) then ScanE.readIR_Single(newbie,"tmp-High") else 1

            (*split and translate fields*)
            val newbies = single_pass([newbie])
            (*has to run multiple times in case a probe is embedded inside a cfexp*)
            val newbies = single_pass newbies
            (* ************** ProbeEIN *********** *)
            val _ = ("****about to call probe ein")
            (*   val _ = "about to call probe ein"*)
            val avail = AvailRHS.new()
            val _ = List.app  (ProbeEin.expand avail) newbies;
            val stmts = List.rev (AvailRHS.getAssignments avail)
            (*val _ = prntNewbies(stmts, "\n\n\npost probe ein ")*)
            val asgn = List.map DstIR.ASSGN stmts
            val _ = "exit"
            val _ = ("\n\n   ***********\n")
            in
                asgn
            end

  end (* HandleEin *)
